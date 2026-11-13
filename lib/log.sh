# shellcheck shell=bash
#
# Logging helpers. Terminal output respects -q/-v and NO_COLOR; the log file
# always gets every message, with timestamps and without colors.

# Path of this run's log file. Empty until log_init runs (or if it fails).
LOG_FILE=""

# Appends a timestamped line to the log file, if there is one.
_log_file() {
    [ -n "$LOG_FILE" ] || return 0
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >>"$LOG_FILE"
}

_log_print() {
    local fd=$1 color=$2 prefix=$3 msg=$4
    if [ -n "$color" ] && [ -z "${NO_COLOR:-}" ] && [ -t "$fd" ]; then
        printf '\033[%sm%s\033[0m%s\n' "$color" "$prefix" "$msg" >&"$fd"
    else
        printf '%s%s\n' "$prefix" "$msg" >&"$fd"
    fi
}

log_error() {
    _log_file ERROR "$*"
    _log_print 2 '31' 'error: ' "$*"
}

log_warn() {
    _log_file WARN "$*"
    _log_print 2 '33' 'warning: ' "$*"
}

# hidden by -q
log_info() {
    _log_file INFO "$*"
    if [ "${VERBOSITY:-1}" -ge 1 ]; then
        _log_print 1 '' '' "$*"
    fi
}

# a headline for each stage of a run
log_step() {
    _log_file STEP "$*"
    if [ "${VERBOSITY:-1}" -ge 1 ]; then
        _log_print 1 '1;34' '==> ' "$*"
    fi
}

# only shown with -v
log_debug() {
    _log_file DEBUG "$*"
    if [ "${VERBOSITY:-1}" -ge 2 ]; then
        _log_print 2 '2' 'debug: ' "$*"
    fi
}

# opens todays log file in ~/Library/Logs/spicetify-updater/ and marks the
# start of this run. If the file can't be created, warns and carries on
# without one
log_init() {
    local dir file
    dir="$HOME/Library/Logs/spicetify-updater"
    file="$dir/$(date '+%Y-%m-%d').log"
    if ! mkdir -p "$dir" 2>/dev/null || ! touch "$file" 2>/dev/null; then
        log_warn "can't write to $file; continuing without a log file"
        return 0
    fi
    LOG_FILE="$file"
    _log_file INFO "--- spicetify-updater${*:+ $*} (pid $$)"
}

run_cmd() {
    local cmd status=0
    cmd="$(printf '%q ' "$@")"
    cmd="${cmd% }"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_info "[dry-run] $cmd"
        return 0
    fi
    log_debug "running: $cmd"
    if [ -n "$LOG_FILE" ]; then
        "$@" > "$LOG_FILE" 2>&1 || status=$?
    else
        "$@" || status=$?
    fi
    if [ "$status" -ne 0 ]; then
        log_debug "exit $status: $cmd"
    fi
    return "$status"
}
