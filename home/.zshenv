# Environment shared by interactive and non-interactive Zsh sessions.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export FNM_DIR="${FNM_DIR:-$XDG_DATA_HOME/fnm}"
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="${GOBIN:-$GOPATH/bin}"
export PNPM_HOME="${PNPM_HOME:-$XDG_DATA_HOME/pnpm}"

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.local/opt/nvim/bin"
  "$HOME/.local/opt/go/bin"
  "$BUN_INSTALL/bin"
  "$FNM_DIR"
  "$GOBIN"
  "$PNPM_HOME"
  $path
)
export PATH

# Secrets and machine-specific values go in this ignored file.
[[ -r "$XDG_CONFIG_HOME/zsh/env.local.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/env.local.zsh"
