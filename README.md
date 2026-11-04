# Omarchy config

My customizations on top of [Omarchy](https://omarchy.org/): Hyprland, the Omarchy shell, the Ghostty and foot terminals, zsh and the Starship prompt.

The git history starts with the config as Omarchy installed it, then adds one commit per customization, so each one can be inspected or reverted on its own.

## How this repo works

The repository lives in `~/Projects/omarchy-config`, but its work tree is `~/.config` (`core.worktree`), so git tracks the live files in place. No copies, no symlinks: Omarchy scripts rewrite files with `sed -i` and would silently replace a symlink.

Only files added explicitly are tracked, and untracked files are hidden from `git status` (`status.showUntrackedFiles=no`).

```bash
cd ~/Projects/omarchy-config
git status                      # what changed since the last commit
git diff                        # exact lines
git add ~/.config/foo/bar.conf  # start tracking a new file
git log --oneline               # every customization
git revert <commit>             # undo one customization
```

After reverting a Hyprland change, run `hyprctl reload && hyprctl configerrors`. After reverting a shell plugin change, run `omarchy restart shell`.

## Several machines

Every machine uses the same `main` branch. Commit on one, `git push`, then `git pull` on the other, followed by `hyprctl reload && hyprctl configerrors` and `omarchy restart terminal`.

Files that only fit one machine's hardware stay tracked but are marked `skip-worktree` on the machines where they don't fit. Git then leaves the local copy alone and never shows it in `git status`:

| File | Why it's per machine |
|---|---|
| `hypr/monitors.lua` | the dual Dell layout and scale; other machines set their displays from the bar's monitor panel |
| `hypr/hyprland.lua` | VM-only Hyprland quirks |
| `omarchy/shell.json` | bar layout (the per-monitor workspace widget only matters with two screens) and idle timers |

```bash
git ls-files -v | grep '^S'                       # files kept local on this machine
git update-index --skip-worktree <file>           # keep a file local
git update-index --no-skip-worktree <file>        # sync it again
```

If a `git pull` changes a skipped file, git stops with "would be overwritten". Run `--no-skip-worktree` on it, `git stash`, pull, merge by hand, then skip it again.

### Setting up another machine

Back up `~/.config` first: `git checkout` overwrites the files it writes.

```bash
git clone https://github.com/UrbanWill/omarchy-config.git ~/Projects/omarchy-config
cd ~/Projects/omarchy-config
git config core.worktree ~/.config
git config status.showUntrackedFiles no
git update-index --skip-worktree hypr/monitors.lua hypr/hyprland.lua omarchy/shell.json
find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +   # drop the clone's own copies
git checkout -- .                                 # write the shared files into ~/.config
omarchy install terminal ghostty
omarchy pkg add omarchy-zsh zsh-autosuggestions mosh
omarchy-setup-zsh
ln -sf ~/.config/zsh/zshrc ~/.zshrc
hyprctl reload && hyprctl configerrors
```

## Customizations

### Dual monitors with split workspaces
- **Files:** `hypr/monitors.lua`
- **What:** left Dell U2422H (serial 36FJRP3) at `0x0`, right (serial FV8HRP3) at `1920x0`, both 1920x1080@60, scale 1. Monitors are matched by serial, so swapping cables between ports keeps the layout. Workspaces 1–5 are bound to the left monitor, 6–10 to the right.
- **Trade-offs:** the explicit `scale = 1` wins over Omarchy's scaling shortcut after any config reload. To change scale permanently, edit these lines.
- **Check:** `hyprctl workspaces -j | jq -r '.[] | "\(.id) -> \(.monitor)"'`

### Per-monitor workspace widget in the bar
- **Files:** `omarchy/plugins/urban.workspaces/`, `omarchy/shell.json`
- **What:** a clone of `omarchy.workspaces`. Each bar shows the five workspaces of its own screen (screens ordered left to right) plus any other workspace on that screen, and marks that screen's active workspace.
- **Trade-offs:** the clone no longer receives Omarchy's updates to the stock widget. Hot reload doesn't apply edits to this file, so run `omarchy restart shell` after changing it.
- **Check:** each bar shows its own numbers (left 1–5, right 6–0).

### Window resizing on `;` and `/`
- **Files:** `hypr/bindings.lua`
- **What:** `SUPER + ;` wider, `SUPER + /` narrower, add `SHIFT` for height, 100px per press. Small (`ALT`, 25px) and large (`CTRL`, 300px) steps remain on Omarchy's `-` / `=` keys.
- **Overrides:** `SUPER + /` was *Monitor scaling up*; `SUPER + SHIFT + /` was *Passwords* (1Password) and has no shortcut now. `SUPER + -` / `=` (with or without `SHIFT`) are unbound.
- **Known quirk:** in tiling layouts the keys move the shared border, so on a window in the right or bottom half "wider" or "taller" shrinks it.

### Screenshot on `SUPER + SHIFT + S`
- **Files:** `hypr/bindings.lua`
- **What:** `SUPER + SHIFT + S` runs `omarchy-capture-screenshot`, like Windows' `WIN + SHIFT + S`.
- **Overrides:** `SUPER + SHIFT + S` was *Google Maps*.

### Screensaver after 5 minutes, screen lock after 15
- **Files:** `omarchy/shell.json`
- **What:** `idle.screensaver` is 300 seconds (was 150) and `idle.lock` is 900 seconds (was 300).

### Bar layout
- **Files:** `omarchy/shell.json`
- **What:** the clock sits alone in the center, with the status indicators just before it and a world clock (`omarchy.elsewhen`: Bangkok, Los Angeles, New York, London, Dubai), weather and system updates after it. The keyboard layout moves to the right, after the tray, and the monitor button is last, after power.
- **Check:** `omarchy restart shell` if the bar doesn't pick up the change.

### Mac-style line editing in every app
- **Files:** `hypr/line-editing.lua`, `hypr/bindings.lua` (loads it), `Code/User/keybindings.json`, `foot/foot.ini`, `zsh/zshrc` (`CTRL + Backspace` and `CTRL + Delete` word deletion)
- **What:**

  | Keys | Action | Sent to GUI apps | Sent to terminals |
  |---|---|---|---|
  | `CTRL + A` | start of line | `Home` | `CTRL + A` |
  | `CTRL + E` | end of line | `End` | `CTRL + E` |
  | `CTRL + U` | delete before cursor | `SHIFT + Home`, `BackSpace` | `CTRL + U` |
  | `CTRL + K` | delete after cursor | `SHIFT + End`, `Delete` | `CTRL + K` |
  | `CTRL + SHIFT + BackSpace` | delete word after cursor | `CTRL + Delete` | `CTRL + Delete` → zsh `kill-word` |
  | `SUPER + A` | select all | `CTRL + A` | `SUPER + A` → Ghostty selects all, foot copies its scrollback |

  Terminals are detected with Omarchy's `terminal` window tag. Keys are sent with explicit modifiers so the physically held `CTRL` doesn't leak into them.

  VS Code hosts a terminal Hyprland can't see focus inside, so it gets a plain `CTRL + U`. `Code/User/keybindings.json` turns that into *delete to start of line* in the editor and lets it reach the shell in the integrated terminal. The same file pastes with `CTRL + V` and passes `CTRL + R` (history search) to the shell in the integrated terminal.
- **Overrides:** in every GUI app, `CTRL + A` (select all, now `SUPER + A`), `CTRL + K` (link insertion, command palettes, VS Code and Zed `CTRL + K` chords), `CTRL + U` (underline, view source) and `CTRL + E` (center align, browser search).
- **Known quirks:** at the start or end of a line, `CTRL + U` / `CTRL + K` delete the line break and join lines. The foot `SUPER + A` binding only applies to terminal windows opened after the change.
- **Check:** in a text field, put the cursor mid-line and try each key.

### Undo and redo on `SUPER + Z`
- **Files:** `hypr/line-editing.lua`
- **What:** `SUPER + Z` undoes, `SUPER + SHIFT + Z` redoes, matching Omarchy's `SUPER + C` / `V` / `X`.

  | Keys | Sent to GUI apps | Sent to terminals |
  |---|---|---|
  | `SUPER + Z` | `CTRL + Z` | `CTRL + _` (shell undo) |
  | `SUPER + SHIFT + Z` | `CTRL + SHIFT + Z` | nothing |

- **Why terminals differ:** `CTRL + Z` in a terminal suspends the running program. The shell has no redo.
- **Known quirks:** apps that only accept `CTRL + Y` for redo won't redo. Inside Neovim, `SUPER + Z` does nothing; use `u` / `CTRL + R`.

### Ghostty as the terminal
- **Files:** `xdg-terminals.list`, `ghostty/config`
- **What:** installed with `omarchy install terminal ghostty`, which makes it the terminal for `SUPER + Return` and every terminal Omarchy opens. `ghostty/config` is Omarchy's default plus `SUPER + A` to select all (then `SUPER + C` copies) and a 96% opaque background (`background-opacity`). foot stays installed, and its config is kept.
- **Check:** `SUPER + Return`, then `hyprctl activewindow | grep class` shows `com.mitchellh.ghostty`.

### zsh
- **Files:** `zsh/zshrc`
- **What:** zsh from `omarchy-zsh` (`omarchy-setup-zsh`), plus:
  - gray autosuggestions from history (`zsh-autosuggestions` package), `→` accepts
  - `CTRL + U` deletes only before the cursor, like bash and macOS (zsh's default deletes the whole line)
  - `~/.local/bin` on `PATH`
  - `t3gui` opens the T3 Code desktop app on this machine's screen, also from an SSH session, so the app's own server is the only one running
- **Per machine:** aliases and functions that only make sense on one machine, such as SSH shortcuts to the other machines, go in `~/.config/zsh/local.zsh`. `zsh/zshrc` sources it last when it exists. It isn't tracked, so each machine keeps its own, and a machine without one starts normally.
- **How it's tracked:** `~/.zshrc` is a symlink to `~/.config/zsh/zshrc`, the one exception to the no-symlinks rule. zsh only reads `~/.zshrc`, and installers that append to it write through the symlink into the tracked file, so their changes show up in `git status`. If a tool replaces the symlink with a regular file, `ls -la ~/.zshrc` shows it; merge the new lines into `zsh/zshrc` and recreate the link with `ln -sf ~/.config/zsh/zshrc ~/.zshrc`.
- **Check:** in a new terminal, `echo $0` prints `zsh`.

### Git details and language versions in the prompt
- **Files:** `starship.toml`
- **What:** the Starship prompt also shows:
  - git stash, staged, renamed and deleted counts (`≡2 +1 »1 ✘1`), next to Omarchy's ahead/behind, modified and untracked markers
  - the current git operation, e.g. `(MERGING)` or `(REBASING 2/5)`
  - Node, Python, Rust, Ruby, Java and Go versions, only inside projects that use them
- **Trade-offs:** `omarchy refresh` on this file resets it to Omarchy's default.
- **Check:** `cd` into a git repo with a `package.json` and look at the prompt.

### Slightly rounded window corners
- **Files:** `hypr/looknfeel.lua`
- **What:** `decoration.rounding = 6` (Omarchy's default is 0, square corners). Bigger numbers are rounder; Omarchy's popped windows use 8.

### Monitor scale written by Omarchy
- **Files:** `hypr/monitors.lua`
- **What:** Omarchy's scaling shortcut set the catch-all scale to 1.25 and `GDK_SCALE` to 1. The two Dells keep their explicit scale 1; `GDK_SCALE` 1 renders GTK apps at normal size.

## After each `omarchy update`

1. `hyprctl reload && hyprctl configerrors` — the config still loads.
2. `omarchy menu keybindings --print | grep -E 'SEMICOLON|SLASH|CTRL \+ [AEKU] |SUPER \+ A '` — custom bindings still win.
3. `diff /usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml ~/.config/omarchy/plugins/urban.workspaces/Workspaces.qml` — pick up upstream fixes to the widget.
4. `git status` — check whether the update rewrote any tracked file.
5. `ls -la ~/.zshrc` — still a symlink to `~/.config/zsh/zshrc`.
