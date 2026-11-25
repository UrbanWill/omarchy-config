-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Android emulator: tiled, its window stretches to the tile and paints the phone
-- in a corner (and shakes on resize). Float it at its own size instead.
o.window("^Emulator$", { float = true, center = true })

-- btop needs at least 80x24 cells, and the shared 875x600 float is one row short
-- at this font size. Size rules can't beat the floating-window tag, so btop runs
-- under its own app-id (see bindings.lua) and floats without that tag.
o.window("org.omarchy.activity", { float = true, center = true, size = { 1100, 700 } })
