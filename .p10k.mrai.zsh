# .p10k.mrai.zsh — Mrai overrides, sourced AFTER ~/.p10k.zsh
#
# This file re-asserts the Mrai identity on top of ANY p10k config — including
# one written by the `p10k configure` wizard. It is overrides ONLY, not a
# second full config: it sets the Mrai red, the left-prompt order, the custom
# `mrai` segment, the prompt char, the directory colours, ascii mode and
# one-line layout, and leaves every other wizard choice alone.
#
# How it is used:
#   ~/.zshrc sources it after ~/.p10k.zsh:
#     [[ ! -f ~/.p10k.zsh ]]      || source ~/.p10k.zsh
#     [[ ! -f ~/.p10k.mrai.zsh ]] || source ~/.p10k.mrai.zsh
#   `mrai-configure.sh` installs it and also appends a hook to ~/.p10k.zsh
#   so the overrides survive a plain `p10k reload` too.
#   Do NOT edit the skull text below — it is transcribed glyph for glyph
#   from .p10k.zsh (skull U+2620 + two U+FE0E).
#
# Mrai red — single source of truth here, same as in .p10k.zsh.
typeset -g MRAI_RED='#C62828'
typeset -g MRAI_RED_256=160
typeset -g POWERLEVEL9K_MRAI_FOREGROUND='#C62828'

# Left prompt, Layout A, one line: MRAI ☠︎︎ TECH -> dir -> vcs -> prompt_char (➜ last).
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(mrai dir vcs prompt_char)

# Right prompt, minimal (same as Mrai's config): status on error, slow-command
# time, 24h clock.
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time time)

# No Nerd Font needed; one line, no blank line before the prompt.
typeset -g POWERLEVEL9K_MODE=ascii
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

# Directory: white + bold.
typeset -g POWERLEVEL9K_DIR_FOREGROUND=15
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=15
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=15
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

# Prompt char: ➜, bold, Mrai red (palette 160) on success, bright red (196) on error.
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=160
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_FOREGROUND=160
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_FOREGROUND=160
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIOWR_FOREGROUND=160
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIVIS_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIOWR_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='%B➜%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_CONTENT_EXPANSION='%B➜%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_CONTENT_EXPANSION='%B➜%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIOWR_CONTENT_EXPANSION='%B➜%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='%B➜%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_CONTENT_EXPANSION='%B➜%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIVIS_CONTENT_EXPANSION='%B➜%b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIOWR_CONTENT_EXPANSION='%B➜%b'

# Custom segment: MRAI ☠︎︎ TECH — copied verbatim from .p10k.zsh.
function prompt_mrai() {
  p10k segment -f "${POWERLEVEL9K_MRAI_FOREGROUND:-#C62828}" -t '%BMRAI ☠︎︎ TECH%b'
}
function instant_prompt_mrai() {
  prompt_mrai
}
# Keep the full prompt on accept, quiet instant prompt, no hot reload.
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

# Apply now if p10k is already loaded. Note: `p10k reload` re-sources
# ~/.p10k.zsh, which (once mrai-configure.sh has run) ends with a hook that
# sources this file again — so the overrides survive a reload.
(( ! $+functions[p10k] )) || p10k reload
