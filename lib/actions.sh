# shellcheck shell=bash
#
# Things that change the system. Every change goes through run_cmd, so
# --dry-run and the log file work for all of them.

# How long to wait for Spotify to quit before force-quitting it, in seconds
SPOTIFY_QUIT_TIMEOUT=10

# Returns 0 if Spotify is running. -x matches the main process only, not
# the "Spotify Helper" processes.
spotify_is_running() {
    pgrep -x Spotify >/dev/null
}

# Waits up to <seconds> for Spotify to exit. Returns 1 if it's still running.
_spotify_wait_for_exit() {
    local i=0
    while spotify_is_running; do
        if [ "$i" -ge "$1" ]; then
            return 1
        fi
        sleep 1
        i=$((i + 1))
    done
}

# Quits Spotify if it's running: asks it to quit, then force-quits it after
# SPOTIFY_QUIT_TIMEOUT seconds. Returns 1 if it still won't close.
spotify_quit() {
    if ! spotify_is_running; then
        log_debug "Spotify isn't running"
        return 0
    fi
    log_step "Quitting Spotify"
    # A failure here (e.g. no Automation permission) is fine: the timeout
    # and pkill below still close it
    run_cmd osascript -e 'quit app "Spotify"' || true
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        return 0
    fi
    if _spotify_wait_for_exit "$SPOTIFY_QUIT_TIMEOUT"; then
        return 0
    fi
    log_warn "Spotify didn't quit after ${SPOTIFY_QUIT_TIMEOUT}s; force-quitting it"
    run_cmd pkill -x Spotify || true
    if _spotify_wait_for_exit 5; then
        return 0
    fi
    log_error "couldn't quit Spotify"
    return 1
}

# Opens Spotify.
spotify_launch() {
    log_step "Opening Spotify"
    run_cmd open -a Spotify
}

# Reopens Spotify at the end of a manual run, unless --no-relaunch was given.
spotify_relaunch() {
    if [ "${NO_RELAUNCH:-0}" -eq 1 ]; then
        log_info "Not reopening Spotify (--no-relaunch)"
        return 0
    fi
    spotify_launch
}
