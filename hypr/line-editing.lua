-- Mac-style line editing in every app:
--   CTRL + A / E   jump to start / end of line
--   CTRL + U / K   delete everything before / after the cursor
--   CTRL + SHIFT + Backspace   delete the word after the cursor
--   SUPER + A      select all (in terminals: copy the whole scrollback)
--   SUPER + Z      undo, with SHIFT redo
--
-- Terminals already do the line actions with these exact keys, so they get the
-- original chord back. Everything else gets the equivalent Home/End sequence.
-- Keys are sent with explicit mods (like Omarchy's universal clipboard) so the
-- physically held CTRL doesn't merge into them, e.g. SHIFT + Home becoming
-- CTRL + SHIFT + Home and selecting to the start of the document.

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

-- Press and release each { mods, key } in order. The down/up split mirrors
-- Omarchy's clipboard bindings, which avoids stuck synthetic keys.
local function send_keys(steps)
  for index, step in ipairs(steps) do
    local start = (index - 1) * 60

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = step[1], key = step[2], state = "down" }))
    end, { timeout = start + 1, type = "oneshot" })

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = step[1], key = step[2], state = "up" }))
    end, { timeout = start + 30, type = "oneshot" })
  end
end

-- VS Code hosts a terminal Hyprland can't see focus inside, so it gets the
-- original chord and maps it per focus in keybindings.json.
local function active_window_is_vscode()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  local class = window.class or window.initial_class
  return class == "code" or class == "Code" or class == "com.microsoft.VSCode"
end

local function per_app(terminal_steps, app_steps, vscode_steps)
  return function()
    if vscode_steps and active_window_is_vscode() then
      send_keys(vscode_steps)
    else
      send_keys(active_window_is_terminal() and terminal_steps or app_steps)
    end
  end
end

o.bind("CTRL + A", "Jump to start of line", per_app({ { "CTRL", "A" } }, { { "", "Home" } }))
o.bind("CTRL + E", "Jump to end of line", per_app({ { "CTRL", "E" } }, { { "", "End" } }))
o.bind("CTRL + U", "Delete to start of line", per_app({ { "CTRL", "U" } }, { { "SHIFT", "Home" }, { "", "BackSpace" } }, { { "CTRL", "U" } }))
o.bind("CTRL + K", "Delete to end of line", per_app({ { "CTRL", "K" } }, { { "SHIFT", "End" }, { "", "Delete" } }))

-- Every app gets CTRL + Delete, which deletes the next word in GUI apps and VS
-- Code. Terminals send it as ^[[3;5~, which zshrc binds to kill-word.
o.bind("CTRL + SHIFT + BACKSPACE", "Delete word after cursor", function()
  send_keys({ { "CTRL", "Delete" } })
end)

-- foot binds SUPER + A to piping its scrollback into wl-copy (see foot.ini).
-- Newer Omarchy binds SUPER + A to select all itself; unbind it so only this one fires.
hl.unbind("SUPER + A")
o.bind("SUPER + A", "Select all", per_app({ { "SUPER", "A" } }, { { "CTRL", "A" } }))

-- CTRL + Z would suspend the running program in a terminal, so terminals get
-- the shell's own undo (CTRL + _). For redo they get CTRL + SHIFT + Z, which
-- Ghostty sends as CSI 122;6u rather than CTRL + Z (see ghostty/config); zshrc
-- binds that to redo, and Neovim maps it in insert mode.
o.bind("SUPER + Z", "Undo", per_app({ { "CTRL SHIFT", "minus" } }, { { "CTRL", "Z" } }))
o.bind("SUPER + SHIFT + Z", "Redo", per_app({ { "CTRL SHIFT", "Z" } }, { { "CTRL SHIFT", "Z" } }))
