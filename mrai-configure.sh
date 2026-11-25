#!/usr/bin/env bash
# mrai-configure.sh — MRAI'S setup wizard for Mrai Powerlevel10k (v2)
#
# This is Mrai's wizard, NOT p10k's. It never calls `p10k configure`.
# p10k is only the template underneath: the base config in ~/.p10k.zsh
# (forked from upstream config/p10k-lean.zsh, MIT) stays as the template,
# and THIS wizard writes what Mrai chose on top of it, in
# ~/.p10k.mrai.zsh — sourced AFTER ~/.p10k.zsh, so Mrai's choices win.
# What you pick here is what you get, everywhere it touches: layout,
# red, directory, git, right prompt, prompt char and AUTO_CD.
# Run plain `p10k configure` and it overwrites ~/.p10k.zsh with p10k's
# own config and wipes the Mrai prompt. Do not run it. Run this instead:
#
#   bash ~/mrai-p10k/mrai-configure.sh        # from anywhere, no cd needed
#   bash ~/mrai-configure.sh                  # same, after install-termux.sh
#   bash ~/mrai-p10k/mrai-configure.sh --defaults   # Mrai defaults, no questions
#   bash ~/mrai-p10k/mrai-configure.sh --restore    # restore newest backup
#
# What it does:
#   1. Backs up ~/.p10k.zsh to a timestamped file BEFORE anything changes.
#   2. Asks 7 questions (Enter = Mrai default). Every answer is written
#      into ~/.p10k.mrai.zsh (overrides) and, for AUTO_CD, into ~/.zshrc.
#   3. Reloads zsh and prints a summary of exactly what was set, so you
#      can see you got what you configured.
#
# The wizard needs a real terminal — it asks questions on the phone.
# If you run it piped / non-interactive (except --defaults / --restore /
# --help), it refuses instead of breaking your config.
# It does NOT touch ~/.bashrc, your MRAI banner, /etc/bash.bashrc, or GitHub.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.p10k.zsh"
OVERRIDES_DST="$HOME/.p10k.mrai.zsh"
ZSHRC="$HOME/.zshrc"
OVERRIDES_LINE='[[ ! -f ~/.p10k.mrai.zsh ]] || source ~/.p10k.mrai.zsh'

usage() {
  cat <<'EOF'
Mrai setup wizard — your wizard, p10k's template, your rules.
Usage:
  mrai-configure.sh            Ask 7 questions, apply what you pick
  mrai-configure.sh --defaults Apply Mrai defaults, no questions
  mrai-configure.sh --restore  Restore the newest ~/.p10k.zsh backup
  mrai-configure.sh --help     Show this help

Questions (Enter = Mrai default):
  1 Layout:      1 Lean one-line (default) | 2 Classic two-line
  2 Red:         1 #C62828 deep blood red (default) | 2 #690202 dark (dim!) | 3 #D70000 brighter
  3 Directory:   1 short/truncated (default) | 2 full path | 3 hide it
  4 Git segment: 1 on (default) | 2 off
  5 Right prompt: 1 minimal time + error (default) | 2 time only | 3 off
  6 AUTO_CD:     1 on (default) | 2 off
  7 Prompt char: 1 ➜ (default) | 2 ❯ | 3 $
EOF
}

ask() {
  # ask <prompt> <default> — prints the answer on stdout.
  # Reads from /dev/tty so it works even when the script was started
  # with stdin redirected; refuses when there is no terminal at all.
  local prompt="$1" default="$2" ans=""
  printf '%s' "$prompt" > /dev/tty
  IFS= read -r ans < /dev/tty || ans=""
  if [[ -z "$ans" ]]; then ans="$default"; fi
  printf '%s' "$ans"
}

do_restore() {
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
  echo ""
  echo "Restored. Starting zsh — your prompt should read:"
  echo "  MRAI ☠︎︎ TECH  <directory>  ➜"
  exec zsh
}

