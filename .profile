# .profile - Shell startup script for login shells
#

umask 027

# Get the aliases and functions
for sourcefile in \
    .profile-functions .bashrc \
    .profile-git .profile-prompt \
    .profile-ssh \
    .profile-aliases \
    .profile-cygwin
do
	echo $sourcefile
	if [ -f ~/${sourcefile} ]; then
		. ~/${sourcefile}
	fi
done

prependPath $HOME/bin
appendPath /usr/local/bin /usr/local/sbin
appendPath /usr/X11R6/bin /opt/puppetlabs/bin
appendPath ~/.local/bin

proxy # http://localhost:7128/

export BC_ENV_ARGS=~/.extensions.bc
[[ ! -f $BC_ENV_ARGS ]] && \
    curl -o $BC_ENV_ARGS https://x-bc.sourceforge.net/extensions.bc

cleansePath
export PATH

# Try to unse them in a subshell.  If it works, make them read-only
(unset HISTCONTROL 2>/dev/null) && readonly HISTCONTROL
(unset HISTFILE    2>/dev/null) && readonly HISTFILE

set -o vi
export TZ=EST5EDT
export AWS_DEFAULT_PROFILE=default
