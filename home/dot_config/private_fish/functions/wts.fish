function wts --description 'Switch to a git worktree (fzf picker)'
    # wts
    # Pick a git worktree via fzf and cd into it. Main working tree excluded.
    set -l rows (__wt_rows)
    or begin
        echo "No worktrees to switch to."
        return 0
    end

    set -l pick (printf '%s\n' $rows | fzf --with-nth=1,2 --delimiter=\t --prompt='switch worktree> ')
    or return 1

    set -l fields (string split \t $pick)
    cd $fields[3]
end
