#!/usr/bin/env bash
# install-termux.sh — install Mrai Powerlevel10k on Termux (Android, no root, no PC)
#
# Run from inside the mrai-p10k repo folder on the phone:
#   cd ~/mrai-p10k
#   bash install-termux.sh
#
# What it does:
#   1. Installs zsh + git if missing (pkg).
#   2. Installs/updates Powerlevel10k at ~/powerlevel10k.
#   3. Copies this repo's .p10k.zsh to ~/.p10k.zsh (backs up any existing one),
#      .p10k.mrai.zsh to ~/.p10k.mrai.zsh, and mrai-configure.sh to
#      ~/mrai-configure.sh (so it runs from anywhere, no cd needed).
#   4. Adds the theme + config lines to ~/.zshrc — only if not already there —
#      plus `setopt AUTO_CD` (type a folder name alone to cd into it, from
#      home or anywhere, no `cd` needed) and the Mrai overrides source line.
#   5. Switches the default shell to zsh (chsh -s zsh) and starts zsh.
#
# What it does NOT do (safe by design):
#   - Does NOT touch ~/.bashrc — your bash PS1 (MRAI ☠︎︎ TECH ➜ in #690202) stays.
#   - Does NOT delete or change your MRAI banner (~/.mrai-banner.sh).
#   - Does NOT touch /etc/bash.bashrc.
#   - Does NOT run `p10k configure` — that would overwrite ~/.p10k.zsh.
#   - Does NOT push to GitHub or use any token.
#
# Idempotent: run it again and it pulls the latest p10k, re-copies .p10k.zsh
# and adds nothing twice to ~/.zshrc.
#
# First zsh launch after install fetches gitstatusd for linux-aarch64
# (one-time, a few MB) — that is normal, it makes the git segment fast.
# If `pkg install` fails with a 429 / mirror error, run `termux-change-repo`
# first and pick a working mirror (grimler.se or packages.termux.dev).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P10K_DIR="$HOME/powerlevel10k"
CONFIG_SRC="$SCRIPT_DIR/.p10k.zsh"
CONFIG_DST="$HOME/.p10k.zsh"
OVERRIDES_SRC="$SCRIPT_DIR/.p10k.mrai.zsh"
OVERRIDES_DST="$HOME/.p10k.mrai.zsh"
CONFIGURE_SRC="$SCRIPT_DIR/mrai-configure.sh"
CONFIGURE_DST="$HOME/mrai-configure.sh"
ZSHRC="$HOME/.zshrc"
OVERRIDES_LINE='[[ ! -f ~/.p10k.mrai.zsh ]] || source ~/.p10k.mrai.zsh'

echo "== Mrai Powerlevel10k — Termux install =="

# 0. Sanity: are we in Termux?
if ! command -v pkg >/dev/null 2>&1; then
  echo "ERROR: 'pkg' not found. Run this in Termux on Android, not on a PC."
  exit 1
fi
if [[ ! -f "$CONFIG_SRC" ]]; then
  echo "ERROR: .p10k.zsh not found next to this script ($CONFIG_SRC)."
  echo "Run this script from inside the mrai-p10k folder."
  exit 1
fi

# 1. zsh + git.
echo "[1/5] Installing zsh + git (if missing)..."
pkg install -y zsh git

# 2. Powerlevel10k at ~/powerlevel10k.
echo "[2/5] Installing Powerlevel10k at $P10K_DIR..."
if [[ -d "$P10K_DIR/.git" ]]; then
  git -C "$P10K_DIR" pull --ff-only || echo "Note: p10k update skipped (no network / already up to date)."
elif [[ -d "$P10K_DIR" ]]; then
  echo "Note: $P10K_DIR exists but is not a git repo — leaving it as-is."
elif [[ -d "$SCRIPT_DIR/powerlevel10k/.git" ]]; then
  cp -r "$SCRIPT_DIR/powerlevel10k" "$P10K_DIR"
  echo "Copied bundled powerlevel10k from this repo."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 3. Mrai config -> ~/.p10k.zsh (backup the old one, if any).
