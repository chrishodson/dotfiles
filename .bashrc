# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias vi=vim
alias rot13='/usr/bin/tr A-Za-z N-ZA-Mn-za-m'
alias irssi='screen -Rd -S irssi /usr/bin/irssi'
alias gitcleanup='git branch --merged | grep -v "\*" | grep -v " master" | xargs -n 1 git branch -d'
alias aws='docker run --rm -it -v ~/.aws:/root/.aws -v $(pwd):/aws -e AWS_DEFAULT_PROFILE amazon/aws-cli'
which more > /dev/null 2>&1 || \
	alias more=less
