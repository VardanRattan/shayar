-- Load Variant (with layered-config override support)
-- If ~/.config/overrides/hypr/conf/<name>/<file>.lua exists, it wins over the
-- shipped module. This lets users customize keybindings / windows / layouts /
-- monitors / etc. without editing tracked repo files (no merge conflicts on
-- git pull). See config/shayar/docs/overrides.md.
function load_variant(variant_file, variant_name)
    variant_file = variant_file:gsub(".lua", "")
    local rel = "hypr/conf/" .. variant_name .. "/" .. variant_file .. ".lua"
    local path = config_path(rel)
    local shipped = os.getenv("HOME") .. "/.config/" .. rel
    if path ~= shipped then
        dofile(path)
    else
        require("conf." .. variant_name .. "." .. variant_file)
    end
end

-- Layered config: user override path
function config_path(rel)
    local home = os.getenv("HOME")
    local user = home .. "/.config/overrides/" .. rel
    local def  = home .. "/.config/" .. rel
    local f = io.open(user, "r")
    if f then
        f:close()
        return user
    else
        return def
    end
end