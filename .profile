# .profile - Bourne Shell startup script for login shells
#

export PATH=$HOME/bin:/sbin:/bin:/usr/sbin:/usr/bin::/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

BLOCKSIZE=K;	export BLOCKSIZE
EDITOR=vim;   	export EDITOR
PAGER=more;  	export PAGER

export GDFONTPATH=/usr/share/fonts/liberation
export GNUPLOT_DEFAULT_GDFONT=LiberationSans-Regular

# set ENV to a file invoked each time sh is started for interactive use.
export ENV=$HOME/.shrc

export PS1="\[\e]2;\u@\H \w\a\e[32;1m\]\#\$ \[\e[0m\]"

# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls:ls -l'
export HISTCONTROL=ignoreboth:erasedups
readonly HISTCONTROL
readonly HISTFILE
export BC_ENV_ARGS=~/.extensions.bc
# wget http://x-bc.sourceforge.net/extensions.bc

unset proxy
#proxy=http://192.168.1.10:7128/
#proxy=http://localhost:7128/
for setting in http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
do
	eval ${setting}="$proxy"
	export ${setting}
done

export SSH_ENV="$HOME/.ssh/environment-${HOSTNAME}"

function start_agent {
     echo -n "Initialising new SSH agent... "
     /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}" &&
       echo -n succeeded
     echo ""
     chmod 600 "${SSH_ENV}"
     . "${SSH_ENV}" > /dev/null
     /usr/bin/ssh-add;
}

if [ -f "${SSH_ENV}" ]; then
     . "${SSH_ENV}" > /dev/null
     #ps ${SSH_AGENT_PID} doesn't work under cywgin
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
         start_agent;
     }
else
     umask 077
     mkdir -p $(dirname ${SSH_ENV})
     chmod 700 $(dirname ${SSH_ENV}) # Just in case
     start_agent;
fi

which git  > /dev/null 2>&1 && \
       	git config --global credential.helper 'cache --timeout=86400'

export TZ=EST5EDT
umask 027
set -o vi
