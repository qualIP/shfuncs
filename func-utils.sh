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

declare -F utils_set_cleanup_function > /dev/null && return

_utils_cleanup_function=
_utils_signal_value=
_utils_signal_name=

_utils_trap_handler() {
    _utils_signal_name="$1" ; shift
    case "$_utils_signal_name" in
        0|EXIT)  _utils_signal_value=0 ; _utils_signal_name=EXIT ;;
        1|HUP)   _utils_signal_value=1 ; _utils_signal_name=HUP ;;
        2|INT)   _utils_signal_value=2 ; _utils_signal_name=INT ;;
        15|TERM) _utils_signal_value=15 ; _utils_signal_name=TERM ;;
        *)    echo "Unrecognized trap ($_utils_signal_name)" >&2 ; _utils_signal_value=127 ;;
    esac

    [ -n "$_utils_cleanup_function" ] && eval "$_utils_cleanup_function"

    if [ "$_utils_signal_name" != "EXIT" ] ; then
        trap 0 ;# Disable exit trap
        exit $((_utils_signal_value + 128))
    fi
}

## utils_set_cleanup_function function
utils_set_cleanup_function() {
    _utils_cleanup_function="$1" ; shift || true
    trap '_utils_trap_handler EXIT' 0
    trap '_utils_trap_handler HUP'  1
    trap '_utils_trap_handler INT'  2
    trap '_utils_trap_handler TERM' 15
}

## utils_run_curl [curl ...] url
utils_run_curl() {
    local loc_OUT_TMP=${OUT_TMP:-${TMPDIR:-/tmp}/$$.out.tmp}
    rm -f "$loc_OUT_TMP"
    HTTP_CODE=
    eval $(${OPT_DEBUG:-false} && set -x ; ${CURL:-curl} \
        --compress \
        --silent \
        -w 'HTTP_CODE=%{http_code}' \
        -o "$loc_OUT_TMP" \
        $(${OPT_DEBUG:-false} && echo "-v") \
        "$@")
    if [ "$HTTP_CODE" != "200" ] ; then
        print_err "Error: Request returned code $HTTP_CODE."
        if [ -f "$loc_OUT_TMP" ] ; then
            cat "$loc_OUT_TMP" >&2
            rm -f "$loc_OUT_TMP"
        fi
        return 1
    else
        if [ -f "$loc_OUT_TMP" ] ; then
            cat "$loc_OUT_TMP"
            rm -f "$loc_OUT_TMP"
        fi
        return 0
    fi
}

_with_OUT_TMP_unique=0
with_OUT_TMP() {
    local old_OUT_TMP=${OUT_TMP:-}
    export OUT_TMP=${TMPDIR:-/tmp}/$$.out.tmp
    if [[ -e "$OUT_TMP" ]] ; then
        export OUT_TMP=${TMPDIR:-/tmp}/$$.out.${_with_OUT_TMP_unique}.tmp
        while [[ -e "$OUT_TMP" ]] ; do
            _with_OUT_TMP_unique=$(( _with_OUT_TMP_unique + 1 ))
            export OUT_TMP=${TMPDIR:-/tmp}/$$.out.${_with_OUT_TMP_unique}.tmp
        done
    fi
    if "$@"
    then local rc=0 ; else local rc=$? ; fi
    rm -f "$OUT_TMP"
    if [[ -n "$old_OUT_TMP" ]] ; then
        export OUT_TMP="$old_OUT_TMP"
    else
        unset OUT_TMP
    fi
    return $rc
}
