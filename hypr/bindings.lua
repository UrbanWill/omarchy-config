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

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
