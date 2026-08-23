#!/usr/bin/env zsh
# Same pty harness, but with a fake `ollama` binary so local/running model
# completion can be exercised without a server.
# usage: zsh test_ollama_completion_stub.zsh <dir-containing-_ollama>

emulate -L zsh
setopt err_return

local compdir=${1:?need fpath dir}
local tmp=${TMPDIR:-/tmp}/ozc-stub
rm -rf $tmp; mkdir -p $tmp/bin

cat > $tmp/bin/ollama <<'STUB'
#!/bin/sh
case "$1" in
list|ls)
cat <<'EOF'
NAME                       ID              SIZE      MODIFIED
qwen3:8b                   500a1f067a9f    5.2 GB    3 days ago
llama3.2:latest            a80c4f17acd5    2.0 GB    2 weeks ago
nomic-embed-text:latest    0a109f422b47    274 MB    5 months ago
EOF
;;
ps)
cat <<'EOF'
NAME        ID              SIZE      PROCESSOR    CONTEXT    UNTIL
qwen3:8b    500a1f067a9f    6.5 GB    100% GPU     4096       4 minutes from now
EOF
;;
esac
STUB
chmod +x $tmp/bin/ollama

cat > $tmp/.zshrc <<ZRC
path=($tmp/bin \$path)
fpath=($compdir \$fpath)
autoload -Uz compinit
compinit -u -d $tmp/.zcompdump
zstyle ':completion:*' menu no
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
  while zpty -r -t comp chunk 2>/dev/null; do out+=$chunk; sleep 0.05; done
  print -rn -- $out
}
clean() { tr -d '\r' | sed -E $'s/\x1b\\[[0-9;?]*[a-zA-Z]//g; s/\x1b[()][B0]//g; s/\x1b[=>]//g' }

sleep 2
drain >/dev/null

run_case() {
  print -r -- "======== $1"
  zpty -w -n comp "$2"; sleep 0.4
  zpty -w -n comp $'\t'; sleep 2.5
  drain | clean | grep -v '^[[:space:]]*$' | head -20
  zpty -w -n comp $'\025'; sleep 0.4; drain >/dev/null
  print -r -- ''
}

run_case 'ollama show <TAB>'                'ollama show '
run_case 'ollama rm <TAB>'                  'ollama rm '
run_case 'ollama rm qwen3:8b <TAB>'         'ollama rm qwen3:8b '
run_case 'ollama stop <TAB>'                'ollama stop '
run_case 'ollama cp <TAB>'                  'ollama cp '
run_case 'ollama run <TAB>'                 'ollama run '
run_case 'ollama push <TAB>'                'ollama push '
run_case 'ollama launch claude --model <TAB>' 'ollama launch claude --model '

zpty -d comp
