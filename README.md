# dotfiles

## Installation

```bash
#!/bin/bash
git clone --bare git@github.com:chrishodson/dotfiles.git $HOME/.cfg
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "^M*\s+" | sed -e 's/\(^M*\s*\)\(.*\)/\2/' | xargs -I{} mv $HOME/{} .config-backup/
fi;
config checkout
config config status.showUntrackedFiles no
```
