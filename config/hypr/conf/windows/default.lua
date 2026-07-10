hl.config({
    general = {
        gaps_in  = dt.spacing.gaps_in,
        gaps_out = dt.spacing.gaps_out,
        border_size = dt.spacing.border_size,
        col = {
            active_border   = { colors = {primary, on_primary}, angle = 90 },
            inactive_border = on_primary,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    }
})