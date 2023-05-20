#!/bin/sh 

# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install brew apps
brew bundle install --file /Users/ivan/.local/share/chezmoi/Brewfile

# Install and setup fish shell
echo /usr/local/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/local/bin/fish