# Copyright © 2021 qualIP Software
#
# This file is part of shfuncs:
#
#     https://github.com/qualIP/shfuncs
#
# shfuncs is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# shfuncs is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# shfuncs; if not, write to the Free Software Foundation, Inc., 51 Franklin
# Street, Fifth Floor, Boston, MA 02110-1301 USA

if [ -z "${BASH_VERSION:-}${ZSH_VERSION:-}" ] ; then echo Not running bash or zsh! >&2 ; exit 1 ; fi

typeset -f screen_new_window > /dev/null && return

## screen_new_window [args ...]
screen_new_window() {
    if [[ "${WINDOW:+set}" = "set" ]] ; then
        screen -X screen "$@"
    elif [[ "${TMUX:+set}" = "set" ]] ; then
        tmux new-window "$@"
    else
        echo "Not running under screen/tmux!" >&2
        return 1
    fi
}

## screen_set_title [title ...]
screen_set_title() {
    if [[ "${WINDOW:+set}" = "set" ]] ; then
        screen -p "$WINDOW" -X title "$*"
    elif [[ "${TMUX_PANE:+set}" = "set" ]] ; then
        tmux rename-window -t "$TMUX_PANE" "$*"
    else
        # Assume compatible with xterm control sequences:
        # OSC P s ; P t ST
        # P s = 0 → Change Icon Name and Window Title to P t
        /bin/echo -n -e '\033]0;'"$*"'\007'
    fi
}

# vim: ft=bash
