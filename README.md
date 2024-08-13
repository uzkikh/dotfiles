# Dotfiles

My dotfiles repository, managed by [chezmoi](https://github.com/twpayne/chezmoi)

## Setup a new mac

### Install xcode command line tools

```sh
xcode-select --install
```

### Clone the dotfiles repository and run the bootstrap scripts

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply uzkikh
```

### Install brew apps

```sh
brew bundle --no-lock --file /Users/ivan/.local/share/chezmoi/Brewfile
```

### Setup fish shell

```sh
echo "$(which fish)" | sudo tee -a /etc/shells
chsh -s "$(which fish)"
fish
eval "$(/opt/homebrew/bin/brew shellenv fish)"
```
