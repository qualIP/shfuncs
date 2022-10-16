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

typeset -f test_git_changeset > /dev/null && return

_qip_func_git_saved_state=""
if [[ -n "${BASH_VERSION:-}" ]] ; then
    shopt -q extglob || _qip_func_git_saved_state+="shopt -u extglob"$'\n' ; shopt -s extglob
elif [[ -n "${ZSH_VERSION:-}" ]] ; then
    setopt KSH_GLOB
fi

# shellcheck disable=all
SHFUNCS_DIR=${SHFUNCS_DIR:-$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")}
. "$SHFUNCS_DIR/func-cmd.sh"
. "$SHFUNCS_DIR/func-assert.sh"
. "$SHFUNCS_DIR/func-print.sh"
. "$SHFUNCS_DIR/func-utils.sh"
. "$SHFUNCS_DIR/func-hook.sh"

# shellcheck disable=SC2034
EGIT_BISECT_CANT_TEST=125

# See https://github.com/libgit2/libgit2/blob/1327dbcf2a4273a8ba6fd978db5f0882530af94d/src/libgit2/refs.h
# shellcheck disable=SC2034
{
GIT_REFS_DIR="refs/"
GIT_REFS_HEADS_DIR="${GIT_REFS_DIR}heads/"
GIT_REFS_TAGS_DIR="${GIT_REFS_DIR}tags/"
GIT_REFS_REMOTES_DIR="${GIT_REFS_DIR}remotes/"
GIT_REFS_NOTES_DIR="${GIT_REFS_DIR}notes/"
GIT_RENAMED_REF_FILE="${GIT_REFS_DIR}RENAMED-REF"
GIT_PACKEDREFS_FILE="packed-refs"
GIT_HEAD_FILE="HEAD"
GIT_ORIG_HEAD_FILE="ORIG_HEAD"
GIT_FETCH_HEAD_FILE="FETCH_HEAD"
GIT_MERGE_HEAD_FILE="MERGE_HEAD"
GIT_REVERT_HEAD_FILE="REVERT_HEAD"
GIT_CHERRYPICK_HEAD_FILE="CHERRY_PICK_HEAD"
GIT_BISECT_LOG_FILE="BISECT_LOG"
GIT_REBASE_MERGE_DIR="rebase-merge/"
GIT_REBASE_MERGE_INTERACTIVE_FILE="${GIT_REBASE_MERGE_DIR}interactive"
GIT_REBASE_APPLY_DIR="rebase-apply/"
GIT_REBASE_APPLY_REBASING_FILE="${GIT_REBASE_APPLY_DIR}rebasing"
GIT_REBASE_APPLY_APPLYING_FILE="${GIT_REBASE_APPLY_DIR}applying"
GIT_SEQUENCER_DIR="sequencer/"
GIT_SEQUENCER_HEAD_FILE="${GIT_SEQUENCER_DIR}head"
GIT_SEQUENCER_OPTIONS_FILE="${GIT_SEQUENCER_DIR}options"
GIT_SEQUENCER_TODO_FILE="${GIT_SEQUENCER_DIR}todo"
GIT_STASH_FILE="stash"
GIT_REFS_STASH_FILE="${GIT_REFS_DIR}$GIT_STASH_FILE"
}

_git_changeset_state=unknown

## git_eval_changeset_state
git_eval_changeset_state() {
    _git_changeset_state=error
    if [[ -z "${OUT_TMP:-}" ]] ; then
        with_OUT_TMP git_eval_changeset_state "$@"
        return $?
    fi
    # Use? git diff-index --quiet HEAD --
    if false ; then
        log_cmd_live git diff --name-status
        if [[ -s "$OUT_TMP" ]] ; then
            _git_changeset_state=diff
        else
            _git_changeset_state=clean
        fi
    else
        if tty <&1 >/dev/null 2>&1 ; then
            # This is live to user, might as well let it update the index.
            log_cmd_live_pty git status
        else
            # This could be used by a shell script, finish fast.
            GIT_OPTIONAL_LOCKS=${GIT_OPTIONAL_LOCKS:-0} log_cmd_live git status
        fi
        # On branch master
        # No commits yet
        if ${GREP:-grep} -q "^nothing to commit, \(worktree\|working tree\) clean" "$OUT_TMP" ; then
            _git_changeset_state="clean"
        elif ${GREP:-grep} -q "^nothing to commit (create/copy files and use \"git add\" to track)" "$OUT_TMP" ; then
            # "nothing to commit (create/copy files and use "git add" to track)"
            # Different version of the above?
            _git_changeset_state="clean"
        elif ${GREP:-grep} -q "^nothing added to commit but untracked files present" "$OUT_TMP" ; then
            _git_changeset_state="clean"
            _git_changeset_state+="-untracked"
        else
            _git_changeset_state="dirty"
        fi
        if [[ "$_git_changeset_state" =~ ^clean ]] ; then
            if ${GREP:-grep} -q "^On branch " "$OUT_TMP" ; then
                # On branch xyz
                if ! ${GREP:-grep} -q "^Your branch is up to date with " "$OUT_TMP" ; then
                    # Your branch is up to date with 'origin/xyz'.
                    _git_changeset_state+="-notpushed"
                fi
            fi
        fi
    fi
    # GIT_OPTIONAL_LOCKS=${GIT_OPTIONAL_LOCKS:-0} log_cmd_live git status --porcelain
    # if ! $OPT_FORCE && test -s "$OUT_TMP" ; then
    #     print_err "Your worktree is dirty. Please commit or stash all changes and run $prog again."
    #     exit 1
    # fi
}

git_changeset_state() {
    _git_changeset_state=error
    git_eval_changeset_state "$@" > /dev/null || return $?
    echo "$_git_changeset_state"
}

git_changeset_state_cached() {
    echo "$_git_changeset_state"
}

## test_git_changeset [options...]
test_git_changeset() {
    local untracked_ok=true
    local branch_not_pushed_ok=true
    local git_changeset_state
    while (( $# )) ; do
        case "$1" in
            --changeset-state) git_changeset_state="$2" ; shift 2 ;;
            --untracked-ok)    untracked_ok=true  ; shift ;;
            --untracked-fail)  untracked_ok=false ; shift ;;
            --branch-not-pushed-ok)   branch_not_pushed_ok=true  ; shift ;;
            --branch-not-pushed-fail) branch_not_pushed_ok=false ; shift ;;
            *) print_err "Invalid argument: $1" ; return 1 ;;
        esac
    done
    if [[ -z "$git_changeset_state" ]] ; then
        git_eval_changeset_state || return $?
        git_changeset_state=$(git_changeset_state_cached)
    fi
    case "$git_changeset_state" in
        diff)
            print_status "Worktree clean" FAIL "(uncommitted changes present)"
            return 1
            ;;
        clean)
            print_status "Worktree clean" PASS
            return 0
            ;;
        clean-notpushed)
            if $branch_not_pushed_ok ; then
                print_status "Worktree clean" PASS "(branch not pushed)"
                return 0
            else
                print_status "Worktree clean" FAIL "(branch not pushed)"
                return 1
            fi
            ;;
        clean-untracked)
            if $untracked_ok ; then
                print_status "Worktree clean" PASS "(untracked files present)"
                return 0
            else
                print_status "Worktree clean" FAIL "(untracked files present)"
                return 1
            fi
            ;;
        clean-untracked-notpushed)
            if $untracked_ok && $branch_not_pushed_ok ; then
                print_status "Worktree clean" PASS "(untracked files present; branch not pushed)"
                return 0
            else
                print_status "Worktree clean" FAIL "(untracked files present; branch not pushed)"
                return 1
            fi
            ;;
        dirty)
            print_status "Worktree clean" FAIL "(uncommitted changes present)"
            return 1
            ;;
        *)
            print_status "Worktree clean" FAIL "($git_changeset_state)"
            return 1
            ;;
    esac
}

