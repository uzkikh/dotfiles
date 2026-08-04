function brew-dump -d "refresh the Brewfile for this machine's chezmoi profile"
    # Which Brewfile belongs to this machine is decided by the chezmoi profile,
    # exactly as the install script decides it. Asking chezmoi keeps the two
    # from drifting apart.
    set -l profile (chezmoi execute-template '{{ .profile }}' 2>/dev/null)
    set -l root (chezmoi execute-template '{{ .chezmoi.workingTree }}' 2>/dev/null)

    if test -z "$profile" -o -z "$root"
        echo "brew-dump: cannot read the chezmoi profile, is chezmoi initialised?" >&2
        return 1
    end

    switch $profile
        case personal
            set -f name Brewfile.age
        case work-s
            set -f name Brewfile-work-s.age
        case work-e
            set -f name Brewfile-work-e.age
        case '*'
            echo "brew-dump: no Brewfile mapped for profile \"$profile\"" >&2
            return 1
    end

    set -l target $root/$name
    test -f $target; or begin
        echo "brew-dump: $target does not exist" >&2
        return 1
    end

    # Read the current list before anything slow runs. A failure here -- wrong
    # key after a rotation, key removed, file damaged -- must not be mistaken
    # for an empty file: the whole dump would then show as additions and a "y"
    # would overwrite the .age with something never compared against anything.
    # The plaintext lives in this variable and never reaches the disk.
    set -l current (chezmoi decrypt <$target)
    if test $status -ne 0
        echo "brew-dump: cannot decrypt $name, is ~/.config/chezmoi/key.txt in place?" >&2
        return 1
    end

    # `brew bundle dump` does not load formulae from untrusted taps and drops
    # them from its output without a word, exiting 0. Refuse to dump rather
    # than quietly delete entries the repo depends on.
    set -l untrusted
    for tap in (brew tap)
        if test (brew tap-info --json $tap 2>/dev/null | jq -r '.[0].trusted') != true
            set -a untrusted $tap
        end
    end
    if test (count $untrusted) -gt 0
        echo "brew-dump: these taps are untrusted, dump would silently drop their formulae:" >&2
        printf '  %s\n' $untrusted >&2
        echo "Run: brew trust --tap $untrusted" >&2
        return 1
    end

    set -l out (mktemp)
    brew bundle dump --file=$out --force; or begin
        rm -f $out
        return 1
    end

    # dump appends `, trusted: true` to a brew/cask line when that individual
    # entry was trusted (`brew trust --formula x/y/z`) rather than its whole
    # tap (`brew trust --tap x/y`) -- and Homebrew's own error message suggests
    # the per-entry form. Trust granularity is machine-local state that never
    # reaches the repository, so two machines produce different text for the
    # same set of packages. The flags are valid and harmless in themselves;
    # only the churn between machines is a nuisance. Report it and let the
    # owner decide rather than rewriting the dump behind their back.
    #
    # Formulae and casks are collected apart because `brew untrust` needs to be
    # told which it is -- a bare name is rejected, and --formula and --cask
    # cannot share one invocation.
    set -l trusted_formulae (grep -E '^brew .*, trusted: true$' $out | string replace -r '^brew "([^"]+)".*' '$1')
    set -l trusted_casks (grep -E '^cask .*, trusted: true$' $out | string replace -r '^cask "([^"]+)".*' '$1')

    # Compare as sets: a dump reorders everything, so a plain diff buries the
    # real changes in noise.
    set -l pat '^(tap|brew|cask|mas|vscode) '
    set -l added (comm -13 (printf '%s\n' $current | grep -E $pat | sort | psub) (grep -E $pat $out | sort | psub))
    set -l removed (comm -23 (printf '%s\n' $current | grep -E $pat | sort | psub) (grep -E $pat $out | sort | psub))

    # Writing only on a real difference is load-bearing now that the file is
    # encrypted: age emits fresh ciphertext on every call, so an unconditional
    # write would produce a diff after every dump and, through the hash in
    # run_onchange_after_2, reinstall every entry on the next apply.
    if test (count $added) -eq 0 -a (count $removed) -eq 0
        echo "$name is already up to date ($profile)."
        rm -f $out
        return 0
    end

    echo "$name ($profile):"
    for l in $added
        set_color green; echo "  + $l"; set_color normal
    end
    for l in $removed
        set_color red; echo "  - $l"; set_color normal
    end

    if test (count $trusted_formulae) -gt 0 -o (count $trusted_casks) -gt 0
        # An entry is user/repo/name, so its tap is the first two components.
        # Anything shorter is not from a tap and cannot be normalised this way.
        set -l taps
        for e in $trusted_formulae $trusted_casks
            set -l p (string split '/' $e)
            if test (count $p) -ge 3
                contains -- "$p[1]/$p[2]" $taps; or set -a taps "$p[1]/$p[2]"
            end
        end

        set_color yellow
        echo "  these entries carry a per-entry trusted: true, because they were trusted"
        echo "  individually rather than by tap. Harmless, but another machine's dump will"
        echo "  drop the flags again. Normalise with:"
        test (count $trusted_formulae) -gt 0; and echo "    brew untrust --formula $trusted_formulae"
        test (count $trusted_casks) -gt 0; and echo "    brew untrust --cask $trusted_casks"
        test (count $taps) -gt 0; and echo "    brew trust --tap $taps"
        set_color normal
    end

    read -l -P "Write $name? [y/N] " reply
    switch $reply
        case y Y yes YES
            # Encrypt into a temp file and check it before the target is touched.
            # `chezmoi encrypt <$out >$target` would truncate the target before
            # encrypt even runs, so a failure -- a recipient that no longer
            # matches the key, say -- would leave a tracked, empty .age behind.
            set -l enc (mktemp)
            if not chezmoi encrypt <$out >$enc
                rm -f $enc $out
                echo "brew-dump: encryption failed, $name left unchanged" >&2
                return 1
            end
            # Redirect rather than `mv`: mktemp creates 0600, and moving it
            # over the Brewfile would take those permissions with it.
            cat $enc >$target
            rm -f $enc $out
            # `git diff` is useless on armored ciphertext -- it is noise from the
            # first line to the last. Compare the decrypted versions instead.
            echo "Written. Review with:"
            echo "  diff (git -C $root show HEAD:$name | chezmoi decrypt | psub) (chezmoi decrypt <$target | psub)"
        case '*'
            rm -f $out
            echo "Left unchanged."
    end
end
