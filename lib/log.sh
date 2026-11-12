# shellcheck shell=bash
#
# Logging helpers. Terminal output respects -q/-v and NO_COLOUR

_log_print() {
    local fd=$1 color=$2 prefix=$3 msg=$4
    if [ -n "$color" ] && [ -z "${NO_COLOR:-}" ] && [ -t "$fd" ]; then
        printf '\033[%sm%s\033[0m%s\n' "$color" "$prefix" "$msg" >&"$fd"
    else
        printf '%s%s\n' "$prefix" "$msg" >&"$fd"
    fi
}

log_error() {
    _log_print 2 '31' 'error: ' "$*"
}

log_warn() {
    _log_print 2 '33' 'warning: ' "$*"
}

# hidden by -q
log_info() {
    if [ "${VERBOSITY:-1}" -ge 1 ]; then
        _log_print 1 '' '' "$*"
    fi
}

# a headline for each stage of a run
log_step() {
    if [ "${VERBOSITY:-1}" -ge 1 ]; then
        _log_print 1 '1;34' '==> ' '$*'
    fi
}

# only shown with -v
log_debug() {
    if [ "${VERBOSITY:-1}" -ge 2 ]; then
        _log_print 2 '2' 'debug: ' "$*"
    fi
}
