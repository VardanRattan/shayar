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
        ipcTarget: "bt"
    }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: root.ready ? root.tokens.panel_width : 180
    implicitHeight: Math.min(btColumn.implicitHeight + 32, Screen.height * 0.75)
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
        if (state.isOpen && !btScan.running) {
            selectedIndex = -1
            btScan.running = true
            btColumn.forceActiveFocus()
        } else if (!state.isOpen) {
            btScan.running = false
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

    property bool btEnabled: true
    property int selectedIndex: -1

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

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= btModel.count) return
        var item = btModel.get(selectedIndex)
        if (item.connected) {
            Quickshell.execDetached(["bash", "-c", "bluetoothctl disconnect " + item.mac])
        } else if (item.paired) {
            Quickshell.execDetached(["bash", "-c", "bluetoothctl connect " + item.mac])
        } else {
            Quickshell.execDetached(["bash", "-c", "bluetoothctl pair " + item.mac + " && bluetoothctl trust " + item.mac + " && bluetoothctl connect " + item.mac])
        }
        btScan.running = true
    }

    Item {
        id: panelContainer
        width: root.tokens.panel_width
        height: Math.min(btColumn.implicitHeight + 32, Screen.height * 0.75)
        anchors.top: parent.top
        anchors.right: parent.right

        GlassPanel.GlassPanel {
            anchors.fill: parent
            colors: state.colors
            tokens: root.tokens
        }

        ColumnLayout {
            id: btColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            focus: true

            Keys.onUpPressed: {
                if (selectedIndex <= 0) selectedIndex = btModel.count - 1
                else selectedIndex--
            }
            Keys.onDownPressed: {
                if (selectedIndex >= btModel.count - 1) selectedIndex = 0
                else selectedIndex++
            }
            Keys.onReturnPressed: activateSelected()
            Keys.onEnterPressed: activateSelected()

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "\uF1AD"
                    color: state.colors.primary
                    font.pixelSize: root.tokens.icon_size + 4
                    font.family: "Symbols Nerd Font Mono"
                }

                Text {
                    text: "Bluetooth"
                    color: state.colors.on_surface
                    font.pixelSize: root.tokens.font_size_label + 2
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: mouseAreaBtToggle.containsMouse
                        ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.2)
                        : Qt.rgba(state.colors.surface_container_high.r, state.colors.surface_container_high.g, state.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, mouseAreaBtToggle.containsMouse ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Text {
                        anchors.centerIn: parent
                        text: root.btEnabled ? "\uF1AD" : "\uF057"
                        color: root.btEnabled ? state.colors.primary : state.colors.on_surface_variant
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
                        ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.2)
                        : Qt.rgba(state.colors.surface_container_high.r, state.colors.surface_container_high.g, state.colors.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, mouseAreaBtScan.containsMouse ? root.tokens.hover_border_alpha : 0)
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
                color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.1)
            }

            Repeater {
                model: btModel

                Rectangle {
                    required property int index
                    required property string mac
                    required property string name
                    required property bool paired
                    required property bool connected
                    required property bool trusted

                    Layout.fillWidth: true
                    Layout.preferredHeight: connected ? root.tokens.row_height + 12 : root.tokens.row_height
                    radius: 12
                    scale: connected ? 1.02 : 1.0
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.2 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

                    color: btRowMouse.containsMouse || index === selectedIndex
                        ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.15)
                        : connected
                            ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.12)
                            : "transparent"
                    border.color: connected || index === selectedIndex ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.3) : "transparent"
                    border.width: connected || index === selectedIndex ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Item {
                            width: 32; height: 32
                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: connected
                                    ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, root.tokens.primary_alpha)
                                    : Qt.rgba(state.colors.surface_container_high.r, state.colors.surface_container_high.g, state.colors.surface_container_high.b, 0.6)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\uF1AD"
                                color: connected ? state.colors.on_primary : state.colors.on_surface
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font Mono"
                            }
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: state.colors.surface_container
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                visible: trusted
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uF00C"
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
                                text: name
                                color: connected ? state.colors.primary : state.colors.on_surface
                                font.pixelSize: connected ? root.tokens.font_size_label + 2 : root.tokens.font_size_label
                                font.weight: connected ? Font.Bold : Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                spacing: 6
                                Text {
                                    text: mac
                                    color: state.colors.on_surface_variant
                                    font.pixelSize: root.tokens.font_size_small
                                }
                                Rectangle {
                                    width: stateLabel.implicitWidth + 8
                                    height: 16
                                    radius: 8
                                    color: connected
                                        ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.25)
                                        : paired
                                            ? Qt.rgba(state.colors.surface_bright.r, state.colors.surface_bright.g, state.colors.surface_bright.b, 0.5)
                                            : "transparent"
                                    visible: connected || paired
                                    border.color: connected ? Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, 0.5) : "transparent"
                                    border.width: connected ? 1 : 0

                                    Text {
                                        id: stateLabel
                                        anchors.centerIn: parent
                                        text: connected ? "Connected" : paired ? "Paired" : ""
                                        color: connected ? state.colors.primary : state.colors.on_surface
                                        font.pixelSize: 10
                                        font.weight: connected ? Font.Bold : Font.Medium
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
                            if (connected) {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl disconnect " + mac])
                            } else if (paired) {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl connect " + mac])
                            } else {
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl pair " + mac + " && bluetoothctl trust " + mac + " && bluetoothctl connect " + mac])
                            }
                            btScan.running = true
                        }
                    }
                }
            }

            Text {
                visible: btModel.count === 0 && root.btEnabled
                text: "No devices found"
                color: state.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
            }

            Text {
                visible: !root.btEnabled
                text: "Bluetooth is disabled"
                color: state.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
            }
        }
    }
}
