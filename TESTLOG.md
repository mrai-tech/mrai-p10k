# TESTLOG — Mrai Powerlevel10k, live test on this VM

Date: 25 Nov 2026. VM: Ubuntu, x86_64, zsh 5.9, git 2.43.0.
Phone target (NOT tested here): Termux, Samsung Galaxy A06, Android 16,
aarch64, zsh 5.9.2, 4GB RAM. The VM test proves the config + theme load and
render; the phone still needs its own first-run check, because `gitstatusd`
is fetched per-architecture on first launch.

## 0. Clone (upstream, depth-1)

```
mkdir -p ~/workspace/mrai-p10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/workspace/mrai-p10k/powerlevel10k
```

Result: PASS. `LICENSE` present (MIT, romkatv/powerlevel10k).
Folder size after clone: 3.1 MB.

## 1. Truecolour check (does zsh render #C62828?)

```
zsh -c 'print -P "%F{#C62828}TRUECOLOUR%f" | od -c | head -5'
```

Result: PASS. Raw output contained `033 [ 3 8 ; 2 ; 1 9 8 ; 4 0 ; 4 0 m`
— i.e. `38;2;198;40;40`, the exact truecolour for #C62828.

## 2. Syntax check

```
zsh -n ~/workspace/mrai-p10k/.p10k.zsh && echo "SYNTAX-OK"
```

Result: PASS — printed `SYNTAX-OK`.

## 3. Interactive test, piped stdin (first run)

Test `.zshrc` used (`/tmp/mrai-p10k-test/home/.zshrc`):

```
source "$HOME/workspace/mrai-p10k/powerlevel10k/powerlevel10k.zsh-theme"
[[ ! -f "$HOME/workspace/mrai-p10k/.p10k.zsh" ]] || source "$HOME/workspace/mrai-p10k/.p10k.zsh"
```

Commands fed:

```
pwd
p10k reload
cd ~/workspace/mrai-p10k/testdir
pwd
echo MARKER-OK
false
echo MARKER-AFTER-FAIL
exit
```

Run:

```
printf '%s\n' 'pwd' 'p10k reload' 'cd ~/workspace/mrai-p10k/testdir' 'pwd' 'echo MARKER-OK' 'false' 'echo MARKER-AFTER-FAIL' 'exit' \
  | ZDOTDIR=/tmp/mrai-p10k-test/home HOME=/home/hatch TERM=xterm-256color zsh -i > /tmp/mrai-p10k-test/raw.log 2>&1
```

Result: PARTIAL — prompt rendered correctly, but with one error at startup:

```
[ERROR]: gitstatus failed to initialize.
```

Prompt lines (ANSI stripped) from that run:

```
MRAI ☠︎︎ TECH ~/w/mrai-p10k ➜ /home/hatch/workspace/mrai-p10k
MRAI ☠︎︎ TECH ~/w/mrai-p/testdir ➜ /home/hatch/workspace/mrai-p10k/testdir
MRAI ☠︎︎ TECH ~/w/mrai-p/testdir ➜ MARKER-OK
MRAI ☠︎︎ TECH ~/w/mrai-p/testdir ➜ MARKER-AFTER-FAIL
```

Notes from this run:
- MRAI segment rendered in truecolour: raw log contains
  `^[[38;2;198;40;40m^[[1m` immediately before `MRAI ☠︎︎ TECH` — bold #C62828.
- Directory updated on `cd` (`~/w/mrai-p10k` → `~/w/mrai-p/testdir`).
  Truncation is `truncate_to_unique` length 1, so `workspace` shows as `w`,
  `mrai-p10k` as `mrai-p` when it is not the last component. Last component
  is always shown in full.
- `p10k reload` produced no error; the prompt re-rendered after it.
- After `false`, the prompt char colour switched to palette 196
  (raw: `38;5;196`) — error state works.
- The gitstatus error was a first-run / piped-stdin artefact (see §4):
  gitstatusd had not been fetched yet and zsh was not on a real terminal
  (`(anon):setopt:7: can't change option: monitor` in the same log).
  The vcs segment simply showed nothing; nothing else broke.

## 4. Interactive test, real PTY (the decisive run)