## git_dir
#
# Returns the relative location of the .git directory.
# Defaults to GIT_DIR environment variable.
git_dir() {
    GIT_OPTIONAL_LOCKS=${GIT_OPTIONAL_LOCKS:-0} git rev-parse --git-dir
}

## git_path path
#
# Resolves "$GIT_DIR/<path>".
git_path() {
    GIT_OPTIONAL_LOCKS=${GIT_OPTIONAL_LOCKS:-0} git rev-parse --git-path "$1"
}

## git_toplevel
git_toplevel() {
    GIT_OPTIONAL_LOCKS=${GIT_OPTIONAL_LOCKS:-0} git rev-parse --show-toplevel
}

## git_repo [remote]
git_repo() {
    local git_repo=
    git_repo=$(GIT_OPTIONAL_LOCKS=${GIT_OPTIONAL_LOCKS:-0} git remote get-url "${1:-origin}")
    [[ -n "$git_repo" ]] || return
    git_repo=$(basename "$git_repo" .git)
    [[ -n "$git_repo" ]] || return
    echo "$git_repo"
}

## _git_sequencer_get_last_command
_git_sequencer_get_last_command() {
    local git_dir ; git_dir=$(git_dir)
    local command
    local rest
    if [[ -f "$git_dir/$GIT_SEQUENCER_TODO_FILE" ]] ; then
        if read command rest < "$git_dir/$GIT_SEQUENCER_TODO_FILE"
        then
            case "$command" in
                p|pick) echo "pick" ; return 0 ;;
                revert) echo "revert" ; return 0 ;;
            esac
        fi
    fi
    # return 1
}

