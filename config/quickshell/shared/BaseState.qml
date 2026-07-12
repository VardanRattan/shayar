import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: handler

    property PanelWindow parent
    property var tokens

    property bool isOpen: false
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
                return true
            } catch (e) {
                console.log("Failed to parse quickshell colors: " + e)
                return false
            }
        }
    }

    function reload(): void {
        colorReader.running = false
        colorReader.running = true
        tokenReader.running = false
        tokenReader.running = true
    }

    Process {
        id: colorReader
        command: ["cat", Quickshell.env("HOME") + "/.config/shayar/colors/quickshell.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                handler.colorsLoaded = handler.colors.updateFromJson(this.text.trim())
                handler.ready = handler.colorsLoaded && handler.tokensLoaded
                colorReader.running = false
            }
        }
        running: true
    }

    Process {
        id: tokenReader
        command: ["cat", Quickshell.env("HOME") + "/.config/shayar/colors/quickshell-tokens.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (handler.tokens) {
                    handler.tokensLoaded = handler.tokens.updateFromJson(this.text.trim())
                    handler.ready = handler.colorsLoaded && handler.tokensLoaded
                }
                tokenReader.running = false
            }
        }
        running: true
    }

    IpcHandler {
        target: ""
        function toggle(): void { handler.isOpen = !handler.isOpen }
        function open(): void { handler.isOpen = true }
        function close(): void { handler.isOpen = false }
    }
}
