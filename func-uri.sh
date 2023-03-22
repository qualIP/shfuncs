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

typeset -f make_url > /dev/null && return

## make_url url [arg value] ...
make_url() {
    local url="$1" ; shift
    local sep="?"
    while (( $# )) ; do
        url="$url$sep$1=$(encode_pct "$2")"
        shift 2
        sep="&"
    done
    echo "$url"
}

## get_query_var [var]
get_query_var() {
    if [[ -n "${1:-}" ]] ; then
        decode_pct "$(${SED:-sed} -n -e 's/^\(.*&\)\?'"$1"'=\([^&]*\).*$/\2/p' <<< "$QUERY_STRING")"
    else
        decode_pct "$QUERY_STRING"
    fi
}

## encode_html in [...]
encode_html() {
    ${SED:-sed} -e '
    s@&@\&amp;@g
    s@>@\&gt;@g
    s@<@\&lt;@g
    s@"@\&#34;@g
    s@'"'"'@\&#39;@g
    ' <<< "$*"
}

## decode_html in [...]
decode_html() {
    ${SED:-sed} -e '
    s@&gt;@>@g
    s@&lt;@<@g
    s@&#34;@"@g
    s@&#39;@'"'"'@g
    s@&nbsp;@ @g
    s@&\(amp\|#38\);@\&@g
    ' <<< "$*"
}

## encode_pct in [...]
encode_pct() {
    ${SED:-sed} -e '
    s@%@%25@g
    s@&@%26@g
    s@'"'"'@%27@g
    s@(@%28@g
    s@)@%29@g
    s@/@%2F@g
    s@:@%3A@g
    s@=@%3D@g
    s@ @+@g
    ' <<< "$*"
}

## decode_pct in [...]
decode_pct() {
    ${SED:-sed} -e '
    s@+@ @g
    s@%0D@ @g
    s@%0A@ @g
    s@%25@%@g
    s@%26@\&@g
    s@%27@'"'"'@g
    s@%28@(@g
    s@%29@)@g
    s@%2F@/@g
    s@%3A@:@g
    s@%3D@=@g
    ' <<< "$*"
}

# vim: ft=bash
