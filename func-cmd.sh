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

declare -F log_cmd > /dev/null && return

. "$(dirname "${BASH_SOURCE[0]}")/func-print.sh"

## run_indent cmd ...
#
# Executes the command.
# stdout is indented then sent to stdout.
# stderr is not redirected.
run_indent() {
    local state ; state=$(set +o) ; shopt -qo errexit && state="$state ; set -e"
    set -o pipefail
    if "$@" | indent
    then local rc=0 ; else local rc=$? ; fi
    eval "$state"
    return $rc
}

## run_indent_esc cmd ...
#
# Executes the command.
# stdout is indented then sent to stdout.
# Indentation supports reformatting terminal escape sequences.
# stderr is not redirected.
run_indent_esc() {
    local state ; state=$(set +o) ; shopt -qo errexit && state="$state ; set -e"
    set -o pipefail
    if "$@" | indent_esc
    then local rc=0 ; else local rc=$? ; fi
    eval "$state"
    return $rc
}

## run_cmd_redirected file cmd ...
#
# Executes the command.
# stdout and stderr are both redirected to file.
run_cmd_redirected() {
    local file="$1" ; shift
    "$@" 2> "$file" 1>&2
}

## run_cmd_redirected_nohup file cmd ...
#
# Executes the command immune to hangups.
# stdout and stderr are both redirected to file.
run_cmd_redirected_nohup() {
    local file="$1" ; shift
    # This is not ideal, would be best in a subshell?
    run_cmd_redirected "$file" nohup "$@" < /dev/null
}

## run_cmd_redirected_pty file cmd ...
#
# Executes the command in a pseudoterminal.
# stdout and stderr are both redirected to file.
run_cmd_redirected_pty() {
    run_cmd_piped_pty "$@" > /dev/null
}

## run_cmd_piped file cmd ...
#
# Executes the command.
# stdout and stderr are both copied to file and output on stdout.
run_cmd_piped() {
    local file="$1" ; shift
    local state ; state=$(set +o) ; shopt -qo errexit && state="$state ; set -e"
    set -o pipefail
    if { "$@" ; } | tee "$file" 2>&1
    then local rc=0 ; else local rc=$? ; fi
    eval "$state"
    return $rc
}

## run_cmd_piped_nohup file cmd ...
#
# Executes the command immune to hangups.
# stdout and stderr are both copied to file and output on stdout.
run_cmd_piped_nohup() {
    local file="$1" ; shift
    # This is not ideal, would be best in a subshell?
    run_cmd_piped "$file" nohup "$@" < /dev/null
}

_run_script_version=
## run_cmd_piped_pty file cmd ...
#
# Executes the command in a pseudoterminal.
# stdout and stderr are both copied to file and output on stdout.
run_cmd_piped_pty() {
    local file="$1" ; shift
    local cmd ; cmd=$(quote_args "$@")
    local rows=
    local cols=
    local colcmd=
    local stty_size ; stty_size=$(stty size 2>/dev/null || true)
    read -r rows cols <<<"$stty_size"
    if [[ -n "$cols" ]] ; then
        colcmd="export LINES=$rows COLUMNS=$(( cols - 4 )) ; stty rows $rows cols $(( cols - 4 )) ;"
        stty rows "$rows" cols "$(( cols - 4 ))"
    fi
    if [[ -z "$_run_script_version" ]] ; then
        if { script --version 2>&1 || true ; } | grep -q util-linux ; then
            _run_script_version=util-linux
        else
            # Probably BSD
            _run_script_version=bsd
        fi
    fi
    if [[ "$_run_script_version" = "util-linux" ]] ; then
        if script --flush --quiet --command "$colcmd$cmd" --return "$file"
        then local rc=0 ; else local rc=$? ; fi
    else
        # TODO colcmd
        if script -F -q "$file" "$@"
        then local rc=0 ; else local rc=$? ; fi
    fi
    if [[ -n "$cols" ]] ; then
        stty rows "$rows" cols "$cols"
    fi
    return $rc
}

