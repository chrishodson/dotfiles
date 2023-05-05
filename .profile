# .profile - Bourne Shell startup script for login shells
#

PATH=$HOME/bin
PATH=${PATH}:/sbin:/bin:/usr/sbin:/usr/bin
PATH=${PATH}:/usr/local/bin:/usr/local/sbin
PATH=${PATH}:/usr/X11R6/bin:/opt/puppetlabs/bin
PATH=${PATH}:/home/nerf/.local/bin
export PATH

# Get the aliases and functions
for sourcefile in .bashrc .profile-git .profile-ssh
do
	echo $sourcefile
	if [ -f ~/${sourcefile} ]; then
		. ~/${sourcefile}
	fi
done

BLOCKSIZE=K;	export BLOCKSIZE
EDITOR=vim;   	export EDITOR
PAGER=more;  	export PAGER

export GDFONTPATH=/usr/share/fonts/liberation
export GNUPLOT_DEFAULT_GDFONT=LiberationSans-Regular

# set ENV to a file invoked each time sh is started for interactive use.
export ENV=$HOME/.shrc

if [ -f ~/.profile-prompt ]; then
	echo .profile-prompt
	. .profile-prompt
else
	export PS1="\[\e]2;\u@\H \w\a\e[32;1m\]\#\$ \[\e[0m\]"
fi

# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls:ls -l'
export HISTCONTROL=ignoreboth:erasedups
readonly HISTCONTROL
readonly HISTFILE
export BC_ENV_ARGS=~/.extensions.bc
# wget http://x-bc.sourceforge.net/extensions.bc

export no_proxy=127.0.0.1,localhost
unset proxy
#proxy=http://192.168.1.10:7128/
#proxy=http://localhost:7128/
for setting in http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
do
	eval ${setting}="$proxy"
	export ${setting}
done

function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

export TZ=EST5EDT
umask 027
set -o vi
export AWS_DEFAULT_PROFILE=amazon
