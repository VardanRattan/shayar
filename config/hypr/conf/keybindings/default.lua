-- Configuration
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local HOME = os.getenv("HOME")

-- Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(HOME .. "/.config/shayar/settings/terminal.sh"), { description = "Open the terminal" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(HOME .. "/.config/shayar/settings/browser.sh"), { description = "Open the browser" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-toggle-statusbar"), { description = "Toggle statusbar" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(HOME .. "/.config/shayar/settings/filemanager"), { description = "Open the filemanager" })
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd(HOME .. "/.config/shayar/settings/emojipicker.sh"), { description = "Open the emoji picker" })
hl.bind(mainMod .. " + CTRL + c", hl.dsp.exec_cmd(HOME .. "/.config/shayar/settings/calculator.sh"), { description = "Open the calculator" })

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}), { description = "Focus workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
end

-- Windows
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Kill active window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Toggle Fullscreen" })
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating" })
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle split" })
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }), { description = "Move focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Move focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }), { description = "Move focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }), { description = "Move focus down" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window with the mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window with the mouse" })

-- Actions
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("shayar-menu"), { description = "Open unified settings menu" })
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("shayar-screenshot"), { description = "Take a screenshot" })
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-wallpaper --random"), { description = "Open wallpaper selector" })
hl.bind(mainMod .. " + CTRL + RETURN", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/launcher.sh"), { description = "Open application launcher" })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/keybindings.sh"), { description = "Show keybindings" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-cliphist"), { description = "Open clipboard manager" })


hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd(HOME .. "/.config/shayar/bin/shayar-power-toggle"), { description = "Open power menu" })
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd(HOME .. "/.config/shayar/bin/shayar-net-toggle"),  { description = "Network applet" })
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(HOME .. "/.config/shayar/bin/shayar-bt-toggle"),   { description = "Bluetooth applet" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-power -l"), { description = "Lock Screen directly" })

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"), { description = "Toggle special workspace magic" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(HOME .. "/.config/shayar/scripts/shayar-toggle-scratchpad-window"), { description = "Toggle window in/out of special workspace magic" })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Switch to next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Switch to previous workspace" })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume 5"),               { locked = true, repeating = true, description = "Raise volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"),              { locked = true, repeating = true, description = "Lower volume" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),     { locked = true, repeating = true, description = "Mute audio" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),      { locked = true, repeating = true, description = "Mute microphone" })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("swayosd-client --brightness 5"),                  { locked = true, repeating = true, description = "Increase brightness" })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("swayosd-client --brightness -5"),                 { locked = true, repeating = true, description = "Decrease brightness" })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Pause audio" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play audio" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Previous track" })
