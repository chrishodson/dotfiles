if [ -n "$ZSH_VERSION" ]; then
    # Source .profile to ensure all environment variables and settings are loaded
    if [ -f ~/.profile ]; then
        . ~/.profile
    fi
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="robbyrussell"
    DISABLE_MAGIC_FUNCTIONS=true
    plugins=(git)

    source $ZSH/oh-my-zsh.sh
fi
