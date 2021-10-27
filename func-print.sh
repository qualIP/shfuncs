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

declare -F print_fmt > /dev/null && return

. "$(dirname "${BASH_SOURCE[0]}")/func-tty-colors.sh"
. "$(dirname "${BASH_SOURCE[0]}")/func-args.sh"

_qip_func_print_saved_state=""
shopt -q extglob || _qip_func_args_saved_state+="shopt -u extglob"$'\n' ; shopt -s extglob

_last_print_is_nl=false

## print [str ...]
print() {
    local v="$*"
    echo "$v"
    [[ -n "$v" ]] && _last_print_is_nl=false || _last_print_is_nl=true
}

## print_nl
print_nl() {
    print ""
}

## print_need_nl
#
# Prints a new line, unless the last print was an empty line.
print_need_nl() {
    ${_last_print_is_nl:-false} || print ""
}

indent() {
    sed -e 's/^/    /'
}

indent_esc() {
    ${PERL:-perl} -lpe '
    BEGIN {
        sub inc { my ($num) = @_; $num += 4 }
    }
    s/^/    / ;
    s/\r([^\r\n])/\r    \1/g ;
    s/\[(\d+);(\d+)H/"[" . $1 . ";" . (inc($2)) . "H"/eg ;
    '
}

print_fmt() {
    local c=$1 ; shift
    local f=$1 ; shift
    printf "${hoPRE:-}${c}$f${cOFF:-}${hcPRE:-}" "$@"
    _last_print_is_nl=false
}

print_err() {
    print "${hoPRE:-}${cRED:-}** $* **${cOFF:-}${hcPRE:-}" >&2
}

print_dbg() {
    print "${hoPRE:-}${cYELLOW:-}$*${cOFF:-}${hcPRE:-}" >&2
}

## print_q "q" [choices]
print_q() {
    local q=$1 ; shift
    [[ "${q: -1}" = "?" ]] || [[ "${q: -1}" = ":" ]] || q="$q:"
    local choices=${1:-} ; shift || true
    [[ -n "$choices" ]] && choices=" [$choices]"
    print_need_nl
    print_fmt "${cMAGENTA:-}" "$q$choices " "$@"
}

print_a() {
    print_status -0 "" "$@"
}

# _print_status_internal [-n] [--nosep] s ...
_print_status_internal() {
    local n=-20
    case "${1:-}" in
        -+([0-9])) n="$1" ; shift 1 ;;
    esac
    local nosep=
    case "$1" in
        --nosep) nosep=$1 ; shift 1 ;;
    esac
    s="$1" ; shift
    local sep=:
    if [[ "$nosep" = "--nosep" ]] ; then
        sep=
    else
        case "x$s" in
            x)   sep= ;;
            *\?) sep= ;;
            *:)  sep= ;;
        esac
    fi
    if [[ "$n$s$sep" = "-0" ]] ; then
        printf "%s\n" "$*"
    elif [[ -n "$*" ]] ; then
        printf "${cBLACKb:-}%${n}s${cOFF:-} %s\n" "$s$sep" "$*"
    else
        printf "${cBLACKb:-}%s${cOFF:-}\n" "$s$sep"
    fi
    _last_print_is_nl=false
}

# print_status [-n] [--nosep] title [status] [...]
print_status() {
    local n=-20
    case "${1:-}" in
        -+([0-9])) n="$1" ; shift 1 ;;
    esac
    local nosep=
    case "$1" in
        --nosep) nosep=$1 ; shift 1 ;;
    esac
    local t="$1" ; shift
    local s="${1:-}" ; shift || true
    local c=
    local b=
    case "$s" in
        true)      c=${cGREEN:-} s=TRUE  ;;
        false)     c=${cRED:-}   s=FALSE ;;
        OK|PASS)   c=${cGREEN:-}         ;;
        YES)       c=${cGREEN:-}         ;;
        ERR|ERROR) c=${cREDb:-}  s=ERROR ;;
        NO)        c=${cRED:-}           ;;
        WARNING)   c=${cMAGENTA:-}       ;;
        NA|N/A)    c=${cYELLOW:-} s=N/A  ;;
        TODO)      c=${cMAGENTA:-} b=${cbBLUE} ;;
        ...)       c=${cBLACKb:-}        ;;
        +([A-Z-])) c=${cRED:-}           ;;
    esac
    if [[ -n "$s" ]] ; then
        _print_status_internal "$n" $nosep "$t" "${c}${b}$s${b:+${cbOFF}}${c:+${cOFF:-}}" "$@"
    else
        _print_status_internal "$n" $nosep "$t" "" "$@"
    fi
}

## print_cmd_status [-n] "cmd" [status] [...]
print_cmd_status() {
    local n=-20
    case "${1:-}" in
        -+([0-9])) n="$1" ; shift 1 ;;
    esac
    local nosep=--nosep  # default for cmd
    case "$1" in
        --nosep) nosep=$1 ; shift 1 ;;
    esac
    local t="$1" ; shift
    local s="${1:-}" ; shift || true
    print_status "$n" $nosep "\$ $t" "$s" "$@" | indent
    _last_print_is_nl=false
}

## print_value [-n] [--nosep] "name" ["value"...]
print_value() {
    local n=-20
    case "${1:-}" in
        -+([0-9])) n="$1" ; shift 1 ;;
    esac
    local nosep=
    case "$1" in
        --nosep) nosep=$1 ; shift 1 ;;
    esac
    local t="$1" ; shift
    _print_status_internal "$n" $nosep "$t" "" "$@"
}

# Shell-like Printing

_print_shell_type=

print_var_csh() {
    print set "$1"="$(quote_args "$2")"
}
print_var_sh() {
    print "$1"="$(quote_args "$2")"
}

print_source_csh() {
    print source "$(quote_args "$1")"
}
print_source_sh() {
    print . "$(quote_args "$1")"
}

set_print_shell_type() {
    local t="$1"
    case "$t" in
        *csh*)
            _print_shell_type=csh
            _print_var=print_var_csh
            _print_source=print_source_csh
            _print_script_ext=.csh
            ;;
        *)
            _print_shell_type=sh
            _print_var=print_var_sh
            _print_source=print_source_sh
            _print_script_ext=.sh
            ;;
    esac
}
set_print_shell_type "$SHELL"

# Debug mode

set_debug_mode() {
    if ${1:-true} ; then
        PS4="+[\t] "
        set -x
    else
        set +x
        PS4="+ "
    fi
}

# Markdown-like Statements

print_h1() {
    print_need_nl
    print "${hoPRE:-}${cBLUE:-}# $*${cOFF:-}${hcPRE:-}"
    print ""
}

print_h2() {
    print_need_nl
    print "${hoPRE:-}${cBLUE:-}## $*${cOFF:-}${hcPRE:-}"
    print ""
}

print_h3() {
    print_need_nl
    print "${hoPRE:-}${cBLUE:-}### $*${cOFF:-}${hcPRE:-}"
    print ""
}

print_em() {
    print "${hoPRE:-}${cBLUEb:-}*$**${cOFF:-}${hcPRE:-}"
}

print_li() {
    print "${hoPRE:-}- ${cBLACKb:-}$*${cOFF:-}${hcPRE:-}"
}

eval "$_qip_func_print_saved_state" ; unset _qip_func_print_saved_state

# vim: ft=bash
