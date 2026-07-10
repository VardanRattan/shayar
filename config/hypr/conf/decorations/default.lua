-- -----------------------------------------------------
-- General window decoration
-- name: "Default"
-- -----------------------------------------------------

hl.config({
    decoration = {
        rounding = dt.spacing.rounding,
        active_opacity = dt.opacity.active,
        inactive_opacity = dt.opacity.inactive,
        fullscreen_opacity = dt.opacity.fullscreen,
        rounding_power = dt.spacing.rounding_power,

        shadow = {
            enabled = true,
            range = dt.spacing.shadow_range,
            color = dt.spacing.shadow_color,
        },

        blur = {
            enabled   = true,
            size      = dt.spacing.blur_size,
            passes    = dt.spacing.blur_passes,
            ignore_opacity = true,
            xray = true,
            vibrancy  = dt.spacing.blur_vibrancy,
        },
    },
})