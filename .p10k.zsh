# MRAI POWERLEVEL10K CONFIG — ~/.p10k.zsh
#
# Fork of romkatv/powerlevel10k (MIT), config based on upstream
# config/p10k-lean.zsh, customised for Mrai / Termux / Samsung Galaxy A06.
# Upstream: https://github.com/romkatv/powerlevel10k
# See README.md in this folder for the red, the layout and install steps.
#
# Layout A (one line, Lean style):
#   MRAI ☠︎︎ TECH  <directory>  ➜
# Left, in order: mrai (custom) -> dir -> vcs (git, short) -> prompt_char (➜).
# The prompt char sits AFTER the directory, where you type — that is the
# standard p10k position, and the operative order for this config.
# Right, minimal: status (only on error) -> command_execution_time -> time (24h).
#
# Do NOT run `p10k configure` — it overwrites this file with a wizard config.
# To reload after editing: `p10k reload` or `source ~/.p10k.zsh`.
#
# Colour — the Mrai red:
#   #C62828  RGB (198, 40, 40)  — Material Red 800, deep blood red.
#   #690202  RGB (105, 2, 2) was sampled from his screenshot but REJECTED:
#   its relative luminance is ~0.03, contrast vs a black terminal only
#   ~1.6:1, so even bold it stayed dim / invisible. #C62828 has luminance
#   ~0.14, contrast ~3.7:1, and is still a deep blood red — NOT a light or
#   pink red (#EF5350 / #E57373 would be light; #F06292 would be pink).
#   In p10k's 256-colour palette the nearest rendering is 160 (#D70000,
#   RGB 215,0,0, contrast ~3.9:1). This config uses the exact truecolour
#   #C62828 where p10k/zsh allows it (zsh %F{#RRGGBB}), with 160 as the
#   palette fallback for the prompt char / status segments.
#   MRAI segment foreground: #C62828, bold. Directory: white, bold.

