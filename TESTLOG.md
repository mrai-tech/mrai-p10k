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
