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

typeset -f make_comma_list > /dev/null && return

## split sep data... ...
#
# Splits all the data strings using the specified separator(s).
split() {
    local old_IFS="$IFS"
    local IFS="$1" ; shift
    # shellcheck disable=SC2068
    set -- $@
    IFS="$old_IFS"
    echo "$@"
}

## make_comma_list data... ...
#
# Arguments are split on spaces and commas then joined with commas ','.
make_comma_list() {
    local IFS=",$IFS"
    # shellcheck disable=SC2048,SC2086
    set -- $*
    echo "$*"
}

## make_space_list data... ...
#
# Arguments are split on spaces and commas then joined with spaces ' '.
make_space_list() {
    local IFS=" $IFS,"
    # shellcheck disable=SC2048,SC2086
    set -- $*
    echo "$*"
}

## make_newline_list data... ...
#
# Arguments are split on spaces and commas then joined with newlines '\n'.
make_newline_list() {
    local IFS=$'\n'"$IFS,"
    # shellcheck disable=SC2048,SC2086
    set -- $*
    echo "$*"
}

## make_colon_list data... ...
#
# Arguments are split on spaces and commas then joined with colons ':'.
make_colon_list() {
    local IFS=":$IFS,"
    # shellcheck disable=SC2048,SC2086
    set -- $*
    echo "$*"
}

## make_semicolon_list data... ...
#
# Arguments are split on spaces and commas then joined with semicolons ';'.
make_semicolon_list() {
    local IFS=";$IFS,"
    # shellcheck disable=SC2048,SC2086
    set -- $*
    echo "$*"
}

## join_list sep args...
#
# Arguments are joined with the specified separator.
join_list() {
    # fudging IFS only works with a single-character separator
    local sep="$1" ; shift
    local ret=
    local v
    for v in "$@" ; do
        ret="$ret${ret:+$sep}$v"
    done
    echo "$ret"
}

## lprepend var args...
#
# Modify the specified variable by prepending it with all other arguments
lprepend() {
    local _lprepend_var="$1" ; shift 1
    # shellcheck disable=SC2086
    set -- "$@" ${!_lprepend_var}
    local _lprepend_val="$*"
    eval "$_lprepend_var"=\$_lprepend_val
}
alias lpush=lprepend

## lappend var args...
#
# Modify the specified variable by appending it with all other arguments
lappend() {
    local _lappend_var="$1" ; shift 1
    # shellcheck disable=SC2086
    set -- ${!_lappend_var} "$@"
    local _lappend_val="$*"
    eval "$_lappend_var"=\$_lappend_val
}

## lpop var [outvar=lpop_value]
#
# Modify the specified variable by popping the first element
lpop() {
    local _lpop_var="$1" ; shift
    if (( $# )) ; then
        local _lpop_outvar="$1" ; shift
    else
        local _lpop_outvar=lpop_value
    fi
    # shellcheck disable=SC2086
    set -- ${!_lpop_var}
    (( $# )) || return 1
    eval "$_lpop_outvar"=\$1 ; shift 1
    eval "$_lpop_var"=\$\*
}

## lindex idx args...
#
# Returns the idx-nth index of the argument list.
lindex() {
    local shift_cnt=$1 ; shift
    case "$shift_cnt" in
        end|end-[0-9]*)
            # shellcheck disable=SC2034
            local end=$(( $# - 1 ))
            # shellcheck disable=SC2004
            local shift_cnt=$(( $shift_cnt ))
            ;;
        *)
            :
            ;;
    esac
    if (( $shift_cnt >= 0 )) && (( $shift_cnt < $# )) ; then
        shift $shift_cnt
        echo "$1"
    fi
}

## lcontain needle args...
#
# Tests if needle is an element of the argument list.
lcontain() {
    local el="$1" ; shift
    local v
    for v in "$@" ; do [[ "$v" != "$el" ]] || return 0 ; done
    return 1
}

## lrmdupes args...
#
# Returns all unique arguments, in first appearance order.
lrmdupes() {
    local l='' v
    for v in "$@" ; do
        # shellcheck disable=SC2086
        lcontain "$v" $l || l="$l $v"
    done
    # shellcheck disable=SC2086
    echo $l
}

## lsubst from to args...
#
# Substitute all elements equal to `from` with `to` in the arguments list.
lsubst() {
    local from="$1" ; shift
    local to="$1" ; shift
    local ret='' v
    for v in "$@" ; do
        [[ "$v" = "$from" ]] && v="$to"
        ret="$ret $v"
    done
    # shellcheck disable=SC2086
    echo $ret
}

## lorder list1 list2
#
# Return all elements of list1 in the order presented in list2, with unique
# elements of l1 at the end.
lorder() {
    local unorderedl="$1" ; shift
    local l2="$1" ; shift
    local tmpl=
    local orderredl=
    local e
    local lpop_value
    for e in $l2 ; do
        tmpl=
        while lpop unorderedl ; do
            if [[ "$lpop_value" = "$e" ]] ; then
                orderredl="$orderredl $e"
                break
            fi
            tmpl="$tmpl $lpop_value"
        done
        unorderedl="$tmpl $unorderedl"
    done
    # shellcheck disable=SC2086
    echo $orderredl $unorderedl
}

## lsort args...
#
# Returns the sorted list of arguments.
lsort() {
    local old_IFS="$IFS"
    local IFS=$'\n'
    local v ; v=$(sort <<<"$*")
    IFS="$old_IFS"
    # shellcheck disable=SC2086
    echo $v
}

## lmap func args...
#
# Maps a function to each list argument.
lmap() {
    local func=$1 ; shift
    local e
    for e in "$@" ; do
        $func "$e"
    done
}

# vim: ft=bash
