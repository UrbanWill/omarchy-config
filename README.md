# Omarchy config

My customizations on top of [Omarchy](https://omarchy.org/): Hyprland, the Omarchy shell and the foot terminal.

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

### Screen lock after 15 minutes
- **Files:** `omarchy/shell.json`
- **What:** `idle.lock` is 900 seconds (was 300). Screensaver unchanged at 150 seconds.

### Mac-style line editing in every app
- **Files:** `hypr/line-editing.lua`, `hypr/bindings.lua` (loads it), `foot/foot.ini`
- **What:**

  | Keys | Action | Sent to GUI apps | Sent to terminals |
  |---|---|---|---|
  | `CTRL + A` | start of line | `Home` | `CTRL + A` |
  | `CTRL + E` | end of line | `End` | `CTRL + E` |
  | `CTRL + U` | delete before cursor | `SHIFT + Home`, `BackSpace` | `CTRL + U` |
  | `CTRL + K` | delete after cursor | `SHIFT + End`, `Delete` | `CTRL + K` |
  | `SUPER + A` | select all | `CTRL + A` | `SUPER + A` → foot copies its scrollback |

  Terminals are detected with Omarchy's `terminal` window tag. Keys are sent with explicit modifiers so the physically held `CTRL` doesn't leak into them.
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

### Git details and language versions in the prompt
- **Files:** `starship.toml`
- **What:** the Starship prompt also shows:
  - git stash, staged, renamed and deleted counts (`≡2 +1 »1 ✘1`), next to Omarchy's ahead/behind, modified and untracked markers
  - the current git operation, e.g. `(MERGING)` or `(REBASING 2/5)`
  - Node, Python, Rust, Ruby, Java and Go versions, only inside projects that use them
- **Trade-offs:** `omarchy refresh` on this file resets it to Omarchy's default.
- **Check:** `cd` into a git repo with a `package.json` and look at the prompt.

### Monitor scale written by Omarchy
- **Files:** `hypr/monitors.lua`
- **What:** Omarchy's scaling shortcut set the catch-all scale to 1.25 and `GDK_SCALE` to 1. The two Dells keep their explicit scale 1; `GDK_SCALE` 1 renders GTK apps at normal size.

## After each `omarchy update`

1. `hyprctl reload && hyprctl configerrors` — the config still loads.
2. `omarchy menu keybindings --print | grep -E 'SEMICOLON|SLASH|CTRL \+ [AEKU] |SUPER \+ A '` — custom bindings still win.
3. `diff /usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml ~/.config/omarchy/plugins/urban.workspaces/Workspaces.qml` — pick up upstream fixes to the widget.
4. `git status` — check whether the update rewrote any tracked file.
