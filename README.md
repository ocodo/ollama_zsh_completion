# Ollama zsh completion plugin

Completion for the whole `ollama` CLI, tracking the 0.32.x command set.
Based on [Obeone's Gist](https://gist.github.com/obeone/9313811fd61a7cbb843e0001a4434c58).

## Installation

### With Antidote

Add to `~/.zsh_plugins.txt`:

```text
ocodo/ollama_zsh_completion
```

Then `source ~/.zshrc` or start a new shell. Update with `antidote update`.

### With Oh My Zsh

```sh
git clone https://github.com/ocodo/ollama_zsh_completion.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ollama
```

Add `ollama` to your `plugins=(...)` list, then `omz reload`.

### Manually

Drop `_ollama` anywhere in your `$fpath` and run `compinit`.

## What it completes

| Context | Completion |
| --- | --- |
| `ollama <TAB>` | every command, with descriptions |
| `ollama <cmd> -<TAB>` | the exact flags of that command, short and long forms grouped |
| `ollama show\|push\|cp\|rm <TAB>` | local models, annotated with size and age |
| `ollama rm a <TAB>` | remaining local models — already typed ones are dropped |
| `ollama stop <TAB>` | running models (`ollama ps`), with size, processor and TTL |
| `ollama pull <TAB>` | models from ollama.com/library |
| `ollama pull qwen3:<TAB>` | the tags published for that model |
| `ollama run <TAB>` | local models *and* library models (run pulls what is missing) |
| `ollama run llama3.2 <TAB>` | file paths, for multimodal prompts |
| `ollama create -f <TAB>` | Modelfiles first, then directories and files |
| `ollama create -q <TAB>` | quantization levels, described |
| `ollama run --think=<TAB>` | `true` `false` `high` `medium` `low` |
| `ollama run --keepalive <TAB>` | usual durations, plus `0` and `-1` |
| `ollama launch <TAB>` | the 18 supported integrations, aliases included |
| `ollama help <TAB>` | command list |

Examples:

```text
$ ollama show <TAB>
llama3.2:latest          -- 2.0 GB, 2 weeks ago
nomic-embed-text:latest  -- 274 MB, 5 months ago
qwen3:8b                 -- 5.2 GB, 3 days ago

$ ollama pull qwen3:<TAB>
qwen3:0.6b        qwen3:14b-q4_K_M    qwen3:30b-a3b
qwen3:0.6b-fp16   qwen3:14b-q8_0      qwen3:30b-a3b-q4_K_M
...

$ ollama launch <TAB>
chatgpt         -- ChatGPT (codex-app, codex-desktop, codex-gui)
claude          -- Claude Code
cline           -- Cline
...
```

## Network use and caching

Library models and tags are fetched from `ollama.com` with `curl` (falling back
to `wget`, then `python3`). Responses are cached under
`${XDG_CACHE_HOME:-~/.cache}/ollama-zsh-completion/`.

The cache is served immediately and refreshed in the background once it goes
stale, so only the very first completion of a given list ever waits on the
network.

Flush it with:

```sh
_ollama_cache_flush
```

## Configuration

```zsh
# Cache lifetime in seconds (default 21600 — 6 hours)
zstyle ':completion:*:ollama:*' cache-ttl 3600

# Never touch the network: `pull` and `run` then complete local models only
zstyle ':completion:*:ollama:*' remote-models no

# Show local models before ollama.com models on `ollama run`
zstyle ':completion:*:*:ollama:*' group-name ''
zstyle ':completion:*:*:ollama:*' tag-order local-models library-models
```

Local and running models come from `ollama list` / `ollama ps`, so they follow
`OLLAMA_HOST` like the rest of the CLI. The table parser locates columns from
the header row, so an added or reordered column in a future release will not
break it.

## License

MIT
