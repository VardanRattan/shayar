hl.on("hyprland.start", function ()
    local HOME = os.getenv("HOME")

    -- Wave A: Core environment, shell & daemons in parallel
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("pgrep -x qs >/dev/null || caelestia shell -d")
    hl.exec_cmd("hyprctl setcursor " .. dt.typography.cursor_theme .. " " .. tostring(dt.typography.cursor_size))

    -- Dynamic scaling propagation for HiDPI screens (async)
    hl.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-scale-sync &")

    -- Background services & listeners (non-blocking)
    hl.exec_cmd(HOME .. "/.config/shayar/listeners.sh --startall &")

    -- Dynamic Polkit agent search
    local polkits = {
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
        "/usr/libexec/polkit-gnome/polkit-gnome-authentication-agent-1",
        "/usr/lib/polkit-kde-authentication-agent-1",
        "/usr/lib/polkit-kde/polkit-kde-authentication-agent-1",
        "/usr/libexec/polkit-kde/polkit-kde-authentication-agent-1",
        "/usr/lib/xfce4/auth/polkit-gnome-authentication-agent-1",
        "/usr/libexec/polkit-mate-authentication-agent-1"
    }
    for _, agent in ipairs(polkits) do
        local file = io.open(agent, "r")
        if file then
            file:close()
            hl.exec_cmd(agent .. " &")
            break
        end
    end

    -- Wallpaper sync & GTK theme (async background)
    hl.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-autostart &")
    hl.exec_cmd(HOME .. "/.config/hypr/scripts/gtk.sh &")

    -- Idle daemon & clipboard watcher
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")
end)