# Temporarily change options.
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options. This allows you to apply configuration changes without
  # restarting zsh. Edit ~/.p10k.zsh and type `source ~/.p10k.zsh`.
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Zsh >= 5.1 is required.
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # Mrai red, single source of truth for this config.
  # Truecolour hex for zsh %F{#...}; 160 is the nearest 256-colour palette entry.
  typeset -g MRAI_RED='#C62828'
  typeset -g MRAI_RED_256=160

  # Left prompt: mrai -> dir -> vcs -> prompt_char, ONE line (no newline).
  # One line, not two: a phone screen is narrow and a two-line Lean prompt
  # eats a full line per command. One line keeps the whole prompt + command
  # visible at once in Termux.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    mrai                    # custom: MRAI ☠︎︎ TECH, bold deep red
    dir                     # current directory (short, truncated)
    vcs                     # git status, short (branch + dirty counts only)
    prompt_char             # ➜ prompt symbol, bold, after the directory
  )

  # Right prompt: minimal. Only shown when it fits; hidden while typing.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # exit code of the last command (error only)
    command_execution_time  # duration of the last command (only if >= 3s)
    time                    # current time, 24h
  )

  # No nerd-font glyphs required. Termux's stock font does not ship a Nerd
  # Font, so `ascii` avoids boxes for missing icons. Our segments use only
  # plain text + ➜, which renders on the stock font.
  typeset -g POWERLEVEL9K_MODE=ascii
  typeset -g POWERLEVEL9K_ICON_PADDING=none

  # Lean look: transparent background, segments separated by a space.
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true

  # One line: no blank line before the prompt, no multiline prefixes.
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX=
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=
  typeset -g POWERLEVEL9K_SHOW_RULER=false

  ####################################[ mrai: MRAI ☠︎︎ TECH ]####################################
  # Custom segment. `mrai` in LEFT_PROMPT_ELEMENTS calls prompt_mrai() below.
  # Foreground: Mrai red #C62828, bold. No background block (Lean style),
  # so the red is the text itself, exactly like his bash PS1.
  # Tweak the red here and in $MRAI_RED above — nowhere else.
  typeset -g POWERLEVEL9K_MRAI_FOREGROUND='#C62828'

  ####################################[ prompt_char: ➜ ]####################################
  # Prompt char: ➜ in both states, bold, Mrai red when the last command
  # succeeded, bright red (196) when it failed.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=160
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='%B➜%b'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='%B➜%b'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='%B➜%b'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='%B➜%b'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=

  ####################################[ dir: current directory ]####################################
  # White + bold so the folder name stands out against the red MRAI text.
  # Short/truncated: on a phone, `~/RED_HAWK` must not eat the whole line.
  # At home it shows `~`; in ~/RED_HAWK it shows `~/RED_HAWK` (shortened to
  # the last components); in a deep path it truncates to unique prefixes.
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=15
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=15
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=15
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=40
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=false
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

  ####################################[ vcs: git status, short ]####################################
  # Short only: branch name, dirty/staged/untracked counts. No full status
  # dump. gitstatus runs in the background, so this stays fast on 4GB RAM.
  # Disabled in $HOME itself (pattern '~') so the home prompt stays clean.
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'
  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1
  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=76
  typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=244
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=76
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178

  # Copied from upstream config/p10k-lean.zsh (MIT) — the short git formatter.
  # Shows branch, then *N staged, +N unstaged, ?N untracked, etc., only when
  # there is something to show. Clean repos show just the branch, in green.
  function my_git_formatter() {
    emulate -L zsh
    if [[ -n $P9K_CONTENT ]]; then
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi
    if (( $1 )); then
      local meta='%f'
      local clean='%76F'
      local modified='%178F'
      local untracked='%76F'
      local conflicted='%196F'
    else
      local meta='%244F'
      local clean='%244F'
      local modified='%244F'
      local untracked='%244F'
      local conflicted='%244F'
    fi
    local res
    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      (( $#branch > 32 )) && branch[13,-13]="…"
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi
    if [[ -n $VCS_STATUS_TAG ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      (( $#tag > 32 )) && tag[13,-13]="…"
      res+="${meta}#${clean}${tag//\%/%%}"
    fi
    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] && res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"
    if [[ -n $VCS_STATUS_REMOTE_BRANCH ]]; then
      local remote=${(V)VCS_STATUS_REMOTE_BRANCH}
      (( $#remote > 32 )) && remote[13,-13]="…"
      res+="${meta}:${clean}${remote//\%/%%}"
    fi
    if [[ $VCS_STATUS_COMMIT_SUMMARY == *[^0-9]* ]]; then
      res+=" ${meta}…"
    elif [[ $VCS_STATUS_COMMITS_AHEAD -gt 0 ]]; then
      res+=" ${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
    fi
    if [[ $VCS_STATUS_COMMITS_BEHIND -gt 0 ]]; then
      res+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
    fi
    if (( VCS_STATUS_STASHES )); then
      res+=" ${clean}*${VCS_STATUS_STASHES}"
    fi
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}?${VCS_STATUS_NUM_UNTRACKED}"
    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null

  ####################################[ status: exit code, error only ]####################################
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='✘'

  ####################################[ command_execution_time ]####################################
  # Only shown when a command took >= 3s. Cheap: no timer work for fast commands.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'

  ####################################[ time: 24h, right prompt ]####################################
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=244
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  # Custom segment: MRAI ☠︎︎ TECH. Called by p10k because `mrai` is in
  # POWERLEVEL9K_LEFT_PROMPT_ELEMENTS above. Text is transcribed glyph for
  # glyph — do not normalise the skull. Foreground is the Mrai red, bold.
  # -f takes the truecolour hex here (zsh %F{#RRGGBB} renders 38;2;198;40;40);
  # if a terminal only does 256 colours, p10k falls back to the palette
  # colour 160 (#D70000) for the prompt char / status segments.
  function prompt_mrai() {
    p10k segment -f "${POWERLEVEL9K_MRAI_FOREGROUND:-#C62828}" -t '%BMRAI ☠︎︎ TECH%b'
  }
  function instant_prompt_mrai() {
    prompt_mrai
  }

  # No transient prompt — the full prompt stays when a command is accepted.
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off

  # Instant prompt: quiet. His .zshrc loads a banner that prints during
  # startup; verbose would warn about that console output on every launch.
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

  # Hot reload off: 1-2 ms faster per prompt, and the config is edited
  # deliberately (p10k reload), not tweaked live.
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  # If p10k is already loaded, reload configuration.
  (( ! $+functions[p10k] )) || p10k reload
}

# Tell `p10k configure` which file it should overwrite.
# (Do not run p10k configure — see the header of this file.)
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
