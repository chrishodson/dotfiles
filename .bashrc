# Only continue if running bash
if [ $BASH ]; then
    # Source global definitions
    if [ -f /etc/bashrc ]; then
        . /etc/bashrc
    fi

    # Bash specific items go here
fi
