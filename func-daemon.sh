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

declare -F daemonize > /dev/null && return

_daemonize_pid=

# redirect tty stdin/stdout/stderr to /dev/null
redirect-tty-std() {
    if [[ -t 0 ]] ; then exec </dev/null ; fi
    if [[ -t 1 ]] ; then exec >/dev/null ; fi
    if [[ -t 2 ]] ; then exec 2>/dev/null ; fi
}

# close all non-std* fds
close-fds() {

    # FD 255 is the actual shell script being read/executed; It may still be needed.

    # BASH 3: eval exec {3..254}\>\&-

    # BASH 4 does not like:
    # eval $(for n in 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 ; do ; \
    #     echo exec $n\>\&- ; \
    # done)

    for n in 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 ; do
        if [[ -t $n ]] ; then eval exec $n\>\&- ; fi
    done
}

# full daemonization of external command with setsid
daemonize() {
    _daemonize_pid=
    (                    # 1. fork
        redirect-tty-std # 2.1. redirect tty stdin/stdout/stderr before setsid
        cd /             # 3. ensure cwd isn't a mounted fs
        # umask 0        # 4. umask (leave this to caller)
        close-fds        # 5. close unneeded fds
        exec ${SETSID:-setsid} "$@"
    ) &
    _daemonize_pid=$!
}

# daemonize without setsid, keeps the child in the jobs table
daemonize-job() {
    _daemonize_pid=
    (                    # 1. fork
        redirect-tty-std # 2.2.1. redirect tty stdin/stdout/stderr
        trap '' 1 2      # 2.2.2. guard against HUP and INT (in child)
        cd /             # 3. ensure cwd isn't a mounted fs
        # umask 0        # 4. umask (leave this to caller)
        close-fds        # 5. close unneeded fds
        if [[ $(type -t "$1") != file ]]; then
            "$@"
        else
            exec "$@"
        fi
    ) &
    _daemonize_pid=$!
    disown -h $!       # 2.2.3. guard against HUP (in parent)
}
