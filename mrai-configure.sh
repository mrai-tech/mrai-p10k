#!/usr/bin/env bash
# mrai-configure.sh — SAFE p10k configure for Mrai Powerlevel10k
#
# The original `p10k configure` wizard overwrites ~/.p10k.zsh with its own
# config and wipes the Mrai prompt (red #C62828, MRAI ☠︎︎ TECH segment,
# Layout A). Do NOT run `p10k configure` directly — run this instead:
#
#   bash ~/mrai-p10k/mrai-configure.sh        # from anywhere, no cd needed
#   bash ~/mrai-configure.sh                  # same, after install-termux.sh
#
# What it does:
#   1. Backs up ~/.p10k.zsh to a timestamped file
#      (~/.p10k.zsh.bak.YYYY-MM-DD-HHMMSS) BEFORE anything changes.
#   2. Runs the real `p10k configure` wizard (in zsh, on your real terminal).
#      Answer its questions as you like — style, prompt, colours, everything.
#   3. After the wizard, re-asserts the Mrai identity WITHOUT wiping the
#      wizard's other choices: it installs ~/.p10k.mrai.zsh (Mrai overrides
#      only) and makes ~/.zshrc source it AFTER ~/.p10k.zsh, and appends a
#      hook to ~/.p10k.zsh so the overrides survive a plain `p10k reload`.
#   4. Reloads / restarts zsh so the prompt shows MRAI ☠︎︎ TECH in #C62828.
#
# Restore the pre-wizard config any time:
#   bash ~/mrai-p10k/mrai-configure.sh --restore
# That copies the newest timestamped backup back to ~/.p10k.zsh.
#
# The wizard needs a real terminal — it asks questions and draws a preview.
# If you run this without a terminal (piped / non-interactive), it refuses
# instead of breaking your config. Run it in Termux, in zsh, on the phone.
#
# It does NOT touch ~/.bashrc, your MRAI banner, /etc/bash.bashrc, or GitHub.
# It does NOT change the red or the layout — those live in .p10k.mrai.zsh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.p10k.zsh"
OVERRIDES_SRC="$SCRIPT_DIR/.p10k.mrai.zsh"
OVERRIDES_DST="$HOME/.p10k.mrai.zsh"
ZSHRC="$HOME/.zshrc"
HOOK_LINE='[[ ! -f ~/.p10k.mrai.zsh ]] || source ~/.p10k.mrai.zsh'

usage() {
  cat <<'EOF'
Usage:
  mrai-configure.sh            Run the p10k wizard safely (backs up first,
                               then re-asserts the Mrai prompt after it)
  mrai-configure.sh --restore  Restore the newest ~/.p10k.zsh backup
  mrai-configure.sh --help     Show this help
EOF
}

# Install the Mrai overrides file and wire it in, once-only.
# Called after the wizard, and also by --restore.
install_overrides() {
  if [[ ! -f "$OVERRIDES_SRC" ]]; then
    echo "ERROR: .p10k.mrai.zsh not found next to this script ($OVERRIDES_SRC)."
    echo "Run this script from inside the mrai-p10k folder, or from ~/mrai-configure.sh"
    echo "after install-termux.sh has copied it there."
    exit 1
  fi
  if [[ -f "$OVERRIDES_DST" ]] && ! cmp -s "$OVERRIDES_SRC" "$OVERRIDES_DST"; then
    cp "$OVERRIDES_DST" "$OVERRIDES_DST.bak"
    echo "Backed up existing ~/.p10k.mrai.zsh to ~/.p10k.mrai.zsh.bak"
  fi
  cp "$OVERRIDES_SRC" "$OVERRIDES_DST"
  echo "Installed Mrai overrides to ~/.p10k.mrai.zsh"

  # ~/.zshrc: source the overrides AFTER ~/.p10k.zsh, once only.
  touch "$ZSHRC"
  if grep -q "p10k.mrai.zsh" "$ZSHRC"; then
    echo "~/.zshrc already sources .p10k.mrai.zsh — nothing added."
  elif grep -q "\.p10k\.zsh" "$ZSHRC"; then
    awk -v hook="$HOOK_LINE" '
      !done && /\.p10k\.zsh/ && !/p10k\.mrai\.zsh/ { print; print hook; done=1; next }
      { print }
    ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
    echo "Wired ~/.zshrc to source .p10k.mrai.zsh after .p10k.zsh."
  else
    cat >> "$ZSHRC" <<EOF

# Mrai Powerlevel10k overrides (added by mrai-configure.sh)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
$HOOK_LINE
EOF
    echo "Added p10k + Mrai overrides lines to ~/.zshrc."
  fi

  # Hook in ~/.p10k.zsh itself, so the overrides survive a plain `p10k reload`
  # (reload re-sources ~/.p10k.zsh; without this hook the overrides would
  # only come back on the next fresh shell). Appended once only, at the end.
  if [[ -f "$CONFIG" ]]; then
    if grep -q "p10k.mrai.zsh" "$CONFIG"; then
      echo "~/.p10k.zsh already hooks .p10k.mrai.zsh — nothing added."
    else
      cat >> "$CONFIG" <<EOF

# Mrai overrides — re-asserts MRAI ☠︎︎ TECH / #C62828 / Layout A on top of
# any config, including one written by the p10k configure wizard.
# Added by mrai-configure.sh; safe to leave here. Do not delete this line.
$HOOK_LINE
EOF
      echo "Hooked .p10k.mrai.zsh into the end of ~/.p10k.zsh."
    fi
  fi

  zsh -n "$OVERRIDES_DST" && echo "Overrides syntax OK."
  zsh -n "$ZSHRC" && echo ".zshrc syntax OK."
  if [[ -f "$CONFIG" ]]; then
    zsh -n "$CONFIG" && echo "Config syntax OK."
  fi
}

