import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../shared/BaseState.qml" as BaseState
import "../shared/GlassPanel.qml" as GlassPanel

PanelWindow {
    id: root

    function reload(): void { state.reload() }

    property alias isOpen: state.isOpen
    property bool ready: state.ready

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

    BaseState.BaseState {
        id: state
        parent: root
        tokens: root.tokens
        ipcTarget: "net"
    }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: root.ready ? root.tokens.panel_width : 180
    implicitHeight: Math.min(netColumn.implicitHeight + 32, Screen.height * 0.75)
    color: "transparent"
    anchors.right: true
    anchors.top: true

    HyprlandFocusGrab {
        windows: [root]
        active: state.isOpen
        onCleared: { if (state.isOpen) state.isOpen = false }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: { if (state.isOpen) state.isOpen = false }
    }

    onIsOpenChanged: {
        if (state.isOpen) {
            selectedIndex = -1
            wifiScan.running = true
            netColumn.forceActiveFocus()
        }
    }

    visible: state.ready && (state.isOpen || root.slideOffset !== 120)

    property int slideOffset: state.isOpen ? 0 : 120

    Behavior on slideOffset {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    margins { right: root.slideOffset; top: root.tokens.calendar_margin_top }

    property bool wifiEnabled: true
    property int selectedIndex: -1

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

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= wifiModel.count) return
        var item = wifiModel.get(selectedIndex)
        if (item.inUse) {
            Quickshell.execDetached(["bash", "-c", "nmcli device disconnect wlan0"])
        } else {
            Quickshell.execDetached(["bash", "-c", "nmcli device wifi connect \"" + item.bssid + "\""])
        }
        wifiScan.running = true
    }

    Timer {
        interval: 3000
        running: state.isOpen
        onTriggered: wifiScan.running = true
    }

    Item {
        id: panelContainer
        width: root.tokens.panel_width
        height: Math.min(netColumn.implicitHeight + 32, Screen.height * 0.75)
        anchors.top: parent.top
        anchors.right: parent.right

        GlassPanel.GlassPanel {
            anchors.fill: parent
            colors: state.colors
            tokens: root.tokens
        }

        ColumnLayout {
            id: netColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            focus: true

            Keys.onUpPressed: {
                if (selectedIndex <= 0) selectedIndex = wifiModel.count - 1
                else selectedIndex--
            }
            Keys.onDownPressed: {
                if (selectedIndex >= wifiModel.count - 1) selectedIndex = 0
                else selectedIndex++
            }
            Keys.onReturnPressed: activateSelected()
            Keys.onEnterPressed: activateSelected()

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "\uF1EB"
                    color: state.colors.primary
                    font.pixelSize: root.tokens.icon_size + 4
                    font.family: "Symbols Nerd Font Mono"
                }

                Text {
                    text: "Wi-Fi"
                    color: state.colors.on_surface
                    font.pixelSize: root.tokens.font_size_label + 2
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: mouseAreaToggle.containsMouse
                        ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.2)
                        : Qt.rgba(state.colors.surface_container_high.r, state.colors.surface_container_high.g, state.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, mouseAreaToggle.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiEnabled ? "\uF1EB" : "\uF057"
                        color: root.wifiEnabled ? state.colors.primary : state.colors.on_surface_variant
                        font.pixelSize: 14
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
                    width: 32; height: 32; radius: 16
                    color: mouseAreaRefresh.containsMouse
                        ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.2)
                        : Qt.rgba(state.colors.surface_container_high.r, state.colors.surface_container_high.g, state.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, mouseAreaRefresh.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Text {
                        anchors.centerIn: parent
                        text: "\uF021"
                        color: state.colors.on_surface
                        font.pixelSize: 14
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
                color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.1)
            }

            Repeater {
                model: wifiModel

                Rectangle {
                    required property int index
                    required property bool inUse
                    required property string ssid
                    required property int signal
                    required property bool secured
                    required property string bssid

                    Layout.fillWidth: true
                    Layout.preferredHeight: inUse ? root.tokens.row_height + 12 : root.tokens.row_height
                    radius: 12
                    scale: inUse ? 1.02 : 1.0
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.2 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

                    color: rowMouse.containsMouse || index === selectedIndex
                        ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.15)
                        : inUse
                            ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.12)
                            : "transparent"
                    border.color: inUse || index === selectedIndex ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.3) : "transparent"
                    border.width: inUse || index === selectedIndex ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Item {
                            width: 32; height: 32
                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: inUse
                                    ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, root.tokens.primary_alpha)
                                    : Qt.rgba(state.colors.surface_container_high.r, state.colors.surface_container_high.g, state.colors.surface_container_high.b, 0.6)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uF1EB"
                                color: inUse ? state.colors.on_primary : (signal > 70 ? state.colors.primary : (signal > 40 ? "#e5c07b" : "#ff5555"))
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font Mono"
                            }
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: state.colors.surface_container
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                visible: secured
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uF023"
                                    color: state.colors.primary
                                    font.pixelSize: 8
                                    font.family: "Symbols Nerd Font Mono"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: ssid
                                color: inUse ? state.colors.primary : state.colors.on_surface
                                font.pixelSize: inUse ? root.tokens.font_size_label + 2 : root.tokens.font_size_label
                                font.weight: inUse ? Font.Bold : Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: inUse ? "Connected" : signal + "%"
                                color: inUse ? state.colors.primary : state.colors.on_surface_variant
                                font.pixelSize: root.tokens.font_size_small
                                font.weight: inUse ? Font.Medium : Font.Normal
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (inUse) {
                                Quickshell.execDetached(["bash", "-c", "nmcli device disconnect wlan0"])
                            } else {
                                Quickshell.execDetached(["bash", "-c", "nmcli device wifi connect \"" + bssid + "\""])
                            }
                            wifiScan.running = true
                        }
                    }
                }
            }

            Text {
                visible: wifiModel.count === 0
                text: root.wifiEnabled ? "No networks found" : "Wi-Fi is disabled"
                color: state.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
            }
        }
    }
}
