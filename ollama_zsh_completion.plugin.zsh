# ZSH Plugin standard
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"
fpath+=( "${0:h}" )

# If the completion system is already running (the usual case with a plugin
# manager), just register this completion instead of paying for a full
# compinit rescan. Otherwise, initialise it.
if (( $+functions[compdef] )); then
  autoload -Uz _ollama && compdef _ollama ollama
else
  autoload -Uz compinit && compinit
fi
