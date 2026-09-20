#!/bin/bash

# lifecycle.sh — sourceable bash library for child process lifecycle handling.
# Source this file from entrypoint.sh before use.
#
# Exposes:
#   wait_for_child <pid> <outvar> — wait until <pid> has actually terminated
#                                   and store its exit status in <outvar>
#
# Depends on logging.sh being sourced by the caller before this file.

# wait_for_child <pid> <outvar>
#   The bash `wait` builtin returns >128 as soon as a trapped signal is
#   received, *before* the child has exited.  The entrypoint runs as PID 1,
#   so returning at that point would end the container and cause the runtime
#   to SIGKILL the child mid-shutdown (e.g. Foundry flushing world data after
#   a forwarded SIGTERM).  Keep waiting until the child has really
#   terminated, then store its true exit status in <outvar>.
wait_for_child() {
  local pid="$1"
  local outvar="$2"
  local status
  # Run without errexit: nonzero wait statuses are expected here.
  local had_errexit=false
  if [[ $- == *e* ]]; then
    had_errexit=true
  fi
  set +e
  while true; do
    wait "${pid}"
    status=$?
    # A status <=128 is a real exit code.  Otherwise the wait may have been
    # interrupted by a trapped signal: only stop once the child is gone.
    # `kill -0` succeeds for zombies, so the follow-up `wait` still reaps
    # the real status.
    if ((status <= 128)) || ! kill -0 "${pid}" 2> /dev/null; then
      break
    fi
    log_debug "wait interrupted by a trapped signal (status ${status}).  Child pid ${pid} is still running; waiting again."
  done
  if [[ "${had_errexit}" == "true" ]]; then
    set -e
  fi
  printf -v "${outvar}" '%s' "${status}"
}
