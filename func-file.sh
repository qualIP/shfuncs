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

typeset -f fix_path_no_slash > /dev/null && return

## fix_path_no_slash path
fix_path_no_slash() {
    local d ; d="$(dirname "$1/dummy")"
    [[ "$d" = "/" ]] || d="${d%/}" ;# cover special case of dirname / -> /
    echo "$d"
}

## fix_path path
fix_path() {
    local d ; d="$(fix_path_no_slash "$1")"
    [[ "$d" = "/" ]] || d="$d/"
    echo "$d"
}

## find_in_dir [-P] [-L] [-H] dir [find-args ...]
find_in_dir() {
    local opt=
    while true ; do
        case "${1:-}" in
            -[PLH]) opt+=" $1" ; shift ;;
            *) break ;;
        esac
    done
    local dir=$1 ; shift
    # shellcheck disable=SC2086
    (cd "$dir" && "${FIND:-find}" $opt . "$@") | ${SED:-sed} -e "s@^\./@$dir/@" -e "s@///*@/@g"
}

## is_temp_file file
is_temp_file() {
  local file=$1
  if [[ -n "${TMPDIR:-}" ]] ; then
      if [[ "${file:0:${#TMPDIR}}" = "$TMPDIR" ]] ; then
          return 0
      fi
  fi
  case "$file" in
    /tmp/*|/var/tmp/*) return 0 ;;
  esac
  return 1
}

# vim: ft=bash
