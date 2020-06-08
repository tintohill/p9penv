#!/bin/bash
# wayland
# export QT_QPA_PLATFORM=wayland-egl
# export MOZ_ENABLE_WAYLAND=1
# export SDL_VIDEODRIVER=wayland
export VDPAU_DRIVER=radeonsi

# QT auto scale
# export QT_AUTO_SCREEN_SCALE_FACTOR=true

# set plan9 environment
export PLAN9=~/.plan9
# mk max concurrent procs
# only valid for linux
export nproc=$(cat /proc/cpuinfo | grep processor | wc -l)

# set golang environment
export GOVERSION=$($PLAN9/bin/ls -p ~/.go | tail -n 1)
export GOROOT=~/.go/$GOVERSION
export GOPATH=$HOME/go
export GO111MODULE=on
export CGO_LDFLAGS_ALLOW='-Wl,-unresolved_symbols=ignore-all'

# set java environmant
export JAVA_VERSION=11.0.7
export JAVA_HOME=~/.java/jdk/$JAVA_VERSION

# set scala environment
export SBT_VERSION=1.3.10
export SBT_HOME=~/.java/sbt/$SBT_VERSION

# set acme environment
export ACME=$HOME/.acme
export usebigarrow=1
export EDITOR=editinacme
export PAGER=nobs
export BROWSER=firefox
unset FCEDIT VISUAL

# set cursor to a steady bar |
# printf '\033[6 q'
# set cursor to a steady block
echo -e -n "\x1b[\x30 q"
export GNUTERM="sixelgd size 1280,720 truecolor font 'DEC Terminal Modern' 14"

# set aliases
alias tb="nc termbin.com 9999"

# set Maven Home
export MVN_VERSION=3.6.3
export MVN_HOME=~/.java/mvn/$MVN_VERSION/

# check if something is not there
dirs=("$HOME/lib" "$PLAN9" "$GOROOT" "$GOPATH" "$ACME")
for d in $dirs; do
	if [ ! -d ${d} ]; then
		echo "$d does not exists. Verify set up"
	fi
done

files=("$HOME/lib/plumbing")
for f in $files; do
	if [ ! -f ${f} ]; then
		echo "$f does not exists. Verify set up"
	fi
done

pathappend() {
  for ARG in "$@"
  do
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="${PATH:+"$PATH:"}$ARG"
    fi
  done
}

pathappend "$HOME/bin" "$GOPATH/bin" "$PLAN9/bin" "$JAVA_HOME/bin" "$SBT_HOME/bin" "$MVN_HOME/bin" "$HOME/.sld/bin"  "/usr/sbin" "/sbin" "$HOME/.acme/bin"

# prepend ~/bin and goroot into path to avoid using gcc-go in system path by default
export PATH="~/bin:$HOME/.local/bin:$GOROOT/bin":$PATH

# ssh agent set up

SSH_ENV="$HOME/.ssh/environment"

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

# set cd to execute awd when in acme win
cda () {
        builtin cd "$@" &&
        case "$TERM!$-" in
        linux!*)
                ;;
        *!*i*)
                awd
        esac
}
alias cd=cda
complete -f nospace _cd cda

_set_font() {
	family="$1"
	shift
	size="$1"
	shift
	hidpi="$1"
	shift

	if [[ $size =~ ^[0-9]+$ ]]; then
		acme_font_size=$size
	fi

	if [[ $hidpi =~ ^[0-9]+$ ]]; then
		acme_font_size_hidpi=$hidpi
	fi

	if [ -z "$family" ]; then
		family="plan9"
	fi

	case $family in
	dejavu)
		mono="DejaVuSansMono"
		sans="DejaVuSans"
		;;
	go)
		mono="Go Mono"
		sans="Go Regular"
		;;
	cmu)
		mono="CMU Typewriter Text Variable Width"
		sans="CMU Concrete Roman"
		;;
	ibm)
		mono="IBMPlexMono"
		sans="IBMPlexSans"
		;;
	fira)
		mono="FiraMono"
		sans="FiraSans"
		;;
	terminus)
		mono="TerminusTTF"
		sans="TerminusTTF"
		;;
	book)
		mono="GoMono"
		sans="Bitter-Regular"
		;;
	input-condensed)
		mono="InputMonoCondensed-Medium"
		sans="InputSansCondensed-Medium"
		;;
	input)
		mono="InputMono"
		sans="InputSans"
		;;
	noto)
		mono="NotoSansMono"
		sans="NotoSans"
		;;
	adobe)
		mono="SourceCodePro-Medium"
		sans="SourceSansPro-Regular"
		;;
	plan9)
		export fixedfont="/usr/local/plan9/font/pelm/unicode.9.font"
		export font="/lib/font/bit/lucsans/euro.8.font"
		return
		;;
	esac

	export fixedfont="/mnt/font/${mono}/${acme_font_size}a/font"
	export font="/mnt/font/${sans}/${acme_font_size}a/font"
	export hidpifixedfont="/mnt/font/${mono}/${acme_font_size_hidpi}a/font"
	export hidpifont="/mnt/font/${sans}/${acme_font_size_hidpi}a/font"
}

_acme() {
	SHELL=bash  $PLAN9/bin/acme -a -c 1 -f "$font,$hidpifont" -F "$fixedfont,$hidpifixedfont" "$@"
}

complete -f nospace _cd acme

# start new p9p session
new_p9p_session() {
	for proc in fontsrv secstored factotum plumber; do
		pgrep $proc 2>&1 > /dev/null
		if [ $? -ne 0 ]; then
			$PLAN9/bin/9 $proc &
		fi
	done
}

#if [ ! -z "$DISPLAY" ]; then
#	new_p9p_session
#fi

export NAMESPACE=/tmp/ns.gdiazlo.sway
mkdir -p $NAMESPACE
new_p9p_session

# default font
_set_font adobe 14 22

# source
source ~/.acme/bin/git-prompt.sh
export PS1='$(__git_ps1 "(%s)")\$ '

# opam configuration
test -r $HOME/.opam/opam-init/init.sh && . $HOME/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true

_set_color() {
        declare -A colors
        colors[black]="#313131"
        colors[gray]="#777777"
        colors[purple]="#bfb1d5"
        colors[green]="#adddcf"
        colors[blue]="#abe1fd"
        colors[orange]="#fed1be"
        colors[yellow]="#f0e0a2"
        colors[lightgray]="#e8e7e5"
        colors[white]="#fafafa"

        echo -ne "\033]11;${colors[$1]}\007"
        echo -ne "\033]10;${colors[$2]}\007"
}
