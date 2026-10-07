#!/bin/sh
# hx-theme.sh - set the Helix theme, both live and on disk.
#
# Helix has no remote-control channel, so it cannot be re-themed from another
# terminal. This is the in-editor half: a keybinding calls it to switch the
# running instance, and it rewrites config.toml at the same time so the choice
# survives a restart.
#
# The mirror-image half is in theme.sh, which does the same rewrite when you
# type `light` or `dark` in a shell (that only affects the next launch).
#
#   hx-theme.sh light   -> acme
#   hx-theme.sh dark    -> amberwood
#   hx-theme.sh toggle  -> flip to whichever is not currently in config.toml
#   hx-theme.sh get     -> print the current theme name, nothing else
#
# Prints the resulting theme name on stdout so a keybinding can chain
# ":theme <name>" onto it.

set -u

CONFIG="${HELIX_CONFIG:-$HOME/.config/helix/config.toml}"

light() { printf 'acme\n'; }
dark() { printf 'amberwood\n'; }

current() {
    [ -r "$CONFIG" ] || return 1
    # First non-indented `theme = "..."` line; anchored so nested or
    # commented lines cannot match.
    sed -n 's/^theme[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -1
}

store() {
    [ -w "$CONFIG" ] || return 1
    tmp="$CONFIG.hx-theme.$$"
    if sed "s|^theme[[:space:]]*=.*|theme = \"$1\"|" "$CONFIG" >"$tmp" 2>/dev/null; then
        mv -f "$tmp" "$CONFIG" 2>/dev/null || { rm -f "$tmp"; return 1; }
        return 0
    fi
    rm -f "$tmp"
    return 1
}

cmd=${1:-get}

case $cmd in
light) want=acme ;;
dark) want=amberwood ;;
toggle)
    was=$(current) || was=amberwood
    if [ "$was" = acme ]; then
        want=amberwood
    else
        want=acme
    fi
    ;;
get)
    current
    exit 0
    ;;
*)
    printf 'usage: hx-theme.sh [light|dark|toggle|get]\n' >&2
    exit 1
    ;;
esac

store "$want" || true
printf '%s\n' "$want"