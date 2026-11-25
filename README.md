# mrai-p10k — Mrai's Powerlevel10k

Mrai's version of Powerlevel10k (p10k) for Termux on his Samsung Galaxy A06.
One line, deep blood red, MRAI TECH first, the folder you're in next, `➜` last.

```
MRAI ☠︎︎ TECH  ~/RED_HAWK  ➜
```

## Upstream + licence

This is a **fork of [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)**,
which is **MIT open source**. The upstream `LICENSE` file is kept in
`powerlevel10k/LICENSE` — do not remove it. The theme code in
`powerlevel10k/` is upstream, cloned `--depth=1` (no huge history).
Only `.p10k.zsh` (the config), `install-termux.sh` and this README are Mrai's.

Repo: **`mrai-p10k` under `mrai-apt`** — the account formerly known as
`adeyanjuadewale17-sys`, renamed 25 Nov 2026 on Mrai's word to `mrai-apt`,
so his personal name is not in the username and the account is not mixed
up with `mrai-driod`. **Pushed live** — see the repo link below.

## The red

**Chosen: `#C62828` — RGB (198, 40, 40), Material Red 800, bold.**

Why not the sampled `#690202` (RGB 105, 2, 2)? That was the exact colour of
the ProxyVault background in his screenshot, and it was tried first — in bash
PS1, then bold. It stayed too dark / invisible on a black terminal:

| Colour | RGB | Relative luminance | Contrast vs black |
|---|---|---|---|
| #690202 (rejected) | 105, 2, 2 | ~0.03 | ~1.6 : 1 |
| **#C62828 (chosen)** | **198, 40, 40** | **~0.14** | **~3.7 : 1** |
| #D32F2F (close alt.) | 211, 47, 47 | ~0.16 | ~4.2 : 1 |
| 256-colour 160 (palette fallback) | 215, 0, 0 | ~0.14 | ~3.9 : 1 |

`#C62828` is still a deep blood red — **not** a light red (`#EF5350`,
`#E57373`) and **not** pink (`#F06292`). Bold makes it read brighter without
changing the hue. In the config, the MRAI segment uses the exact truecolour
`#C62828` (zsh `%F{#C62828}` → `38;2;198;40;40`, verified live); the prompt
char / status segments use palette colour `160` (`#D70000`), the nearest
256-colour rendering of the same red.

Tweak it in `.p10k.zsh` only: `MRAI_RED` / `POWERLEVEL9K_MRAI_FOREGROUND`.

## Layout A

Left prompt, in order:

1. **`mrai`** — custom segment, text `MRAI ☠︎︎ TECH` (transcribed glyph for
   glyph, skull as-is), bold, foreground `#C62828`, transparent background.
2. **`dir`** — current directory, white + bold, short/truncated.
   At home: `~`. In `~/RED_HAWK`: `~/RED_HAWK`. In a deep path it truncates
   to unique prefixes (e.g. `~/w/mrai-p10k`), so it never eats the line.
3. **`vcs`** — git status, short: branch name + dirty counts only
   (e.g. `main !1` = branch `main`, 1 unstaged change). Hidden at home.
4. **`prompt_char`** — `➜`, bold, Mrai red on success, bright red (196)
   on error. It sits **after** the directory, where you type — that is the
   operative order in this config (the shorthand "A" was written as
   `MRAI ☠︎︎ TECH ➜ <directory>`, but p10k puts the prompt char last).

Right prompt, minimal:

- **`status`** — exit code, error only (`✘ 128`), hidden on success.
- **`command_execution_time`** — only if a command took ≥ 3 s.
- **`time`** — 24-hour, `HH:MM` (e.g. `10:28`).

One line, not two (Lean style): a phone screen is narrow and a two-line
prompt eats a full line per command. No heavy segments — no load, RAM,
disk, battery, wifi, IP, or language-version segments. `POWERLEVEL9K_MODE=ascii`
so no Nerd Font is needed; Termux's stock font renders everything here.
Instant prompt is `quiet` (his `.zshrc` banner prints during startup),
hot reload is off (1–2 ms faster per prompt).

## Install on Termux (phone)

```sh
pkg install -y zsh git
git clone https://github.com/mrai-apt/mrai-p10k.git ~/mrai-p10k
cd ~/mrai-p10k
bash install-termux.sh
```

That installs zsh/git if missing, puts p10k at `~/powerlevel10k`, copies
`.p10k.zsh` to `~/.p10k.zsh`, wires `~/.zshrc`, and switches to zsh
(`chsh -s zsh`, then `exec zsh`). First zsh launch fetches `gitstatusd`
for linux-aarch64 (one-time, a few MB) — normal, it powers the git segment.

Manual steps, if you prefer:

```sh
pkg install -y zsh git
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
cp ~/mrai-p10k/.p10k.zsh ~/.p10k.zsh
# add to ~/.zshrc:
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
chsh -s zsh
exec zsh
```

If `pkg install` fails with a 429 / mirror error, run `termux-change-repo`
first and pick a working mirror (grimler.se or packages.termux.dev).

**Safe by design:** the installer does **not** touch `~/.bashrc` (your bash
PS1 stays as-is), does **not** delete your MRAI banner, does **not** touch
`/etc/bash.bashrc`, and does **not** run `p10k configure`.
p10k only works in zsh, not bash — that is why the install switches shells.

## Switch back to bash

```sh
chsh -s bash
exec bash
```

Your bash prompt from `~/.bashrc` (`MRAI ☠︎︎ TECH ➜ ` in #690202) is still
there, untouched.

## Tweak it

```sh
nano ~/.p10k.zsh   # or your editor
p10k reload        # apply, no restart needed
```

- **Red:** change `MRAI_RED` / `POWERLEVEL9K_MRAI_FOREGROUND` at the top
  of the config (hex `#RRGGBB` or a 0–255 palette number).
- **Directory:** `POWERLEVEL9K_DIR_FOREGROUND` (15 = white),
  `POWERLEVEL9K_DIR_MAX_LENGTH` (40), `POWERLEVEL9K_SHORTEN_DIR_LENGTH` (1).
- **Prompt char:** `POWERLEVEL9K_PROMPT_CHAR_*_CONTENT_EXPANSION` (currently `➜`).
- **Right prompt:** add/remove `status`, `command_execution_time`, `time`
  in `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`.

**Do not run `p10k configure`** — the wizard overwrites `~/.p10k.zsh`
with its own config and your Mrai segments are lost. Edit the file instead.

## Files in this folder

| File | What it is |
|---|---|
| `powerlevel10k/` | Upstream p10k, `--depth=1` clone, MIT `LICENSE` kept |
| `.p10k.zsh` | Mrai config (the whole prompt) |
| `install-termux.sh` | Termux installer (idempotent, safe — see its header) |
| `README.md` | This file |
| `TESTLOG.md` | Live-test commands + output from this VM |

## Live test

Live-tested in zsh on this VM — see `TESTLOG.md`. Prompt rendered as
`MRAI ☠︎︎ TECH ~/w/mrai-p10k ➜` (truecolour `#C62828`, bold), directory
updated on `cd`, git showed `main … !1` in a test repo, right prompt showed
`10:28` and `✘ 128` after a failing command, `p10k reload` worked, and the
config loaded with no wizard. Phone test (aarch64, Termux) is still owed —
the VM is x86_64, so `gitstatusd` is fetched fresh on the phone's first run.
