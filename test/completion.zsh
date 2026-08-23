#!/usr/bin/env zsh
# Drive real zsh completion inside a pty and dump what the widget offers.
# usage: zsh test_ollama_completion.zsh <dir-containing-_ollama>

emulate -L zsh
setopt err_return

local compdir=${1:?need fpath dir}
local tmp=${TMPDIR:-/tmp}/ozc-run
rm -rf $tmp; mkdir -p $tmp

cat > $tmp/.zshrc <<ZRC
fpath=($compdir \$fpath)
autoload -Uz compinit
compinit -u -d $tmp/.zcompdump
zstyle ':completion:*' menu no
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' select-prompt ''
LISTMAX=500
setopt nobeep
unsetopt correct correctall
PS1='<<READY>>'
ZRC

zmodload zsh/zpty

zpty -d 2>/dev/null
zpty comp "ZDOTDIR=$tmp HOME=$HOME TERM=xterm-256color zsh -i"

drain() {
  local chunk out=''
  while zpty -r -t comp chunk 2>/dev/null; do
    out+=$chunk
    sleep 0.05
  done
  print -rn -- $out
}

clean() {
  tr -d '\r' | sed -E $'s/\x1b\\[[0-9;?]*[a-zA-Z]//g; s/\x1b[()][B0]//g; s/\x1b[=>]//g'
}

sleep 2
drain >/dev/null

run_case() {
  local desc=$1 line=$2
  print -r -- "======== $desc"
  zpty -w -n comp "$line"
  sleep 0.4
  zpty -w -n comp $'\t'
  sleep 3
  drain | clean | grep -v '^[[:space:]]*$' | head -25
  zpty -w -n comp $'\025'      # kill-whole-line
  sleep 0.4
  drain >/dev/null
  print -r -- ''
}

run_case 'ollama <TAB>'                'ollama '
run_case 'ollama r<TAB>'               'ollama r'
run_case 'ollama show <TAB>'           'ollama show '
run_case 'ollama create -<TAB>'        'ollama create -'
run_case 'ollama run --think=<TAB>'    'ollama run --think='
run_case 'ollama launch <TAB>'         'ollama launch '
run_case 'ollama pull <TAB>'           'ollama pull '
run_case 'ollama pull qwen3:<TAB>'     'ollama pull qwen3:'
run_case 'ollama stop <TAB>'           'ollama stop '
run_case 'ollama create -q <TAB>'      'ollama create -q '
run_case 'ollama run --keepalive <TAB>' 'ollama run --keepalive '
run_case 'ollama help <TAB>'           'ollama help '

zpty -d comp
