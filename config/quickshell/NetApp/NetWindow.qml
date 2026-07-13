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

    implicitWidth: root.ready ? root.tokens.panel_width_wide : 180
    implicitHeight: Math.min(netColumn.implicitHeight + 32, Screen.height * 0.75)
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
    property bool pendingOpen: false
    property bool ready: false
    property bool colorsLoaded: false
    property bool tokensLoaded: false

    onIsOpenChanged: {
        if (isOpen) {
            wifiScan.running = true
        } else {
            root.pendingOpen = false
            root.margins.left = Screen.width + 200
        }
    }

    visible: ready && (isOpen || root.pendingOpen)

    margins {
        left: root.tokens.panel_width_wide ? (Screen.width - root.tokens.panel_width_wide - 8) : 500
        top: root.tokens.waybar_clearance
    }

    Behavior on margins.left {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }
    Behavior on margins.top {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }

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
                return true
            } catch (e) {
                console.log("Failed to parse quickshell colors: " + e)
                return false
            }
        }
    }

    property QtObject tokens: QtObject {
        property int panel_width: 320
        property int panel_width_wide: 320
        property int panel_radius: 24
        property real panel_bg_alpha: 0.7
        property real blur_strength: 0.7
        property real gradient_top_alpha: 0.12
        property real gradient_mid_alpha: 0.04
        property real border_alpha: 0.15
        property int border_width: 1
        property real shadow_alpha: 0.4
        property real blur_saturation: 0.0
        property real gradient_lower_alpha: 0.01
        property int shadow_blur: 24
        property int net_panel_radius: 24
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
        property int waybar_clearance: 42

        function updateFromJson(jsonString) {
            try {
                var t = JSON.parse(jsonString)
                if (!t || Object.keys(t).length === 0) return false
                if (t.panel_width !== undefined) panel_width = t.panel_width
                if (t.panel_width_wide !== undefined) panel_width_wide = t.panel_width_wide
                if (t.panel_radius !== undefined) panel_radius = t.panel_radius
                if (t.panel_bg_alpha !== undefined) panel_bg_alpha = t.panel_bg_alpha
                if (t.blur_strength !== undefined) blur_strength = t.blur_strength
                if (t.gradient_top_alpha !== undefined) gradient_top_alpha = t.gradient_top_alpha
                if (t.gradient_mid_alpha !== undefined) gradient_mid_alpha = t.gradient_mid_alpha
                if (t.border_alpha !== undefined) border_alpha = t.border_alpha
                if (t.border_width !== undefined) border_width = t.border_width
                if (t.shadow_alpha !== undefined) shadow_alpha = t.shadow_alpha
                if (t.blur_saturation !== undefined) blur_saturation = t.blur_saturation
                if (t.gradient_lower_alpha !== undefined) gradient_lower_alpha = t.gradient_lower_alpha
                if (t.shadow_blur !== undefined) shadow_blur = t.shadow_blur
                if (t.net_panel_radius !== undefined) net_panel_radius = t.net_panel_radius
                if (t.list_inner_margin !== undefined) list_inner_margin = t.list_inner_margin
                if (t.list_row_margin !== undefined) list_row_margin = t.list_row_margin
                if (t.list_row_spacing !== undefined) list_row_spacing = t.list_row_spacing
                if (t.list_column_spacing !== undefined) list_column_spacing = t.list_column_spacing
                if (t.header_spacing !== undefined) header_spacing = t.header_spacing
                if (t.toggle_button_size !== undefined) toggle_button_size = t.toggle_button_size
                if (t.list_icon_size !== undefined) list_icon_size = t.list_icon_size
                if (t.separator_alpha !== undefined) separator_alpha = t.separator_alpha
                if (t.row_hover_alpha !== undefined) row_hover_alpha = t.row_hover_alpha
                if (t.row_selected_alpha !== undefined) row_selected_alpha = t.row_selected_alpha
                if (t.row_connected_alpha !== undefined) row_connected_alpha = t.row_connected_alpha
                if (t.row_border_alpha !== undefined) row_border_alpha = t.row_border_alpha
                if (t.icon_circle_alpha !== undefined) icon_circle_alpha = t.icon_circle_alpha
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
                if (t.waybar_clearance !== undefined) waybar_clearance = t.waybar_clearance
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

    property bool wifiEnabled: true

    ListModel { id: wifiModel }

    Process {
        id: wifiScan
        command: ["timeout", "10", "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,BSSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                parseWifi(this.text.trim())
            }
        }
    }

    function parseWifi(text) {
        wifiModel.clear()
        if (!text) return
        text.split("\n").forEach(function (line) {
            if (!line) return
            var p = line.split(":")
            var inUse = p[0] === "*"
            var ssid = p[1] || "(hidden)"
            var signal = parseInt(p[2]) || 0
            var security = p[3] || ""
            var bssid = p.slice(4).join(":").replace(/\\/g, "")
            wifiModel.append({
                inUse: inUse,
                ssid: ssid,
                signal: signal,
                secured: security !== "" && security !== "--",
                bssid: bssid
            })
        })
    }

    Timer {
        interval: 3000
        running: root.isOpen
        onTriggered: wifiScan.running = true
    }

    Item {
        id: panelContainer
        width: root.tokens.panel_width
        height: netColumn.implicitHeight + 32
        anchors.top: parent.top
        anchors.right: parent.right

        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: root.tokens.net_panel_radius
            color: Qt.rgba(root.colors.surface_container.r, root.colors.surface_container.g, root.colors.surface_container.b, root.tokens.panel_bg_alpha)
        }

        Rectangle {
            anchors.fill: panelBg
            anchors.margins: 1
            radius: panelBg.radius - 1
            color: "transparent"
            border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.border_alpha)
            border.width: root.tokens.border_width
        }

        RectangularShadow {
            z: -1
            anchors.fill: panelBg
            radius: panelBg.radius
            blur: root.tokens.shadow_blur
            color: Qt.rgba(root.colors.shadow.r, root.colors.shadow.g, root.colors.shadow.b, root.tokens.shadow_alpha)
            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        ColumnLayout {
            id: netColumn
            anchors.fill: parent
            anchors.margins: root.tokens.list_inner_margin
            spacing: root.tokens.list_column_spacing

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: root.tokens.header_spacing

                Text {
                    text: "\uF1EB"
                    color: root.colors.primary
                    font.pixelSize: root.tokens.icon_size + 4
                    font.family: "Symbols Nerd Font Mono"
                }

                Text {
                    text: "Wi-Fi"
                    color: root.colors.on_surface
                    font.pixelSize: root.tokens.font_size_label + 2
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: root.tokens.toggle_button_size; height: root.tokens.toggle_button_size; radius: root.tokens.toggle_button_size / 2
                    color: mouseAreaToggle.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                        : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, mouseAreaToggle.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiEnabled ? "\uF1EB" : "\uF057"
                        color: root.wifiEnabled ? root.colors.primary : root.colors.on_surface_variant
                        font.pixelSize: root.tokens.list_icon_size
                        font.family: "Symbols Nerd Font Mono"
                    }

                    MouseArea {
                        id: mouseAreaToggle
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.wifiEnabled) {
                                Quickshell.execDetached(["bash", "-c", "nmcli radio wifi off"])
                                root.wifiEnabled = false
                            } else {
                                Quickshell.execDetached(["bash", "-c", "nmcli radio wifi on"])
                                root.wifiEnabled = true
                                wifiScan.running = true
                            }
                        }
                    }
                }

                Rectangle {
                    width: root.tokens.toggle_button_size; height: root.tokens.toggle_button_size; radius: root.tokens.toggle_button_size / 2
                    color: mouseAreaRefresh.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                        : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, mouseAreaRefresh.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Text {
                        anchors.centerIn: parent
                        text: "\uF021"
                        color: root.colors.on_surface
                        font.pixelSize: root.tokens.list_icon_size
                        font.family: "Symbols Nerd Font Mono"
                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1000
                            running: wifiScan.running
                        }
                    }

                    MouseArea {
                        id: mouseAreaRefresh
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "nmcli device wifi rescan"])
                            wifiScan.running = true
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.separator_alpha)
            }

            Repeater {
                model: wifiModel

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: model.inUse ? root.tokens.row_height + 12 : root.tokens.row_height
                    radius: 12
                    scale: model.inUse ? 1.02 : 1.0
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.2 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

                    color: rowMouse.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_hover_alpha)
                        : index === root.selectedIndex
                            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_selected_alpha)
                            : model.inUse
                                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_connected_alpha)
                                : "transparent"
                    border.color: model.inUse || index === root.selectedIndex ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_border_alpha) : "transparent"
                    border.width: model.inUse || index === root.selectedIndex ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root.tokens.list_row_margin
                        spacing: root.tokens.list_row_spacing

                        Item {
                            width: root.tokens.toggle_button_size; height: root.tokens.toggle_button_size
                            Rectangle {
                                anchors.fill: parent
                                radius: root.tokens.toggle_button_size / 2
                                color: model.inUse
                                    ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.primary_alpha)
                                    : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, root.tokens.icon_circle_alpha)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uF1EB"
                                color: model.inUse ? root.colors.on_primary : (model.signal > 70 ? root.colors.primary : (model.signal > 40 ? root.colors.tertiary : root.colors.error))
                                font.pixelSize: root.tokens.list_icon_size
                                font.family: "Symbols Nerd Font Mono"
                            }
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: root.colors.surface_container
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                visible: model.secured
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uF023"
                                    color: root.colors.primary
                                    font.pixelSize: 8
                                    font.family: "Symbols Nerd Font Mono"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Text {
                                    text: model.ssid
                                    color: model.inUse ? root.colors.primary : root.colors.on_surface
                                    font.pixelSize: model.inUse ? root.tokens.font_size_label + 2 : root.tokens.font_size_label
                                    font.weight: model.inUse ? Font.Bold : Font.Medium
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: model.inUse ? "Connected" : model.signal + "%"
                                color: model.inUse ? root.colors.primary : root.colors.on_surface_variant
                                font.pixelSize: root.tokens.font_size_small
                                font.weight: model.inUse ? Font.Medium : Font.Normal
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.inUse) {
                                Quickshell.execDetached(["bash", "-c", "nmcli device disconnect wlan0"])
                            } else {
                                Quickshell.execDetached(["bash", "-c", "nmcli device wifi connect \"" + model.bssid + "\""])
                            }
                            wifiScan.running = true
                        }
                    }
                }
            }

            Text {
                visible: wifiModel.count === 0
                text: root.wifiEnabled ? "No networks found" : "Wi-Fi is disabled"
                color: root.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
            }
        }
    }

    IpcHandler {
        target: "net"
        function toggle(x: real, y: real): void {
            if (root.isOpen) {
                root.isOpen = false
                root.pendingOpen = false
            } else {
                var pw = root.tokens ? root.tokens.panel_width_wide : 320
                root.margins.left = x - pw - 8
                root.margins.top = y + 8
                root.pendingOpen = true
                root.isOpen = true
            }
        }
        function open(x: real, y: real): void {
            var pw = root.tokens ? root.tokens.panel_width_wide : 320
            root.margins.left = x - pw - 8
            root.margins.top = y + 8
            root.pendingOpen = true
            root.isOpen = true
        }
        function close(): void {
            root.isOpen = false
            root.pendingOpen = false
        }
    }
}
