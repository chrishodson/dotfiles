# dotfiles

## Installation

```bash
#!/bin/bash
git clone --bare git@github.com:chrishodson/dotfiles.git $HOME/.cfg
config() {
    /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME "$@"
}

if config checkout; then
    echo "Checked out config."
else
    echo "Backing up pre-existing dot files."
    mkdir -p .config-backup
    config checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' | xargs -I{} mv $HOME/{} .config-backup/
    config checkout
fi

config config status.showUntrackedFiles no
```
