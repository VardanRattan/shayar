hl.on("hyprland.start", function ()
    local HOME = os.getenv("HOME")

    -- Wave A: environment + independent daemons (each spawns and returns)
    hl.exec_cmd("bash -c 'dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal &'")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hyprctl setcursor " .. dt.typography.cursor_theme .. " " .. tostring(dt.typography.cursor_size))

    -- Dynamic scaling propagation for HiDPI screens
    local scale_handle = io.popen("hyprctl monitors -j 2>/dev/null")
    if scale_handle then
        local raw_json = scale_handle:read("*a")
        scale_handle:close()
        if raw_json and raw_json ~= "" then
            -- Find focused monitor's scale safely (key-order independent)
            local focused = nil
            for monitor_block in raw_json:gmatch("{[^}]+}") do
                if monitor_block:match('"focused":%s*true') then
                    focused = monitor_block:match('"scale":%s*([%d%.]+)')
                    break
                end
            end
            if not focused then
                focused = raw_json:match('"scale":%s*([%d%.]+)')
            end
            if focused then
                local scale = tonumber(focused)
                if scale and scale > 1.0 then
                    local scale_int = math.floor(scale + 0.5)
                    hl.exec_cmd("hyprctl setenv GDK_SCALE " .. tostring(scale_int))
                    hl.exec_cmd("hyprctl setenv QT_SCALE_FACTOR " .. tostring(scale))
                    hl.exec_cmd("dbus-update-activation-environment --systemd GDK_SCALE QT_SCALE_FACTOR")
                end
            end
        end
    end

    hl.exec_cmd(HOME .. "/.config/shayar/listeners.sh --startall")

    -- Dynamic Polkit agent search
    local polkits = {
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
        "/usr/libexec/polkit-gnome/polkit-gnome-authentication-agent-1",
        "/usr/lib/polkit-kde/polkit-kde-authentication-agent-1",
        "/usr/libexec/polkit-kde/polkit-kde-authentication-agent-1",
        "/usr/lib/xfce4/auth/polkit-gnome-authentication-agent-1",
        "/usr/libexec/polkit-mate-authentication-agent-1"
    }
    local started_polkit = false
    for _, agent in ipairs(polkits) do
        local file = io.open(agent, "r")
        if file then
            file:close()
            hl.exec_cmd(agent)
            started_polkit = true
            break
        end
    end
    if not started_polkit then
        hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1") -- Fallback
    end

    hl.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-autostart")
    hl.exec_cmd(HOME .. "/.config/hypr/scripts/gtk.sh")

    -- Idempotent launchers (guard against duplicates on reload)
    hl.exec_cmd("rm -f " .. HOME .. "/.config/shayar/settings/waybar-disabled")
    hl.exec_cmd("pgrep -x waybar >/dev/null || " .. HOME .. "/.config/waybar/launch.sh")
    hl.exec_cmd("systemctl --user start swaync.service &")
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")
    hl.exec_cmd("pgrep -x qs >/dev/null || qs -p " .. HOME .. "/.config/quickshell/shell.qml")

    -- Load cliphist history
    hl.exec_cmd("wl-paste --watch cliphist store")

end)
