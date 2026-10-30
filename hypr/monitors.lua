-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.25

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- Dual Dell U2422H: left (serial 36FJRP3) and right (serial FV8HRP3)
local left_monitor = "desc:Dell Inc. DELL U2422H 36FJRP3"
local right_monitor = "desc:Dell Inc. DELL U2422H FV8HRP3"

hl.monitor({ output = left_monitor, mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = right_monitor, mode = "1920x1080@60", position = "1920x0", scale = 1 })

-- Workspaces 1-5 on the left monitor, 6-10 on the right
for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = i <= 5 and left_monitor or right_monitor, default = i == 1 or i == 6 })
end
