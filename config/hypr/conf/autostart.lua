hl.on("hyprland.start", function ()
    local HOME = os.getenv("HOME")

    -- Wave A: environment + independent daemons (each spawns and returns)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hyprctl setcursor " .. dt.typography.cursor_theme .. " " .. tostring(dt.typography.cursor_size))
    hl.exec_cmd(HOME .. "/.config/shayar/listeners.sh --startall")
    hl.exec_cmd("swayosd-server")
    -- Dynamic Polkit agent search
    local polkits = {
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
        "/usr/libexec/polkit-gnome-authentication-agent-1",
        "/usr/lib/polkit-kde-authentication-agent-1",
        "/usr/libexec/polkit-kde-authentication-agent-1",
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
    hl.exec_cmd("pgrep -x swaync >/dev/null || swaync")
    hl.exec_cmd("pgrep -x hypridle >/dev/null || hypridle")
    hl.exec_cmd("pgrep -x qs >/dev/null || qs -p " .. HOME .. "/.config/quickshell/shell.qml")

    -- Load cliphist history
    hl.exec_cmd("wl-paste --watch cliphist store")

end)