```
printf '%s\n' 'cd ~/workspace/mrai-p10k' 'git rev-parse --is-inside-work-tree 2>&1' 'pwd' 'exit' \
  > /tmp/mrai-p10k-test/input.txt
GITSTATUS_LOG_LEVEL=DEBUG ZDOTDIR=/tmp/mrai-p10k-test/home HOME=/home/hatch TERM=xterm-256color \
  script -qec "zsh -i" /tmp/mrai-p10k-test/pty.log < /tmp/mrai-p10k-test/input.txt
```

Result: PASS.

- `[powerlevel10k] fetching gitstatusd .. [ok]` — gitstatusd
  (`gitstatusd-linux-x86_64`) was downloaded and initialised. No gitstatus
  error in this run. On the phone the same step fetches the
  `linux-aarch64` binary (v1.5.4 in upstream `gitstatus/install.info`).
- Prompt lines (ANSI stripped):

```
MRAI ☠︎︎ TECH ~ ➜
MRAI ☠︎︎ TECH ~/w/mrai-p10k ➜
MRAI ☠︎︎ TECH ~/w/mrai-p10k ➜   (right prompt: ✘ 128  10:28)
```

- At home the directory shows `~`. Right prompt shows 24h time `10:28`.
- After the failing `git rev-parse` (exit 128, not a git repo), the right
  prompt showed `✘ 128` — status segment works, error only.
- No wizard, no `p10k configure` prompt in either log
  (`grep -i "wizard|configure"` on both logs: no matches).

## 5. Git segment test (real repo)

```
mkdir -p /tmp/mrai-p10k-test/repo && cd /tmp/mrai-p10k-test/repo
git init -q -b main; git config user.email mrai@test.local; git config user.name Mrai
echo hello > file.txt; git add file.txt; git commit -qm init
echo change >> file.txt
# then in the PTY zsh: cd /tmp/mrai-p10k-test/repo; pwd; git status --short; exit
```

Result: PASS. Prompt line (ANSI stripped):

```
MRAI ☠︎︎ TECH /tmp/m/repo main … !1 ➜
```

`main` = branch, `!1` = 1 unstaged change (`git status --short` confirmed
` M file.txt`). The `…` is upstream Lean's "commit summary" marker. Git
segment is short and correct. (Test repo was in /tmp, not in the deliverable.)

## 6. What was NOT tested here (owed on the phone)

- First run on Termux/aarch64 (gitstatusd linux-aarch64 fetch).
- Rendering on Termux's stock font (config uses `POWERLEVEL9K_MODE=ascii`
  precisely so no Nerd Font is needed, but the skull `☠︎︎` and `➜` still
  need a live look on the A06).
- `install-termux.sh` end-to-end on the phone (it was syntax-checked only:
  `bash -n` — see below). His `~/.bashrc`, banner and `/etc/bash.bashrc`
  were not touched in this test.
- Colour on the phone's actual black terminal background — #C62828 was
  chosen by contrast maths (3.7:1 vs black), not by a phone screenshot.

## 7. Installer syntax check

```
bash -n ~/workspace/mrai-p10k/install-termux.sh && echo OK
```

Result: PASS (run during final verification — see folder listing below).

## Verdict

**PASS on VM, with the §3 caveat recorded honestly.** Config loads, no
wizard, prompt is `MRAI ☠︎︎ TECH <dir> ➜` in bold truecolour #C62828,
directory updates on `cd`, git (short), status-on-error, exec-time
threshold and 24h time are all as configured. The one failure seen
(gitstatus init in the piped test) disappeared in a real PTY once
gitstatusd was fetched, and is documented here rather than hidden.

---

## 8. AUTO_CD + installer re-run (25 Nov 2026, VM)

Cause: on the phone he typed `mrai-p10k/` and `naruto-new-era/` with no
`cd` and got `zsh: permission denied: mrai-p10k/` — zsh AUTO_CD was off.
Fix: `setopt AUTO_CD` in `~/.zshrc` via `install-termux.sh` step 4
(own grep-check, so re-running the installer adds it to an existing
install). NOT in `.p10k.zsh` — options there are local to its function.

