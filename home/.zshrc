# Interactive, headless-friendly Zsh configuration.
[[ -o interactive ]] || return

export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-FRX"

bindkey -e

HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "${HISTFILE:h}"
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY HIST_IGNORE_SPACE HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS INC_APPEND_HISTORY SHARE_HISTORY

autoload -Uz compinit
mkdir -p "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

ZCOMET_HOME="$XDG_DATA_HOME/zcomet"
if [[ -r "$ZCOMET_HOME/zcomet.zsh" ]]; then
  source "$ZCOMET_HOME/zcomet.zsh"
  zcomet load zsh-users/zsh-autosuggestions
  zcomet load zsh-users/zsh-syntax-highlighting
  zcomet load Aloxaf/fzf-tab
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

[[ -r "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

if command -v starship >/dev/null 2>&1 && [[ ${TERM:-dumb} != dumb ]]; then
  eval "$(starship init zsh)"
fi

source "$XDG_CONFIG_HOME/zsh/aliases.zsh"
[[ -r "$XDG_CONFIG_HOME/zsh/local.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/local.zsh"
