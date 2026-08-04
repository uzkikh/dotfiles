#!/bin/bash
# Runs before any file is written, so later after_ scripts can rely on brew.
# Idempotent on purpose: this file's hash is its run_once_ key, and any future
# edit re-runs it on every machine that already has Homebrew.

set -euo pipefail

if [[ $(arch) == "arm64" ]]; then
    brew_prefix="/opt/homebrew"
else
    brew_prefix="/usr/local"
fi

if command -v brew >/dev/null 2>&1 || [[ -x "${brew_prefix}/bin/brew" ]]; then
    echo "Homebrew already installed, skipping."
else
    # install.sh falls back to `sudo -n` and dies when it cannot prompt, so tell
    # it upfront that nobody is watching.
    if [[ ! -t 0 ]]; then
        export NONINTERACTIVE=1
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Append the shellenv line once. Re-running the script must not stack duplicates
# in ~/.zprofile.
if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    printf '\neval "$(%s/bin/brew shellenv)"\n' "$brew_prefix" >>"$HOME/.zprofile"
fi

eval "$("${brew_prefix}/bin/brew" shellenv)"
