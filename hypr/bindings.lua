-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Window resizing on ; and / (replaces SUPER + -/= and their SHIFT variants)
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + code:21")
hl.unbind("SUPER + SHIFT + code:20")
hl.unbind("SUPER + SHIFT + code:21")
hl.unbind("SUPER + SLASH") -- was: Monitor scaling up
hl.unbind("SUPER + SHIFT + SLASH") -- was: Passwords
o.bind("SUPER + SEMICOLON", "Widen window", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SLASH", "Narrow window", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + SEMICOLON", "Make window taller", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
o.bind("SUPER + SHIFT + SLASH", "Make window shorter", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))

-- CTRL + A/E/U/K line editing and SUPER + A select all in every app
require("hypr.line-editing")
hl.unbind("SUPER + SHIFT + S") -- was: Google Maps
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
-- Unbind first: older Omarchy binds these keys itself, and a second bind would fire twice.
if o.dictation_installed and o.dictation_installed() then
  hl.unbind("SUPER + CTRL + X")
  hl.unbind("F9")
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end

-- With both Dell monitors connected, Super + 1-5 go to the left monitor's
-- workspaces 1-5 and Super + 6-0 to the right monitor's workspaces 1-5, whichever
-- monitor is focused. SHIFT moves the window there and follows it; SHIFT + ALT
-- moves it silently. Without both (another machine, one monitor unplugged) the
-- keys do what Omarchy's defaults do: workspaces 1-10 of the focused monitor.
local split_left = "desc:Dell Inc. DELL U2422H 36FJRP3"
local split_right = "desc:Dell Inc. DELL U2422H FV8HRP3"

local function both_connected()
  return hl.get_monitor(split_left) ~= nil and hl.get_monitor(split_right) ~= nil
end

local function split_monitor(key)
  return key <= 5 and split_left or split_right, (key - 1) % 5 + 1
end

local function focus_key(key)
  local dual = o.workspaces.focus(select(2, split_monitor(key)), (split_monitor(key)))
  local single = o.workspaces.focus(key)
  return function()
    if both_connected() then dual() else single() end
  end
end

local function move_key(key, follow)
  local single = o.workspaces.move_window(key, follow)
  local name, slot = split_monitor(key)
  local go_there = o.workspaces.focus(slot, name)
  return function()
    if not both_connected() then return single() end
    local monitor = hl.get_monitor(name)
    local window = hl.get_active_window()
    if not window then return end
    local id = o.workspaces.workspace_id(monitor, slot)

    -- Hyprland creates a missing workspace on the focused monitor, so moving to
    -- the other monitor's block would land it on this one. Move the window
    -- without following, put its workspace on the target monitor, then follow.
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(id), follow = false, window = "address:" .. window.address }))
    local workspace = hl.get_workspace(id)
    if workspace and workspace.monitor and workspace.monitor.name ~= monitor.name then
      hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(id), monitor = monitor.name }))
    end
    if follow then
      go_there()
      hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
    end
  end
end

for key = 1, 10 do
  local code = "code:" .. tostring(key + 9)
  local label = key <= 5 and ("left " .. key) or ("right " .. key - 5)
  o.rebind("SUPER + " .. code, "Switch to workspace " .. key % 10 .. " (dual: " .. label .. ")", focus_key(key))
  o.rebind("SUPER + SHIFT + " .. code, "Move window to workspace " .. key % 10, move_key(key, true))
  o.rebind("SUPER + SHIFT + ALT + " .. code, "Move window silently to workspace " .. key % 10, move_key(key, false))
end
