# Copyright © 2022 qualIP Software
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

typeset -f prompt_q > /dev/null && return

# shellcheck disable=all
SHFUNCS_DIR=${SHFUNCS_DIR:-$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")}
. "$SHFUNCS_DIR/func-print.sh"
. "$SHFUNCS_DIR/func-list.sh"

_qip_func_prompt_saved_state=""
if [[ -n "${BASH_SOURCE:-}" ]] ; then
    shopt -q extglob || _qip_func_args_saved_state+="shopt -u extglob"$'\n' ; shopt -s extglob
fi

prompt_q() {
    local _prompt_q_var=$1 ; shift
    local _prompt_q_q=$1 ; shift
    local _prompt_q_a=
    while true ; do
        print_q "$_prompt_q_q"
        read -r _prompt_q_a
        _last_print_is_nl=false
        if [[ -z "$_prompt_q_a" ]] ; then
            print_err "Answer required"
            continue
        fi
        break
    done
    declare -g "$_prompt_q_var=$_prompt_q_a"
}

prompt_q_default() {
    local _prompt_q_var=$1 ; shift
    local _prompt_q_q=$1 ; shift
    local _prompt_q_default=$1 ; shift
    local _prompt_q_a=
    while true ; do
        print_q "$_prompt_q_q" "" "$_prompt_q_default"
        read -r _prompt_q_a
        _last_print_is_nl=false
        # Default
        if [[ -z "$_prompt_q_a" ]] ; then
            _prompt_q_a="$_prompt_q_default"
            break
        fi
        # Validation
        break
    done
    declare -g "$_prompt_q_var=$_prompt_q_a"
}

prompt_q_choices() {
    local _prompt_q_var=$1 ; shift
    local _prompt_q_q=$1 ; shift
    local _prompt_q_choices_arr=( "$@" )
    local _prompt_q_c=
    local _prompt_q_a=
    while true ; do
        print_em "Choices"
        for _prompt_q_c in "${_prompt_q_choices_arr[@]}" ; do
            print_li "$_prompt_q_c"
        done
        print_q "$_prompt_q_q" ""
        read -r _prompt_q_a
        _last_print_is_nl=false
        # Default
        # Validation
        if ! lcontain "$_prompt_q_a" "${_prompt_q_choices_arr[@]}" ; then
            print_err "Invalid choice"
            continue
        fi
        break
    done
    declare -g "$_prompt_q_var=$_prompt_q_a"
}

prompt_q_default_choices() {
    local _prompt_q_var=$1 ; shift
    local _prompt_q_q=$1 ; shift
    local _prompt_q_default=$1 ; shift
    local _prompt_q_choices_arr=( "$@" )
    local _prompt_q_c=
    local _prompt_q_a=
    while true ; do
        print_em "Choices"
        for _prompt_q_c in "${_prompt_q_choices_arr[@]}" ; do
            print_li "$_prompt_q_c"
        done
        print_q "$_prompt_q_q" "" "$_prompt_q_default"
        read -r _prompt_q_a
        _last_print_is_nl=false
        # Default
        if [[ -z "$_prompt_q_a" ]] ; then
            _prompt_q_a=$_prompt_q_default
            break
        fi
        # Validation
        if ! lcontain "$_prompt_q_a" "${_prompt_q_choices_arr[@]}" ; then
            print_err "Invalid choice"
            continue
        fi
        break
    done
    declare -g "$_prompt_q_var=$_prompt_q_a"
}

prompt_q_yn() {
    local _prompt_q_var=$1 ; shift
    local _prompt_q_q=$1 ; shift
    local _prompt_q_choices="y/n"
    local _prompt_q_a=
    while true ; do
        print_q "$_prompt_q_q" "$_prompt_q_choices"
        read -r _prompt_q_a
        _last_print_is_nl=false
        # Default
        # Validation
        case "x$_prompt_q_a" in
            xY|xy) _prompt_q_a=true ;;
            xN|xn) _prompt_q_a=false ;;
            *)
                print_err "Invalid choice"
                continue
                ;;
        esac
        break
    done
    declare -g "$_prompt_q_var=$_prompt_q_a"
}

prompt_q_default_yn() {
    local _prompt_q_var=$1 ; shift
    local _prompt_q_q=$1 ; shift
    local _prompt_q_default=$1 ; shift
    local _prompt_q_choices=
    if [[ "$_prompt_q_default" = "true" ]] ; then
        _prompt_q_choices="Y/n"
    elif [[ "$_prompt_q_default" = "false" ]] ; then
        _prompt_q_choices="y/N"
    else
        _prompt_q_choices="y/n"
    fi
    local _prompt_q_a=
    while true ; do
        print_q "$_prompt_q_q" "$_prompt_q_choices"
        read -r _prompt_q_a
        _last_print_is_nl=false
        # Default
        if [[ -z "$_prompt_q_a" ]] ; then
            _prompt_q_a=$_prompt_q_default
            break
        fi
        # Validation
        case "$_prompt_q_a" in
            Y|y|yes|Yes|YES) _prompt_q_a=true ;;
            N|n|no|No|NO)    _prompt_q_a=false ;;
            *)
                print_err "Invalid choice"
                continue
                ;;
        esac
        break
    done
    declare -g "$_prompt_q_var=$_prompt_q_a"
}

eval "$_qip_func_prompt_saved_state" ; unset _qip_func_prompt_saved_state

# vim: ft=bash
