# shellcheck shell=bash

# Prints the value of <key> in [<section>] of an INI file. Returns 1 if the
# file, section or key is missing
ini_get() {
    local file=$1 section=$2 key=$3
    [ -r "$file" ] || return 1
    awk -v section="$section" -v key="$key" '
        { sub(/\r$/, "") }
        /^[[:space:]]*[;#]/ { next }
        /^[[:space:]]*\[/ {
            s = $0
            sub(/^[[:space:]]*\[/, "", s)
            sub(/\].*$/, "", s)
            in_section = (s == section)
            next
        }
        in_section && index($0, "=") {
            eq = index($0, "=")
            k = substr($0, 1, eq - 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
            if (k != key) next
            v = substr($0, eq + 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
            print v
            found = 1
            exit
        }
        END { exit !found }
    ' "$file"
}

# spicetify config file
detect_config_file() {
    local file
    file="${SPICETIFY_CONFIG:-$HOME/.config/spicetify}/config-xpui.ini"
    [ -f "$file" ] || return 1
    echo "$file"
}

# spotify Contents/Resources directory
detect_spotify_resources() {
    local config dir=""
    if config="$(detect_config_file)"; then
        dir="$(ini_get "$config" Setting spotify_path)" || dir=""
    fi
    dir="${dir:-/Applications/Spotify.app/Contents/Resources}"
    [ -d "$dir" ] || return 1
    echo "${dir%/}"
}

detect_backup_version() {
    local config value
    config="$(detect_config_file)" || return 1
    value="$(ini_get "$config" Backup version)" || return 1
    [ -n "$value" ] || return 1
    echo "$value"
}

detect_backup_with() {
    local config value
    config="$(detect_config_file)" || return 1
    value="$(ini_get "$config" Backup with)" || return 1
    [ -n "$value" ] || return 1
    echo "$value"
}

detect_spicetify_bin() {
    command -v spicetify || return 1
}

detect_cli_version() {
    local bin version
    bin="$(detect_spicetify_bin)" || return 1
    version="$("$bin" -v 2>/dev/null | head -n 1)" || return 1
    version="$(echo "$version" | tr -d '[:space:]')"
    [ -n "$version" ] || return 1
    echo "$version"
}

detect_spotify_version() {
    local resources plist version
    resources="$(detect_spotify_resources)" || return 1
    plist="$resources/../Info.plist"
    [ -f "$plist" ] || return 1
    version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null)" || return 1
    [ -n "$version" ] || return 1
    echo "$version"
}

# return 0 if a backup version matches a spotify version. the backup has a
# build suffix (1.3.8.620.g39b276d5d7ac vs 1.3.8.620), so it matches when it
# equals the spotify version or it starts with it followed by a bot
versions_match() {
    local backup=$1 spotify=$2
    if [ -z "$backup" ] || [ -z "$spotify" ]; then
        return 1
    fi
    case "$backup" in
        "$spotify" | "$spotify".*) return 0 ;;
    esac
    return 1
}

# returns 0 if spotify is currently patches by spicetify
#
# the xpui folder has a spicetify helper and index.html loads it. a stock or
# freshly updated spotify only has xpui.spa, so both checks fail
detect_patch_present() {
    local resources xpui
    resources="$(detect_spotify_resources)" || return 1
    xpui="$resources/Apps/xpui"
    [ -f "$xpui/helper/spicetifyWrapper.js" ] || return 1
    grep -q 'spicetifyWrapper' "$xpui/index.html" 2>/dev/null
}

config_get() {
    local config value
    config="$(detect_config_file)" || return 1
    value="$(ini_get "$config" "$1" "$2")" || return 1
    [ -n "$value" ] || return 1
    echo "$value"
}

detect_theme() {
    config_get Setting current_theme
}

detect_color_scheme() {
    config_get Setting color_scheme
}

detect_extensions() {
    config AdditionalOptions extensions
}

detect_custom_apps() {
    config_get AdditionalOptions custom_apps
}

# prints the overall state from already-detected facts
detect_state() {
    local spotify=$1 backup=$2 patched=$3
    if [ -z "$backup" ]; then
        echo no_backup
    elif ! versions_match "$backup" "$spotify"; then
        echo spotify_updated
    elif [ "$patched" -ne 1 ]; then
        echo patch_missing
    else
        echo up_to_date
    fi
}
