# Dotfiles

My dotfiles repository, managed by [chezmoi](https://github.com/twpayne/chezmoi).

macOS only. The managed tree lives under `home/`; everything at the top level is
repo metadata that chezmoi never sees, thanks to `.chezmoiroot`.

## Setup a new mac

### 1. Install the Xcode command line tools

```sh
xcode-select --install
```

### 2. Place the age key

The package lists here are encrypted with [age](https://age-encryption.org).
Without the private key nothing can be installed, and the bootstrap stops rather
than pretending to succeed.

Create the file locked down first — a redirect does not change an existing
file's mode, so the key is never on disk world-readable:

```sh
mkdir -p ~/.config/chezmoi
touch ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

Then write the key into it. With the key on the clipboard:

```sh
pbpaste > ~/.config/chezmoi/key.txt
```

Or type it into an editor — use `nano`, which is on every Mac. **Do not reach
for `$EDITOR` here**: it is set by these dotfiles, which have not been applied
yet, and it names `nvim`, which `brew bundle` installs three steps later.

```sh
nano ~/.config/chezmoi/key.txt        # paste, then ctrl-o, ctrl-x
```

Check it arrived intact — a half-pasted key fails much later and much less
obviously:

```sh
grep -c AGE-SECRET-KEY ~/.config/chezmoi/key.txt      # must print 1
```

The key is in 1Password, or on any Mac already set up from this repository. It
cannot be fetched with `op` on a fresh machine: the 1Password CLI is itself
installed from the encrypted package list, so the key has to arrive by hand
first. On a VM, `pbpaste` only works if clipboard sharing is on — otherwise use
`nano`.

### 3. Install chezmoi and apply

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply uzkikh
```

That single command does the whole bootstrap, in this order:

1. stops immediately if `~/.config/chezmoi/key.txt` is missing, before asking
   anything at all;
2. echoes the profile and email you just answered with the package list they
   select, checks that the list really decrypts, and asks for confirmation —
   before anything is installed or written, and before Homebrew asks for your
   password;
3. installs Homebrew, if it is missing;
4. writes every dotfile, and clones the tmux plugins and colour themes declared
   as externals;
5. installs packages with `brew bundle`;
6. installs the fish plugins with `fisher`;
7. runs the macOS defaults script — which does nothing until you uncomment
   something in it, see below;
8. makes fish the login shell, asking for your password twice: once to add it
   to `/etc/shells`, once for `chsh`.

Answering anything but `y` at step 2 stops the run with nothing installed and
nothing written. It asks again on the next `chezmoi apply`. A missing or stale
key stops it just as firmly, without asking anything.

On the first run it asks two questions:

- **Machine profile** — one of `personal`, `work-s`, `work-e`. It selects which
  package list to install and which machine-specific block lands in
  `config.fish`.
- **Git email address** — used for `user.email` in `~/.gitconfig`.

Both answers are stored in `~/.config/chezmoi/chezmoi.toml`, which lives outside
this repository, and are never asked again. To answer without a prompt:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply uzkikh \
  --promptString "Machine profile (personal/work-s/work-e)=personal" \
  --promptString "Git email address=you@example.com"
```

Commits made **inside this repository** are attributed to a GitHub noreply
address regardless of the email above, through an `includeIf` in `~/.gitconfig`.

That is the whole install. Open a new terminal and fish is the login shell.

## Notes

### If the login shell was not changed

Step 8 needs a password, so it is skipped when the apply is not attached to a
terminal, and prints what to run instead. It is not recorded as done in that
case, so a later `chezmoi apply` from a terminal picks it up. By hand:

```sh
echo "$(which fish)" | sudo tee -a /etc/shells
chsh -s "$(which fish)"
```

The `/etc/shells` line is not optional: `chsh` refuses a shell that is not
listed there.

### If package installation fails

Package installation is deliberately allowed to fail without aborting the rest
of the apply, so that one missing package never blocks the fish plugins. On
failure the script prints one of three markers:

```
!! brew bundle FAILED: brew not on PATH; rerun by hand: ...
!! brew bundle FAILED: cannot decrypt ... -- is ~/.config/chezmoi/key.txt in place?
!! brew bundle FAILED, rerun by hand: ...
```

All three contain `brew bundle FAILED`, so searching the apply output for that
string finds any of them. The first and third print the exact command to repeat;
the second means the key is missing or no longer matches, and no amount of
rerunning helps until that is fixed.

**Open a new terminal before repeating the command.** Homebrew puts itself on
`PATH` through `~/.zprofile` and `/etc/paths.d/homebrew`, both of which are read
when a login shell starts — so the session that ran the install, having started
before Homebrew existed, does not have `brew` at all. In that session use
`eval "$(/opt/homebrew/bin/brew shellenv)"` instead.

Note also that a fetch failure takes everything with it: `brew bundle` fetches
the whole list up front and gives up on the first download that fails, before
installing anything. One flaky download therefore means zero packages, not one
missing package — which usually means the repeat command simply succeeds.

### App Store

The `personal` profile pulls 18 App Store apps through `mas`, which requires
being signed in to the App Store first, and some of those installs ask for a
password. The work profiles contain no `mas` entries, so no account is needed
there.

### macOS defaults

`home/.chezmoiscripts/run_onchange_after_4-macos-defaults.sh` carries a handful
of `defaults write` tweaks, **all commented out**. Uncomment a line and the next
`chezmoi apply` applies it by itself — the script's own hash is what triggers
the rerun. Keep each `killall` together with its setting: without it `cfprefsd`
can write the cached value straight back. Expect Dock, Finder or the menu bar to
blink when they restart.
