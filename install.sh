#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/shadmeoli/meoli.dotfiles.git}"
INSTALL_DIR="${DOTFILES_INSTALL_DIR:-$HOME/.dotfiles}"

have() { command -v "$1" >/dev/null 2>&1; }

as_root() {
  if ((EUID == 0)); then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    printf 'Git is required, but root privileges and sudo are unavailable.\n' >&2
    return 1
  fi
}

install_git() {
  have git && return 0
  printf 'Installing Git...\n'
  if have apt-get; then
    as_root apt-get update
    as_root apt-get install -y git ca-certificates
  elif have dnf; then
    as_root dnf install -y git ca-certificates
  elif have pacman; then
    as_root pacman -Syu --needed --noconfirm git ca-certificates
  elif have apk; then
    as_root apk add git ca-certificates
  else
    printf 'Unsupported package manager. Install Git, then run this installer again.\n' >&2
    return 1
  fi
}

install_git

if [[ -d "$INSTALL_DIR/.git" ]]; then
  current_origin="$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ "$current_origin" != "$REPO_URL" ]]; then
    printf 'Refusing to update %s: origin is %s, expected %s.\n' \
      "$INSTALL_DIR" "${current_origin:-<missing>}" "$REPO_URL" >&2
    exit 1
  fi
  printf 'Updating %s...\n' "$INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only
  git -C "$INSTALL_DIR" submodule sync --recursive
  git -C "$INSTALL_DIR" submodule update --init --recursive
elif [[ -e "$INSTALL_DIR" ]]; then
  printf 'Refusing to replace existing non-repository path: %s\n' "$INSTALL_DIR" >&2
  exit 1
else
  git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
fi

exec "$INSTALL_DIR/bootstrap.sh" "$@"
