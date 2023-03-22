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

typeset -f print_fmt > /dev/null && return

# shellcheck disable=all
SHFUNCS_DIR=${SHFUNCS_DIR:-$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")}
. "$SHFUNCS_DIR/func-tty-colors.sh"
. "$SHFUNCS_DIR/func-args.sh"

_qip_func_print_saved_state=""
if [[ -n "${BASH_SOURCE:-}" ]] ; then
    shopt -q extglob || _qip_func_args_saved_state+="shopt -u extglob"$'\n' ; shopt -s extglob
fi

_last_print_is_nl=false

## _print [str ...]
#
# Prints the arguments, just like `echo`.
# Tracks newlines just like all print functions in this library.
_print() {
    local v="$*"
    echo "$v"
    [[ -n "$v" ]] && _last_print_is_nl=false || _last_print_is_nl=true
}

if [[ -z "${ZSH_VERSION:-}" ]] ; then
    # Zsh defines "print()"

    ## _print [str ...]
    #
    # Prints the arguments, just like `echo`.
    # Tracks newlines just like all print functions in this library.
    print() {
        _print "$@"
    }
fi

## print_nl
#
# Prints a new line
print_nl() {
    _print ""
}

## print_need_nl
#
# Prints a new line, unless the last print was an empty line.
print_need_nl() {
    ${_last_print_is_nl:-false} || _print ""
}

## indent [file ...]
#
# Indent the content of standard input or the given file names.
# shellcheck disable=SC2120
indent() {
    sed -e 's/^./    &/' "$@"
}

## indent_esc [file ...]
#
# Indent the content of standard input or the given file names.
# Supports basic terminal escape sequences.
# shellcheck disable=SC2120
indent_esc() {
    # shellcheck disable=SC2016
    ${PERL:-perl} -lpe '
    BEGIN {
        sub inc { my ($num) = @_; $num += 4 }
    }
    s/^(.)/    \1/ ;
    s/\r([^\r\n])/\r    \1/g ;
    s/\[(\d+);(\d+)H/"[" . $1 . ";" . (inc($2)) . "H"/eg ;
    ' "$@"
}

## print_fmt color_code format args...
#
# Prints the format and arguments like printf, prepending an optional color
# code.
print_fmt() {
    local c=$1 ; shift
    local f=$1 ; shift
    # shellcheck disable=SC2059
    printf "${hoPRE:-}${c}$f${cOFF:-}${hcPRE:-}" "$@"
    _last_print_is_nl=false
}

## print_err error_message ...
#
# Prints the error message to standard error in red and with "**" markers around it.
print_err() {
    _print "${hoPRE:-}${cRED:-}** $* **${cOFF:-}${hcPRE:-}" >&2
}

## print_warn warning_message ...
#
# Prints the warning message to standard error in magenta.
print_warn() {
    _print "${hoPRE:-}${cMAGENTA:-}** $* **${cOFF:-}${hcPRE:-}" >&2
}

#
# Prints the debug message to standard error in yellow.
print_dbg() {
    _print "${hoPRE:-}${cYELLOW:-}$*${cOFF:-}${hcPRE:-}" >&2
}

## print_q "q" [choices] [default]
#
# Prints a question prompt. Ends with a space, not a newline.
# No newline is added before so multiple questions can be prompted in brief mode.
print_q() {
    local q=$1 ; shift
    [[ "${q: -1}" = "?" ]] || [[ "${q: -1}" = ":" ]] || q="$q:"
    local choices=
    if (( $# )) ; then
        choices=$1 ; shift
        [[ -n "$choices" ]] && choices=" ($choices)"
    fi
    if (( $# )) ; then
        default=$1 ; shift
        choices+=" [$default]"
    fi
    # print_need_nl
    print_fmt "${cMAGENTA:-}" "$q$choices " "$@"
}

## print_a [...]
#
# Print an "answer" (No special formatting).
print_a() {
    print_status -0 "" "$@"
}

## _print_status_internal [-n] [--nosep] s ...
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

## print_status [-n] [--nosep] title [status] [...]
#
# Print a status message of the form:
#     "title:    status ..."
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
    local s="${1:-}" ; (( $# )) && shift
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
        # shellcheck disable=SC2086
        _print_status_internal "$n" $nosep "$t" "${c}${b}$s${b:+${cbOFF}}${c:+${cOFF:-}}" "$@"
    else
        # shellcheck disable=SC2086
        _print_status_internal "$n" $nosep "$t" "$@"
    fi
}

## print_cmd_status [-n] "cmd" [status] [...]
#
# Print a command status message in the form:
#     "    $ cmd     status ..."
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
    local s="${1:-}" ; (( $# )) && shift
    # shellcheck disable=SC2086
    print_status "$n" $nosep "\$ $t" "$s" "$@" | indent
    _last_print_is_nl=false
}

## print_value [-n] [--nosep] "name" ["value"...]
#
# Print a value in the form:
#     "name:                value ..."
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
    # shellcheck disable=SC2086
    _print_status_internal "$n" $nosep "$t" "$@"
}

# Shell-like Printing

_print_shell_type=

print_set_var() {
    "${_print_set_var}" "$@"
}
print_set_var_csh() {
    _print set "$1"="$(quote_args "$2")"
}
print_set_var_sh() {
    _print "$1"="$(quote_args "$2")"
}

print_set_var_local() {
    "${_print_set_var}_local" "$@"
}
print_set_var_csh_local() {
    _print set "$1"="$(quote_args "$2")"
}
print_set_var_sh_local() {
    _print local "$1"="$(quote_args "$2")"
}

print_set_var_export() {
    "${_print_set_var}"_export "$@"
}
print_set_var_csh_export() {
    _print setenv "$1" "$(quote_args "$2")"
}
print_set_var_sh_export() {
    _print export "$1"="$(quote_args "$2")"
}

print_source() {
    "print_source_$_print_shell_type" "$@"
}
print_source_csh() {
    _print source "$(quote_args "$1")"
}
print_source_sh() {
    _print . "$(quote_args "$1")"
}

set_print_shell_type() {
    local t="$1"
    case "$t" in
        *csh*)
            _print_shell_type='csh'
            _print_set_var='print_set_var_csh'
            _print_source='print_source_csh'
            _print_script_ext='.csh'
            ;;
        *)
            _print_shell_type='sh'
            _print_set_var='print_set_var_sh'
            _print_source='print_source_sh'
            _print_script_ext='.sh'
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
    _print "${hoPRE:-}${cBLUE:-}# $*${cOFF:-}${hcPRE:-}"
    _print ""
}

print_h2() {
    print_need_nl
    _print "${hoPRE:-}${cBLUE:-}## $*${cOFF:-}${hcPRE:-}"
    _print ""
}

print_h3() {
    print_need_nl
    _print "${hoPRE:-}${cBLUE:-}### $*${cOFF:-}${hcPRE:-}"
    _print ""
}

print_em() {
    _print "${hoPRE:-}${cBLUEb:-}*$**${cOFF:-}${hcPRE:-}"
}

print_li() {
    _print "${hoPRE:-}- ${cBLACKb:-}$*${cOFF:-}${hcPRE:-}"
}

## print_vars var1 var2 ...
print_vars() {
    local var val
    for var in "$@" ; do
        eval val="\${$var:-\"(not set)\"}"
        print_value -0 "$var" "$val"
    done
}

## print_var_eq_vals var1=val1 var2=val2 ...
print_var_eq_vals() {
    local varval var val
    for varval in "$@" ; do
        var=${varval%%=*}
        if [[ "$var" = "$varval" ]] ; then
            # No '='
            val=
        else
            val=${varval##*=}
        fi
        print_value -0 "$var" "$val"
    done
}

## print_var_val_pairs var1 val1 var2 val2 ...
print_var_val_pairs() {
    local var val
    while (( $# )) ; do
        var=$1 ; shift
        val=${1:-} ; (( $# )) && shift
        print_value -0 "$var" "$val"
    done
}

eval "$_qip_func_print_saved_state" ; unset _qip_func_print_saved_state

# vim: ft=bash
