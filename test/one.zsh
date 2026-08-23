#!/usr/bin/env zsh
# Complete a single command line in a pty and dump what is offered.
# usage: zsh test_one.zsh <dir-containing-_ollama> '<command line to complete>'

emulate -L zsh
setopt err_return

local compdir=${1:?need fpath dir}
local line=${2:?need a command line}
local tmp=${TMPDIR:-/tmp}/ozc-one
rm -rf $tmp; mkdir -p $tmp

cat > $tmp/.zshrc <<ZRC
fpath=($compdir \$fpath)
autoload -Uz compinit
compinit -u -d $tmp/.zcompdump
zstyle ':completion:*' menu no
LISTMAX=1000
setopt nobeep
unsetopt correct correctall
PS1='<<READY>>'
ZRC

zmodload zsh/zpty
zpty -d 2>/dev/null
zpty comp "ZDOTDIR=$tmp HOME=$HOME TERM=xterm-256color zsh -i"
sleep 2
local chunk
while zpty -r -t comp chunk 2>/dev/null; do :; done

zpty -w -n comp "$line"
sleep 0.5
zpty -w -n comp $'\t'
sleep 4

local out=''
while zpty -r -t comp chunk 2>/dev/null; do out+=$chunk; sleep 0.05; done
print -r -- $out | tr -d '\r' | sed -E $'s/\x1b\\[[0-9;?]*[a-zA-Z]//g' | grep -v '^[[:space:]]*$'
zpty -d comp
