#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Load the real installer functions without running the machine bootstrap.
source <(sed '$d' "$repo_dir/bootstrap.sh")
DOTFILES_DIR="$repo_dir"
FORCE_TOOLS=1

# Replace downloads with small scripts that enforce each upstream shell contract.
curl() {
  local url="$2" destination="$4"
  case "$url" in
    https://starship.rs/install.sh)
      cat > "$destination" <<'SCRIPT'
set -eu
if [ -n "${BASH_VERSION+x}" ] && [ -z "${POSIXLY_CORRECT+x}" ]; then
  echo 'Running installation script with non-POSIX `bash` may cause errors.' >&2
  echo 'Please use `sh` instead.' >&2
  exit 1
fi
[ "$#" -eq 3 ] && [ "$1" = -y ] && [ "$2" = -b ] && [ "$3" = "$HOME/.local/bin" ]
SCRIPT
      ;;
    https://fnm.vercel.app/install)
      cat > "$destination" <<'SCRIPT'
set -eu
[[ -n "$BASH_VERSION" ]]
args=("$@")
[[ ${#args[@]} == 3 && ${args[0]} == --install-dir && ${args[2]} == --skip-shell ]]
SCRIPT
      ;;
    https://bun.com/install)
      cat > "$destination" <<'SCRIPT'
set -eu
[[ -n "$BASH_VERSION" && -n "$BUN_INSTALL" && $# == 0 ]]
SCRIPT
      ;;
    *) printf 'Unexpected download: %s\n' "$url" >&2; return 1 ;;
  esac
}

# Avoid invoking real toolchains after their mock installers finish.
fnm() { :; }
npm() { :; }

install_starship
printf 'PASS Starship runs with a POSIX shell and receives its arguments\n'
install_fnm_and_node
printf 'PASS fnm runs with Bash and receives its arguments\n'
install_bun
printf 'PASS Bun runs with Bash and receives BUN_INSTALL\n'
