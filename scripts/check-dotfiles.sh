#!/usr/bin/env bash
set -u

failures=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS %s\n' "$label"
  else
    printf 'FAIL %s\n' "$label"
    failures=$((failures + 1))
  fi
}

check 'Interactive Zsh loads highlighting, autosuggestions, Starship, and Neovim' \
  zsh -ic '(( $+functions[_zsh_highlight] && $+functions[_zsh_autosuggest_start] )) && [[ ${STARSHIP_SHELL:-} == zsh ]] && command -v nvim >/dev/null'
check 'Starship uses the original arrow prompt' \
  grep -Fq 'success_symbol = "[❯](bright-black)"' "$HOME/.config/starship.toml"
check 'Starship keeps Rust removed' \
  bash -c '! grep -Fq '\''$rust'\'' "$1" && ! grep -Fq '\''[rust]'\'' "$1"' \
    _ "$HOME/.config/starship.toml"
check 'Zcomet exists at a supported path' \
  bash -c 'test -r "$1/.local/share/zcomet/zcomet.zsh" || test -r "$1/.zcomet/zcomet.zsh"' \
    _ "$HOME"
check 'TPM exists at a supported path' \
  bash -c 'test -x "$1/.local/share/tmux/plugins/tpm/tpm" || test -x "$1/.config/tmux/plugins/tpm/tpm"' \
    _ "$HOME"

socket="dotfiles-regression-$$"
if tmux -L "$socket" -f "$HOME/.config/tmux/tmux.conf" \
  new-session -d -s regression >/dev/null 2>&1; then
  prefix="$(tmux -L "$socket" show-options -gv prefix 2>/dev/null || true)"
  if [[ "$prefix" == C-a ]]; then
    printf 'PASS tmux uses C-a prefix\n'
  else
    printf 'FAIL tmux uses C-a prefix\n'
    failures=$((failures + 1))
  fi

  keys="$(tmux -L "$socket" list-keys -T root 2>/dev/null || true)"
  for binding in 'C-h' 'C-j' 'C-k' 'C-l' 'M-Left' 'M-Right' 'S-Left' 'S-Right'; do
    if grep -Eq "^bind-key -T root +${binding} +" <<<"$keys"; then
      printf 'PASS tmux root binding %s exists\n' "$binding"
    else
      printf 'FAIL tmux root binding %s exists\n' "$binding"
      failures=$((failures + 1))
    fi
  done
  tmux -L "$socket" kill-server >/dev/null 2>&1 || true
else
  printf 'FAIL tmux config starts a clean server\n'
  failures=$((failures + 1))
fi

exit "$failures"