#    Also install the Mrai overrides and the safe-configure script.
echo "[3/5] Installing Mrai config to $CONFIG_DST..."
if [[ -f "$CONFIG_DST" ]] && ! cmp -s "$CONFIG_SRC" "$CONFIG_DST"; then
  cp "$CONFIG_DST" "$CONFIG_DST.bak"
  echo "Backed up existing ~/.p10k.zsh to ~/.p10k.zsh.bak"
fi
cp "$CONFIG_SRC" "$CONFIG_DST"

if [[ -f "$OVERRIDES_SRC" ]]; then
  if [[ -f "$OVERRIDES_DST" ]] && ! cmp -s "$OVERRIDES_SRC" "$OVERRIDES_DST"; then
    cp "$OVERRIDES_DST" "$OVERRIDES_DST.bak"
    echo "Backed up existing ~/.p10k.mrai.zsh to ~/.p10k.mrai.zsh.bak"
  fi
  cp "$OVERRIDES_SRC" "$OVERRIDES_DST"
  echo "Installed Mrai overrides to ~/.p10k.mrai.zsh"
fi

if [[ -f "$CONFIGURE_SRC" ]]; then
  cp "$CONFIGURE_SRC" "$CONFIGURE_DST"
  chmod +x "$CONFIGURE_DST"
  echo "Installed safe configure to ~/mrai-configure.sh (run it from anywhere)"
fi

# 4. ~/.zshrc: source theme + config, once only. Banner lines are untouched.
#    AUTO_CD and the overrides line are added by their own grep-checks, so
#    re-running this installer adds them to an existing install too.
echo "[4/5] Wiring ~/.zshrc..."
touch "$ZSHRC"
if ! grep -q "powerlevel10k.zsh-theme" "$ZSHRC"; then
  cat >> "$ZSHRC" <<EOF

# Mrai Powerlevel10k (added by mrai-p10k/install-termux.sh)
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
$OVERRIDES_LINE
EOF
  echo "Added p10k lines to ~/.zshrc."
else
  echo "~/.zshrc already sources powerlevel10k — nothing added."
  # Overrides line: insert right after the .p10k.zsh source line, once only.
  if ! grep -q "p10k.mrai.zsh" "$ZSHRC"; then
    awk -v hook="$OVERRIDES_LINE" '
      !done && /\.p10k\.zsh/ && !/p10k\.mrai\.zsh/ { print; print hook; done=1; next }
      { print }
    ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
    echo "Wired ~/.zshrc to source .p10k.mrai.zsh after .p10k.zsh."
  fi
fi

# AUTO_CD: typing a folder name alone cds into it — from home or anywhere,
# no `cd` needed. (This is a zsh option, so it lives in ~/.zshrc, NOT inside
# .p10k.zsh, where options are local to its function and would not stick.)
if ! grep -q "setopt AUTO_CD" "$ZSHRC"; then
  cat >> "$ZSHRC" <<'EOF'

# Mrai: type a folder name alone to cd into it (no `cd` needed), from home or anywhere.
setopt AUTO_CD
EOF
  echo "Added setopt AUTO_CD to ~/.zshrc."
else
  echo "~/.zshrc already has setopt AUTO_CD — nothing added."
fi

# Syntax-check the files we care about.
zsh -n "$CONFIG_DST" && echo "Config syntax OK."
zsh -n "$OVERRIDES_DST" && echo "Overrides syntax OK."
zsh -n "$ZSHRC" && echo ".zshrc syntax OK."

# 5. Switch default shell to zsh. p10k only works in zsh, not bash.
echo "[5/5] Switching default shell to zsh..."
chsh -s zsh || echo "Note: 'chsh -s zsh' failed — run it by hand, then 'exec zsh'."

echo ""
echo "Done. Starting zsh now — your prompt should read:"
echo "  MRAI ☠︎︎ TECH  <directory>  ➜"
echo "First launch fetches gitstatusd (one-time, a few MB)."
echo "To go back to bash any time:  chsh -s bash   then   exec bash"
echo "Your bash PS1 in ~/.bashrc was not touched."
exec zsh
