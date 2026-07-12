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
    implicitHeight: column.implicitHeight + (root.ready ? root.tokens.button_height : 56)
    color: "transparent"
    anchors.right: true

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

    visible: ready && (isOpen || root.slideOffset !== -120)

    property int slideOffset: isOpen ? 0 : -120

    Behavior on slideOffset {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    margins { right: root.slideOffset }

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
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
    }
}
