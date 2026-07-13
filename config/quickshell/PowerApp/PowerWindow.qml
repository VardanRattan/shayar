import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."
PanelWindow {
    id: root
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore
    implicitWidth: root.ready ? root.tokens.panel_width : 180
    implicitHeight: column.implicitHeight + (root.ready ? root.tokens.button_height : 56)
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
    readonly property var colors: ThemeManager.colors
    readonly property var tokens: ThemeManager.tokens
    readonly property bool ready: ThemeManager.ready
    property int selectedIndex: -1
    readonly property int buttonCount: 6
    onIsOpenChanged: {
        if (isOpen) {
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
            root.isOpen = false
        }
    }
    visible: ready && (isOpen || root.pendingOpen)
    margins {
        right: 12
        top: (Screen.height - root.implicitHeight) / 2
    }
    Behavior on margins.right {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }
    Behavior on margins.top {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }
    Item {
        id: panelContainer
        width: 160
        height: column.implicitHeight + root.tokens.button_height
        anchors.centerIn: parent
        Rectangle {
            id: panelBg
            width: 80
            height: parent.height
            anchors.right: parent.right
            radius: root.tokens.panel_radius
            color: Qt.rgba(root.colors.surface_container.r, root.colors.surface_container.g, root.colors.surface_container.b, root.tokens.panel_bg_alpha)
            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Rectangle {
            anchors.fill: panelBg
            anchors.margins: 1
            radius: panelBg.radius - 1
            color: "transparent"
            border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.border_alpha)
            border.width: root.tokens.border_width
            opacity: root.isOpen ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
                opacity: root.isOpen ? 1 : 0
                transform: Translate {
                    x: root.isOpen ? 0 : 40
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
                scale: btn.isSelected ? 1.05 : 1.0
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
                    color: Qt.rgba(root.colors.surface_container.r, root.colors.surface_container.g, root.colors.surface_container.b, root.tokens.label_alpha)
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
                        border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.border_alpha)
                        border.width: root.tokens.border_width
                    }
                    Text {
                        id: labelText
                        anchors.centerIn: parent
                        text: btn.label
                        color: root.colors.on_surface
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
                        : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.primary_alpha)
                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, mouseArea.containsMouse || btn.isSelected ? root.tokens.hover_border_alpha : 0)
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
                                ? root.colors.primary
                                : root.colors.surface_dim
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
                            root.isOpen = false
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
    IpcHandler {
        target: "power"
        function toggle(x: real, y: real): void {
            if (root.isOpen) {
                root.isOpen = false
                root.pendingOpen = false
            } else {
                root.margins.right = 12
                root.margins.top = (Screen.height - root.implicitHeight) / 2
                root.pendingOpen = true
                root.isOpen = true
            }
        }
        function open(x: real, y: real): void {
            root.margins.right = 12
            root.margins.top = (Screen.height - root.implicitHeight) / 2
            root.pendingOpen = true
            root.isOpen = true
        }
        function close(): void {
            root.isOpen = false
            root.pendingOpen = false
        }
    }
}
