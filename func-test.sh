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

typeset -f test_case > /dev/null && return

# shellcheck disable=all
SHFUNCS_DIR=${SHFUNCS_DIR:-$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")}
. "$SHFUNCS_DIR/func-compat.sh"
. "$SHFUNCS_DIR/func-print.sh"

_test_case_name=
_test_step_no=0
_test_step_name=

## test_case name
test_case() {
    _test_case_name=$1 ; shift
    _test_step_no=0
    print_h2 "TEST: $_test_case_name"
}

## test_step name
test_step() {
    _test_step_name=$1 ; shift
    _test_step_no=$(( _test_step_no + 1 ))
    print_h3 "STEP $_test_step_no. $_test_step_name"
}

## test_assert_equal value1 value2
test_assert_equal() {
    local v1=$1 ; shift
    local v2=$1 ; shift
    local desc=${1:-} ; (( $# )) && shift
    if ! [[ "$v1" == "$v2" ]] ; then
        print_err "${desc:-test_assert_equal} failed: '$v1' == '$v2'"
        echo v1:
        echo -n "$v1" | hexdump -c
        echo v2:
        echo -n "$v2" | hexdump -c
        echo diff:
        diff --label v1 <(echo "$v1") --label v2 <(echo "$v2") >&2 || true
        return 1
    fi
}

## test_assert_not_equal value1 value2
test_assert_not_equal() {
    local v1=$1 ; shift
    local v2=$1 ; shift
    local desc=${1:-} ; (( $# )) && shift
    if ! [[ "$v1" != "$v2" ]] ; then
        print_err "${desc:-test_assert_not_equal} failed: '$v1' != '$v2'"
        return 1
    fi
}

## test_assert_rc rc cmd ...
test_assert_rc() {
    local exp_rc=$1 ; shift
    local rc=0
    "$@" || rc=$?
    test_assert_equal "$rc" "$exp_rc" "\"$*\""
}

# vim: ft=bash