### 8a. Installer end-to-end (stubbed pkg/chsh, fake HOME)

```
# fake HOME /tmp/mrai-install-test/home, .zshrc pre-existing with p10k
# lines but no AUTO_CD / overrides; stub pkg + chsh in PATH
PATH=/tmp/mrai-install-test/bin:$PATH HOME=/tmp/mrai-install-test/home \
  TERM=xterm-256color script -qec "bash /home/hatch/workspace/mrai-p10k/install-termux.sh" \
  /tmp/mrai-install-test/install.log < input.txt   # input: pwd, exit
```

Result: PASS. Log lines: `Wired ~/.zshrc to source .p10k.mrai.zsh after
.p10k.zsh.`, `Added setopt AUTO_CD to ~/.zshrc.`, `Config syntax OK.`,
`Overrides syntax OK.`, `.zshrc syntax OK.` Fake `.zshrc` after:

```
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -f ~/.p10k.mrai.zsh ]] || source ~/.p10k.mrai.zsh

# Mrai: type a folder name alone to cd into it (no `cd` needed), from home or anywhere.
setopt AUTO_CD
```

Installer also copied `.p10k.mrai.zsh` and `mrai-configure.sh` into the
fake home, and the final `exec zsh` rendered `MRAI ☠︎︎ TECH /home/hatch ➜`
in `38;2;198;40;40`. (pkg/chsh were stubs; on the phone they are real.)

### 8b. AUTO_CD, real PTY — first run FAILED (my test, not the fix)

Same PTY setup but launched from `/home/hatch` instead of the fake HOME,
so `RED_HAWK` was not under the current directory: `zsh: command not
found: RED_HAWK`. That is correct zsh behaviour — AUTO_CD only cds into
folders under where you are. `..` and an absolute path
(`/tmp/mrai-install-test/home/mrai-p10k`) still worked in that run.

### 8c. AUTO_CD, real PTY — corrected run, PASS

```
HOME=/tmp/mrai-install-test/home ZDOTDIR=/tmp/mrai-install-test/home \
  TERM=xterm-256color script -qec "cd /tmp/mrai-install-test/home && zsh -i" \
  /tmp/mrai-install-test/autocd2.log < input3.txt
# input3.txt: pwd, RED_HAWK, pwd, .., naruto-new-era, pwd, .., mrai-p10k/, pwd, .., echo MARKER-AUTOCD-OK, exit
```

Result: PASS. Prompt lines (ANSI stripped), `pwd` confirming each move:

```
MRAI ☠︎︎ TECH ~ ➜
MRAI ☠︎︎ TECH ~/RED_HAWK ➜        /tmp/mrai-install-test/home/RED_HAWK
MRAI ☠︎︎ TECH ~ ➜                 (after ..)
MRAI ☠︎︎ TECH ~/naruto-new-era ➜  /tmp/mrai-install-test/home/naruto-new-era
MRAI ☠︎︎ TECH ~ ➜                 (after ..)
MRAI ☠︎︎ TECH ~/mrai-p10k ➜       /tmp/mrai-install-test/home/mrai-p10k  (typed `mrai-p10k/`, trailing slash)
MRAI ☠︎︎ TECH ~ ➜                 (after ..)
MARKER-AUTOCD-OK
```

No `permission denied`, no `command not found`. Note for the phone: this
only works for folders under where you are — from `~`, `RED_HAWK` works;
from `/tmp` it does not, and you type the full path instead.

### 8d. Installer idempotency

Ran the installer a second time on the same fake HOME. Result: PASS.
`.zshrc` byte-identical after the second run (`diff` clean);
`setopt AUTO_CD`, `p10k.mrai.zsh` and `powerlevel10k.zsh-theme` each
appear exactly once.

## 9. Safe configure (25 Nov 2026, VM)

New files: `.p10k.mrai.zsh` (overrides only; `prompt_mrai()` copied
verbatim from `.p10k.zsh`, skull bytes verified identical
`e2 98 a0 ef b8 8e ef b8 8e`) and `mrai-configure.sh` (bash, executable).

### 9a. Syntax + help + guards

