function wtn --description 'Create a git worktree + branch from fresh origin/main and cd in'
    # wtn <branch-name>
    # Create a git worktree on a new branch, from a fresh origin/main, and cd into it.
    # The worktree dir mirrors the branch name with slashes replaced by dashes, and always
    # lands under the MAIN repo's worktrees/ - even when run from inside another worktree.
    set -l branch $argv[1]
    if test -z "$branch"
        echo "Usage: wtn <branch-name>"
        return 1
    end

    # --git-common-dir points at the shared .git of the main repo; its parent is that repo's root.
    set -l common_dir (git rev-parse --path-format=absolute --git-common-dir)
    or return 1
    set -l root (path dirname $common_dir)

    set -l wt_name (string replace -a '/' '-' $branch)
    set -l wt_path $root/worktrees/$wt_name

    if git show-ref --quiet --verify refs/heads/$branch
        echo "Branch '$branch' already exists. Use wts to switch to its worktree."
        return 1
    end
    if test -e $wt_path
        echo "Path '$wt_path' already exists."
        return 1
    end

    git fetch origin main
    and git worktree add -b $branch $wt_path origin/main
    and cd $wt_path
end
