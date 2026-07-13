pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool ready: false
    property bool colorsLoaded: false
    property bool tokensLoaded: false

    property QtObject colors: QtObject {
        property color background: "#12131b"
        property color primary: "#acc7ff"
        property color on_primary: "#062f64"
        property color on_surface: "#e4e1ee"
        property color surface_dim: "#12131b"
        property color surface_container: "#1f1f28"
        property color surface_container_high: "#292932"
        property color surface_bright: "#393842"
        property color shadow: "#000000"
        property color on_surface_variant: "#c4c6d1"
        property color error: "#ffb4ab"
        property color tertiary: "#ffb3b0"
        property color outline_variant: "#43474f"

        function updateFromJson(jsonString) {
            try {
                var c = JSON.parse(jsonString)
                if (!c || Object.keys(c).length === 0) return false
                if (c.background) background = c.background
                if (c.primary) primary = c.primary
                if (c.on_primary) on_primary = c.on_primary
                if (c.on_surface) on_surface = c.on_surface
                if (c.surface_dim) surface_dim = c.surface_dim
                if (c.surface_container) surface_container = c.surface_container
                if (c.surface_container_high) surface_container_high = c.surface_container_high
                if (c.surface_bright) surface_bright = c.surface_bright
                if (c.shadow) shadow = c.shadow
                if (c.on_surface_variant) on_surface_variant = c.on_surface_variant
                if (c.error) error = c.error
                if (c.tertiary) tertiary = c.tertiary
                if (c.outline_variant) outline_variant = c.outline_variant
                return true
            } catch (e) {
                console.log("ThemeManager: Failed to parse colors: " + e)
                return false
            }
        }
    }

    property QtObject tokens: QtObject {
        property int panel_width: 180
        property int panel_width_wide: 320
        property int panel_width_vol: 200
        property int panel_radius: 40
        property int net_panel_radius: 24
        property int bt_panel_radius: 24
        property int vol_panel_radius: 12
        property real panel_bg_alpha: 0.95
        property real blur_strength: 0.7
        property real blur_saturation: 0.0
        property real gradient_top_alpha: 0.12
        property real gradient_mid_alpha: 0.04
        property real gradient_lower_alpha: 0.01
        property real border_alpha: 0.2
        property int border_width: 1
        property real shadow_alpha: 0.4
        property int shadow_blur: 24
        property int button_spacing: 12
        property int button_width: 130
        property int button_height: 56
        property int row_height: 48
        property int label_height: 30
        property int label_radius: 15
        property real label_alpha: 0.88
        property int icon_size: 18
        property int icon_circle_size: 52
        property real primary_alpha: 0.9
        property real hover_border_alpha: 0.5
        property int font_size_label: 13
        property int font_size_small: 11
        property int waybar_clearance: 42
        property int calendar_width: 320
        property int calendar_height: 380
        property int calendar_margin_left: 12
        property int calendar_radius: 24
        property int calendar_inner_margin: 20
        property int calendar_spacing: 10
        property int calendar_grid_spacing: 3
        property int font_size_title: 16
        property int font_size_body: 12
        property real hover_scale: 1.05
        property int list_inner_margin: 16
        property int list_row_margin: 8
        property int list_row_spacing: 10
        property int list_column_spacing: 8
        property int header_spacing: 8
        property int toggle_button_size: 32
        property int list_icon_size: 14
        property real separator_alpha: 0.1
        property real row_hover_alpha: 0.15
        property real row_selected_alpha: 0.1
        property real row_connected_alpha: 0.12
        property real row_border_alpha: 0.3
        property real icon_circle_alpha: 0.6
        property real track_alpha: 0.1
        property int thumb_size: 14
        property int bar_radius: 6
        property int bar_min_height: 6
        property int welcome_panel_width: 420
        property int welcome_panel_radius: 24

        function updateFromJson(jsonString) {
            try {
                var t = JSON.parse(jsonString)
                if (!t || Object.keys(t).length === 0) return false
                for (var key in t) {
                    if (root.tokens[key] !== undefined) {
                        root.tokens[key] = t[key]
                    }
                }
                return true
            } catch(e) {
                console.log("ThemeManager: failed to parse tokens: " + e)
                return false
            }
        }
    }

    function reload() {
        colorReader.running = false
        colorReader.running = true
        tokenReader.running = false
        tokenReader.running = true
    }

    property Process colorReader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.config/shayar/colors/quickshell.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.colorsLoaded = root.colors.updateFromJson(this.text.trim())
                root.ready = root.colorsLoaded && root.tokensLoaded
                colorReader.running = false
            }
        }
        running: true
    }

    property Process tokenReader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.config/shayar/colors/quickshell-tokens.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.tokensLoaded = root.tokens.updateFromJson(this.text.trim())
                root.ready = root.colorsLoaded && root.tokensLoaded
                tokenReader.running = false
            }
        }
        running: true
    }

    Component.onCompleted: {
        reload();
    }
}
