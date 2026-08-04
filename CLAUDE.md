# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles for macOS. Everything under `home/` is *source state*: files are transformed by chezmoi's naming conventions and Go templates before landing in `$HOME`. Editing a file here changes nothing until `chezmoi apply` runs.

**`.chezmoiroot` contains `home`, so the source root is `home/`, not the repository root.** Everything at the top level — `README.md`, `CLAUDE.md`, the Brewfiles, `docs/` — is repo metadata that chezmoi cannot see at all. That is deliberate: there is no ignore list to forget to update, and a new metadata file can never leak into `$HOME` by accident.

Paths to managed files below are written relative to the source root. `dot_config/tmux/tmux.conf` means `home/dot_config/tmux/tmux.conf` on disk.

## Chezmoi Naming Conventions

Source filenames encode the target file's name and permissions. Get these wrong and the file lands in the wrong place with the wrong mode:

- `dot_` → leading dot (`dot_gitconfig` → `~/.gitconfig`)
- `private_` → mode 0700/0600 (`dot_config/private_fish/` → `~/.config/fish/`)
- `executable_` → +x (`executable_yabairc` → `~/.config/yabai/yabairc`)
- `.tmpl` → Go template, rendered with chezmoi data
- `run_once_` → script run once, keyed by the hash of its rendered content (`run_once_before_1-install-brew.sh`)
- `run_onchange_` → same, but the hash is meant to change: the script embeds a hash of the file it cares about

Note the asymmetry: `dot_config/private_fish/` is private but `dot_config/nvim/` is not — match the target's real permissions, don't blanket-apply prefixes.

Dot-files in the source are ignored by chezmoi unless they start with `.chezmoi`. A `.gitignore` at the source root stays a repo file and is never written to `$HOME`.

## Commands

```bash
chezmoi diff                    # preview pending changes (always do this first)
chezmoi apply                   # write source state to $HOME
chezmoi status                  # short status: 2nd column = source→target delta
chezmoi add ~/.config/tool/cfg  # bring an existing file under management
chezmoi edit ~/.gitconfig       # edit source of a target path (opens nvim, see [edit] in the config template)
chezmoi edit --apply ~/.gitconfig   # edit and apply in one step
chezmoi edit --watch ~/.gitconfig   # apply on every save, useful while iterating
chezmoi update                  # git pull + apply + refresh externals

# Templates: render without applying
chezmoi execute-template < home/dot_config/private_fish/config.fish.tmpl
chezmoi cat ~/.gitconfig        # what apply would write
chezmoi data                    # the variables templates see

chezmoi state delete-bucket --bucket=scriptState   # force run_once_ scripts to re-run
```

`brew bundle` and the macOS defaults **are** applied by chezmoi now, as scripts in the `after_` phase — see Bootstrap below. Running them by hand is only needed to retry a failure.

