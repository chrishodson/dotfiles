# Only continue if running bash
if [ -n "$BASH" ]; then
    # Source global definitions
    if [ -f /etc/bashrc ]; then
        . /etc/bashrc
    fi

    # Bash specific items go here
fi