write_overrides() {
  # write_overrides <layout> <red_hex> <red_256> <dir_mode> <git> <right> <char>
  # Writes ~/.p10k.mrai.zsh from the wizard's answers. This file is sourced
  # AFTER ~/.p10k.zsh, so every value here wins over the template.
  local layout="$1" red_hex="$2" red_256="$3" dir_mode="$4" git="$5" right="$6" char="$7"
  local left_elems="" newline="false" dir_shorten="truncate_to_unique" dir_max="40"

  # Left prompt: mrai first, always. Then dir (unless hidden), then vcs
  # (unless git is off), then prompt_char last, where you type.
  left_elems="mrai"
  if [[ "$dir_mode" != "hide" ]]; then left_elems="$left_elems dir"; fi
  if [[ "$git" == "on" ]]; then left_elems="$left_elems vcs"; fi
  left_elems="$left_elems prompt_char"

  if [[ "$layout" == "two" ]]; then
    newline="true"
  fi
  if [[ "$dir_mode" == "full" ]]; then
    dir_shorten="truncate_to_last"
    dir_max="0"
  fi

  local right_elems=""
  if [[ "$right" == "minimal" ]]; then
    right_elems="status command_execution_time time"
  elif [[ "$right" == "time" ]]; then
    right_elems="time"
  else
    right_elems=""
  fi

  cat > "$OVERRIDES_DST" <<EOF
# .p10k.mrai.zsh — written by Mrai's setup wizard (mrai-configure.sh).
# Mrai's choices, on top of the p10k template in ~/.p10k.zsh.
# Sourced AFTER ~/.p10k.zsh, so every value here wins.
# Re-run mrai-configure.sh to change them. Do NOT edit the skull text.
typeset -g MRAI_RED='$red_hex'
typeset -g MRAI_RED_256=$red_256
typeset -g POWERLEVEL9K_MRAI_FOREGROUND='$red_hex'
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=($left_elems)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=($right_elems)
typeset -g POWERLEVEL9K_MODE=ascii
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=$newline
typeset -g POWERLEVEL9K_DIR_FOREGROUND=15
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=15
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=15
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=$dir_shorten
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=$dir_max
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=$red_256
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_FOREGROUND=$red_256
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_FOREGROUND=$red_256
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIOWR_FOREGROUND=$red_256
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIVIS_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIOWR_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIOWR_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIVIS_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIOWR_CONTENT_EXPANSION='%B$char%b'
typeset -g POWERLEVEL9K_TIME_FOREGROUND=244
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
function prompt_mrai() {
  p10k segment -f "\${POWERLEVEL9K_MRAI_FOREGROUND:-#C62828}" -t '%BMRAI ☠︎︎ TECH%b'
}
function instant_prompt_mrai() {
  prompt_mrai
}
(( ! \$+functions[p10k] )) || p10k reload
EOF
  zsh -n "$OVERRIDES_DST" && echo "Overrides syntax OK."
}

wire_zshrc() {
  # wire_zshrc <autocd on|off> — sources overrides after .p10k.zsh (once),
  # and adds or removes `setopt AUTO_CD` per the wizard's answer.
  local autocd="$1"
  touch "$ZSHRC"
  if ! grep -q "p10k.mrai.zsh" "$ZSHRC"; then
    if grep -q "\.p10k\.zsh" "$ZSHRC"; then
      awk -v hook="$OVERRIDES_LINE" '
        !done && /\.p10k\.zsh/ && !/p10k\.mrai\.zsh/ { print; print hook; done=1; next }
        { print }
      ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
    else
      cat >> "$ZSHRC" <<EOF

# Mrai Powerlevel10k overrides (added by mrai-configure.sh)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
$OVERRIDES_LINE
EOF
    fi
    echo "Wired ~/.zshrc to source .p10k.mrai.zsh after .p10k.zsh."
  fi
  if [[ "$autocd" == "on" ]]; then
    if ! grep -q "setopt AUTO_CD" "$ZSHRC"; then
      cat >> "$ZSHRC" <<'EOF'

# Mrai: type a folder name alone to cd into it (no `cd` needed).
setopt AUTO_CD
EOF
      echo "AUTO_CD on — added setopt AUTO_CD to ~/.zshrc."
    else
      echo "AUTO_CD on — already in ~/.zshrc."
    fi
  else
    if grep -q "setopt AUTO_CD" "$ZSHRC"; then
      sed -i '/setopt AUTO_CD/d' "$ZSHRC"
      echo "AUTO_CD off — removed setopt AUTO_CD from ~/.zshrc."
    else
      echo "AUTO_CD off — not in ~/.zshrc."
    fi
  fi
  zsh -n "$ZSHRC" && echo ".zshrc syntax OK."
}

