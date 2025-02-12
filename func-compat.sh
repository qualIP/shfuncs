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

[[ -n "${__SHFUNCS_COMPAT_LOADED__:-}" ]] && return
__SHFUNCS_COMPAT_LOADED__=1

if [[ -n "${ZSH_VERSION:-}" ]] ; then
    is_bash() { false ; }
    is_zsh() { true ; }
elif [[ -n "${BASH_VERSION:-}" ]] ; then
    is_bash() { true ; }
    is_zsh() { false ; }
else
    is_bash() { false ; }
    is_zsh() { false ; }
fi

if is_zsh ; then
    if is-at-least 5.0.7 ; then
        has_pipefail() { true ; }
    else
        has_pipefail() { false ; }
    fi
else
    has_pipefail() { true ; }
fi

if is_zsh && [[ -o monitor ]]  ; then
    # Zsh with job control enabled
    without_zsh_job_control() {
        if false ; then
            # NOTE Could also run in a sub-shell: ( "$@" )
            if [[ -o monitor ]] ; then
                unsetopt monitor
                if "$@"
                then local rc=0 ; else local rc=$? ; fi
                setopt monitor
            else
                if "$@"
                then local rc=0 ; else local rc=$? ; fi
            fi
        else
            if ( "$@" )
            then local rc=0 ; else local rc=$? ; fi
        fi
        return $rc
    }
else
    # Zsh without job control (could be a sub-shell) or Bash
    # no=op
    without_zsh_job_control() {
        "$@"
    }
fi
