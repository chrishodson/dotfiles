# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

which vim       > /dev/null 2>&1 && alias vi=vim
which colordiff > /dev/null 2>&1 && alias diff=colordiff
alias rot13='/usr/bin/tr A-Za-z N-ZA-Mn-za-m'
alias irssi='screen -Rd -S irssi /usr/bin/irssi'
alias dedup="awk '!x[$1]++'"
#which docker    > /dev/null 2>&1 && \
#	alias aws='docker run --rm -it -v ~/.aws:/root/.aws -v $(pwd):/aws -e AWS_DEFAULT_PROFILE amazon/aws-cli'
alias getbh='AWS_DEFAULT_PROFILE=amazon aws --no-cli-pager ec2 describe-instances --filters "Name=tag:Name,Values=BastionHost" | jq -r ".Reservations[].Instances[].PublicDnsName"'
unalias rm 2> /dev/null
unalias cp 2> /dev/null
which more > /dev/null 2>&1 || \
	alias more=less
