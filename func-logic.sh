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

typeset -f bool > /dev/null && return

bool() {
    local b="$*"
    case "$b" in
        # Fast
        true) echo true ;;
        false) echo false ;;
        # Slow
        *)
            case "$(tr '[:upper:]' '[:lower:]' <<<"$b")" in
                true) echo true ;;
                y|yes) echo true ;;
                on) echo true ;;
                false) echo false ;;
                n|no) echo false ;;
                off) echo false ;;
                "") echo false ;;
                *) "$@" && echo true || echo false ;;
            esac
            ;;
    esac
}

bool_not() {
    local b ; b=$(bool "$@")
    $b && echo false || echo true
}

bool_and() {
    local b=false
    for b in "$@" ; do
        "$(bool "$b")" || break
    done
    echo "$b"
}

bool_or() {
    local b=false
    for b in "$@" ; do
        "$(bool "$b")" && break
    done
    echo "$b"
}

bool_xor() {
    if (( $# != 2 )) ; then
        echo "Invalid xor syntax" >&2
        return 1
    fi
    [[ $(bool "$1") = $(bool "$2") ]] && echo false || echo true
}

# vim: ft=bash
