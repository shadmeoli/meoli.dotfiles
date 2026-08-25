# meoli.dotfiles

A headless-first terminal environment for Linux workstations, VPS hosts, and
remote development servers. It intentionally contains no desktop applications,
GUI configuration, VNC/remote-desktop setup, credentials, or Rust toolchain.

## What it installs

- Zsh with Zcomet, autosuggestions, syntax highlighting, and `fzf-tab`
- Starship with a compact, plain-glyph prompt that works without a Nerd Font
- tmux with TPM, sensible defaults, Neovim navigation, and session restore
- current stable Neovim plus this repository's complete Lua configuration
- Git, `fzf`, ripgrep, `eza`, `bat`, `jq`, and standard build utilities
- `fnm` as the only Node version manager, the current Node LTS, pnpm, TypeScript,
  Biome, `eslint_d`, markdownlint, Dev Containers CLI, Wrangler, and Codex
- Bun
- current stable Go plus `gopls`, Delve, goimports, gofumpt, Air,
  golangci-lint, gotestsum, govulncheck, and go-licenses
- Black and isort through pipx

Neovim's Mason configuration additionally provisions the Lua and TypeScript
language servers, `gopls`, Stylua, and `eslint_d` when Neovim starts. Rust and
rust-analyzer are deliberately absent.

## Supported systems

The bootstrap targets headless Linux on x86_64 or arm64. System packages are
supported through APT, DNF, Pacman, or APK. Neovim and Go use upstream binaries
in `~/.local/opt`, keeping the setup independent of old server repositories.

## Install

```sh
git clone YOUR_GIT_REMOTE ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
exec zsh
```

The script is idempotent. Existing managed files are moved into a timestamped
`~/.dotfiles-backup/` directory before symlinks are created.

Useful modes:

```sh
./bootstrap.sh --dry-run
./bootstrap.sh --skip-packages
./bootstrap.sh --core-only
./bootstrap.sh --link-only
./bootstrap.sh --force-tools
```

`--core-only` installs the shell/editor environment but skips Node, Bun, Go,
and language-specific CLI tools.

`--link-only` performs no downloads and installs no packages. It is useful for
re-linking an existing machine or testing the repository in a disposable home.

## Git identity and machine-local settings

The shared Git configuration refuses to guess an identity. Set one per server:

```sh
mkdir -p ~/.config/git
git config --file ~/.config/git/local.gitconfig user.name "Your Name"
git config --file ~/.config/git/local.gitconfig user.email "you@example.com"
```

Or provide `DOTFILES_GIT_NAME` and `DOTFILES_GIT_EMAIL` on the first bootstrap.

Copy either example for machine-local shell configuration:

```sh
cp config/zsh/local.zsh.example ~/.config/zsh/local.zsh
cp config/zsh/env.local.zsh.example ~/.config/zsh/env.local.zsh
chmod 600 ~/.config/zsh/env.local.zsh
```

These local files are not symlinked into Git. Use them for server aliases,
private hostnames, work paths, and secrets.

## Updating

```sh
cd ~/.dotfiles
git pull --rebase
./bootstrap.sh
```

Inside tmux, press `C-a I` to install plugins and `C-a r` to reload the config.
Neovim plugins install automatically on first launch.

## Intentionally excluded

- Desktop apps and terminal-emulator configuration
- GUI clipboard packages; tmux and Neovim use terminal/OSC 52 behavior over SSH
- Browser/editor state, caches, histories, WakaTime credentials, pnpm auth,
  SSH keys, GPG keys, tokens, and other secrets
- Work-only hostnames and aliases
- Nix, Android, WireGuard, Docker, Coder, Cloudflared, and ngrok
- Rust, Cargo, rustup, rust-analyzer, rustfmt, and Clippy
