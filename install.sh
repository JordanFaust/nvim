#!/usr/bin/env bash
set -euo pipefail

# ── constants ────────────────────────────────────────────────────────────────

NVIM_VERSION="0.12.2"
case "$(uname -m)" in
    aarch64|arm64) NVIM_ARCH="arm64" ;;
    *)             NVIM_ARCH="x86_64" ;;
esac
NVIM_TARBALL="nvim-linux-${NVIM_ARCH}.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/${NVIM_TARBALL}"
NVIM_BIN="${HOME}/.local/bin/nvim"

NVIM_CONFIG_DIR="${HOME}/.config/nvim"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ──────────────────────────────────────────────────────────────────

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }

apt_install() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null 2>&1; then
    ok "$pkg already installed"
    return 0
  fi
  log "Installing $pkg via apt"
  if sudo apt-get install -y "$pkg" 2>/dev/null; then
    ok "$pkg installed"
  else
    warn "$pkg unavailable in apt — skipping"
  fi
}

npm_global_install() {
  local pkg="$1"
  if npm list -g --depth=0 "$pkg" &>/dev/null 2>&1; then
    ok "$pkg already installed (npm -g)"
    return 0
  fi
  log "Installing $pkg via npm -g"
  npm install -g "$pkg"
  ok "$pkg installed"
}

# ── 1. neovim ────────────────────────────────────────────────────────────────

install_neovim() {
  log "Checking neovim"

  if [[ -x "$NVIM_BIN" ]]; then
    local installed_ver
    installed_ver=$("$NVIM_BIN" --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || true)
    if [[ "$installed_ver" == "$NVIM_VERSION" ]]; then
      ok "neovim $NVIM_VERSION already installed at $NVIM_BIN"
      return 0
    fi
    warn "neovim $installed_ver found, upgrading to $NVIM_VERSION"
  fi

  local tmp
  tmp="$(mktemp -d)"

  log "Downloading neovim $NVIM_VERSION"
  curl -fsSL "$NVIM_URL" -o "${tmp}/${NVIM_TARBALL}"

  log "Extracting neovim"
  tar -C "$tmp" -xzf "${tmp}/${NVIM_TARBALL}"

  mkdir -p "${HOME}/.local/bin" "${HOME}/.local/lib"

  rm -rf "${HOME}/.local/lib/nvim-linux-${NVIM_ARCH}"
  cp -r "${tmp}/nvim-linux-${NVIM_ARCH}" "${HOME}/.local/lib/nvim-linux-${NVIM_ARCH}"
  rm -rf "$tmp"

  ln -sf "${HOME}/.local/lib/nvim-linux-${NVIM_ARCH}/bin/nvim" "${NVIM_BIN}"
  ok "neovim $NVIM_VERSION installed at $NVIM_BIN"
}

# ── 2. system & npm deps ─────────────────────────────────────────────────────

install_deps() {
  log "Updating apt cache"
  sudo apt-get update -qq

  apt_install "ripgrep"

  if command -v npm &>/dev/null; then
    npm_global_install "tree-sitter-cli"
    npm_global_install "markdownlint-cli2"
  elif command -v cargo &>/dev/null; then
    log "npm not found — installing tree-sitter-cli via cargo"
    cargo install tree-sitter-cli
    warn "markdownlint-cli2 requires npm; skipping (npm unavailable)"
  else
    warn "Neither npm nor cargo found — skipping tree-sitter-cli and markdownlint-cli2"
  fi
}

# ── 3. clone config ──────────────────────────────────────────────────────────

setup_nvim_config() {
  log "Setting up ~/.config/nvim"

  if [[ -d "${NVIM_CONFIG_DIR}/.git" ]]; then
    ok "${HOME}/.config/nvim already a git repo — skipping clone"
    return 0
  fi

  # When run by Coder, SCRIPT_DIR is the cloned dotfiles location.
  # Copy/move it into place rather than cloning again.
  if [[ "$(realpath "$SCRIPT_DIR")" != "$(realpath "$NVIM_CONFIG_DIR")" ]]; then
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
      warn "${HOME}/.config/nvim exists but is not a git repo — backing up"
      mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak.$(date +%s)"
    fi
    mkdir -p "${HOME}/.config"
    cp -r "$SCRIPT_DIR" "$NVIM_CONFIG_DIR"
    ok "Copied config to ~/.config/nvim"
  else
    ok "Already running from ~/.config/nvim — nothing to do"
  fi
}

# ── 4. zsh config ────────────────────────────────────────────────────────────

setup_zsh() {
  log "Configuring ~/.zshrc"

  local zshrc="${HOME}/.zshrc"
  touch "$zshrc"

  local marker="# managed by nvim dotfiles install.sh"

  if grep -qF "$marker" "$zshrc" 2>/dev/null; then
    ok "${HOME}/.zshrc already patched — skipping"
    return 0
  fi

  cat >>"$zshrc" <<'ZSHBLOCK'

# managed by nvim dotfiles install.sh
export PATH="${HOME}/.local/bin:${PATH}"
export EDITOR=nvim
ZSHBLOCK

  ok "${HOME}/.zshrc updated"
}

# ── main ─────────────────────────────────────────────────────────────────────

main() {
  log "Starting dotfiles install (neovim config)"

  install_neovim
  install_deps
  setup_nvim_config
  setup_zsh

  ok "Done. Open a new shell or run: export PATH=\"\${HOME}/.local/bin:\${PATH}\""
  ok "Launch nvim once to let lazy.nvim + Mason install plugins and LSP servers."
}

main "$@"
