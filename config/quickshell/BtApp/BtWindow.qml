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

    implicitWidth: root.ready ? root.tokens.panel_width : 180
    implicitHeight: btColumn.implicitHeight + 32
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

    onIsOpenChanged: {
        if (isOpen && !btScan.running) {
            btScan.running = true
        } else if (!isOpen) {
            btScan.running = false
        }
    }

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
        property int panel_width: 320
        property int panel_radius: 24
        property real panel_bg_alpha: 0.7
        property real blur_strength: 0.7
        property real gradient_top_alpha: 0.12
        property real gradient_mid_alpha: 0.04
        property real border_alpha: 0.15
        property int border_width: 1
        property real shadow_alpha: 0.4
        property int button_spacing: 12
        property int row_height: 48
        property int label_height: 30
        property int label_radius: 15
        property real label_alpha: 0.88
        property int icon_size: 18
        property int icon_circle_size: 44
        property real primary_alpha: 0.9
        property real hover_border_alpha: 0.5
        property int font_size_label: 13
        property int font_size_small: 11
        property int calendar_margin_top: 42

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
                if (t.row_height !== undefined) row_height = t.row_height
                if (t.label_height !== undefined) label_height = t.label_height
                if (t.label_radius !== undefined) label_radius = t.label_radius
                if (t.label_alpha !== undefined) label_alpha = t.label_alpha
                if (t.icon_size !== undefined) icon_size = t.icon_size
                if (t.icon_circle_size !== undefined) icon_circle_size = t.icon_circle_size
                if (t.primary_alpha !== undefined) primary_alpha = t.primary_alpha
                if (t.hover_border_alpha !== undefined) hover_border_alpha = t.hover_border_alpha
                if (t.font_size_label !== undefined) font_size_label = t.font_size_label
                if (t.font_size_small !== undefined) font_size_small = t.font_size_small
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

    property bool btEnabled: true

    ListModel { id: btModel }

    Process {
        id: btScan
        command: ["timeout", "10", "bash", "-c", "echo \"POWERED:$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')\"; DEVICES=$(bluetoothctl devices 2>/dev/null | head -20); PAIRED=$(bluetoothctl devices Paired 2>/dev/null); CONNECTED=$(bluetoothctl devices Connected 2>/dev/null); TRUSTED=$(bluetoothctl devices Trusted 2>/dev/null); echo \"$DEVICES\" | while read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); is_paired=$(echo \"$PAIRED\" | grep -q \"$mac\" && echo \"yes\" || echo \"no\"); is_connected=$(echo \"$CONNECTED\" | grep -q \"$mac\" && echo \"yes\" || echo \"no\"); is_trusted=$(echo \"$TRUSTED\" | grep -q \"$mac\" && echo \"yes\" || echo \"no\"); echo \"DEVICE:$mac:$name:$is_paired:$is_connected:$is_trusted\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                parseBt(this.text.trim())
            }
        }
    }

    function parseBt(text) {
        btModel.clear()
        if (!text) return
        text.split("\n").forEach(function (line) {
            if (!line) return
            if (line.indexOf("POWERED:") === 0) {
                root.btEnabled = line.substring(8) === "yes"
                return
            }
            if (line.indexOf("DEVICE:") !== 0) return
            var parts = line.substring(7).split(":")
            var mac = parts[0] + ":" + parts[1] + ":" + parts[2] + ":" + parts[3] + ":" + parts[4] + ":" + parts[5]
            var name = parts.slice(6, parts.length - 3).join(":")
            var paired = parts[parts.length - 3] === "yes"
            var connected = parts[parts.length - 2] === "yes"
            var trusted = parts[parts.length - 1] === "yes"
            btModel.append({
                mac: mac,
                name: name || "Unknown",
                paired: paired,
                connected: connected,
                trusted: trusted
            })
        })
    }

    Item {
        id: panelContainer
        width: root.tokens.panel_width
        height: btColumn.implicitHeight + 32
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

        ColumnLayout {
            id: btColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "\uF1AD"
                    color: root.colors.primary
                    font.pixelSize: root.tokens.icon_size + 4
                    font.family: "Symbols Nerd Font Mono"
                }

                Text {
                    text: "Bluetooth"
                    color: root.colors.on_surface
                    font.pixelSize: root.tokens.font_size_label + 2
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: mouseAreaBtToggle.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                        : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, mouseAreaBtToggle.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Text {
                        anchors.centerIn: parent
                        text: root.btEnabled ? "\uF1AD" : "\uF057"
                        color: root.btEnabled ? root.colors.primary : root.colors.on_surface_variant
                        font.pixelSize: 14
                        font.family: "Symbols Nerd Font Mono"
                    }

                    MouseArea {
                        id: mouseAreaBtToggle
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.btEnabled) {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl power off"])
                                root.btEnabled = false
                                btModel.clear()
                            } else {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl power on"])
                                root.btEnabled = true
                                btScan.running = true
                            }
                        }
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: mouseAreaBtScan.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                        : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, mouseAreaBtScan.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Text {
                        anchors.centerIn: parent
                        text: "\uF021"
                        color: root.colors.on_surface
                        font.pixelSize: 14
                        font.family: "Symbols Nerd Font Mono"
                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1000
                            running: btScan.running
                        }
                    }

                    MouseArea {
                        id: mouseAreaBtScan
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "bluetoothctl --timeout 12 scan on"])
                            btScan.running = true
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.1)
            }

            Repeater {
                model: btModel

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: model.connected ? root.tokens.row_height + 12 : root.tokens.row_height
                    radius: 12
                    scale: model.connected ? 1.02 : 1.0
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.2 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

                    color: btRowMouse.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15)
                        : model.connected
                            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.12)
                            : "transparent"
                    border.color: model.connected ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3) : "transparent"
                    border.width: model.connected ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Item {
                            width: 32; height: 32
                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: model.connected
                                    ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.primary_alpha)
                                    : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uF1AD"
                                color: model.connected ? root.colors.on_primary : root.colors.on_surface
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font Mono"
                            }
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: root.colors.surface_container
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                visible: model.trusted
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uF028" // Actually, \uF132 (shield) or \uF00C (check). \uF058 (check circle)
                                    color: root.colors.primary
                                    font.pixelSize: 8
                                    font.family: "Symbols Nerd Font Mono"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: model.name
                                color: model.connected ? root.colors.primary : root.colors.on_surface
                                font.pixelSize: model.connected ? root.tokens.font_size_label + 2 : root.tokens.font_size_label
                                font.weight: model.connected ? Font.Bold : Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                spacing: 6
                                Text {
                                    text: model.mac
                                    color: root.colors.on_surface_variant
                                    font.pixelSize: root.tokens.font_size_small
                                }
                                Rectangle {
                                    width: stateLabel.implicitWidth + 8
                                    height: 16
                                    radius: 8
                                    color: model.connected
                                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25)
                                        : model.paired
                                            ? Qt.rgba(root.colors.surface_bright.r, root.colors.surface_bright.g, root.colors.surface_bright.b, 0.5)
                                            : "transparent"
                                    visible: model.connected || model.paired
                                    border.color: model.connected ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : "transparent"
                                    border.width: model.connected ? 1 : 0

                                    Text {
                                        id: stateLabel
                                        anchors.centerIn: parent
                                        text: model.connected ? "Connected" : model.paired ? "Paired" : ""
                                        color: model.connected ? root.colors.primary : root.colors.on_surface
                                        font.pixelSize: 10
                                        font.weight: model.connected ? Font.Bold : Font.Medium
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: btRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.connected) {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl disconnect " + model.mac])
                            } else if (model.paired) {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl connect " + model.mac])
                            } else {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl pair " + model.mac + " && bluetoothctl trust " + model.mac + " && bluetoothctl connect " + model.mac])
                            }
                            btScan.running = true
                        }
                    }
                }
            }

            Text {
                visible: btModel.count === 0 && root.btEnabled
                text: "No devices found"
                color: root.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
            }

            Text {
                visible: !root.btEnabled
                text: "Bluetooth is disabled"
                color: root.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
            }
        }
    }

    IpcHandler {
        target: "bt"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
    }
}
