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

declare -F test_git_changeset > /dev/null && return

. "$(dirname "${BASH_SOURCE[0]}")/func-cmd.sh"
. "$(dirname "${BASH_SOURCE[0]}")/func-assert.sh"
. "$(dirname "${BASH_SOURCE[0]}")/func-print.sh"
. "$(dirname "${BASH_SOURCE[0]}")/func-utils.sh"

EGIT_BISECT_CANT_TEST=125

## test_git_changeset [untracked_ok?]
test_git_changeset() {
    if [[ -z "${OUT_TMP:-}" ]] ; then
        with_OUT_TMP test_git_changeset "$@"
        return $?
    fi
    local untracked_ok=${1:-true}
    # Use? git diff-index --quiet HEAD --
    if false ; then
        log_cmd_live git diff --name-status
        if [ -s "$OUT_TMP" ] ; then
            print_status "Changeset not empty" FAIL
            return 1
        fi
        print_status "Changeset empty" PASS
    else
        log_cmd_live_pty git status
	# On branch master
	# No commits yet
        if ${GREP:-grep} -q "^nothing to commit, \(worktree\|working tree\) clean" "$OUT_TMP" ; then
            print_status "Worktree clean" PASS
        elif ${GREP:-grep} -q "^nothing to commit (create/copy files and use \"git add\" to track)" "$OUT_TMP" ; then
	    # nothing to commit (create/copy files and use "git add" to track)
            print_status "Worktree clean" PASS
        elif ${GREP:-grep} -q "^nothing added to commit but untracked files present" "$OUT_TMP" ; then
            if $untracked_ok ; then
                print_status "Worktree clean" PASS "(untracked files present)"
            else
                print_status "Worktree clean" FAIL "(untracked files present)"
                return 1
            fi
        else
            print_status "Worktree not clean" FAIL
            return 1
        fi
    fi
    # TODO
    # log_cmd_live git status --porcelain
    # if ! $OPT_FORCE && test -s "$OUT_TMP" ; then
    #     print_err "Your worktree is dirty. Please commit or stash all changes and run $prog again."
    #     exit 1
    # fi
}

## git_dir
git_dir() {
    git rev-parse --git-dir
}

## git_toplevel
git_toplevel() {
    git rev-parse --show-toplevel
}
