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
    implicitWidth: root.ready ? root.tokens.welcome_panel_width : 420
    implicitHeight: contentColumn.implicitHeight + 48
    color: "transparent"
    Shortcut {
        sequence: "Escape"
        onActivated: { if (root.isOpen) root.isOpen = false }
    }
    property bool isOpen: false
    property bool pendingOpen: false
    readonly property var colors: ThemeManager.colors
    readonly property var tokens: ThemeManager.tokens
    readonly property bool ready: ThemeManager.ready
    property bool welcomed: false
    Component.onCompleted: {
        welcomeCheck.running = true
    }
    visible: ready && (isOpen || root.pendingOpen)
    margins {
        left: Math.round((Screen.width - (root.ready ? root.tokens.welcome_panel_width : 420)) / 2)
        top: Math.round((Screen.height - contentColumn.implicitHeight - 48) / 2)
    }
    Behavior on margins.top {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }
    Process {
        id: welcomeCheck
        command: ["cat", Quickshell.env("HOME") + "/.config/shayar/.welcomed"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.welcomed = this.text.trim() === "1"
                if (!root.welcomed && !root.isOpen) {
                    root.pendingOpen = true
                    root.isOpen = true
                    markWelcomed.running = true
                }
            }
        }
        running: false
    }
    Process {
        id: markWelcomed
        command: ["bash", "-c", "echo '1' > " + Quickshell.env("HOME") + "/.config/shayar/.welcomed"]
        running: false
    }
    Rectangle {
        id: panelBg
        anchors.fill: contentColumn
        anchors.margins: -24
        radius: root.ready ? root.tokens.welcome_panel_radius : 24
        color: Qt.rgba(root.colors.surface_container.r, root.colors.surface_container.g, root.colors.surface_container.b, 0.95)
        border.color: Qt.rgba(root.colors.outline_variant.r, root.colors.outline_variant.g, root.colors.outline_variant.b, 0.2)
        border.width: 1
    }
    RectangularShadow {
        z: -1
        anchors.fill: panelBg
        radius: panelBg.radius
        blur: 24
        color: Qt.rgba(root.colors.shadow.r, root.colors.shadow.g, root.colors.shadow.b, 0.5)
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    ColumnLayout {
        id: contentColumn
        width: root.ready ? root.tokens.welcome_panel_width - 48 : 372
        anchors.centerIn: parent
        spacing: 0
        // Close button — top right corner, overlapping the header
        Rectangle {
            id: closeBtn
            z: 20
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.topMargin: -12
            Layout.rightMargin: -8
            Layout.bottomMargin: 8
            radius: 14
            color: closeMa.containsMouse
                ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.3)
                : Qt.rgba(root.colors.surface_bright.r, root.colors.surface_bright.g, root.colors.surface_bright.b, 0.3)
            Text {
                anchors.centerIn: parent
                text: "\u2715"
                font.pixelSize: 14
                color: closeMa.containsMouse ? root.colors.error : root.colors.on_surface_variant
            }
            MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.isOpen = false
                    root.pendingOpen = false
                }
            }
        }
        // Logo — centered, prominent
        ColumnLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            spacing: 12
            Image {
                source: Quickshell.env("HOME") + "/.config/shayar/assets/shayar-logo.png"
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                Layout.alignment: Qt.AlignHCenter
                fillMode: Image.PreserveAspectFit
            }
            Text {
                text: "Welcome to Shayar"
                font.family: "Fira Sans"
                font.pixelSize: root.ready ? root.tokens.font_size_title : 16
                font.bold: true
                color: root.colors.on_surface
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Your Hyprland desktop is ready. Here are the essentials:"
                font.family: "Fira Sans"
                font.pixelSize: root.ready ? root.tokens.font_size_body : 12
                color: root.colors.on_surface_variant
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.bottomMargin: 12
            height: 1
            color: Qt.rgba(root.colors.outline_variant.r, root.colors.outline_variant.g, root.colors.outline_variant.b, 0.2)
        }
        // Keybindings
        Text {
            text: "KEYBINDINGS"
            font.family: "Fira Sans"
            font.pixelSize: root.ready ? root.tokens.font_size_small : 11
            font.bold: true
            color: root.colors.primary
            font.letterSpacing: 1.2
            Layout.bottomMargin: 8
        }
        Repeater {
            model: ListModel {
                ListElement { key: "SUPER + Return"; action: "Terminal" }
                ListElement { key: "SUPER + B"; action: "Browser" }
                ListElement { key: "SUPER + CTRL + Return"; action: "App Launcher" }
                ListElement { key: "SUPER + CTRL + W"; action: "Random Wallpaper" }
                ListElement { key: "SUPER + V"; action: "Clipboard Manager" }
                ListElement { key: "ALT + SPACE"; action: "Settings Menu" }
                ListElement { key: "SUPER + CTRL + K"; action: "Keybindings" }
                ListElement { key: "SUPER + CTRL + L"; action: "Power Menu" }
                ListElement { key: "SUPER + SHIFT + B"; action: "Toggle Statusbar" }
                ListElement { key: "SUPER + CTRL + H"; action: "This Screen" }
            }
            delegate: RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 28
                    radius: 6
                    color: Qt.rgba(root.colors.surface_bright.r, root.colors.surface_bright.g, root.colors.surface_bright.b, 0.4)
                    border.color: Qt.rgba(root.colors.outline_variant.r, root.colors.outline_variant.g, root.colors.outline_variant.b, 0.15)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: model.key
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: root.ready ? root.tokens.font_size_small : 11
                        color: root.colors.primary
                    }
                }
                Text {
                    text: model.action
                    font.family: "Fira Sans"
                    font.pixelSize: root.ready ? root.tokens.font_size_body : 12
                    color: root.colors.on_surface_variant
                    Layout.fillWidth: true
                }
            }
        }
        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            height: 1
            color: Qt.rgba(root.colors.outline_variant.r, root.colors.outline_variant.g, root.colors.outline_variant.b, 0.2)
        }
        // Quick launch buttons
        Text {
            text: "QUICK LAUNCH"
            font.family: "Fira Sans"
            font.pixelSize: root.ready ? root.tokens.font_size_small : 11
            font.bold: true
            color: root.colors.primary
            font.letterSpacing: 1.2
            Layout.bottomMargin: 8
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: ListModel {
                    ListElement { label: "Terminal"; cmd: "kitty" }
                    ListElement { label: "Browser"; cmd: "firefox" }
                    ListElement { label: "Launcher"; cmd: "~/.config/hypr/scripts/launcher.sh" }
                }
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 10
                    color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.primary_alpha)
                    opacity: launchMa.containsMouse ? 0.9 : 0.75
                    Text {
                        anchors.centerIn: parent
                        text: model.label
                        font.family: "Fira Sans"
                        font.pixelSize: root.ready ? root.tokens.font_size_body : 12
                        font.bold: true
                        color: root.colors.on_primary
                    }
                    MouseArea {
                        id: launchMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", model.cmd])
                            root.isOpen = false
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
            }
        }
        // Footer
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 16
            height: 1
            color: Qt.rgba(root.colors.outline_variant.r, root.colors.outline_variant.g, root.colors.outline_variant.b, 0.2)
        }
        Text {
            text: "Run shayar-welcome anytime to see this again"
            font.family: "Fira Sans"
            font.pixelSize: root.ready ? root.tokens.font_size_small : 11
            color: Qt.rgba(root.colors.on_surface_variant.r, root.colors.on_surface_variant.g, root.colors.on_surface_variant.b, 0.5)
            Layout.fillWidth: true
            Layout.topMargin: 8
        }
    }
    IpcHandler {
        target: "welcome"
        function toggle(): void {
            if (root.isOpen) {
                root.isOpen = false
                root.pendingOpen = false
            } else {
                root.pendingOpen = true
                root.isOpen = true
            }
        }
        function open(): void {
            root.pendingOpen = true
            root.isOpen = true
        }
        function close(): void {
            root.isOpen = false
            root.pendingOpen = false
        }
    }
}
