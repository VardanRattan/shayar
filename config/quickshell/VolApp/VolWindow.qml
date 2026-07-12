import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

PanelWindow {
    id: root

    function reload(): void {
        colorReader.running = false
        colorReader.running = true
        tokenReader.running = false
        tokenReader.running = true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: 200
    implicitHeight: 45
    color: "transparent"
    anchors.right: true
    anchors.top: true

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: { if (root.isOpen) root.isOpen = false }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: { if (root.isOpen) root.isOpen = false }
    }

    property bool isOpen: false
    property bool ready: false
    property bool colorsLoaded: false
    property bool tokensLoaded: false

    visible: ready && (isOpen || root.slideOffset !== 120)

    property int slideOffset: isOpen ? 0 : 120

    Behavior on slideOffset {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    margins { right: root.slideOffset; top: root.tokens.calendar_margin_top }

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

    property QtObject tokens: QtObject {
        property int panel_width: 200
        property int panel_radius: 12
        property real panel_bg_alpha: 0.9
        property real blur_strength: 0.7
        property real gradient_top_alpha: 0.12
        property real gradient_mid_alpha: 0.04
        property real border_alpha: 0.08
        property int border_width: 1
        property real shadow_alpha: 0.4
        property int button_spacing: 12
        property int icon_size: 18
        property real primary_alpha: 0.9
        property real hover_border_alpha: 0.5
        property int font_size_label: 13
        property int calendar_margin_top: 55
        property real track_alpha: 0.1
        property int thumb_size: 14
        property int bar_radius: 6
        property int bar_min_height: 6

        function updateFromJson(jsonString) {
            try {
                var t = JSON.parse(jsonString)
                if (!t || Object.keys(t).length === 0) return false
                if (t.panel_width !== undefined) panel_width = t.panel_width
                if (t.panel_radius !== undefined) panel_radius = t.panel_radius
                if (t.panel_bg_alpha !== undefined) panel_bg_alpha = t.panel_bg_alpha
                if (t.blur_strength !== undefined) blur_strength = t.blur_strength
                if (t.gradient_top_alpha !== undefined) gradient_top_alpha = t.gradient_top_alpha
                if (t.gradient_mid_alpha !== undefined) gradient_mid_alpha = t.gradient_mid_alpha
                if (t.border_alpha !== undefined) border_alpha = t.border_alpha
                if (t.border_width !== undefined) border_width = t.border_width
                if (t.shadow_alpha !== undefined) shadow_alpha = t.shadow_alpha
                if (t.button_spacing !== undefined) button_spacing = t.button_spacing
                if (t.icon_size !== undefined) icon_size = t.icon_size
                if (t.primary_alpha !== undefined) primary_alpha = t.primary_alpha
                if (t.hover_border_alpha !== undefined) hover_border_alpha = t.hover_border_alpha
                if (t.font_size_label !== undefined) font_size_label = t.font_size_label
                if (t.calendar_margin_top !== undefined) calendar_margin_top = t.calendar_margin_top
                return true
            } catch (e) {
                console.log("Failed to parse quickshell tokens: " + e)
                return false
            }
        }
    }

    Process {
        id: colorReader
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

    Process {
        id: tokenReader
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

    property real volume: 0.5
    property real displayVolume: 0.5
    Behavior on displayVolume { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    onVolumeChanged: displayVolume = volume
    property bool isMuted: false

    Process {
        id: volumePoller
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                if (lines.length > 0) {
                    var parts = lines[0].split(" ")
                    if (parts.length >= 2) {
                        var parsedVol = parseFloat(parts[1])
                        root.volume = isNaN(parsedVol) ? 0 : parsedVol
                        root.isMuted = lines[0].indexOf("[MUTED]") !== -1
                    }
                }
            }
        }
        running: root.isOpen
    }

    Timer {
        interval: 500
        running: root.isOpen
        repeat: true
        onTriggered: volumePoller.running = true
    }

    function setVolume(vol) {
        root.volume = vol
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol.toFixed(2)])
    }

    function toggleMute() {
        root.isMuted = !root.isMuted
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    Item {
        id: panelContainer
        width: root.tokens.panel_width
        height: 45
        anchors.top: parent.top
        anchors.right: parent.right

        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: root.tokens.panel_radius
            color: Qt.rgba(root.colors.surface_container.r, root.colors.surface_container.g, root.colors.surface_container.b, root.tokens.panel_bg_alpha)

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: root.tokens.blur_strength
                saturation: 0.0
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.gradient_top_alpha) }
                    GradientStop { position: 0.3; color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.gradient_mid_alpha) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "transparent"
                border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.border_alpha)
                border.width: root.tokens.border_width
            }
        }

        RectangularShadow {
            anchors.fill: panelBg
            radius: panelBg.radius
            blur: 24
            color: Qt.rgba(root.colors.shadow.r, root.colors.shadow.g, root.colors.shadow.b, root.tokens.shadow_alpha)
        }

        RowLayout {
            id: volRow
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Item {
                width: root.tokens.icon_size + 4
                height: root.tokens.icon_size + 4
                Text {
                    id: volIcon
                    anchors.centerIn: parent
                    text: (root.volume > 0.5 ? "\uF028" : root.volume > 0 ? "\uF027" : "\uF026")
                    color: root.isMuted ? root.colors.on_surface_variant : root.colors.primary
                    font.pixelSize: root.tokens.icon_size
                    font.family: "Symbols Nerd Font Mono"
                }
                Rectangle {
                    width: Math.sqrt(parent.width*parent.width + parent.height*parent.height) * 0.8
                    height: 2
                    color: "#ff5555"
                    anchors.centerIn: parent
                    rotation: 45
                    opacity: root.isMuted ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMute()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.tokens.bar_min_height
                radius: root.tokens.bar_radius
                color: Qt.rgba(root.colors.on_surface.r, root.colors.on_surface.g, root.colors.on_surface.b, root.tokens.track_alpha)

                Rectangle {
                    id: volHighlight
                    width: parent.width * root.volume
                    height: parent.height
                    radius: parent.radius
                    color: root.volume > 1.0 ? "#ff5555" : root.colors.primary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Behavior on width {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }

                Rectangle {
                    id: volThumb
                    width: root.tokens.thumb_size
                    height: root.tokens.thumb_size
                    radius: root.tokens.thumb_size / 2
                    color: root.colors.on_surface
                    anchors.verticalCenter: parent.verticalCenter
                    x: (parent.width - width) * root.volume

                    scale: thumbMouseArea.pressed || parentMouseArea.pressed ? 1.4 : 1.0
                    Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }

                    Behavior on x {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }

                    MouseArea {
                        id: thumbMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        property real dragStartX: 0
                        property real dragStartVol: 0
                        onPressed: {
                            dragStartX = mouseX
                            dragStartVol = root.volume
                        }
                        onPositionChanged: {
                            if (pressed) {
                                var delta = (mouseX - dragStartX) / volRow.width
                                var newVol = Math.max(0, Math.min(1.5, dragStartVol + delta))
                                root.setVolume(newVol)
                            }
                        }
                    }
                }

                MouseArea {
                    id: parentMouseArea
                    anchors.fill: parent
                    onPressed: {
                        var newVol = Math.max(0, Math.min(1.5, mouseX / width))
                        root.setVolume(newVol)
                    }
                    onWheel: function(event) {
                        var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                        root.setVolume(Math.max(0, Math.min(1.5, root.volume + delta)))
                    }
                }
            }

            Text {
                text: Math.round(root.displayVolume * 100) + "%"
                color: root.colors.on_surface
                font.pixelSize: root.tokens.font_size_label
                font.weight: Font.Medium
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    IpcHandler {
        target: "vol"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
    }
}
