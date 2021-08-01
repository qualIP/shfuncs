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

declare -F test_case > /dev/null && return

. "$(dirname "${BASH_SOURCE[0]}")/func-print.sh"

_test_case_name=

## test_case name
test_case() {
    _test_case_name=$1 ; shift
    print_h2 "TEST: $_test_case_name"
}

## test_assert_equal value1 value2
test_assert_equal() {
    local v1=$1 ; shift
    local v2=$1 ; shift
    local desc=${1:-} ; shift || true
    if ! [[ "$v1" == "$v2" ]] ; then
        print_err "${desc:-test_assert_equal} failed: $v1 == $v2"
        return 1
    fi
}

## test_assert_not_equal value1 value2
test_assert_not_equal() {
    local v1=$1 ; shift
    local v2=$1 ; shift
    local desc=${1:-} ; shift || true
    if ! [[ "$v1" != "$v2" ]] ; then
        print_err "${desc:-test_assert_not_equal} failed: $v1 != $v2"
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