**`brew bundle dump` silently drops formulae from untrusted third-party taps.** Homebrew 6.0 will not load non-official formulae until the tap is trusted, and `dump` omits what it cannot load — with no warning and exit 0. Casks are unaffected. Two of the losses are ones the repo depends on: `felixkratz/formulae/borders` (launched by `aerospace.toml`'s `after-startup-command`) and `felixkratz/formulae/sketchybar` (the whole `dot_config/sketchybar/` tree). Before re-dumping:

```bash
brew trust --tap felixkratz/formulae fluxcd/tap nikitabobko/tap siderolabs/tap umputun/apps
brew tap-info <tap> | sed -n 2p     # must say "Trusted"
```

Trust is local machine state in `~/.homebrew/trust.json` and does **not** travel with the repository. What makes a fresh machine work is `trusted: true` on the `tap` lines inside the Brewfiles — keep both in sync.

Then diff the result against HEAD as a set, not as a text diff — a re-dump reorders everything, so a plain `git diff` hides real losses. Both sides need decrypting, and on ciphertext `git diff` is not merely noisy but useless:

```bash
diff <(git show HEAD:Brewfile.age | chezmoi decrypt | grep -E '^(tap|brew|cask|mas) ' | sort) \
     <(chezmoi decrypt < Brewfile.age | grep -E '^(tap|brew|cask|mas) ' | sort)
```

**Use the `brew-dump` fish function instead of doing this by hand.** It picks the encrypted Brewfile from the chezmoi profile, decrypts it into memory, **refuses to run while any tap is untrusted** (the one hazard above that actually destroys data), shows the change as a set, and asks before writing.

It also refuses when the file will not decrypt, and that check is deliberately the *first* thing it does. A failed decryption yields an empty list, which would render as "every entry added" and, answered with `y`, overwrite the `.age` with content that was never compared against anything.

It never rewrites the dump. The one thing it reports and leaves alone is **`, trusted: true` on a `brew`/`cask` line**: `dump` appends that when the individual entry was trusted (`brew trust --formula x/y/z`) rather than its whole tap (`brew trust --tap x/y`), and Homebrew's own error message nudges you toward the per-entry form. Trust granularity is machine-local state that never reaches the repository, so two machines produce different text for the same packages. The flags are valid and harmless; the fix for the churn belongs on the machine — `brew untrust <entries>`, then `brew trust --tap <taps>`.

**The Brewfiles carry no hand-written comments, deliberately.** `brew bundle dump` regenerates them from installed state and silently drops anything typed in by hand, so a note added there survives exactly until the next dump — and on armored ciphertext no diff will show you it went. The files are therefore kept byte-identical to what `dump` produces (the `#` description above each entry is `dump`'s own), and anything worth saying about a package is written here instead.

**`brew "resticprofile"` is unqualified on purpose.** The project's own documentation points at the `creativeprojects/tap` tap, so `creativeprojects/tap/resticprofile` looks like the more precise spelling. It is not: that tap ships a `tap_migrations.json` mapping `resticprofile` to `homebrew/core`, so the qualified name redirects straight back to core and pins nothing at all. The bare name is the honest one, and the formula does install from `homebrew/core`. This round-trip has already been made once — tap removed, docs cited, qualified name restored, migrations file found, name reverted — so do not start it again.

Note what `dump` does **not** lose: `trusted: true` and custom URLs on `tap` lines survive it intact, for every tap that is trusted locally. A tap that comes back bare is a tap that is not trusted on this machine — which is what the guard above is for.

There is no build, lint, or test step. Verification is `chezmoi diff` plus launching the affected tool.

### Syncing drift back into the source

**`chezmoi re-add` silently skips every file whose source is a template** — it cannot reverse a rendered template. It exits 0 and prints nothing, so it looks like it worked. `dot_gitconfig.tmpl` and `config.fish.tmpl` are both templates, so editing `~/.gitconfig` or `~/.config/fish/config.fish` directly (including via `git config --global`) and then running `re-add` syncs nothing, and those edits still die at the next `apply`.

Merge that drift back by hand, keeping `{{ .name }}` / `{{ .email }}` / `{{ .chezmoi.homeDir }}` intact. To verify a merged gitconfig, compare parsed keys rather than eyeballing the diff — indentation differences are noise:

```bash
chezmoi cat ~/.gitconfig > /tmp/rendered
diff <(git config -f /tmp/rendered --list | sort) <(git config -f ~/.gitconfig --list | sort)
```

The mirror-image hazard is worse: on **non-template** files `re-add` works, and will happily overwrite the source with whatever is live. If a machine never applied a commit made elsewhere, its stale live copy gets pushed back into the source and silently deletes that committed work. This is how the `[custom.worktree]` block from e142bff vanished from `starship.toml`. Before any `re-add`, apply first, and check `git diff` afterwards for deletions you did not intend.

Run `chezmoi status` before every apply: `M` in the second column means the target has drifted and apply will overwrite it.

`chezmoi apply` prompts for confirmation when a target changed since chezmoi last wrote it (`M` or `D` in the *first* column) and aborts without a TTY. Non-interactively, apply that one path with `--force` once you have confirmed the diff is safe. Do not pipe `chezmoi apply -v` into `head` — SIGPIPE kills it mid-run and leaves the apply half-finished.

## Machine Profiles

The config template asks two questions on `chezmoi init` and stores the answers in `~/.config/chezmoi/chezmoi.toml`, which is outside the repository:

- `profile` — `promptStringOnce`, validated against `personal`, `work-s`, `work-e`
- `email` — `promptStringOnce`

No employer address or machine identifier lives in the repository as a result.

**The template carries a second `fail`, checked before either prompt.** Without `~/.config/chezmoi/key.txt` it stops `chezmoi init` outright — earlier than any script, earlier than Homebrew's installer asks for a sudo password, and without asking two questions it is about to reject the answers to. See Encryption below for why a missing key has to be caught this early.

**Why a plain string prompt and not `promptChoiceOnce`.** The choice widget pre-fills its input field with the option list, and a mistyped answer could come back as the first option — silently selecting `personal` and installing the personal package set on a work machine. A string field starts empty, so an unexpected answer reaches the `fail` in the template and stops the run with a readable message. The validation is load-bearing either way: `chezmoi init` does not check prompt answers against anything, and `--promptString` keys are the **prompt text**, so the non-interactive form is `--promptString "Machine profile (personal/work-s/work-e)=work-e"`.

`run_once_before_0-confirm-profile.sh.tmpl` echoes the profile, the email and the Brewfile they select, and asks for confirmation. **It is deliberately the very first script**: Homebrew's installer asks for a sudo password, so a wrong profile has to be caught before that, not after. Declining writes no files and installs nothing. The package script later repeats the banner without a question — by then a long install has scrolled the first one out of sight.

Both talk to **`/dev/tty` directly**, not to stdout or stderr. chezmoi captures a script's stdout outright, and how it wires stdin and stderr is not worth depending on — `/dev/tty` is the same terminal under `apply` and under `init --apply` alike. Watch the redirection order in the probe: `: 2>/dev/null < /dev/tty`, because bash reports a failed `< /dev/tty` on the *not yet redirected* stderr. Without a controlling terminal the banner falls back to stderr and the question is skipped, so an unattended install never blocks. Declining exits non-zero on purpose: chezmoi records script state only on success, so the question returns on the next apply instead of the script never running again.

`before_0` is **also the key gate**, and that part is a deliberate exception to "an unattended install never blocks". The gate sits between the `/dev/tty` probe and the early `[ -n "$tty" ] || exit 0`, precisely so that it still runs when there is no terminal — the unattended case is the one it exists for. Nothing useful follows an install that cannot read its own package list, so it exits non-zero there rather than carrying on. Order inside the script is load-bearing three ways: below the probe so it can reach the terminal, below the banner so the failure names a profile, above the early exit so it is not skipped.

**The config template is evaluated at `chezmoi init`, not at `chezmoi apply`.** Changing it has no effect until `chezmoi init` runs again. If template output looks stale on a machine, that is why — the answers are frozen in the generated config.

`promptStringOnce` returns the stored value and ignores `--promptString` once the key exists, so re-running `init` will not re-ask for the email.

## Bootstrap

`chezmoi init --apply` is the whole install. Four scripts in `.chezmoiscripts/` hang off chezmoi's phases:

```
run_once_before_0-confirm-profile.sh.tmpl  key gate + profile banner + confirmation
        ↓
run_once_before_1-install-brew.sh          Homebrew
        ↓
files + externals                          dotfiles, themes, tmux plugins
        ↓
run_onchange_after_2-brew-bundle.sh.tmpl   packages, per profile
run_onchange_after_3-install-fisher.sh.tmpl  fish plugins
run_onchange_after_4-macos-defaults.sh     macOS settings
run_once_after_5-login-shell.sh            chsh to fish
```

`run_once_after_5-login-shell.sh` is last because it needs fish to exist and asks for a password twice (`/etc/shells`, then `chsh`). Two details worth keeping: `$SHELL` inside a chezmoi script is the shell that launched it — `/bin/zsh` even when fish is the login shell — so the real value comes from `dscl . -read "$HOME" UserShell`; and when there is no terminal the script prints the two commands and exits **non-zero**, so chezmoi does not record it and an interactive apply later tries again. Nothing runs after it, so failing there costs nothing.

**`run_onchange_` instead of `run_once_` is mandatory for the package scripts.** State is keyed on the hash of the rendered script, and the Brewfile is not part of it — with `run_once_` the script would never run again after a `brew bundle dump`. The scripts therefore embed the hash of the file they install from:

```bash
{{- $files := dict "personal" "Brewfile.age" "work-s" "Brewfile-work-s.age" "work-e" "Brewfile-work-e.age" -}}
{{- $bf := index $files .profile -}}
# {{ $bf }} hash: {{ include (printf "../%s" $bf) | sha256sum }}
```

The hash must be computed over the *same* file the profile selects. A hardcoded `include "../Brewfile.age"` on a work machine gives the worst of both: edits to the work Brewfile never re-run the script, and edits to the personal one re-run it with the wrong file. Note `../` — after `.chezmoiroot`, `{{ .chezmoi.sourceDir }}` is `<repo>/home` while the Brewfiles sit at `{{ .chezmoi.workingTree }}`, the repo root.

**A failing `after_` script aborts apply and everything after it never runs.** `brew bundle` has no type selectors, so App Store entries cannot be split off with a flag. The package script therefore **exits 0 even on failure** and prints a fixed marker instead. There are three, one per reason:

```
!! brew bundle FAILED: brew not on PATH; rerun by hand: ...
!! brew bundle FAILED: cannot decrypt <file> -- is ~/.config/chezmoi/key.txt in place?
!! brew bundle FAILED, rerun by hand: ...
```

Those markers are the failure signal, because the exit code is always 0 by design. All three share the substring `brew bundle FAILED`, so one grep finds any of them — keep that property when editing the text. Decryption is a separate stage from installation for the same reason there are separate markers: folded into one pipeline, a missing key would surface as "brew bundle failed" and send you looking at packages.

`brew bundle check` is the obvious alternative and does not work here. By default it treats an **outdated** package as unsatisfied, not just a missing one — an installed-but-stale `pkgconf` yields `Formula pkgconf needs to be installed or updated` and a non-zero exit. `--no-upgrade` narrows it to genuinely missing packages, but even then it flags the App Store entries whose failure this design deliberately tolerates. As a gate it would be red on a perfectly healthy machine.

**`brew bundle` itself runs with `--no-upgrade`, deliberately.** Apply installs what is missing and never touches what already works; upgrading versions is the `update` fish function's job (`brew update && brew upgrade && brew cleanup`). Without the flag, adding a single tool to a Brewfile would drag every outdated package along on the next apply — the first run of this script upgraded 15. Keep the two concerns apart: apply converges configuration, `update` converges versions.

Scripts run in separate processes that inherit chezmoi's environment, which on a fresh machine predates Homebrew. Any `after_` script needing brew bootstraps the PATH itself with `eval "$(/opt/homebrew/bin/brew shellenv)"`. The defaults script does not — it only uses `/usr/bin/defaults` and `killall`.

`run_onchange_after_4-macos-defaults.sh` ships with every `defaults write` **commented out**. Uncommenting one changes the script's hash, so the setting applies on the next `apply` by itself. Each `killall` must be uncommented with its setting: `cfprefsd` caches preferences and can write the old value back.

## Encryption

The three package lists are age-encrypted: `Brewfile.age`, `Brewfile-work-s.age`, `Brewfile-work-e.age`. They hide hardware-wallet casks, an employer's internal tap and the work package lists in general. The repository stays public — once the contents are unreadable, its visibility is a convenience question rather than a security one.

**The layout did not change, and that is the whole trick.** `chezmoi encrypt` and `chezmoi decrypt` are ordinary filters: they work on any file and do not require it to be a managed target. So the Brewfiles stayed at the repository root, outside `home/`, and merely grew a suffix. No `encrypted_` attribute, no move into the source tree.

**`include` of an encrypted file needs no key.** It reads the ciphertext raw and hashes that, so `run_onchange_after_2` still re-runs exactly when the file changes — on machines that cannot decrypt as well. Verified on all three profiles: the hash in the rendered script equals `shasum -a 256` of the `.age` file.

**Nothing in the source state is encrypted**, which inverts the failure mode you would expect. `apply` and `status` work fine without a key; decryption happens in exactly one place at runtime, inside `after_2`. A keyless machine would therefore run a full apply and finish with zero packages and no error anywhere. Three barriers exist because of that, in the order they fire:

1. `fail` in `.chezmoi.toml.tmpl` — at `chezmoi init`, before any script and before Homebrew asks for a password;
2. the gate in `before_0` — a real decryption, so a key left over from an earlier rotation is caught too, not just a missing file;
3. the `cannot decrypt` marker from `after_2` — last resort, making the failure loud instead of silent.

**The `age` binary is not required.** `useBuiltinAge` defaults to `auto`, so chezmoi falls back to its own implementation. That matters: `brew "age"` is only in the personal Brewfile, and on a fresh machine it would be installed by the very `brew bundle` that needs decrypting first. **Do not set `age.command`** — it turns the built-in off and reintroduces the cycle.

`recipient` sits in `.chezmoi.toml.tmpl` in the clear, which is what a public key is for. The private half lives at `~/.config/chezmoi/key.txt`, mode 0600, placed by hand on every machine and backed up in 1Password.

**Instructions that run before the bootstrap may only use stock macOS tools.** The key has to be in place before `chezmoi init`, which is before dotfiles are written and before a single package is installed — so `$EDITOR` is unset (it is set by `config.fish.tmpl`), and the `nvim` it would name does not exist yet either. The README used `$EDITOR` at that step and failed on a clean VM exactly that way: zsh tried to execute the path, and the `chmod` after it failed because no file had been created. `nano`, `pbpaste`, `touch` and `chmod` are the safe vocabulary. Same class of cycle as `op`: anything installed by `brew bundle` is unavailable to any instruction that precedes it.

### Rotating the key

Rare enough that it is a written procedure rather than a script:

```bash
# with the OLD key still in place, decrypt ALL THREE first
for f in Brewfile Brewfile-work-s Brewfile-work-e; do
    chezmoi decrypt < "$f.age" > "/tmp/$f"
done

chezmoi age-keygen --output="$HOME/.config/chezmoi/key.txt"   # overwrites
chmod 600 ~/.config/chezmoi/key.txt
# put the new public key in the recipient field of home/.chezmoi.toml.tmpl
chezmoi init                                                   # regenerate the config

for f in Brewfile Brewfile-work-s Brewfile-work-e; do
    chezmoi encrypt < "/tmp/$f" > "$f.age" && rm "/tmp/$f"
done
```

Decrypting all three **before** generating the new key is the load-bearing step: afterwards the old ciphertext is unreadable unless the old key was kept somewhere. Then distribute the new key to every machine — one still holding the old key stops at `before_0` with a readable message rather than installing nothing.

Note the plaintext in `/tmp` in the middle of that. It is the one moment plaintext exists on disk; nothing else in the design puts it there, including `brew-dump`.

## Architecture

### The keybinding stack (spans three files)

The modifier layout is a deliberate hierarchy — changing one layer breaks the others:

1. **AeroSpace owns `alt-*`** (`dot_config/aerospace/aerospace.toml`): window focus `alt-hjkl`, workspaces, and app launchers (`alt-t` → kitty, `alt-f` → Firefox, …).
2. **Zellij therefore avoids Alt** (`dot_config/zellij/config.kdl`): `keybinds clear-defaults=true`, `default_mode "locked"`, and `Ctrl g` acts as a tmux-style leader. Bindings Zellij normally puts on Alt were remapped (`Ctrl g` → `f` for floating panes, `[`/`]` for swap layouts).
3. **`Ctrl hjkl` is a shared nav channel** bound in `shared_among "normal" "locked"` to the `vim-zellij-navigator` wasm plugin, which forwards into nvim. In nvim, `dot_config/nvim/lua/plugins/smart-splits.lua` (`multiplexer_integration = "zellij"`) overrides LazyVim's `<C-w>hjkl` and, at a window edge, calls `zellij action move-focus` to cross back out. Both halves must stay in sync.

### Terminal / multiplexer reality

- **kitty is the terminal actually launched** (`alt-t` in aerospace.toml). WezTerm is configured (`dot_config/wezterm/wezterm.lua`, uses `ALT|SHIFT` for splits) but is not the one AeroSpace opens.
- **Zellij is the active multiplexer**; tmux (`dot_config/tmux/tmux.conf` + plugins) is still fully configured and kept in parity — e.g. both bind a lazygit floating/popup pane (`Ctrl g`+`g` in zellij, `prefix g` in tmux).
- Zellij sets `env { TERM "xterm-256color" }` for child panes deliberately: the inherited `xterm-kitty` is absent from terminfo on most servers, breaking backspace/arrows over ssh.
- **AeroSpace is the live WM**; yabai + skhd configs are retained as an alternative and are not in use.

### tmux plugins are externals, not a plugin manager

`.chezmoiexternal.toml` declares `tpm`, `tmux-sensible`, `tmux-yank` and `catppuccin/tmux` as `type = "git-repo"`: chezmoi clones them when missing and pulls when present. There is no install script and no dependency on tmux existing at apply time.

`catppuccin/tmux` is **pinned** to `v2.1.3` via `clone.args = ["--branch", "v2.1.3", "--depth", "1"]` because `tmux.conf` is written against the v2 option API. The narrowed refspec makes `git pull` a no-op there.

Two traps around that clone:

- `tmux.conf` must **not** list `catppuccin/tmux` as a `@plugin`. It is loaded by the explicit `run` line near the bottom; listing it as well loads the theme twice.
- To check the pin, use `git tag --points-at HEAD | grep -qx v2.1.3`. **`git describe --tags` returns the wrong answer** — several tags sit on that commit and describe picks one of the others.

An old plugin-manager clone at `~/.config/tmux/plugins/catppuccin/tmux` breaks the first apply: its `git pull` fails with `would clobber existing tag`. Remove the directory before applying on a machine that still has one. `.chezmoiremove` cleans up three other dead plugin directories — note that it runs on **every** apply, not once, so those entries should be dropped after all machines have applied.

### Theming

Catppuccin Mocha is applied everywhere, but through four different mechanisms — a theme change means touching all of them:

- bat themes come from an `archive` external with `exact = true` (chezmoi owns `~/.config/bat/themes` outright and will delete anything dropped in by hand); the kitty theme is a single `file` external. Both refresh every 168h and are not stored in git
- fish/fzf palettes are **hardcoded hex** in `config.fish.tmpl`
- starship carries **all four flavours** as `[palettes.*]` tables in `starship.toml`, selected by `palette =`
- tmux/nvim/zed pull it from plugins

### Git identity

`dot_gitconfig.tmpl` ends with an `includeIf "gitdir:~/.local/share/chezmoi/"` pointing at `dot_config/git/dotfiles.inc`, which sets a GitHub noreply address. Commits made inside the dotfiles repo are attributed to that address on every machine, whatever `user.email` the profile answered with.

**The include must stay last in the file.** Git applies an include where it appears, so the `[user]` section at the top would win over it.

### Fish functions (`dot_config/private_fish/functions/`)

Git worktrees — `wtn` (new worktree+branch from fresh `origin/main`), `wtp` (fzf-pick an open PR via `gh` and check its branch out), `wts` (fzf switch), `wtr` (fzf remove + delete branch), `wtl` (list, marks current). All place worktrees under `<main-repo>/worktrees/<branch-with-slashes-dashed>`, resolved via `git rev-parse --git-common-dir` so they work from inside another worktree.

`wts` and `wtr` share the `__wt_rows` helper, which emits `dir<TAB>branch<TAB>path` per worktree, excludes the main working tree, and returns 1 when there are none. Change its field order and both callers break — they index `$fields[2]` and `$fields[3]` directly.

`_wt_open_tab` (zellij tab with claude on the left, shell on the right) is **work in progress and intentionally uncalled** — do not delete it as dead code.

`brew-dump` refreshes the encrypted Brewfile that belongs to this machine's profile — see the `brew bundle dump` warning above for the traps it exists to close. It decrypts into memory, never to disk, and writes through a temp file: `chezmoi encrypt <dump >target` would truncate the target before encrypt even runs, leaving a tracked empty `.age` if encryption failed. It writes **only on a real difference**, which is load-bearing rather than an optimisation — age emits fresh ciphertext on every call, so an unconditional write would churn the hash in `run_onchange_after_2` and reinstall every package on the next apply.

Other: `update` (brew+fisher+softwareupdate), `git-cleanup`, `encrypt-files`/`decrypt-files` (tar + openssl AES-256, pbkdf2 600k), `fw` (AeroSpace window picker via `sk`), `y` (yazi with cwd tracking), `zns` (zellij session named after the dir), `hle-*` (hledger), `ll`/`lla`/`llt`/`llat` (eza).

Fish plugins are declared in `fish_plugins` (fisher-managed, installed by the bootstrap script); `config.fish.tmpl` activates mise, zoxide, starship, and 1Password completions. Only the 1Password line is guarded with `command -q` — fish does not abort `config.fish` on an unknown command, and the other tools are always present once packages are installed.

## Known Issues

- **The `JAVA_HOME` pin no longer means what it says.** `config.fish.tmpl:17` asks for `java_home -v21`. All three Brewfiles install `cask "temurin"` (currently 26), and two of them add a pinned JDK alongside it: `Brewfile-work-s` has `temurin@17`, `Brewfile-work-e` has `temurin@21`. Since `-v<N>` matches "N **or later**", the call resolves to the newest installed JDK — temurin-26 — on every machine, including the two where an older JDK was installed for a reason. Note that even `work-e`, which does install a real JDK 21, does not get it. Decide whether the pin should name a version that is actually selected, or be dropped.

## Conventions

- Commit messages are `<tool>: <lowercase description>` (`starship: add git worktree indication`, `fish: git worktree functions`). No `Co-Authored-By`, no mention of Claude.
- Non-obvious config decisions get an inline comment explaining *why* (see the `TERM` block in `config.kdl` or the nav comments in `smart-splits.lua`).
- **Comments are English only.** One exception that is not a comment: `kitty.conf` binds two `map cmd+<key>` lines whose key names are Cyrillic letters. That is Russian-layout support for copy and paste — the characters are load-bearing, and a blanket de-Cyrillicisation of the repo would break them.
- `dot_config/nvim/` is a LazyVim starter — `lazyvim.json` lists enabled extras, `lazy-lock.json` pins plugins. Add plugins as files under `lua/plugins/`; `example.lua` is the upstream reference and is disabled.
- `dot_config/zellij/config.kdl` was autogenerated by zellij and then hand-edited. Regenerating it wholesale discards the custom keybinds.
- Repo metadata — docs, `brew bundle` inputs, this file — belongs at the repository root, outside `home/`, where chezmoi cannot see it. `docs/` is also in `.gitignore`: working notes are not published.