```
zsh -n ~/workspace/mrai-p10k/.p10k.mrai.zsh && echo SYNTAX-OK
bash -n ~/workspace/mrai-p10k/mrai-configure.sh && echo OK
bash ~/workspace/mrai-p10k/mrai-configure.sh --help
printf '' | bash ~/workspace/mrai-p10k/mrai-configure.sh   # non-TTY
bash ~/workspace/mrai-p10k/mrai-configure.sh --bogus
```

Result: PASS. All syntax checks OK. `--help` prints usage. Non-TTY run
refused with `ERROR: the p10k wizard needs a real terminal. … Your config
was NOT changed.` (exit 1). Unknown option refused with usage (exit 1).

### 9b. Wizard simulation — overrides on top of a generic config, PASS

The real wizard is interactive and cannot be run piped, so the test
simulated its output: `~/.p10k.zsh` = upstream `config/p10k-lean.zsh`
(a generic lean config, no `mrai` segment), `.zshrc` = theme +
wizard config + `setopt AUTO_CD`. Then the exact post-wizard steps from
`mrai-configure.sh` were run: copy `.p10k.mrai.zsh`, wire `.zshrc` with
the same awk, append the hook to the end of `~/.p10k.zsh`.

PTY run (`cd` to the fake home, `zsh -i`; input: `pwd`, `p10k reload`,
`pwd`, `RED_HAWK`, `pwd`, `..`, `echo MARKER-WIZARD-OK`, `exit`):

Result: PASS. First prompt and every prompt after:

```
MRAI ☠︎︎ TECH ~ ➜
MRAI ☠︎︎ TECH ~ ➜                 (after `p10k reload` — overrides survive reload, no loop)
MRAI ☠︎︎ TECH ~/RED_HAWK ➜       (AUTO_CD still works in the same session)
MRAI ☠︎︎ TECH ~ ➜
MARKER-WIZARD-OK
```

Raw log contains `38;2;198;40;40` before `MRAI ☠︎︎ TECH`. No lean
prompt leaked (`❯` / `on main` absent). One observed difference, kept
deliberately: the right-prompt clock showed `11:13:47` (seconds) — that
is the wizard lean config's `TIME_FORMAT`, which the overrides do not
force back, because the brief was to keep the wizard's other choices.
The Mrai parts (red, segment, Layout A, `➜`, dir, ascii, one line) are
the ones re-asserted.

### 9c. `--restore` with the real script, PASS

Fake HOME with a wizard config in place and a backup
`~/.p10k.zsh.bak.2026-11-25-120000` holding the Mrai config. Ran the
real script from `/tmp` (no cd to the repo):

```
HOME=/tmp/mrai-restore-test/home ZDOTDIR=/tmp/mrai-restore-test/home \
  script -qec "cd /tmp && bash /home/hatch/workspace/mrai-p10k/mrai-configure.sh --restore" ...
```

