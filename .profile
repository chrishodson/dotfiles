# .profile - Bourne Shell startup script for login shells
#

PATH=$HOME/bin
PATH=${PATH}:/sbin:/bin:/usr/sbin:/usr/bin
PATH=${PATH}:/usr/local/bin:/usr/local/sbin
PATH=${PATH}:/usr/X11R6/bin:/opt/puppetlabs/bin
PATH=${PATH}:/home/nerf/.local/bin
export PATH

# Get the aliases and functions
for sourcefile in .bashrc .profile-git
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

mkdir -p "$HOME/.ssh/environment/"
export SSH_ENV="$HOME/.ssh/environment/env-${HOSTNAME}"

magic() { # returns unexpanded tilde express on invalid user
    local _safe_path; printf -v _safe_path "%q" "$1"
    eval "ln -sf ${_safe_path#\\} /tmp/realpath.$$"
    readlink /tmp/realpath.$$
    rm -f /tmp/realpath.$$
}

function start_agent {
     echo -n "Initialising new SSH agent... "
     /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}" &&
       echo -n succeeded
     echo ""
     chmod 600 "${SSH_ENV}"
     . "${SSH_ENV}" > /dev/null
     for id_file in $(awk '/^[     ]*IdentityFile/ {print $2}' ~/.ssh/config | sort -u)
     do
	 /usr/bin/ssh-add $(magic $id_file)
     done
     echo "Done adding keys" ;
}

if [ -z "${SSH_AUTH_SOCK}" ]; then
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
else
     echo "SSH agent running via previous host"
fi

function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

export TZ=EST5EDT
umask 027
set -o vi
export AWS_DEFAULT_PROFILE=amazon