## git_state
git_state() {
    # See https://github.com/libgit2/libgit2/blob/main/src/libgit2/repository.c
    # Much faster to use $git_dir than rely on git_path for every file.
    local git_dir ; git_dir=$(git_dir)
    local git_state
    local hook_func
    for hook_func in $(hook_get git_state) ; do
        # $hook_func "$git_dir"
        git_state=$($hook_func "$git_dir")
        if [[ -n "$git_state" ]] ; then
            echo "$git_state"
            break
        fi
    done
}
hook_declare git_state

git_state_default() {
    local git_dir ; git_dir=${1:-$(git_dir)}
    if [[ -f "$git_dir/$GIT_REBASE_MERGE_INTERACTIVE_FILE" ]] ; then
        echo "rebase_interactive"
    elif [[ -d "$git_dir/$GIT_REBASE_MERGE_DIR" ]] ; then
        echo "rebase_merge"
    elif [[ -f "$git_dir/$GIT_REBASE_APPLY_REBASING_FILE" ]] ; then
        echo "rebase"
    elif [[ -f "$git_dir/$GIT_REBASE_APPLY_APPLYING_FILE" ]] ; then
        echo "apply_mailbox"
    elif [[ -d "$git_dir/$GIT_REBASE_APPLY_DIR" ]] ; then
        echo "apply_mailbox_or_rebase"
    elif [[ -f "$git_dir/$GIT_MERGE_HEAD_FILE" ]] ; then
        echo "merge"
    elif [[ -f "$git_dir/$GIT_REVERT_HEAD_FILE" ]] ; then
        if [[ -f "$git_dir/$GIT_SEQUENCER_TODO_FILE" ]] ; then
            echo "revert_sequence"
        else
            echo "revert"
        fi
    elif [[ -f "$git_dir/$GIT_CHERRYPICK_HEAD_FILE" ]] ; then
        if [[ -f "$git_dir/$GIT_SEQUENCER_TODO_FILE" ]] ; then
            echo "cherrypick_sequence"
        else
            echo "cherrypick"
        fi
    elif [[ -f "$git_dir/$GIT_BISECT_LOG_FILE" ]] ; then
        echo "bisect"
    else
        local sequencer_last_command ; sequencer_last_command=$(_git_sequencer_get_last_command)
        if [[ "$sequencer_last_command" = "pick" ]] ; then
            echo "cherrypick_sequence"
        elif [[ "$sequencer_last_command" = "revert" ]] ; then
            echo "revert_sequence"
        fi
    fi
}
hook_add git_state git_state_default

# TODO this is not inclusive enough -- See: git check-ref-format
is_git_branch_name() {
    case "$1" in
        *..*|*.) return 1 ;;
        *//*|/*|*/) return 1 ;;
        -*) return 1 ;;
        +([A-Za-z0-9_/.+-])) return 0 ;;
        *) return 1 ;;
    esac
}

git_branch_exists() {
    local v
    sha=$(git show-ref "refs/heads/$1")
    [[ -n "$sha" ]]
}

git_remote_branch_exists() {
    local v
    sha=$(git show-ref "refs/remotes/$1")
    [[ -n "$sha" ]]
}

eval "$_qip_func_git_saved_state" ; unset _qip_func_git_saved_state

# vim: ft=bash
