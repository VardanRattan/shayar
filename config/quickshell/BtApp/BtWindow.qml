import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
PanelWindow {
    id: root
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore
    implicitWidth: root.ready ? root.tokens.panel_width_wide : 180
    implicitHeight: Math.min(btColumn.implicitHeight + 32, Screen.height * 0.75)
    color: "transparent"
    anchors.left: true
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
    readonly property var colors: ThemeManager.colors
    readonly property var tokens: ThemeManager.tokens
    readonly property bool ready: ThemeManager.ready
    onIsOpenChanged: {
        if (isOpen) {
            if (!btScan.running) btScan.running = true
        } else {
            root.pendingOpen = false
            root.margins.left = Screen.width + 200
            btScan.running = false
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
            radius: root.tokens.bt_panel_radius
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
            id: btColumn
            anchors.fill: parent
            anchors.margins: root.tokens.list_inner_margin
            spacing: root.tokens.list_column_spacing
            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: root.tokens.header_spacing
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
                    width: root.tokens.toggle_button_size; height: root.tokens.toggle_button_size; radius: root.tokens.toggle_button_size / 2
                    color: mouseAreaBtToggle.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                        : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, mouseAreaBtToggle.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width
                    Text {
                        anchors.centerIn: parent
                        text: root.btEnabled ? "\uF1AD" : "\uF057"
                        color: root.btEnabled ? root.colors.primary : root.colors.on_surface_variant
                        font.pixelSize: root.tokens.list_icon_size
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
                    width: root.tokens.toggle_button_size; height: root.tokens.toggle_button_size; radius: root.tokens.toggle_button_size / 2
                    color: mouseAreaBtScan.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                        : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, mouseAreaBtScan.containsMouse ? root.tokens.hover_border_alpha : 0)
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
                color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.separator_alpha)
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
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_hover_alpha)
                        : index === root.selectedIndex
                            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_selected_alpha)
                            : model.connected
                                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_connected_alpha)
                                : "transparent"
                    border.color: model.connected || index === root.selectedIndex ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_border_alpha) : "transparent"
                    border.width: model.connected || index === root.selectedIndex ? 1 : 0
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root.tokens.list_row_margin
                        spacing: root.tokens.list_row_spacing
                        Item {
                            width: root.tokens.toggle_button_size; height: root.tokens.toggle_button_size
                            Rectangle {
                                anchors.fill: parent
                                radius: root.tokens.toggle_button_size / 2
                                color: model.connected
                                    ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.primary_alpha)
                                    : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, root.tokens.icon_circle_alpha)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uF1AD"
                                color: model.connected ? root.colors.on_primary : root.colors.on_surface
                                font.pixelSize: root.tokens.list_icon_size
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
                                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.badge_alpha)
                                        : model.paired
                                            ? Qt.rgba(root.colors.surface_bright.r, root.colors.surface_bright.g, root.colors.surface_bright.b, root.tokens.badge_paired_alpha)
                                            : "transparent"
                                    visible: model.connected || model.paired
                                    border.color: model.connected ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.badge_border_alpha) : "transparent"
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
        function toggle(x: real, y: real): void {
            if (root.isOpen) {
                root.isOpen = false
                root.pendingOpen = false
            } else {
                var pw = root.tokens ? root.tokens.panel_width_wide : 320
                root.margins.left = Math.max(12, Math.min(x - pw / 2, Screen.width - pw - 12))
                root.margins.top = y + 8
                root.pendingOpen = true
                root.isOpen = true
            }
        }
        function open(x: real, y: real): void {
            var pw = root.tokens ? root.tokens.panel_width_wide : 320
            root.margins.left = Math.max(12, Math.min(x - pw / 2, Screen.width - pw - 12))
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
