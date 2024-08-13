#!/bin/bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [[ $(arch) == "arm64" ]]; then
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >>$HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    (echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >>$HOME/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
fi
