#!/usr/bin/env python3
import os
import sys
import json
import re

def get_env_or_default(key, default):
    return os.environ.get(key, default)

def flatten_dict(d, prefix="", sep="-"):
    items = []
    for k, v in d.items():
        new_key = f"{prefix}{sep}{k}" if prefix else k
        # Lowercase and replace underscores with hyphens
        new_key = new_key.lower().replace("_", "-")
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

def generate_css(flat_tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens.css")
    with open(out_path, "w") as f:
        f.write("/* Generated from design-tokens.json — DO NOT EDIT */\n")
        for k, v in flat_tokens.items():
            f.write(f"@define-color dt-{k} {v};\n")
    print(f"Generated: {out_path}")

def generate_lua(tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens.lua")
    lines = ["-- Generated from design-tokens.json -- DO NOT EDIT", "dt = {}"]
    
    def emit(d, prefix=""):
        for k, v in d.items():
            # Escape key quotes
            k_esc = k.replace('"', '\\"')
            tbl = f"dt{prefix}"
            if isinstance(v, dict):
                lines.append(f'{tbl}["{k_esc}"] = {{}}')
                emit(v, f'{prefix}["{k_esc}"]')
            elif isinstance(v, str):
                v_esc = v.replace('"', '\\"')
                lines.append(f'{tbl}["{k_esc}"] = "{v_esc}"')
            elif isinstance(v, bool):
                lines.append(f'{tbl}["{k_esc}"] = {str(v).lower()}')
            else:
                lines.append(f'{tbl}["{k_esc}"] = {v}')
                
    emit(tokens)
    with open(out_path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated: {out_path}")

def generate_rasi(flat_tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens.rasi")
    with open(out_path, "w") as f:
        f.write("/* Generated from design-tokens.json -- DO NOT EDIT */\n* {\n")
        for k, v in flat_tokens.items():
            val = str(v)
            # Match rofi formatting logic
            is_num_or_color = (
                re.match(r"^[0-9.-]+(px|em|%)?$", val) or
                re.match(r"^#[0-9a-fA-F]+$", val) or
                re.match(r"^[0-9.]+$", val)
            )
            if k.startswith("typography") or not is_num_or_color:
                f.write(f'    dt-{k}: "{val}";\n')
            else:
                f.write(f"    dt-{k}: {val};\n")
        f.write("}\n")
    print(f"Generated: {out_path}")

def generate_hyprlock_conf(flat_tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens-hyprlock.conf")
    with open(out_path, "w") as f:
        f.write("# Generated from design-tokens.json -- DO NOT EDIT\n")
        for k, v in flat_tokens.items():
            f.write(f"$dt-{k} = {v}\n")
    print(f"Generated: {out_path}")

def generate_kitty_conf(tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens-kitty.conf")
    kitty = tokens.get("kitty", {})
    with open(out_path, "w") as f:
        f.write("# Generated from design-tokens.json -- DO NOT EDIT\n")
        for k, v in kitty.items():
            f.write(f"{k} {v}\n")
    print(f"Generated: {out_path}")

def generate_gtk_settings(tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens-gtk.ini")
    gtk = tokens.get("gtk", {})
    with open(out_path, "w") as f:
        f.write("# Generated from design-tokens.json -- DO NOT EDIT\n")
        for k, v in gtk.items():
            key_formatted = k.replace("_", "-")
            f.write(f"gtk-{key_formatted}={v}\n")
    print(f"Generated: {out_path}")

def generate_env(tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens.env")
    lines = ["# Generated from design-tokens.json -- DO NOT EDIT"]
    
    def flatten_env(d, prefix="DT_"):
        for k, v in d.items():
            path = prefix + k.upper().replace("-", "_").replace(".", "_")
            if isinstance(v, dict):
                flatten_env(v, path + "_")
            else:
                # Escape double quotes
                val_esc = str(v).replace('"', '\\"')
                lines.append(f'{path}="{val_esc}"')
                
    flatten_env(tokens)
    with open(out_path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated: {out_path}")

def generate_shayar_json(tokens, out_dir):
    out_path = os.path.join(out_dir, "shayar.json")
    colors = tokens.get("colors", {})
    shayar_colors = {}
    for k, v in colors.items():
        shayar_colors[k] = {
            "dark": {"color": v},
            "default": {"color": v},
            "light": {"color": v}
        }
    with open(out_path, "w") as f:
        json.dump({"colors": shayar_colors}, f, indent=4)
    print(f"Generated: {out_path}")

def generate_quickshell_tokens(tokens, out_dir):
    out_path = os.path.join(out_dir, "quickshell-tokens.json")
    qs = tokens.get("quickshell", {})
    with open(out_path, "w") as f:
        json.dump(qs, f, indent=4)
    print(f"Generated: {out_path}")

def generate_rofi_font(tokens, out_dir):
    out_path = os.path.join(out_dir, "design-tokens-rofi-font.rasi")
    typo = tokens.get("typography", {})
    rofi_font = typo.get("rofi_font", "")
    icon_theme = typo.get("icon_theme", "")
    with open(out_path, "w") as f:
        f.write("/* Generated from design-tokens.json -- DO NOT EDIT */\n")
        f.write("configuration {\n")
        f.write(f'    font: "{rofi_font}";\n')
        f.write(f'    icon-theme: "{icon_theme}";\n')
        f.write("}\n")
    print(f"Generated: {out_path}")

def get_sorted_replacements(tokens):
    # Flatten environment style tokens
    env_tokens = {}
    def flatten(d, prefix="DT_"):
        for k, v in d.items():
            path = prefix + k.upper().replace("-", "_").replace(".", "_")
            if isinstance(v, dict):
                flatten(v, path + "_")
            else:
                env_tokens[path] = str(v)
    flatten(tokens)
    
    # Sort replacements by key length descending to prevent substring collisions
    sorted_reps = sorted(env_tokens.items(), key=lambda x: len(x[0]), reverse=True)
    return sorted_reps

def apply_replacements(content, sorted_reps):
    for k, v in sorted_reps:
        if k.startswith("DT_COLORS_"):
            color_name = k[len("DT_COLORS_"):].lower().replace("_", "-")
            content = content.replace(f"@{color_name}", v)
        content = content.replace(f"@{k}@", v)
    return content

def generate_fastfetch(tokens, out_dir):
    home = os.environ.get("HOME", "")
    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.join(home, ".config"))
    src = os.path.join(config_home, "fastfetch", "config.jsonc")
    dst = os.path.join(out_dir, "fastfetch.jsonc")
    
    if not os.path.exists(src):
        print(f":: fastfetch config not found at {src}, skipping")
        return
        
    with open(src, "r") as f:
        content = f.read()
        
    reps = get_sorted_replacements(tokens)
    resolved = apply_replacements(content, reps)
    
    with open(dst, "w") as f:
        f.write(resolved)
    print(f"Generated: {dst}")

def generate_waybar_css(tokens, out_dir):
    home = os.environ.get("HOME", "")
    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.join(home, ".config"))
    src = os.path.join(config_home, "shayar", "themes", "waybar-style.css")
    dst = os.path.join(out_dir, "waybar-style.css")
    
    reps = get_sorted_replacements(tokens)
    
    if src != dst and os.path.exists(src):
        with open(src, "r") as f:
            content = f.read()
        resolved = apply_replacements(content, reps)
        with open(dst, "w") as f:
            f.write(resolved)
        print(f"Generated: {dst}")
        
    # Swaync CSS generation
    for component in ["notifications", "control_center"]:
        sway_src = os.path.join(config_home, "swaync", "themes", "glass", f"{component}.template.css")
        sway_dst = os.path.join(out_dir, f"swaync-{component}.css")
        if os.path.exists(sway_src):
            with open(sway_src, "r") as f:
                content = f.read()
            resolved = apply_replacements(content, reps)
            with open(sway_dst, "w") as f:
                f.write(resolved)
            print(f"Generated: {sway_dst}")

def main():
    home = os.environ.get("HOME", "")
    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.join(home, ".config"))
    
    tokens_file = get_env_or_default("TOKENS_FILE", os.path.join(config_home, "shayar", "themes", "design-tokens.json"))
    out_dir = get_env_or_default("OUT_DIR", os.path.join(config_home, "shayar", "themes"))
    
    if not os.path.exists(tokens_file):
        print(f"Error: {tokens_file} not found")
        sys.exit(1)
        
    os.makedirs(out_dir, exist_ok=True)
    
    with open(tokens_file, "r") as f:
        tokens = json.load(f)
        
    flat_tokens = flatten_dict(tokens)
    
    generate_css(flat_tokens, out_dir)
    generate_lua(tokens, out_dir)
    generate_rasi(flat_tokens, out_dir)
    generate_hyprlock_conf(flat_tokens, out_dir)
    generate_kitty_conf(tokens, out_dir)
    generate_gtk_settings(tokens, out_dir)
    generate_env(tokens, out_dir)
    generate_shayar_json(tokens, out_dir)
    generate_quickshell_tokens(tokens, out_dir)
    generate_rofi_font(tokens, out_dir)
    generate_fastfetch(tokens, out_dir)
    generate_waybar_css(tokens, out_dir)

if __name__ == "__main__":
    main()
