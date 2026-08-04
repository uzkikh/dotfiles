# Author: Uzkikh Ivan
# Created: 2026-01-05

function git-cleanup -d "Clean up old git branches"
    set -l base_branch main

    # Parse arguments
    for arg in $argv
        switch $arg
            case -h --help
                echo "Usage: git-cleanup [BASE_BRANCH]"
                echo "Clean up branches merged into BASE_BRANCH (default: main)"
                return 0
            case '*'
                set base_branch $arg
        end
    end

    # Verify we're in a git repo
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Not a git repository"
        return 1
    end

    echo "Fetching from remote..."
    git fetch --prune

    # Find branches to delete
    set -l merged (git branch --merged $base_branch | grep -v "^\*\|main\|master\|develop" | awk '{print $1}')
    set -l gone (git branch -vv | grep ': gone]' | awk '{print $1}')

    set -l total_count (count $merged $gone)

    if test $total_count -eq 0
        echo "Nothing to clean up"
        return 0
    end

    echo "Found $total_count branches to delete:"

    if test (count $merged) -gt 0
        echo ""
        echo "Merged into $base_branch:"
        for branch in $merged
            echo "  • $branch"
        end
    end

    if test (count $gone) -gt 0
        echo ""
        echo "Remote deleted:"
        for branch in $gone
            echo "  • $branch"
        end
    end

    echo ""
    echo "Deleting branches..."

    # Delete merged branches
    for branch in $merged
        git branch -d $branch
    end

    # Delete gone branches
    for branch in $gone
        git branch -D $branch
    end

    echo "Cleaned up $total_count branches"
end
