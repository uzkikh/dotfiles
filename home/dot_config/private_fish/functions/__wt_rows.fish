function __wt_rows
    # Emit "dir<TAB>branch<TAB>path" for every worktree except the main one.
    # Shared by wtr/wts. Prints nothing (returns 1) when there are none.
    set -l common_dir (git rev-parse --path-format=absolute --git-common-dir)
    or return 1
    set -l root (path dirname $common_dir)

    set -l rows
    set -l wt_path
    set -l wt_branch
    for line in (git worktree list --porcelain)
        switch $line
            case 'worktree *'
                set wt_path (string replace 'worktree ' '' $line)
                set wt_branch ''
            case 'branch *'
                set wt_branch (string replace 'branch refs/heads/' '' $line)
            case ''
                if test -n "$wt_path"; and test "$wt_path" != "$root"
                    set -a rows (printf '%s\t%s\t%s' (path basename $wt_path) $wt_branch $wt_path)
                end
                set wt_path ''
        end
    end
    # Flush the last record (porcelain output may not end with a blank line).
    if test -n "$wt_path"; and test "$wt_path" != "$root"
        set -a rows (printf '%s\t%s\t%s' (path basename $wt_path) $wt_branch $wt_path)
    end

    if test (count $rows) -eq 0
        return 1
    end
    printf '%s\n' $rows
end
