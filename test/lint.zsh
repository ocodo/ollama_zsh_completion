#!/usr/bin/env zsh
# Static checks on the completion file. Exits non-zero on the first failure,
# so it can be dropped straight into CI.
#
# usage: zsh test_lint.zsh [path-to-_ollama]   (default: ../_ollama)

emulate -L zsh

local script_dir=${0:A:h}
local file=${1:-$script_dir/../_ollama}
local -i failed=0

pass() { print -r -- "  ok    $1" }
fail() { print -r -- "  FAIL  $1"; (( failed++ )) }

print -r -- "checking $file"

# 1. The file has to exist and be named _ollama, or compinit never looks at it.
if [[ -r $file ]]; then
  pass "file is readable"
else
  fail "file is missing or unreadable"
  exit 1
fi

[[ ${file:t} == _ollama ]] && pass "named _ollama" || fail "must be named _ollama"

# 2. The #compdef line must be the very first line. A single leading blank line
#    silently disables the whole completion: compinit stops looking after it,
#    `ollama <TAB>` falls back to filenames, and nothing warns you.
local first
first=$(head -1 -- $file)
if [[ $first == '#compdef ollama' ]]; then
  pass "first line is '#compdef ollama'"
else
  fail "first line is '${first}', expected '#compdef ollama'"
fi

# 3. It must parse.
if zsh -n -- $file 2>/dev/null; then
  pass "parses (zsh -n)"
else
  fail "syntax error:"
  zsh -n -- $file
fi

# 4. And compinit must actually pick the command up.
local tmp=${TMPDIR:-/tmp}/ozc-lint.$$
mkdir -p $tmp
local found
found=$(zsh -f -c "
  fpath=(${file:A:h} \$fpath)
  autoload -Uz compinit
  compinit -u -d $tmp/dump
  print -r -- \${_comps[ollama]:-NONE}
" 2>/dev/null)
rm -rf $tmp
if [[ $found == _ollama ]]; then
  pass "compinit binds ollama -> _ollama"
else
  fail "compinit did not bind ollama (got '${found}')"
fi

if (( failed )); then
  print -r -- "$failed check(s) failed"
  exit 1
fi
print -r -- "all checks passed"
