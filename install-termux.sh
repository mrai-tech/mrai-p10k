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
#   3. Copies this repo's .p10k.zsh to ~/.p10k.zsh (backs up any existing one).
#   4. Adds the theme + config lines to ~/.zshrc — only if not already there.
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
ZSHRC="$HOME/.zshrc"

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
echo "[3/5] Installing Mrai config to $CONFIG_DST..."
if [[ -f "$CONFIG_DST" ]] && ! cmp -s "$CONFIG_SRC" "$CONFIG_DST"; then
  cp "$CONFIG_DST" "$CONFIG_DST.bak"
  echo "Backed up existing ~/.p10k.zsh to ~/.p10k.zsh.bak"
fi
cp "$CONFIG_SRC" "$CONFIG_DST"

# 4. ~/.zshrc: source theme + config, once only. Banner lines are untouched.
echo "[4/5] Wiring ~/.zshrc..."
touch "$ZSHRC"
if ! grep -q "powerlevel10k.zsh-theme" "$ZSHRC"; then
  cat >> "$ZSHRC" <<'EOF'

# Mrai Powerlevel10k (added by mrai-p10k/install-termux.sh)
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
  echo "Added p10k lines to ~/.zshrc."
else
  echo "~/.zshrc already sources powerlevel10k — nothing added."
fi

# Syntax-check the two files we care about.
zsh -n "$CONFIG_DST" && echo "Config syntax OK."
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
