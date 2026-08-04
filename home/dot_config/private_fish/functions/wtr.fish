function wtr --description 'Remove a git worktree + its branch (fzf picker)'
    # wtr
    # Pick a git worktree via fzf and remove it (plus its local branch).
    # The main working tree is excluded. Refuses dirty trees / unmerged branches
    # unless you confirm a force. Runs `git worktree prune` at the end.
    set -l rows (__wt_rows)
    or begin
        echo "No worktrees to remove."
        return 0
    end

    set -l common_dir (git rev-parse --path-format=absolute --git-common-dir)
    or return 1
    set -l root (path dirname $common_dir)

    set -l pick (printf '%s\n' $rows | fzf --with-nth=1,2 --delimiter=\t --prompt='remove worktree> ')
    or return 1

    set -l fields (string split \t $pick)
    set -l sel_branch $fields[2]
    set -l sel_path $fields[3]

    # Step out of the target if we're inside it, so git can remove it.
    switch $PWD/
        case $sel_path/\*
            cd $root
    end

    if not git worktree remove $sel_path
        # Dirty tree: git refused. Ask before forcing.
        read -l -P "Force remove '$sel_path' and lose changes? [y/N] " reply
        if test "$reply" != y -a "$reply" != Y
            echo "Aborted."
            return 1
        end
        git worktree remove --force $sel_path
        or return 1
    end

    if test -n "$sel_branch"
        # -d refuses unmerged branches; force after a forced worktree removal.
        if not git branch -d $sel_branch
            read -l -P "Branch '$sel_branch' is not fully merged. Delete anyway? [y/N] " breply
            if test "$breply" = y -o "$breply" = Y
                git branch -D $sel_branch
            end
        end
    end

    git worktree prune
end
