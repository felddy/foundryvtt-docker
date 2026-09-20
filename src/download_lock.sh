#!/bin/bash

# download_lock.sh — sourceable bash library arbitrating release downloads
# between container instances that share a CONTAINER_CACHE volume.
# Source this file from entrypoint.sh before use.
#
# Coordination is purely filesystem-based, so it works across containers,
# hosts, and cluster nodes mounting the same cache volume:
#   * mutual exclusion — atomic mkdir of a per-release lock directory
#   * liveness — progress of the in-progress download files, measured as
#     size deltas between our own successive polls (immune to clock skew
#     between nodes and to NFS attribute-cache lag)
#   * crash recovery — a stalled holder's lock is stolen with an atomic
#     rename, so two waiters can never both claim the same stale lock
#
# Exposes:
#   download_slot_acquire <lock_dir> <release_file> <temp_glob>
#     0 → slot acquired: caller downloads, then calls download_slot_release
#     1 → release file appeared: nothing to download, no lock held
#     2 → degraded: locking impossible (e.g. read-only cache), no lock held
#     3 → gave up: steal limit reached on a stalled lock, no lock held
#   download_slot_release
#     Release the lock if this process holds one.  Safe to call
#     unconditionally, including from EXIT traps.
#
# Tunables (mainly for tests):
#   DOWNLOAD_LOCK_POLL_SECONDS  seconds between polls          (default 5)
#   DOWNLOAD_LOCK_STALL_TICKS   polls without progress before the holder
#                               is presumed dead               (default 60)
#   DOWNLOAD_LOCK_STEAL_LIMIT   stale locks stolen before giving up
#                                                              (default 3)
#
# Depends on logging.sh being sourced by the caller before this file.

DOWNLOAD_LOCK_POLL_SECONDS="${DOWNLOAD_LOCK_POLL_SECONDS:-5}"
DOWNLOAD_LOCK_STALL_TICKS="${DOWNLOAD_LOCK_STALL_TICKS:-60}"
DOWNLOAD_LOCK_STEAL_LIMIT="${DOWNLOAD_LOCK_STEAL_LIMIT:-3}"

# The tunables feed arithmetic contexts and sleep; a non-numeric override
# would abort startup under nounset/errexit, and a leading zero would be
# read as octal.  Fall back to the defaults with a warning instead.
if ! [[ "${DOWNLOAD_LOCK_POLL_SECONDS}" =~ ^[0-9]*\.?[0-9]+$ ]] \
  || [[ "${DOWNLOAD_LOCK_POLL_SECONDS}" =~ ^[0.]+$ ]]; then
  log_warn "DOWNLOAD_LOCK_POLL_SECONDS must be a positive number.  Found: '${DOWNLOAD_LOCK_POLL_SECONDS}'.  Using 5."
  DOWNLOAD_LOCK_POLL_SECONDS=5