do_restore() {
  # Newest timestamped backup first; fall back to the plain .bak.
  local newest
  newest="$(ls -t "$HOME"/.p10k.zsh.bak.* 2>/dev/null | head -n 1 || true)"
  if [[ -z "$newest" && -f "$HOME/.p10k.zsh.bak" ]]; then
    newest="$HOME/.p10k.zsh.bak"
  fi
  if [[ -z "$newest" ]]; then
    echo "ERROR: no backup found (~/.p10k.zsh.bak.*). Nothing to restore."
    exit 1
  fi
  cp "$newest" "$CONFIG"
  echo "Restored ~/.p10k.zsh from $newest"
  install_overrides
  echo ""
  echo "Restored. Starting zsh — your prompt should read:"
  echo "  MRAI ☠︎︎ TECH  <directory>  ➜"
  exec zsh
}

# --- main ---
case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  --restore)
    do_restore
    ;;
  "")
    ;;
  *)
    echo "ERROR: unknown option: $1"
    usage
    exit 1
    ;;
esac

# The wizard needs a real terminal and zsh. Refuse instead of breaking things.
if ! command -v zsh >/dev/null 2>&1; then
  echo "ERROR: zsh not found. Install it first: pkg install -y zsh"
  exit 1
fi
if [[ ! -t 0 || ! -t 1 ]]; then
  echo "ERROR: the p10k wizard needs a real terminal."
  echo "Run this in Termux, in zsh, on the phone — not piped, not in a script."
  echo "Your config was NOT changed. Nothing was backed up or overwritten."
  exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: ~/.p10k.zsh not found. Run install-termux.sh first."
  exit 1
fi

# 1. Back up BEFORE anything changes.
BACKUP="$HOME/.p10k.zsh.bak.$(date +%F-%H%M%S)"
cp "$CONFIG" "$BACKUP"
echo "Backed up ~/.p10k.zsh to $BACKUP"
echo "Restore any time with: bash $SCRIPT_DIR/mrai-configure.sh --restore"
echo ""

# 2. Run the real wizard, in an interactive zsh (it must run under zsh, and
# it needs your terminal to ask questions and draw its preview).
echo "== Starting the p10k wizard — answer it as you like =="
echo "When it finishes, this script re-asserts the Mrai prompt automatically."
echo ""
zsh -i -c 'p10k configure'

# 3. Re-assert Mrai identity, without wiping the wizard's other choices.
echo ""
echo "== Wizard done — re-asserting the Mrai prompt =="
install_overrides

echo ""
echo "Done. Starting zsh — your prompt should read:"
echo "  MRAI ☠︎︎ TECH  <directory>  ➜"
echo "in bold #C62828, with the wizard's other choices kept."
echo "Backup kept at: $BACKUP"
exec zsh