## log_cmd [cmd ...]
#
# Logs and executes the command.
# Output is redirected to OUT_TMP.
# Status is printed on same line as command.
# On error or verbose: Output is printed.
log_cmd() {
    local loc_OUT_TMP=${OUT_TMP:-${TMPDIR:-/tmp}/$$.out.tmp}
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    if run_cmd_redirected "$loc_OUT_TMP" "$@"
    then local rc=0 ; else local rc=$? ; fi
    #print_nl
    if [[ $rc != 0 ]] ; then
        print_cmd_status "$cmd" ERROR "($rc)"
    else
        print_cmd_status "$cmd" OK
    fi
    if [[ $rc != 0 ]] ; then
        if [[ -s "$loc_OUT_TMP" ]] ; then
            print_err "$(<"$loc_OUT_TMP")" |& indent >&2
        fi
    elif $OPT_VERBOSE ; then
        if [[ -s "$loc_OUT_TMP" ]] ; then
            print_dbg "$(<"$loc_OUT_TMP")" |& indent >&2
        fi
    fi
    [[ "$loc_OUT_TMP" = "${OUT_TMP:-}" ]] || rm -f "$loc_OUT_TMP"
    return $rc
}

## log_cmd_long [cmd ...]
#
# Logs and executes the command.
# Continuation dots are printed first.
# Output is redirected to OUT_TMP.
# Status is printed on new line upon completion.
# On error or verbose: Output is printed.
log_cmd_long() {
    local loc_OUT_TMP=${OUT_TMP:-${TMPDIR:-/tmp}/$$.out.tmp}
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd" ...
    if run_cmd_redirected "$loc_OUT_TMP" "$@"
    then local rc=0 ; else local rc=$? ; fi
    #print_nl
    if [[ $rc != 0 ]] ; then
        print_cmd_status "$cmd" ERROR "($rc)"
    else
        if [[ -s "$loc_OUT_TMP" ]] ; then
            print_cmd_status "$cmd" OK
        else
            print_cmd_status "..." OK
        fi
    fi
    if [[ $rc != 0 ]] ; then
        if [[ -s "$loc_OUT_TMP" ]] ; then
            print_err "$(<"$loc_OUT_TMP")" |& indent >&2
        fi
    elif $OPT_VERBOSE ; then
        if false ; then
            if [[ -s "$loc_OUT_TMP" ]] ; then
                print_dbg "$(<"$loc_OUT_TMP")" |& indent >&2
            fi
        fi
    fi
    [[ "$loc_OUT_TMP" = "${OUT_TMP:-}" ]] || rm -f "$loc_OUT_TMP"
    return $rc
}

## log_cmd_live [cmd ...]
#
# Logs and executes the command.
# No continuation dots.
# Output is piped to stdout and OUT_TMP as well as indented.
# Status is printed on error only.
log_cmd_live() {
    local loc_OUT_TMP=${OUT_TMP:-${TMPDIR:-/tmp}/$$.out.tmp}
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd"
    if run_indent run_cmd_piped "$loc_OUT_TMP" "$@"
    then local rc=0 ; else local rc=$? ; fi
    print_nl
    if [[ $rc != 0 ]] ; then
        print_cmd_status "$cmd" ERROR "($rc)"
    else
        : # print_cmd_status "$cmd" OK
    fi
    [[ "$loc_OUT_TMP" = "${OUT_TMP:-}" ]] || rm -f "$loc_OUT_TMP"
    return $rc
}

log_cmd_live_nohup() {
    local loc_OUT_TMP=${OUT_TMP:-${TMPDIR:-/tmp}/$$.out.tmp}
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd"
    if run_indent run_cmd_piped_nohup "$loc_OUT_TMP" "$@"
    then local rc=0 ; else local rc=$? ; fi
    print_nl
    if [[ $rc != 0 ]] ; then
        print_cmd_status "$cmd" ERROR "($rc)"
    else
        : # print_cmd_status "$cmd" OK
    fi
    [[ "$loc_OUT_TMP" = "${OUT_TMP:-}" ]] || rm -f "$loc_OUT_TMP"
    return $rc
}

