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

declare -F findexec > /dev/null && return

. "$(dirname "${BASH_SOURCE[0]}")/func-print.sh"

## my_which name
my_which() {
    local arg="$1"
    case "$arg" in
        /*)
            if [ -f "$arg" ] && [ -x "$arg" ] ; then
                echo "$arg"
                return 0
            fi
            ;;
        */*)
            if [ -f "$arg" ] && [ -x "$arg" ] ; then
                echo "$(pwd)/$arg"
                return 0
            fi
            ;;
        *)
            local p
            local old_IFS="$IFS" ; IFS=":"
            for p in $PATH ; do
                IFS="$old_IFS"
                [ -z "$p" ] && p="."
                if [ -f "$p/$arg" ] && [ -x "$p/$arg" ] ; then
                    echo "$p/$arg"
                    return 0
                fi
            done
            ;;
    esac
    return 1
}

## findexec name1 [name2 ...]
findexec() {
    local p
    for p in "$@" ; do
        if [ "${p:0:1}" != "/" ] ; then
            p=$(my_which "$p" 2>/dev/null) || continue
            [ "${p:0:1}" = "/" ] || continue
        fi
        [ -x "$p" ] && echo "$p" && return
    done
    print_err Executable not found: "$@"
    return 1
}

## next_in_path name ["$PATH"]
next_in_path() {
    local bin="$1" ; shift
    local pathenv="${1:-$PATH}"
    local binname=$(basename "$bin")
    local bindir=$(cd "$(dirname "$bin")" && pwd)
    local bindir_found=false
    local p
    local old_IFS="$IFS" ; IFS=":"
    for p in $pathenv ; do
        IFS="$old_IFS"
        if $bindir_found ; then
            if [ -x "$p/$binname" ] ; then
                echo "$p/$binname"
                return 0
            fi
        else
            if [ "$p" = "$bindir" ] ; then
                bindir_found=true
            elif [ -x "$p/$binname" ] ; then
                p=$( (cd "$p" && pwd) )
                if [ "$p" = "$bindir" ] ; then
                    bindir_found=true
                fi
            fi
        fi
    done
    echo "$bin: next command in PATH not found" >& 2
    return 1
}

## _realpath path
_realpath() {
    local f d d1 d2
    local p=$1
    local l=$(readlink "$p")
    if [ -n "$l" ] ; then
        d1=$(dirname "$p")
        d2=$(dirname "$l")
        d=$(cd "$d1" ; cd "$d2" ; pwd)
        f=$(basename "$l")
    else
        d=$(dirname "$p")
        d=$(cd "$d" ; pwd)
        f=$(basename "$p")
    fi
    echo "${d%/}/$f"
    return 0
}

if [ ! -f "$(my_which realpath 2> /dev/null)" ] ; then
    alias realpath=_realpath
fi
