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
    readonly property int buttonCount: 6
    property int selectedIndex: -1

    property QtObject tokens: QtObject {
        property int panel_width: 180
        property int panel_radius: 40
        property real panel_bg_alpha: 0.7
        property real blur_strength: 0.7
        property real gradient_top_alpha: 0.12
        property real gradient_mid_alpha: 0.04
        property real border_alpha: 0.15
        property int border_width: 1
        property real shadow_alpha: 0.4
        property int button_spacing: 12
        property int button_width: 130
        property int button_height: 56
        property int label_height: 30
        property int label_radius: 15
        property real label_alpha: 0.88
        property int icon_size: 18
        property int icon_circle_size: 52
        property real primary_alpha: 0.9
        property real hover_border_alpha: 0.5
        property int font_size_label: 13

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
                if (t.button_width !== undefined) button_width = t.button_width
                if (t.button_height !== undefined) button_height = t.button_height
                if (t.label_height !== undefined) label_height = t.label_height
                if (t.label_radius !== undefined) label_radius = t.label_radius
                if (t.label_alpha !== undefined) label_alpha = t.label_alpha
                if (t.icon_size !== undefined) icon_size = t.icon_size
                if (t.icon_circle_size !== undefined) icon_circle_size = t.icon_circle_size
                if (t.primary_alpha !== undefined) primary_alpha = t.primary_alpha
                if (t.hover_border_alpha !== undefined) hover_border_alpha = t.hover_border_alpha
                if (t.font_size_label !== undefined) font_size_label = t.font_size_label
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
        ipcTarget: "power"
    }

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: root.ready ? root.tokens.panel_width : 180
    implicitHeight: column.implicitHeight + (root.ready ? root.tokens.button_height : 56)
    color: "transparent"
    anchors.right: true

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
            column.forceActiveFocus()
        }
    }

    function activateSelected() {
        var commands = [
            Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -l",
            Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -s",
            Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -e",
            Quickshell.env("HOME") + "/.config/hypr/scripts/power.sh hibernate",
            Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -r",
            Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -p"
        ]
        if (selectedIndex >= 0 && selectedIndex < commands.length) {
            Quickshell.execDetached(["bash", "-c", commands[selectedIndex]])
            state.isOpen = false
        }
    }

    visible: state.ready && (state.isOpen || root.slideOffset !== -120)

    property int slideOffset: state.isOpen ? 0 : -120

    Behavior on slideOffset {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    margins { right: root.slideOffset }

    Item {
        id: panelContainer
        width: 160
        height: column.implicitHeight + root.tokens.button_height
        anchors.centerIn: parent

        GlassPanel.GlassPanel {
            anchors.fill: parent
            colors: state.colors
            tokens: root.tokens
        }

        ColumnLayout {
            id: column
            anchors.right: parent.right
            anchors.rightMargin: root.tokens.button_spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.tokens.button_spacing
            focus: true

            Keys.onUpPressed: {
                if (root.selectedIndex <= 0) root.selectedIndex = root.buttonCount - 1
                else root.selectedIndex--
            }
            Keys.onDownPressed: {
                if (root.selectedIndex >= root.buttonCount - 1) root.selectedIndex = 0
                else root.selectedIndex++
            }
            Keys.onReturnPressed: root.activateSelected()
            Keys.onEnterPressed: root.activateSelected()

            component PowerButton: Item {
                id: btn
                property string iconSrc: ""
                property string action: ""
                property string label: ""
                property string originalLabel: label
                property bool isSelected: false
                property int btnIndex: 0

                implicitWidth: root.tokens.button_width
                implicitHeight: root.tokens.button_height

                opacity: state.isOpen ? 1 : 0
                transform: Translate {
                    x: state.isOpen ? 0 : 40
                    Behavior on x {
                        SequentialAnimation {
                            PauseAnimation { duration: btn.btnIndex * 40 }
                            NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
                        }
                    }
                }
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: btn.btnIndex * 40 }
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
                    }
                }

                SequentialAnimation on scale {
                    running: btn.isSelected
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.05; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                }
                scale: btn.isSelected ? 1.05 : (mouseArea.containsMouse ? 1.05 : 1.0)
                Behavior on scale {
                    enabled: !btn.isSelected
                    NumberAnimation { duration: 200 }
                }

                Rectangle {
                    id: labelPill
                    anchors.right: circle.left
                    anchors.rightMargin: root.tokens.button_spacing
                    anchors.verticalCenter: parent.verticalCenter
                    height: root.tokens.label_height
                    width: (mouseArea.containsMouse || btn.isSelected) ? labelText.implicitWidth + 24 : 0
                    radius: root.tokens.label_radius
                    color: Qt.rgba(state.colors.surface_container.r, state.colors.surface_container.g, state.colors.surface_container.b, root.tokens.label_alpha)
                    opacity: width > 0 ? 1 : 0
                    clip: true

                    Behavior on width {
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: parent.radius - 1
                        color: "transparent"
                        border.color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, root.tokens.border_alpha)
                        border.width: root.tokens.border_width
                    }

                    Text {
                        id: labelText
                        anchors.centerIn: parent
                        text: btn.label
                        color: state.colors.on_surface
                        font.pixelSize: root.tokens.font_size_label
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    id: circle
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.tokens.icon_circle_size
                    height: root.tokens.icon_circle_size
                    radius: root.tokens.icon_circle_size / 2
                    color: mouseArea.containsMouse || btn.isSelected
                        ? "transparent"
                        : Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, root.tokens.primary_alpha)
                    border.color: Qt.rgba(state.colors.primary.r, state.colors.primary.g, state.colors.primary.b, mouseArea.containsMouse || btn.isSelected ? root.tokens.hover_border_alpha : 0)
                    border.width: root.tokens.border_width

                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }

                    Image {
                        id: btnIcon
                        anchors.centerIn: parent
                        source: btn.iconSrc
                        width: root.tokens.icon_size
                        height: root.tokens.icon_size
                        sourceSize.width: root.tokens.icon_size
                        sourceSize.height: root.tokens.icon_size
                        fillMode: Image.PreserveAspectFit
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: mouseArea.containsMouse || btn.isSelected
                                ? state.colors.primary
                                : state.colors.surface_dim
                        }
                        scale: mouseArea.pressed ? 0.8 : 1.0
                        rotation: mouseArea.pressed ? 8 : 0
                        Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }
                        Behavior on rotation { SpringAnimation { spring: 4; damping: 0.3 } }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    property bool confirmed: false
                    onClicked: {
                        if (!confirmed) {
                            confirmed = true
                            btn.label = "Confirm?"
                            resetTimer.start()
                        } else {
                            Quickshell.execDetached(["bash", "-c", btn.action])
                            state.isOpen = false
                        }
                    }
                    Timer {
                        id: resetTimer
                        interval: 2000
                        onTriggered: { mouseArea.confirmed = false; btn.label = btn.originalLabel }
                    }
                }
            }

            PowerButton {
                iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/lock.svg"
                action: Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -l"
                label: "Lock"
                isSelected: root.selectedIndex === 0
                btnIndex: 0
            }
            PowerButton {
                iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/suspend.svg"
                action: Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -s"
                label: "Suspend"
                isSelected: root.selectedIndex === 1
                btnIndex: 1
            }
            PowerButton {
                iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/logout.svg"
                action: Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -e"
                label: "Log Out"
                isSelected: root.selectedIndex === 2
                btnIndex: 2
            }
            PowerButton {
                iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/hibernate.svg"
                action: Quickshell.env("HOME") + "/.config/hypr/scripts/power.sh hibernate"
                label: "Hibernate"
                isSelected: root.selectedIndex === 3
                btnIndex: 3
            }
            PowerButton {
                iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/reboot.svg"
                action: Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -r"
                label: "Restart"
                isSelected: root.selectedIndex === 4
                btnIndex: 4
            }
            PowerButton {
                iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/shutdown.svg"
                action: Quickshell.env("HOME") + "/.config/shayar/scripts/shayar-power -p"
                label: "Shut Down"
                isSelected: root.selectedIndex === 5
                btnIndex: 5
            }
        }
    }
}
