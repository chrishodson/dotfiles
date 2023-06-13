# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

alias rot13='/usr/bin/tr A-Za-z N-ZA-Mn-za-m'
alias irssi='screen -Rd -S irssi /usr/bin/irssi'
alias dedup="awk '!x[$1]++'"

#which docker    > /dev/null 2>&1 && \
#	alias aws='docker run --rm -it -v ~/.aws:/root/.aws -v $(pwd):/aws -e AWS_DEFAULT_PROFILE amazon/aws-cli'
alias getbh='AWS_DEFAULT_PROFILE=amazon aws --no-cli-pager ec2 describe-instances --filters "Name=tag:Name,Values=BastionHost" | jq -r ".Reservations[].Instances[].PublicDnsName"'

unalias rm 2> /dev/null
unalias cp 2> /dev/null

which vim       > /dev/null 2>&1 && alias vi=vim
which colordiff > /dev/null 2>&1 && alias diff=colordiff
which more      > /dev/null 2>&1 || alias more=less

BLOCKSIZE=K;    export BLOCKSIZE
EDITOR=vim;     export EDITOR
PAGER=more;     export PAGER

export GDFONTPATH=/usr/share/fonts/liberation
export GNUPLOT_DEFAULT_GDFONT=LiberationSans-Regular

# set ENV to a file invoked each time sh is started for interactive use.
export ENV=$HOME/.shrc

# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls:ls -l'
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoreboth
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}erasedups

export no_proxy=127.0.0.1,localhost

export TZ=EST5EDT
export AWS_DEFAULT_PROFILE=default