fi
if [[ "${DOWNLOAD_LOCK_STALL_TICKS}" =~ ^[0-9]+$ ]]; then
  DOWNLOAD_LOCK_STALL_TICKS=$((10#${DOWNLOAD_LOCK_STALL_TICKS}))
else
  log_warn "DOWNLOAD_LOCK_STALL_TICKS must be a non-negative integer.  Found: '${DOWNLOAD_LOCK_STALL_TICKS}'.  Using 60."
  DOWNLOAD_LOCK_STALL_TICKS=60
fi
if [[ "${DOWNLOAD_LOCK_STEAL_LIMIT}" =~ ^[0-9]+$ ]]; then
  DOWNLOAD_LOCK_STEAL_LIMIT=$((10#${DOWNLOAD_LOCK_STEAL_LIMIT}))
else
  log_warn "DOWNLOAD_LOCK_STEAL_LIMIT must be a non-negative integer.  Found: '${DOWNLOAD_LOCK_STEAL_LIMIT}'.  Using 3."
  DOWNLOAD_LOCK_STEAL_LIMIT=3
fi

# Lock directory currently held by this process, if any.
_download_lock_held=""

# In a container the entrypoint's PID is always 1 and a restarted container
# keeps its hostname, so this id is stable per run but not across runs —
# which is exactly what the owner file (debug info only) needs.
_download_lock_instance_id() {
  printf '%s-%s' "${HOSTNAME:-unknown}" "$$"
}

# _download_lock_try <lock_dir> → 0 acquired / 1 busy / 2 cannot lock
_download_lock_try() {
  local lock_dir="$1"
  if mkdir "${lock_dir}" 2> /dev/null; then
    _download_lock_held="${lock_dir}"
    # Debug info only: PIDs are meaningless across containers and nodes,
    # so liveness is judged by download progress, never by this file.
    _download_lock_instance_id > "${lock_dir}/owner" 2> /dev/null || true
    return 0
  fi
  if [[ -d "${lock_dir}" ]]; then
    return 1
  fi
  return 2
}

download_slot_release() {
  local owner
  if [[ -n "${_download_lock_held}" ]]; then
    # Only remove the directory if it is still the one this process created.
    # After a steal-and-reacquire the same path belongs to a newer holder,
    # and deleting it would break mutual exclusion for everyone waiting.
    # A missing owner file is treated as "not ours": it may be a new
    # holder's mkdir caught before its owner write, and an ownerless lock
    # of our own is self-healing (it stalls and gets stolen).
    owner=$(cat "${_download_lock_held}/owner" 2> /dev/null) || owner=""
    if [[ "${owner}" == "$(_download_lock_instance_id)" ]]; then
      log_debug "download_lock: releasing ${_download_lock_held}"
      rm -rf "${_download_lock_held}" 2> /dev/null || true
    else
      log_debug "download_lock: not removing ${_download_lock_held}: owner is '${owner:-unknown}', not us"
    fi
    _download_lock_held=""
  fi
}

# _download_progress_signature <temp_glob>
#   Print a signature of every in-progress file matching the glob.  A change
#   between two of our own polls means the download is alive; comparing our
#   successive observations avoids trusting any node's clock.
_download_progress_signature() {
  local sig="" f
  while IFS= read -r f; do
    [[ -f "${f}" ]] || continue
    # wc -c on a regular file is fstat/lseek in both GNU coreutils and BSD
    # (a 4 GB file answers in milliseconds) — metadata only, chosen over
    # stat because the -c/-f flag split makes stat non-portable.
    sig+="${f}=$(wc -c < "${f}" 2> /dev/null || printf '?');"
  done < <(compgen -G "$1" 2> /dev/null || true)
  printf '%s' "${sig}"
}

download_slot_acquire() {
  local lock_dir="$1"
  local release_file="$2"
  local temp_glob="$3"
  local steals=0
  local rc sig last_sig ticks stale_dir

  while true; do
    # The release may have been produced since we last looked.
    if [[ -f "${release_file}" ]]; then
      return 1
    fi

    if _download_lock_try "${lock_dir}"; then
      rc=0
    else
      rc=$?
    fi

    if ((rc == 0)); then
      # Double-check after winning: another instance may have finished
      # between our release check and the mkdir.
      if [[ -f "${release_file}" ]]; then
        download_slot_release
        return 1
      fi
      log_debug "download_lock: acquired ${lock_dir}"
      return 0
    fi

    if ((rc == 2)); then
      log_warn "Cannot create download lock '${lock_dir}'.  Proceeding without download arbitration."
      return 2
    fi

    # Lock is busy: wait, watching the holder's progress.
    log "Another instance is downloading this release.  Waiting for it to finish..."
    last_sig=$(_download_progress_signature "${temp_glob}")
    ticks=0
    while [[ -d "${lock_dir}" ]]; do
      if [[ -f "${release_file}" ]]; then
        return 1
      fi
      sig=$(_download_progress_signature "${temp_glob}")
      if [[ "${sig}" != "${last_sig}" ]]; then
        last_sig="${sig}"
        ticks=0
      else
        ticks=$((ticks + 1))
        if ((ticks >= DOWNLOAD_LOCK_STALL_TICKS)); then
          if ((steals >= DOWNLOAD_LOCK_STEAL_LIMIT)); then
            log_error "Download lock '${lock_dir}' is stalled and the steal limit (${DOWNLOAD_LOCK_STEAL_LIMIT}) is reached.  Giving up."
            return 3
          fi
          # Atomic rename claims the stale lock: exactly one waiter's mv
          # succeeds, so two waiters can never both steal.  The RANDOM
          # suffix keeps a leftover stale directory from a previous run
          # turning this mv into a move-into-directory.
          stale_dir="${lock_dir}.stale.$(_download_lock_instance_id)-${RANDOM}"
          if mv "${lock_dir}" "${stale_dir}" 2> /dev/null; then
            steals=$((steals + 1))
            log_warn "Download lock holder is not making progress.  Stole stale lock (steal ${steals}/${DOWNLOAD_LOCK_STEAL_LIMIT})."
            rm -rf "${stale_dir}" 2> /dev/null || true
          fi
          # Whether we or another waiter stole it, retry acquisition.
          break
        fi
      fi
      sleep "${DOWNLOAD_LOCK_POLL_SECONDS}"
    done
    # Lock gone (released or stolen): loop and try again.
  done
}
