#!/bin/sh
# hx-pos.sh - persist/restore the Helix cursor position per file.
#
#   hx-pos.sh save <file> <line> <col>   record the position for <file>
#   hx-pos.sh load <file>                print "<line>:<col>" (nothing if unknown)
#   hx-pos.sh key  <file>                print the store key for <file>
#
# Positions live in one file per file, keyed by a hash of the absolute path,
# so a file can be renamed or deleted without leaving stale entries behind to
# accumulate in a single shared file.

set -u

store="${XDG_STATE_HOME:-$HOME/.local/state}/helix/positions"

# Absolute, symlink-resolved path, so "hx ./a.rs" and "hx b/../a.rs" agree.
abspath() {
    ( CDPATH= cd -- "$(dirname -- "$1")" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$(basename -- "$1")" )
}

key() {
    printf '%s' "$1" | sha256sum | cut -c1-40
}

cmd=${1:-}
case $cmd in
save)
    file=${2:-}
    line=${3:-1}
    col=${4:-1}
    [ -n "$file" ] || exit 0
    # Scratch buffers have no path; nothing to remember.
    case $file in
    '<empty>' | '[scratch]') exit 0 ;;
    esac
    # A non-numeric line or column means the filename was mangled upstream
    # (e.g. it contained a quote and got word-split). Bail out rather than
    # record a bogus position.
    case ${line:-x} in '' | *[!0-9]*) exit 0 ;; esac
    case ${col:-x} in '' | *[!0-9]*) exit 0 ;; esac
    path=$(abspath "$file") || exit 0
    mkdir -p "$store" || exit 0
    tmp="$store/$(key "$path").tmp.$$"
    if printf '%s %s\n' "$line" "$col" >"$tmp" 2>/dev/null; then
        mv -f "$tmp" "$store/$(key "$path")" 2>/dev/null || rm -f "$tmp" 2>/dev/null
    fi
    ;;
load)
    file=${2:-}
    [ -n "$file" ] || exit 0
    path=$(abspath "$file") || exit 0
    f="$store/$(key "$path")"
    [ -r "$f" ] || exit 0
    read -r line col <"$f" || exit 0
    case ${line:-x} in '' | *[!0-9]*) exit 0 ;; esac
    case ${col:-x} in '' | *[!0-9]*) exit 0 ;; esac
    printf '%s:%s\n' "$line" "$col"
    ;;
key)
    file=${2:-}
    [ -n "$file" ] || exit 0
    path=$(abspath "$file") || exit 0
    printf '%s\n' "$(key "$path")"
    ;;
esac

exit 0
