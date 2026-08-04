function wtl --description 'List git worktrees'
    # wtl
    # List git worktrees. With no args, marks the current worktree with an arrow
    # and a muted colour. Any args (e.g. --porcelain, -v) pass through unchanged,
    # since custom output formats should not be reformatted.
    if test (count $argv) -gt 0
        git worktree list $argv
        return
    end

    set -l current (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$current"
        # Not inside a git repo; just show the plain list.
        git worktree list
        return
    end

    git worktree list | while read -l line
        # First whitespace-separated field is the worktree path.
        set -l path (string split -f1 ' ' -- $line)
        if test "$path" = "$current"
            set_color green
            printf '→ %s\n' $line
            set_color normal
        else
            printf '  %s\n' $line
        end
    end
end
