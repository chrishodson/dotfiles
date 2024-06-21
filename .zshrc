if [ -n "$ZSH_VERSION" ]; then
    # Source .profile to ensure all environment variables and settings are loaded
    if [ -f ~/.profile ]; then
        . ~/.profile
    fi
fi
