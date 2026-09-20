#!/bin/bash

# backoff.sh — sourceable bash library providing exponential backoff functions.
# Source this file from entrypoint.sh before use.
#
# Exposes:
#   backoff_reset              — delete the failure state file on successful startup
#   backoff_on_failure <code>  — sleep with exponential backoff then exit <code>
#   backoff_sleep_pid          — PID of the background sleep (if any); kill from
#                                trap_sigterm to interrupt the sleep promptly
#
# Depends on logging.sh being sourced by the caller before this file.

# PID of any in-progress background sleep subprocess.
# entrypoint.sh's trap_sigterm kills this PID to interrupt the sleep promptly.
backoff_sleep_pid=""

# Failures further apart than this many seconds are not a restart loop: the
# stored failure count is reset instead of continuing to grow, so a container
# that crashes rarely (e.g. weekly) is not punished with the maximum delay.
# Overridable mainly for tests.
BACKOFF_DECAY_SECONDS="${BACKOFF_DECAY_SECONDS:-3600}"

# backoff_reset
#   Delete ${CONTAINER_CACHE}/backoff_state.json if it exists; no-op otherwise.
backoff_reset() {
  # Disable errexit — this runs from an EXIT trap and must not re-trigger it.
  local old_opts
  old_opts=$(set +o)
  set +e
  local state_file="${CONTAINER_CACHE:-}/backoff_state.json"
  log_debug "backoff_reset: CONTAINER_CACHE='${CONTAINER_CACHE:-}'"
  if [[ -n "${CONTAINER_CACHE:-}" && -f "${state_file}" ]]; then
    log "Resetting backoff state after successful startup."
    rm -f "${state_file}"
    log_debug "backoff_reset: deleted ${state_file}"
  else
    log_debug "backoff_reset: no state file to remove (file absent or no cache dir)."
  fi
  eval "$old_opts"
}

