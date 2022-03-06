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

typeset -f quote_args > /dev/null && return

OPT_DEBUG=${OPT_DEBUG:-false}
OPT_VERBOSE=${OPT_VERBOSE:-false}

_qip_func_args_saved_state=""
if [[ -n "${BASH_VERSION:-}" ]] ; then
    shopt -q extglob || _qip_func_args_saved_state+="shopt -u extglob"$'\n' ; shopt -s extglob
elif [[ -n "${ZSH_VERSION:-}" ]] ; then
    setopt KSH_GLOB
fi

quote_args() {
    local ret='' arg sfx
    # quote commas!
    for arg in "$@" ; do
        case "x$arg" in
            x)
                arg="''"
                ;;
            x+([A-Za-z0-9/@%:._=+-]))
                :  # arg="$arg"
                ;;
            x--+([A-Za-z0-9_-])=*) ;&
            x+([A-Za-z0-9_])=*)
                sfx="${arg#*=}"
                arg="${arg%%=*}='${sfx//\'/\'\\\'\'}'"
                ;;
            x*)
                arg="'${arg//\'/\'\\\'\'}'"
                ;;
        esac
        ret="$ret${ret:+ }$arg"
    done
    echo "$ret"
}

dquote_args() {
    local ret='' arg
    # quote commas!
    for arg in "$@" ; do
        case "x$arg" in
            x)
                arg='""'
                ;;
            x+([A-Za-z0-9/@%:._=+-]))
                :  # arg="$arg"
                ;;
            x--+([A-Za-z0-9_-])=*) ;&
            x+([A-Za-z0-9_])=*)
                sfx="${arg#*=}"
                sfx="${sfx//\$/\\\$}"
                arg="${arg%%=*}=\"${sfx//\"/\\\"}\""
                ;;
            x*)
                arg="${arg//\$/\\\$}"
                arg="\"${arg//\"/\\\"}\""
                ;;
        esac
        ret="$ret${ret:+ }$arg"
    done
    echo "$ret"
}

eval "$_qip_func_args_saved_state" ; unset _qip_func_args_saved_state

# vim: ft=bash
