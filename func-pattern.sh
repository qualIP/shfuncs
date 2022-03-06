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

typeset -f is_glob_pattern > /dev/null && return

## is_glob_pattern string
#
# Returns wether the string looks like a glob pattern.
is_glob_pattern() {
    case "$1" in
        *\**|*\?*|*\[*\]*) return 0 ;;
        *)                 return 1 ;;
    esac
}

## is_regexp_pattern string
#
# Returns wether the string looks like a regular expression pattern.
is_regexp_pattern() {
    case "$1" in
        ^*|*\$|*\**) return 0 ;;
        *)         return 1 ;;
    esac
}

## expand_glob_pattern pat args...
#
# Print only arguments that match the specified glob pattern.
expand_glob_pattern() {
    local pat="$1" ; shift
    local v
    local ret=
    for v in "$@" ; do
        # shellcheck disable=SC2254
        case "$v" in
            $pat) ret="$ret $v" ;;
        esac
    done
    # shellcheck disable=SC2086
    echo $ret
}

# vim: ft=bash
