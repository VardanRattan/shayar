-------------------------------------------------------
-- Custom Hyprland User Configuration
-------------------------------------------------------

local HOME = os.getenv("HOME")
local mainMod = "SUPER"

-- Display switcher menu (Super + P: Mirror, Extend Right, Extend Left, Pull All, Laptop Only, External Only)
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/display-switch.sh"), { description = "Display Switcher Menu" })

-- Emergency escape to laptop screen (Super + BackSpace)
hl.bind(mainMod .. " + BackSpace", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/escape-monitor.sh"), { description = "Escape to laptop screen" })

-- Pull current workspace to laptop screen (Super + Shift + BackSpace)
hl.bind(mainMod .. " + SHIFT + BackSpace", hl.dsp.workspace.move({ monitor = "eDP-1" }), { description = "Pull workspace to laptop screen" })

-- Pull ALL workspaces and windows back to laptop screen (Super + Ctrl + BackSpace & Super + Escape)
hl.bind(mainMod .. " + CTRL + BackSpace", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/pull-all.sh"), { description = "Pull ALL windows and workspaces to laptop" })
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/pull-all.sh"), { description = "Pull ALL windows and workspaces to laptop" })
