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

if [ -z "$BASH_VERSION" ] ; then echo Not running bash! >&2 ; exit 1 ; fi

declare -F make_comma_list > /dev/null && return

split() {
    local old_IFS="$IFS"
    local IFS="$1" ; shift
    set -- $@
    IFS="$old_IFS"
    echo "$@"
}

make_comma_list() {
    local IFS=",$IFS"
    set -- $*
    echo "$*"
}

make_space_list() {
    local IFS=" $IFS,"
    set -- $*
    echo "$*"
}

make_newline_list() {
    local IFS="
$IFS,"
    set -- $*
    echo "$*"
}

make_colon_list() {
    local IFS=":$IFS,"
    set -- $*
    echo "$*"
}

make_semicolon_list() {
    local IFS=";$IFS,"
    set -- $*
    echo "$*"
}

join_list() {
    local sepin="$1" ; shift
    local sep=
    local ret=
    local v
    for v in "$@" ; do
        ret="$ret$sep$v"
        sep="$sepin"
    done
    echo "$ret"
}

lprepend() {
    local var="$1" ; shift 1
    local val="$*${!var:+ }${!var}"
    eval "$var"="'$val'"
}
alias lpush=lprepend

lappend() {
    local var="$1" ; shift 1
    local val="${!var}${!var:+ }$*"
    eval "$var"="'$val'"
}

lpop() {
    local var="$1"
    local outvar=lpop_value ; [ -n "$2" ] && outvar="$2"
    set -- ${!var}
    [ $# = 0 ] && return 1
    eval "$outvar"="$1" ; shift 1
    eval "$var"="'$*'"
}

lindex() {
    local shift_cnt=$1 ; shift
    case "$shift_cnt" in
        end|end-[0-9]*)
            local end=$(( $# - 1))
            local shift_cnt=$(($shift_cnt))
            ;;
        *)
            :
            ;;
    esac
    if [[ $shift_cnt -ge 0 ]] && [[ $shift_cnt -lt $# ]] ; then
        shift $shift_cnt
        echo "$1"
    fi
}

lcontain() {
    local el="$1" ; shift
    local v
    for v in $* ; do [[ "$v" != "$el" ]] || return 0 ; done
    return 1
}

lrmdupes() {
    local l='' v
    for v in "$@" ; do
        lcontain "$v" $l || l="$l $v"
    done
    echo $l
}

#lrmdupes() {
#    echo $(make_newline_list $* | sort -u)
#}

lsubst() {
    local from="$1" ; shift
    local to="$1" ; shift
    local ret='' v
    for v in $* ; do
        [ "$v" = "$from" ] && v="$to"
        ret="$ret $v"
    done
    echo $ret
}

lorder() {
    local l1="$1" ; shift
    local l2="$1" ; shift
    local l v
    for v in $l2 ; do
        if lcontain "$v" $l1 ; then
            l="$l${l:+ }$v"
        fi
    done
    for v in $l1 ; do
        if ! lcontain "$v" $l ; then
            l="$l${l:+ }$v"
        fi
    done
    echo "$l"
}

lsort() {
    local old_IFS="$IFS"
    local IFS=$'\n'
    sort <<<"$*"
    IFS="$old_IFS"
}

# vim: ft=bash
