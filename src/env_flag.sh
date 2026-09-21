#!/bin/bash

# env_flag.sh — sourceable bash library for boolean environment variables.
# Source this file after logging.sh.
#
# Accepted forms, case-insensitive:
#   truthy: 1, true, yes, on
#   falsy:  0, false, no, off, empty, unset
# Any other value logs a warning naming the variable and is treated as
# unset, so a typo falls back to the variable's documented default instead
# of silently flipping behavior.
#
# Exposes:
#   env_is_true <name>   — 0 when the named variable is truthy
#   env_is_false <name>  — 0 when the named variable is explicitly falsy
#                          (for default-true toggles: unset is NOT false)

_env_flag_warn() {
  log_warn "$1 has unrecognized value '$2'.  Expected true/false (also accepted: 1/0, yes/no, on/off).  Treating it as unset."
}

env_is_true() {
  local name="$1"
  local value="${!name:-}"
  case "${value,,}" in
    1 | true | yes | on) return 0 ;;
    0 | false | no | off | "") return 1 ;;
    *)
      _env_flag_warn "${name}" "${value}"
      return 1
      ;;
  esac
}

env_is_false() {
  local name="$1"
  local value="${!name:-}"
  case "${value,,}" in
    0 | false | no | off) return 0 ;;
    1 | true | yes | on | "") return 1 ;;
    *)
      _env_flag_warn "${name}" "${value}"
      return 1
      ;;
  esac
}