# backoff_on_failure <exit_code>
#   Apply exponential backoff before exiting with <exit_code>.
#
#   Kubernetes environment (KUBERNETES_SERVICE_HOST set):
#     Log and return immediately — no file I/O, no sleep.
#
#   No cache directory (CONTAINER_CACHE unset or empty):
#     Log a warning and sleep indefinitely (interruptible by SIGTERM).
#     Exit 0 on SIGTERM (clean operator-initiated shutdown).
#
#   Cache directory configured:
#     Read state file (missing/corrupt → treat as consecutive_failures=0;
#     a last failure older than BACKOFF_DECAY_SECONDS also resets the count).
#     Compute delay = min(10 * 2^(n-2), 960) where n = consecutive_failures + 1.
#     Log failure count and delay.
#     Write updated state file atomically (.tmp + mv).
#     Sleep $delay in background (interruptible by SIGTERM).
#     Exit with original <exit_code>.
backoff_on_failure() {
  # Disable errexit for the entire function — this runs from an EXIT trap and
  # any unexpected command failure must not re-trigger the trap.
  set +e
  local exit_code="${1}"

  log_debug "backoff_on_failure: called with exit_code=${exit_code}"
  log_debug "backoff_on_failure: CONTAINER_CACHE='${CONTAINER_CACHE:-}'"
  log_debug "backoff_on_failure: KUBERNETES_SERVICE_HOST='${KUBERNETES_SERVICE_HOST:-}'"

  # ── Kubernetes bypass ──────────────────────────────────────────────────────
  if [[ -n "${KUBERNETES_SERVICE_HOST:-}" ]]; then
    log "Kubernetes environment detected.  Skipping backoff — CrashLoopBackOff will handle restart throttling."
    return
  fi

  # ── No cache directory ─────────────────────────────────────────────────────
  # Apply the same default as the install block: null → default path, empty → disabled.
  # Then attempt to create the directory. If it can't be created (e.g. permissions
  # failure before /data is writable), treat it as disabled and sleep indefinitely.
  if [[ -z "${CONTAINER_CACHE+x}" ]]; then
    CONTAINER_CACHE="/data/container_cache"
  fi

  if [[ -n "${CONTAINER_CACHE:-}" ]]; then
    if ! mkdir -p "${CONTAINER_CACHE}" 2> /dev/null; then
      log_warn "Cannot create CONTAINER_CACHE directory '${CONTAINER_CACHE}'.  Treating cache as disabled."
      CONTAINER_CACHE=""
    fi
  fi

  if [[ -z "${CONTAINER_CACHE:-}" ]]; then
    log_warn "No CONTAINER_CACHE available.  Cannot persist backoff state."
    log_warn "Sleeping indefinitely to prevent a restart loop.  Send SIGTERM to shut down."

    # Sleep in background so SIGTERM can interrupt it.
    sleep infinity &
    backoff_sleep_pid=$!
    log_debug "backoff_on_failure: indefinite sleep pid=${backoff_sleep_pid}"
    wait "${backoff_sleep_pid}" || true
    backoff_sleep_pid=""

    # SIGTERM during indefinite sleep → clean shutdown.
    trap - EXIT
    exit 0
  fi

  # ── Cache directory configured ─────────────────────────────────────────────

  local state_file="${CONTAINER_CACHE}/backoff_state.json"
  local tmp_file="${state_file}.tmp"

  # Read current consecutive_failures from state file.
  local consecutive_failures=0
  if [[ -f "${state_file}" ]]; then
    log_debug "backoff_on_failure: reading state file ${state_file}"
    local parsed
    parsed=$(jq --raw-output '.consecutive_failures // empty' "${state_file}" 2> /dev/null) || parsed=""
    if [[ "${parsed}" =~ ^[0-9]+$ ]]; then
      consecutive_failures="${parsed}"
      log_debug "backoff_on_failure: read consecutive_failures=${consecutive_failures}"
    else
      log_warn "Backoff state file is missing or corrupt.  Resetting failure count."
      consecutive_failures=0
    fi
  else
    log_debug "backoff_on_failure: no state file found, starting from consecutive_failures=0"
  fi

  # Guard the override before it reaches an arithmetic context, where a
  # non-numeric value would evaluate to 0 (a zero-width decay window).
  if ! [[ "${BACKOFF_DECAY_SECONDS}" =~ ^[0-9]+$ ]]; then
    log_warn "BACKOFF_DECAY_SECONDS must be a non-negative integer.  Found: '${BACKOFF_DECAY_SECONDS}'.  Using 3600."
    BACKOFF_DECAY_SECONDS=3600
  fi

  # Failures separated by more than BACKOFF_DECAY_SECONDS are independent
  # incidents, not a restart loop; start counting from scratch.
  if ((consecutive_failures > 0)); then
    local last_failure_epoch
    last_failure_epoch=$(jq --raw-output '.last_failure_epoch // empty' "${state_file}" 2> /dev/null) || last_failure_epoch=""
    if [[ "${last_failure_epoch}" =~ ^[0-9]+$ ]]; then
      local seconds_since_failure=$(($(date +%s) - last_failure_epoch))
      if ((seconds_since_failure > BACKOFF_DECAY_SECONDS)); then
        log "Last failure was ${seconds_since_failure}s ago (> ${BACKOFF_DECAY_SECONDS}s).  Resetting failure count."
        consecutive_failures=0
      fi
    fi
  fi

  # n is the failure count we are about to record (1-based for the formula).
  local n=$((consecutive_failures + 1))

  # Compute delay = min(10 * 2^(n-2), 960), with n=1 (first failure) exiting
  # immediately (delay=0) so the operator sees the error without waiting.
  # Cap the shift operand at 7 (n=9 → 960s) to avoid undefined behaviour from
  # large bit shifts when consecutive_failures grows very large.
  local delay
  if ((n <= 1)); then
    delay=0
  elif ((n >= 9)); then
    delay=960
  else
    delay=$((10 * (1 << (n - 2))))
  fi

  if ((delay == 0)); then
    log_warn "Failure ${n} detected (exit code ${exit_code}).  Exiting immediately."
  else
    log_warn "Failure ${n} detected (exit code ${exit_code}).  Waiting ${delay}s before exiting."
  fi

  # Write updated state file atomically.
  # If the write or rename fails (disk full, read-only volume, etc.), fall back
  # to the no-cache indefinite sleep so a broken write doesn't silently degrade
  # into a rapid restart loop.
  local timestamp epoch
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  epoch=$(date +%s)
  if ! printf '{"consecutive_failures":%d,"last_failure_timestamp":"%s","last_failure_epoch":%d}\n' \
    "${n}" "${timestamp}" "${epoch}" > "${tmp_file}" \
    || ! mv "${tmp_file}" "${state_file}"; then
    log_error "Failed to write backoff state file '${state_file}'.  Falling back to indefinite sleep."
    rm -f "${tmp_file}" 2> /dev/null
    sleep infinity &
    backoff_sleep_pid=$!
    log_debug "backoff_on_failure: indefinite sleep (write failure) pid=${backoff_sleep_pid}"
    wait "${backoff_sleep_pid}" || true
    backoff_sleep_pid=""
    trap - EXIT
    exit 0
  fi
  log_debug "backoff_on_failure: wrote state file ${state_file} (consecutive_failures=${n})"

  # Sleep in background so SIGTERM can interrupt it (skip if no delay).
  if ((delay > 0)); then
    sleep "${delay}" &
    backoff_sleep_pid=$!
    log_debug "backoff_on_failure: sleeping ${delay}s (pid=${backoff_sleep_pid})"
    wait "${backoff_sleep_pid}" || true
    backoff_sleep_pid=""
    log_debug "backoff_on_failure: sleep complete, exiting with code ${exit_code}"
  fi

  # Exit with the original non-zero exit code.
  trap - EXIT
  exit "${exit_code}"
}
