function wtp --description 'Check out an open PR into a git worktree (fzf picker)'
    # wtp
    # Pick an open PR via fzf and check its branch out into a git worktree, then cd in.
    # The worktree dir mirrors the branch name with slashes replaced by dashes, and always
    # lands under the MAIN repo's worktrees/ - even when run from inside another worktree.
    # Assumes PRs come from branches on the repo itself (no forks).
    set -l list (gh pr list --json number,title,headRefName,author \
        --template '{{range .}}{{printf "%v\t%s\t%s\t@%s\n" .number .headRefName .title .author.login}}{{end}}')
    or return 1

    if test -z "$list"
        echo "No open PRs."
        return 0
    end

    # fzf runs --preview in its own shell (sh), not fish, so {1} is passed verbatim to gh.
    set -l pick (printf '%s\n' $list | fzf --delimiter=\t --with-nth=1,4,2 \
        --prompt='review PR> ' \
        --preview='gh pr view {1}')
    or return 1

    set -l fields (string split \t $pick)
    set -l branch $fields[2]

    set -l common_dir (git rev-parse --path-format=absolute --git-common-dir)
    or return 1
    set -l root (path dirname $common_dir)

    set -l wt_name (string replace -a '/' '-' $branch)
    set -l wt_path $root/worktrees/$wt_name

    # Already checked out somewhere: that's the branch we wanted, just go there.
    if test -e $wt_path
        cd $wt_path
        return
    end

    if git show-ref --quiet --verify refs/heads/$branch
        # Local branch already exists; reuse it without fetching.
        git worktree add $wt_path $branch
        and cd $wt_path
    else
        git fetch origin $branch
        and git worktree add --track -b $branch $wt_path origin/$branch
        and cd $wt_path
    end
end
