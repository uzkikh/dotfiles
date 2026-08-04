#!/bin/bash
# Makes fish the login shell -- the last manual step from the README.
#
# Runs last on purpose. It needs fish to exist, so it has to come after the
# package script, and both `sudo tee /etc/shells` and `chsh` may ask for a
# password, which is a poor thing to hit in the middle of an install.

set -uo pipefail

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Redirection order matters: 2>/dev/null must come first, otherwise bash prints
# "/dev/tty: Device not configured" to the not-yet-redirected stderr.
if : 2>/dev/null < /dev/tty; then
    tty=/dev/tty
else
    tty=/dev/stderr
fi

fish_path="$(command -v fish || true)"
if [ -z "$fish_path" ]; then
    echo "  fish not installed, leaving the login shell alone." > "$tty"
    # Non-zero for the same reason as the no-terminal branch below: this is a
    # skipped prerequisite, not a completed job. Exiting 0 would record the
    # script as done and the login shell would stay zsh forever, however many
    # applies followed.
    exit 1
fi

# $SHELL is the shell that launched this script, not the configured login
# shell -- inside a chezmoi script it reads /bin/zsh even when fish is set.
# Directory Services holds the real answer.
current="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$current" = "$fish_path" ]; then
    exit 0
fi

if [ "$tty" != /dev/tty ]; then
    cat > "$tty" <<MANUAL
  Login shell is $current, not fish. Both steps below need a password, so they
  cannot run unattended. Either rerun \`chezmoi apply\` from a terminal, or:
    echo "$fish_path" | sudo tee -a /etc/shells
    chsh -s "$fish_path"
MANUAL
    # Non-zero keeps chezmoi from recording this script as done, so an
    # interactive apply later gets another go. Nothing runs after it.
    exit 1
fi

# chsh refuses a shell that is not listed here.
if ! grep -qxF "$fish_path" /etc/shells; then
    echo "  Adding $fish_path to /etc/shells (needs your password)." > "$tty"
    if ! echo "$fish_path" | sudo tee -a /etc/shells > /dev/null; then
        echo "  Could not write /etc/shells, leaving the login shell alone." > "$tty"
        exit 1
    fi
fi

echo "  Setting fish as the login shell (needs your password)." > "$tty"
if ! chsh -s "$fish_path"; then
    echo "  chsh failed, run it by hand: chsh -s $fish_path" > "$tty"
    exit 1
fi

echo "  Login shell set to $fish_path. It applies to new terminals." > "$tty"
