#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PACKAGES=1
INSTALL_LANGUAGES=1
DRY_RUN=0
FORCE_TOOLS=0
LINK_ONLY=0
TARGET_HOME="${DOTFILES_TARGET_HOME:-$HOME}"
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${TARGET_HOME}/.dotfiles-backup/${BACKUP_STAMP}"

usage() {
  printf '%s\n' \
    'Usage: ./bootstrap.sh [options]' \
    '' \
    '  --skip-packages  Only link configs and install user-space plugins' \
    '  --link-only      Only link configs; do not download or install anything' \
    '  --core-only      Skip Node/Bun/Go and language CLI installation' \
    '  --force-tools    Reinstall user-space toolchains' \
    '  --dry-run        Print changes without applying them' \
    '  -h, --help       Show this help'
}

while (($#)); do
  case "$1" in
    --skip-packages) INSTALL_PACKAGES=0 ;;
    --link-only) INSTALL_PACKAGES=0; INSTALL_LANGUAGES=0; LINK_ONLY=1 ;;
    --core-only) INSTALL_LANGUAGES=0 ;;
    --force-tools) FORCE_TOOLS=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

run() {
  if ((DRY_RUN)); then
    printf '  +'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

as_root() {
  if ((EUID == 0)); then
    run "$@"
  elif have sudo; then
    run sudo "$@"
  else
    warn 'Root privileges are required, but sudo is unavailable.'
    return 1
  fi
}

download_and_run() {
  local url="$1"
  shift
  if ((DRY_RUN)); then
    printf '  + download and run %s' "$url"
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  local temp_script
  temp_script="$(mktemp)"
  curl -fsSL "$url" -o "$temp_script"
  run bash "$temp_script" "$@"
  rm -f "$temp_script"
}

install_system_packages() {
  ((INSTALL_PACKAGES)) || return 0
  log 'Installing headless system packages'

  if have apt-get; then
    as_root apt-get update
    as_root apt-get install -y zsh git curl ca-certificates tmux fzf ripgrep eza bat jq unzip tar build-essential python3 python3-venv pipx
  elif have dnf; then
    as_root dnf install -y zsh git curl ca-certificates tmux fzf ripgrep eza bat jq unzip tar gcc gcc-c++ make python3 pipx
  elif have pacman; then
    as_root pacman -Syu --needed --noconfirm zsh git curl ca-certificates tmux fzf ripgrep eza bat jq unzip tar base-devel python python-pipx
  elif have apk; then
    as_root apk add zsh git curl ca-certificates tmux fzf ripgrep eza bat jq unzip tar build-base python3 py3-pip pipx
  else
    warn 'Unsupported package manager. Install the packages listed in README.md manually.'
  fi
}

backup_and_link() {
  local source="$1" target="$2"
  local backup_target

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return 0
  fi

  run mkdir -p "$(dirname -- "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    backup_target="$BACKUP_DIR/${target#"$TARGET_HOME"/}"
    log "Backing up $target"
    run mkdir -p "$(dirname -- "$backup_target")"
    run mv "$target" "$backup_target"
  fi
  run ln -s "$source" "$target"
}

link_dotfiles() {
  log 'Linking dotfiles'
  run mkdir -p "$TARGET_HOME/.local/bin" "$TARGET_HOME/.config/zsh" "$TARGET_HOME/.config/git"
  backup_and_link "$DOTFILES_DIR/home/.zshenv" "$TARGET_HOME/.zshenv"
  backup_and_link "$DOTFILES_DIR/home/.zshrc" "$TARGET_HOME/.zshrc"
  backup_and_link "$DOTFILES_DIR/home/.gitconfig" "$TARGET_HOME/.gitconfig"
  backup_and_link "$DOTFILES_DIR/config/zsh/aliases.zsh" "$TARGET_HOME/.config/zsh/aliases.zsh"
  backup_and_link "$DOTFILES_DIR/config/starship.toml" "$TARGET_HOME/.config/starship.toml"
  backup_and_link "$DOTFILES_DIR/config/tmux/tmux.conf" "$TARGET_HOME/.config/tmux/tmux.conf"
  backup_and_link "$DOTFILES_DIR/config/nvim" "$TARGET_HOME/.config/nvim"
  backup_and_link "$DOTFILES_DIR/bin/dotfiles-git-pager" "$TARGET_HOME/.local/bin/dotfiles-git-pager"

  if [[ ! -e "$TARGET_HOME/.config/git/local.gitconfig" ]]; then
    if [[ -n "${DOTFILES_GIT_NAME:-}" && -n "${DOTFILES_GIT_EMAIL:-}" ]]; then
      if ((DRY_RUN)); then
        printf '  + create %q from DOTFILES_GIT_NAME and DOTFILES_GIT_EMAIL\n' "$TARGET_HOME/.config/git/local.gitconfig"
      else
        umask 077
        printf '[user]\n\tname = %s\n\temail = %s\n' "$DOTFILES_GIT_NAME" "$DOTFILES_GIT_EMAIL" > "$TARGET_HOME/.config/git/local.gitconfig"
      fi
    else
      warn 'Git identity not set. See config/git/local.gitconfig.example.'
    fi
  fi
}

install_shell_plugins() {
  log 'Installing shell and tmux plugin managers'
  local zcomet_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zcomet"
  local tpm_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins/tpm"
  if [[ ! -r "$zcomet_dir/zcomet.zsh" && -r "$HOME/.zcomet/zcomet.zsh" ]]; then
    zcomet_dir="$HOME/.zcomet"
  fi
  if [[ ! -x "$tpm_dir/tpm" && -x "$HOME/.config/tmux/plugins/tpm/tpm" ]]; then
    tpm_dir="$HOME/.config/tmux/plugins/tpm"
  fi
  [[ -d "$zcomet_dir/.git" ]] || run git clone --depth 1 https://github.com/agkozak/zcomet.git "$zcomet_dir"
  [[ -d "$tpm_dir/.git" ]] || run git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
    run "$tpm_dir/bin/install_plugins"
  fi
}

install_starship() {
  if have starship && ((FORCE_TOOLS == 0)); then return 0; fi
  log 'Installing Starship'
  download_and_run https://starship.rs/install.sh -y -b "$HOME/.local/bin"
}

install_neovim() {
  if [[ -x "$HOME/.local/opt/nvim/bin/nvim" ]] && ((FORCE_TOOLS == 0)); then return 0; fi
  log 'Installing current stable Neovim'
  local machine asset temp_dir archive destination
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) asset='nvim-linux-x86_64' ;;
    aarch64|arm64) asset='nvim-linux-arm64' ;;
    *) warn "No Neovim binary mapping for $machine"; return 0 ;;
  esac
  if ((DRY_RUN)); then
    printf '  + install https://github.com/neovim/neovim/releases/latest/download/%s.tar.gz into %q\n' "$asset" "$HOME/.local/opt/nvim"
    return 0
  fi
  temp_dir="$(mktemp -d)"
  archive="$temp_dir/$asset.tar.gz"
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/$asset.tar.gz" -o "$archive"
  tar -xzf "$archive" -C "$temp_dir"
  destination="$HOME/.local/opt/nvim"
  run mkdir -p "$HOME/.local/opt"
  if [[ -e "$destination" ]]; then
    run mv "$destination" "${destination}.previous-${BACKUP_STAMP}"
  fi
  run mv "$temp_dir/$asset" "$destination"
  rm -rf "$temp_dir"
}

