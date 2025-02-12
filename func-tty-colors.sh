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

# Might want to be able re-source...
typeset -f setup_tty_colors > /dev/null && return

tty_light_or_dark_mode() {
    local fgbg=${COLORFGBG:-15;0}
    local bg=${fgbg#*;}
    case "$bg" in
        0) echo dark ;;
        *) echo light ;;
    esac
}
tty_light_or_dark_mode_choice() {
    if [[ "$(tty_light_or_dark_mode)" = "light" ]] ; then
        echo "${1:-}"
    else
        echo "${2:-}"
    fi
}

# shellcheck disable=SC2034
tty_colors_off() {
    tty_colors_mode=off
    # Foreground, normal and bold
    cBLACK=""
    cBLACKb=""
    cRED=""
    cREDb=""
    cGREEN=""
    cGREENb=""
    cYELLOW=""
    cYELLOWb=""
    cBLUE=""
    cBLUEb=""
    cMAGENTA=""
    cMAGENTAb=""
    cCYAN=""
    cCYANb=""
    cWHITE=""
    cWHITEb=""
    # Background
    cbBLACK=""
    cbRED=""
    cbGREEN=""
    cbYELLOW=""
    cbBLUE=""
    cbMAGENTA=""
    cbCYAN=""
    cbWHITE=""
    # Reset
    cOFF=""
    cbOFF="$cOFF"
    # Special
    hoPRE=""
    hcPRE=""
    cFG=""
    cFGb=""
}

# shellcheck disable=SC2034
tty_colors_on() {
    tty_colors_mode=on
    # Foreground, normal and bold
    cBLACK="[30m"
    cBLACKb="[30;1m"
    cRED="[31m"
    cREDb="[31;1m"
    cGREEN="[32m"
    cGREENb="[32;1m"
    cYELLOW="[33m"
    cYELLOWb="[33;1m"
    cBLUE="[34m"
    cBLUEb="[34;1m"
    cMAGENTA="[35m"
    cMAGENTAb="[35;1m"
    cCYAN="[36m"
    cCYANb="[36;1m"
    cWHITE="[37m"
    cWHITEb="[37;1m"
    # Background
    cbBLACK="[40m"
    cbRED="[41m"
    cbGREEN="[42m"
    cbYELLOW="[43m"
    cbBLUE="[44m"
    cbMAGENTA="[45m"
    cbCYAN="[46m"
    cbWHITE="[47m"
    # Reset
    cOFF1="[0m"
    cOFF2="[39;49m"
    cOFF="$cOFF1$cOFF2"
    cbOFF="$cOFF"
    # Special
    hoPRE=""
    hcPRE=""
    cFG=$(tty_light_or_dark_mode_choice  "$cBLACK"  "$cWHITE")
    cFGb=$(tty_light_or_dark_mode_choice "$cBLACKb" "$cWHITEb")
}

# shellcheck disable=SC2034
tty_colors_html() {
    tty_colors_mode=html
    # Foreground, normal and bold
    cBLACK="<font color='black'>"
    cBLACKb=$cBLACK
    cRED="<font color='red'>"
    cREDb=$cRED
    cGREEN="<font color='green'>"
    cGREENb=$cGREEN
    cYELLOW="<font color='yellow'>"
    cYELLOWb=$cYELLOW
    cBLUE="<font color='blue'>"
    cBLUEb=$cBLUE
    cMAGENTA="<font color='magenta'>"
    cMAGENTAb=$cMAGENTA
    cCYAN="<font color='cyan'>"
    cCYANb=$cCYAN
    cWHITE="<font color='white'>"
    cWHITEb=$cWHITE
    # Background
    cbBLACK="<font bgcolor='black'>"
    cbRED="<font bgcolor='red'>"
    cbGREEN="<font bgcolor='green'>"
    cbYELLOW="<font bgcolor='yellow'>"
    cbBLUE="<font bgcolor='blue'>"
    cbMAGENTA="<font bgcolor='magenta'>"
    cbCYAN="<font bgcolor='cyan'>"
    cbWHITE="<font bgcolor='white'>"
    # Reset
    cOFF="</font>"
    cbOFF="$cOFF"
    # Special
    hoPRE="<pre>"
    hcPRE="</pre>"
}

setup_tty_colors() {
    if [[ -n "${REQUEST_URI:-}" ]] || [[ "${tty_colors_mode:-}" = "html" ]] ; then
        tty_colors_html
    elif tty <&2 >/dev/null 2>&1 || tty <&1 >/dev/null 2>&1 ; then
        tty_colors_on
    else
        tty_colors_off
    fi
}
setup_tty_colors

test_tty_colors() {
    local var val
    for var in \
        cBLACK \
        cBLACKb \
        cRED \
        cREDb \
        cGREEN \
        cGREENb \
        cYELLOW \
        cYELLOWb \
        cBLUE \
        cBLUEb \
        cMAGENTA \
        cMAGENTAb \
        cCYAN \
        cCYANb \
        cWHITE \
        cWHITEb \
    ; do
        eval val="\${$var:-\"(not set)\"}"
        echo "${val}This is $var$cOFF"
    done
}

# vim: ft=bash