## log_cmd_live_pty [cmd ...]
#
# Logs and executes the command under a pseudopty.
# No continuation dots.
# Output is piped to stdout and OUT_TMP.
# Status is printed on error only.
log_cmd_live_pty() {
    local loc_OUT_TMP=${OUT_TMP:-${TMPDIR:-/tmp}/$$.out.tmp}
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd"
    if run_indent_esc run_cmd_piped_pty "$loc_OUT_TMP" "$@"
    then local rc=0 ; else local rc=$? ; fi
    print_nl
    if [[ $rc != 0 ]] ; then
        print_cmd_status "$cmd" ERROR "($rc)"
    else
        : # print_cmd_status "$cmd" OK
    fi
    [[ "$loc_OUT_TMP" = "${OUT_TMP:-}" ]] || rm -f "$loc_OUT_TMP"
    return $rc
}

log_cmd_live_maybe_pty() {
    if [[ "${tty_colors_mode:-off}" = "on" ]] ; then
        log_cmd_live_pty "$@"
    else
        log_cmd_live "$@"
    fi
}

## log_cmd_nostatus [cmd ...]
#
# Logs and executes the command.
# No continuation dots.
# Output is send to stdout.
# Interactive mode is uncaptured and unindented.
log_cmd_nostatus() {
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd"
    if run_indent "$@"
    then local rc=0 ; else local rc=$? ; fi
    print_nl
    return $rc
}

## log_cmd_nostatus_interactive [cmd ...]
#
# Logs and executes the command with full interactive support.
# No continuation dots.
# Output is send to stdout.
# Interactive mode is uncaptured and unindented.
log_cmd_nostatus_interactive() {
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd"
    if "$@"
    then local rc=0 ; else local rc=$? ; fi
    print_nl
    return $rc
}

## log_cmd_interactive [cmd ...]
#
# Logs and executes the command with full interactive support.
# No continuation dots.
# Output is send to stdout.
# Status is printed on error only.
log_cmd_interactive() {
    if log_cmd_nostatus_interactive "$@"
    then local rc=0 ; else local rc=$? ; fi
    if [[ $rc != 0 ]] ; then
        local cmd ; cmd=$(quote_args "$@")
        print_cmd_status "$cmd" ERROR "($rc)"
    else
        : # print_cmd_status "$cmd" OK
    fi
    return $rc
}

## log_cmd_nostatus_shell [cmd ...]
#
# Logs and executes the command in the current shell (appropriate for shell
# internals).
# No continuation dots.
# Output is send to stdout.
# Shell mode is uncaptured and unindented.
log_cmd_nostatus_shell() {
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd"
    # Using "$cmd" instead of "$@" because eval concatenates spaces
    if eval "$cmd"
    then local rc=0 ; else local rc=$? ; fi
    print_nl
    return $rc
}

## log_cmd_shell [cmd ...]
#
# Logs and executes the command in the current shell (appropriate for shell
# internals).
log_cmd_shell() {
    if log_cmd_nostatus_shell "$@"
    then local rc=0 ; else local rc=$? ; fi
    if [[ $rc != 0 ]] ; then
        local cmd ; cmd=$(quote_args "$@")
        print_cmd_status "$cmd" ERROR "($rc)"
    else
        : # print_cmd_status "$cmd" OK
    fi
    return $rc
}

## test_cmd_dryrun log_cmd_func [cmd ...]
#
# Run `log_cmd_func cmd ...` unless OPT_DRYRUN is true in which case
# `log_cmd_dryrun cmd ...`.
test_cmd_dryrun() {
    local log_cmd_func=$1 ; shift
    if ${OPT_DRYRUN:-false} ; then
        log_cmd_dryrun "$@"
    else
        $log_cmd_func "$@"
    fi
}

## log_cmd_dryrun cmd ...
#
# Print the command and arguments with a "DRYRUN" status, but do not execute
# it.
log_cmd_dryrun() {
    local cmd ; cmd=$(quote_args "$@")
    print_need_nl
    print_cmd_status "$cmd" DRYRUN
    local rc=0
    test -n "${OUT_TMP:-}" && :> "$OUT_TMP"
    return $rc
}

# vim: ft=bash
