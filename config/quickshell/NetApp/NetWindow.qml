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
    implicitHeight: Math.min(netColumn.implicitHeight + 32, Screen.height * 0.75)
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
                    font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
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
                        font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
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
                        font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
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
                                font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
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
                                    font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
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
