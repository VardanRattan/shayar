-- -----------------------------------------------------
-- Animations
-- name "Default"
-- -----------------------------------------------------

--------------------------------------------------------------------------------
-- Animation Master Switch
--------------------------------------------------------------------------------
hl.config({
    animations = {
        enabled = true,
    }
})

--------------------------------------------------------------------------------
-- Animation Curves (Bezier)
--------------------------------------------------------------------------------
-- Bezier curves from design tokens
local function parse_bezier(str)
    local points = {}
    for part in str:gmatch("([^,]+)") do
        local x, y = part:match("(%S+)%s+(%S+)")
        table.insert(points, { tonumber(x), tonumber(y) })
    end
    return points
end

local curves = {
    { "linear", dt.animation.bezier_linear },
    { "md3_standard", dt.animation.bezier_md3_standard },
    { "md3_decel", dt.animation.bezier_md3_decel },
    { "md3_accel", dt.animation.bezier_md3_accel },
    { "overshot", dt.animation.bezier_overshot },
    { "crazyshot", dt.animation.bezier_crazyshot },
    { "hyprnostretch", dt.animation.bezier_hyprnostretch },
    { "menu_decel", dt.animation.bezier_menu_decel },
    { "menu_accel", dt.animation.bezier_menu_accel },
    { "easeInOutCirc", dt.animation.bezier_easeInOutCirc },
    { "easeOutCirc", dt.animation.bezier_easeOutCirc },
    { "easeOutExpo", dt.animation.bezier_easeOutExpo },
    { "softAcDecel", dt.animation.bezier_softAcDecel },
    { "md2", dt.animation.bezier_md2 },
}

for _, c in ipairs(curves) do
    hl.curve(c[1], { type = "bezier", points = parse_bezier(c[2]) })
end

--------------------------------------------------------------------------------
-- Animation Rules
--------------------------------------------------------------------------------
hl.animation({ leaf = "windows", enabled = true, speed = dt.animation.speed_window, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = dt.animation.speed_window, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = dt.animation.speed_window, bezier = "md3_accel", style = "popin 60%" })
hl.animation({ leaf = "border", enabled = true, speed = dt.animation.speed_border, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = dt.animation.speed_fade, bezier = "md3_decel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = dt.animation.speed_layers_in, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = dt.animation.speed_layers_out, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = dt.animation.speed_fade_layers_in, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = dt.animation.speed_fade_layers_out, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = dt.animation.speed_workspace, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = dt.animation.speed_special_workspace, bezier = "md3_decel", style = "slidevert" })