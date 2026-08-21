--    __  _____  _____      __  ____  ____
--   /  |/  / / / / / | /| / / / __ \/ __/
--  / /|_/ / /_/_  _/ |/ |/ / / /_/ /\ \  
-- /_/  /_/____//_/ |__/|__/  \____/___/
--   
-- Advanced configuration for Hyprland

-- FUNCTIONS
require("functions")

-- MONITORS
require("monitors")

-- INPUT
require("input")

-- GESTURE
require("gestures")

-- AUTOSTART
require("conf.autostart")

-- COLORS
require("colors")

-- DESIGN TOKENS
require("design-tokens")

-- CONFIGURATION
require("conf.environment")
require("conf.window")
require("conf.decoration")
require("conf.layout")
require("conf.workspace")
require("conf.misc")
require("conf.keybinding")
require("conf.windowrule")
require("conf.animation")
require("conf.shayar")

-- CUSTOM
local f = io.open(os.getenv("HOME") .. "/.config/hypr/custom.lua", "r")
if f then
    f:close()
    local ok, err = pcall(require, "custom")
    if not ok then
        print("[ERROR] Failed to load custom.lua: " .. tostring(err))
    end
end

