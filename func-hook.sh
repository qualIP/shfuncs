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

typeset -f hook_declare > /dev/null && return

# shellcheck disable=all
SHFUNCS_DIR=${SHFUNCS_DIR:-$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")}
. "$SHFUNCS_DIR/func-list.sh"

hook_declare() {
    local hook_name ; hook_name=$1 ; shift 1
    local hook_var="_hook_${hook_name}_"
    # No -g in bash 3.2: declare -g $hook_var=
    eval "$hook_var="
}

hook_add() {
    local hook_name ; hook_name=$1 ; shift 1
    local hook_func ; hook_func=$1 ; shift 1
    local hook_var="_hook_${hook_name}_"
    lappend "$hook_var" "$hook_func"
}

hook_get() {
    local hook_name ; hook_name=$1 ; shift 1
    local hook_var="_hook_${hook_name}_"
    eval "echo \"\$${hook_var}\""
}

hook_invoke() {
    local hook_name ; hook_name=$1 ; shift 1
    local hook_funcs ; hook_funcs=$(hook_get "$hook_name")
    local hook_func
    for hook_func in $hook_funcs ; do
        if $hook_func "$@"
        then local rc=0 ; else local rc=$? ; return $rc ; fi
    done
}