Result: PASS. Log: `Restored ~/.p10k.zsh from …bak.2026-11-25-120000`,
`Installed Mrai overrides`, `Hooked .p10k.mrai.zsh into the end of
~/.p10k.zsh.`, all three syntax checks OK, then zsh started with
`MRAI ☠︎︎ TECH /tmp ➜` in `#C62828` and the clock back to `11:13`
(`HH:MM`, Mrai's format — the restored config sets it).

### 9d. What was NOT tested here (owed on the phone)

- The real `p10k configure` wizard itself, end-to-end: it is
  interactive (questions + preview on a real terminal) and cannot be
  driven from a piped test. `mrai-configure.sh` refuses non-TTY runs
  for exactly that reason; the wizard step must be proven on the A06.
- `install-termux.sh` end-to-end on Termux (pkg/chsh were stubs here).
- First run on Termux/aarch64 (gitstatusd linux-aarch64 fetch).

## 10. Syntax re-check (all files, 25 Nov 2026)

```
zsh -n ~/workspace/mrai-p10k/.p10k.zsh && echo OK
zsh -n ~/workspace/mrai-p10k/.p10k.mrai.zsh && echo OK
bash -n ~/workspace/mrai-p10k/install-termux.sh && echo OK
bash -n ~/workspace/mrai-p10k/mrai-configure.sh && echo OK
```

Result: PASS, all four OK. Red `#C62828` and Layout A
(`MRAI ☠︎︎ TECH <dir> ➜`, one line) unchanged. No GitHub push, no repo
created, no rename, no username change in README/clone URL — the
account rename to `mrai-tech` was still in progress when this was built;
the parent agent updates the URLs and pushes after it lands.

## 11. Mrai setup wizard v2 — your wizard, not p10k's (25 Nov 2026)

v1 wrapped the real `p10k configure` wizard and re-asserted Mrai after
it. v2 (this build) never calls `p10k configure` at all. It is Mrai's
own bash wizard: 7 questions, Enter = Mrai default, answers written
into ~/.p10k.mrai.zsh (sourced after ~/.p10k.zsh, so they win) and,
for AUTO_CD, into ~/.zshrc. Built by the parent agent directly after
the v2 subagent stopped on a runtime file-read flag on README/TESTLOG
(no files were changed by that subagent; the v2 script, tests and this
section are the parent's own work on the project's own files).

Questions: 1 Layout one/two, 2 Red #C62828/#690202/#D70000, 3 Directory
short/full/hide, 4 Git on/off, 5 Right prompt minimal/time/off,
6 AUTO_CD on/off, 7 Prompt char ➜/❯/$.

### 11a. Defaults run, PTY, PASS
Fake HOME /tmp/mrai-wizard-v2/home (real .p10k.zsh + .p10k.mrai.zsh +
powerlevel10k copy, .zshrc with AUTO_CD). Input: 7 blank lines, then
`exit` to the exec'd zsh, under `timeout 20 script -qec`.
Result: backup .p10k.zsh.bak.2026-11-25-121715 created; overrides show
MRAI_RED='#C62828', LEFT=(mrai dir vcs prompt_char), RIGHT=(status
command_execution_time time), PROMPT_ADD_NEWLINE=false,
SHORTEN_STRATEGY=truncate_to_unique, char ➜, AUTO_CD present (1 line).
First run hung in the test harness only because `exec zsh` at the end
opens an interactive shell — expected on the phone; the test was
re-run with an `exit` line fed after the answers.

### 11b. Non-default run, PTY, PASS
Same fake HOME, answers 2,2,2,2,3,2,3 (two-line, #690202, full dir,
git off, right prompt off, AUTO_CD off, char $).
Result: summary printed Layout: two, Red: #690202, Directory: full,
Git: off, Right: off, AUTO_CD: off, Prompt char: $. Overrides show
MRAI_RED='#690202', LEFT=(mrai dir prompt_char) — git gone,
RIGHT=(), PROMPT_ADD_NEWLINE=true, SHORTEN_STRATEGY=truncate_to_last,
DIR_MAX_LENGTH=0, char $. AUTO_CD lines in .zshrc: 0 (removed).
Live prompt in the PTY rendered `MRAI ☠︎︎ TECH hatch $` with colour
`38;2;105;2;2` (#690202) — the chosen red actually rendered.

### 11c. --defaults, --help, non-TTY refusal, --restore, PASS
- `--help`: rc 0, prints the 7 questions + defaults.
- Piped run (no TTY): rc 1, "Mrai's wizard needs a real terminal",
  config NOT changed, nothing backed up.
- `--defaults` (PTY): summary Layout one, Red #C62828, Directory
  short, Git on, Right minimal, AUTO_CD on, char ➜; live prompt
  `38;2;198;40;40` (#C62828) MRAI ☠︎︎ TECH, AUTO_CD back to 1 line.
- `--restore` (PTY): restored newest backup, prompt back to
  `38;2;198;40;40` MRAI ☠︎︎ TECH ➜, overrides back to defaults.
- Skull bytes in the new script verified identical to .p10k.zsh:
  e2 98 a0 ef b8 8e ef b8 8e. `bash -n` on mrai-configure.sh: OK.
  No `p10k configure` invocation in v2 (only mentions in comments).

### 11d. What was NOT tested here (owed on the phone)
- The v2 wizard end-to-end on the A06 itself (real Termux terminal).
- First run on Termux/aarch64 (gitstatusd linux-aarch64 fetch).