# --- main ---
MODE="${1:-}"
case "$MODE" in
  --help|-h)
    usage
    exit 0
    ;;
  --restore)
    do_restore
    ;;
  --defaults|"")
    ;;
  *)
    echo "ERROR: unknown option: $MODE"
    usage
    exit 1
    ;;
esac

if ! command -v zsh >/dev/null 2>&1; then
  echo "ERROR: zsh not found. Install it first: pkg install -y zsh"
  exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: ~/.p10k.zsh not found. Run install-termux.sh first."
  exit 1
fi
# Interactive questions need a real terminal, except --defaults.
if [[ "$MODE" != "--defaults" && ( ! -t 0 || ! -t 1 ) ]]; then
  echo "ERROR: Mrai's wizard needs a real terminal."
  echo "Run this in Termux, in zsh, on the phone — not piped, not in a script."
  echo "Or run it with --defaults to apply Mrai defaults without questions."
  echo "Your config was NOT changed. Nothing was backed up or overwritten."
  exit 1
fi

# 1. Back up BEFORE anything changes.
BACKUP="$HOME/.p10k.zsh.bak.$(date +%F-%H%M%S)"
cp "$CONFIG" "$BACKUP"
echo "Backed up ~/.p10k.zsh to $BACKUP"
echo "Restore any time with: bash $SCRIPT_DIR/mrai-configure.sh --restore"
echo ""

# Defaults (Mrai's rules).
LAYOUT="one"; RED_HEX="#C62828"; RED_256="160"; DIR_MODE="short"
GIT="on"; RIGHT="minimal"; AUTOCD="on"; CHAR="➜"

if [[ "$MODE" != "--defaults" ]]; then
  echo "== Mrai setup wizard — your wizard, p10k's template, your rules =="
  echo "Enter = Mrai default. Your answers apply to everything."
  echo ""
  A="$(ask '1 Layout — 1 Lean one-line [default] | 2 Classic two-line: ' 1)"
  case "$A" in 2) LAYOUT="two" ;; *) LAYOUT="one" ;; esac
  A="$(ask '2 Red — 1 #C62828 deep blood red [default] | 2 #690202 dark | 3 #D70000 brighter: ' 1)"
  case "$A" in
    2) RED_HEX="#690202"; RED_256="52"; echo "   Warning: #690202 is very dim on black — you picked it, it is yours." ;;
    3) RED_HEX="#D70000"; RED_256="160" ;;
    *) RED_HEX="#C62828"; RED_256="160" ;;
  esac
  A="$(ask '3 Directory — 1 short/truncated [default] | 2 full path | 3 hide it: ' 1)"
  case "$A" in 2) DIR_MODE="full" ;; 3) DIR_MODE="hide" ;; *) DIR_MODE="short" ;; esac
  A="$(ask '4 Git segment — 1 on [default] | 2 off: ' 1)"
  case "$A" in 2) GIT="off" ;; *) GIT="on" ;; esac
  A="$(ask '5 Right prompt — 1 minimal time + error [default] | 2 time only | 3 off: ' 1)"
  case "$A" in 2) RIGHT="time" ;; 3) RIGHT="off" ;; *) RIGHT="minimal" ;; esac
  A="$(ask '6 AUTO_CD (type a folder to cd, no cd needed) — 1 on [default] | 2 off: ' 1)"
  case "$A" in 2) AUTOCD="off" ;; *) AUTOCD="on" ;; esac
  A="$(ask '7 Prompt char — 1 ➜ [default] | 2 ❯ | 3 $: ' 1)"
  case "$A" in 2) CHAR="❯" ;; 3) CHAR='$' ;; *) CHAR="➜" ;; esac
  echo ""
fi

# 2. Write what was configured, everywhere it touches.
write_overrides "$LAYOUT" "$RED_HEX" "$RED_256" "$DIR_MODE" "$GIT" "$RIGHT" "$CHAR"
wire_zshrc "$AUTOCD"

echo ""
echo "== What you configured — this is what you get =="
echo "  Layout:      $LAYOUT"
echo "  Red:         $RED_HEX"
echo "  Directory:   $DIR_MODE"
echo "  Git segment: $GIT"
echo "  Right prompt: $RIGHT"
echo "  AUTO_CD:     $AUTOCD"
echo "  Prompt char: $CHAR"
echo "  Backup kept at: $BACKUP"
echo ""
echo "Done. Starting zsh — your prompt should read:"
echo "  MRAI ☠︎︎ TECH  <directory>  $CHAR"
exec zsh