install_fnm_and_node() {
  local fnm_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
  if [[ ! -x "$fnm_dir/fnm" ]] || ((FORCE_TOOLS)); then
    log 'Installing fnm'
    if ((DRY_RUN)); then
      printf '  + fnm install --lts and install packages from %q\n' "$DOTFILES_DIR/packages/node-global.txt"
      return 0
    fi
    download_and_run https://fnm.vercel.app/install --install-dir "$fnm_dir" --skip-shell
  fi
  export PATH="$fnm_dir:$PATH"
  eval "$(fnm env --shell bash)"
  if ! have node || ((FORCE_TOOLS)); then
    log 'Installing the current Node LTS'
    run fnm install --lts
    run fnm default lts-latest
    eval "$(fnm env --shell bash)"
  fi

  log 'Installing global Node command-line tools'
  while IFS= read -r package; do
    [[ -z "$package" || "$package" == \#* ]] && continue
    run npm install --global "$package"
  done < "$DOTFILES_DIR/packages/node-global.txt"
}

install_bun() {
  if have bun && ((FORCE_TOOLS == 0)); then return 0; fi
  log 'Installing Bun'
  BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}" download_and_run https://bun.com/install
}

install_go() {
  local go_bin="$HOME/.local/opt/go/bin/go"
  if [[ ! -x "$go_bin" ]] || ((FORCE_TOOLS)); then
    if ((DRY_RUN)); then
      printf '  + install the checksummed current Go release into %q\n' "$HOME/.local/opt/go"
      printf '  + install packages from %q\n' "$DOTFILES_DIR/packages/go-tools.txt"
      return 0
    fi
    log 'Installing the current stable Go toolchain'
    local metadata version arch filename checksum temp_dir archive destination
    metadata="$(curl -fsSL 'https://go.dev/dl/?mode=json')"
    version="$(printf '%s' "$metadata" | jq -r '.[0].version')"
    case "$(uname -m)" in
      x86_64|amd64) arch='amd64' ;;
      aarch64|arm64) arch='arm64' ;;
      *) warn "No Go binary mapping for $(uname -m)"; return 0 ;;
    esac
    filename="${version}.linux-${arch}.tar.gz"
    checksum="$(printf '%s' "$metadata" | jq -r --arg name "$filename" '.[0].files[] | select(.filename == $name) | .sha256')"
    [[ -n "$checksum" && "$checksum" != null ]] || { warn "Could not resolve checksum for $filename"; return 1; }
    temp_dir="$(mktemp -d)"
    archive="$temp_dir/$filename"
    curl -fL "https://go.dev/dl/$filename" -o "$archive"
    printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c -
    tar -xzf "$archive" -C "$temp_dir"
    destination="$HOME/.local/opt/go"
    run mkdir -p "$HOME/.local/opt"
    if [[ -e "$destination" ]]; then
      run mv "$destination" "${destination}.previous-${BACKUP_STAMP}"
    fi
    run mv "$temp_dir/go" "$destination"
    rm -rf "$temp_dir"
  fi

  export PATH="$HOME/.local/opt/go/bin:${GOPATH:-$HOME/go}/bin:$PATH"
  log 'Installing Go development tools'
  while IFS= read -r package; do
    [[ -z "$package" || "$package" == \#* ]] && continue
    run "$go_bin" install "$package"
  done < "$DOTFILES_DIR/packages/go-tools.txt"
}

install_python_tools() {
  have pipx || { warn 'pipx is unavailable; skipping Black and isort.'; return 0; }
  log 'Installing Python formatters'
  run pipx install --force black
  run pipx install --force isort
}

install_languages() {
  ((INSTALL_LANGUAGES)) || return 0
  install_fnm_and_node
  install_bun
  install_go
  install_python_tools
}

main() {
  [[ "$(uname -s)" == Linux ]] || { printf 'This headless profile currently supports Linux only.\n' >&2; exit 1; }
  install_system_packages
  link_dotfiles
  if ((LINK_ONLY)); then
    log 'Link-only bootstrap complete.'
    return 0
  fi
  install_shell_plugins
  install_starship
  install_neovim
  install_languages
  log 'Bootstrap complete. Start a new Zsh session with: exec zsh'
  if [[ "$SHELL" != */zsh ]]; then
    warn 'Zsh is not your login shell. Run: chsh -s "$(command -v zsh)"'
  fi
}

main
