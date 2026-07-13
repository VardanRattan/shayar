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
    implicitWidth: root.ready ? root.tokens.panel_width_vol : 200
    implicitHeight: 45
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
    visible: ready && (isOpen || root.pendingOpen)
    margins {
        left: root.tokens.panel_width_vol ? (Screen.width - root.tokens.panel_width_vol - 8) : 300
        top: root.tokens.waybar_clearance
    }
    Behavior on margins.left {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }
    Behavior on margins.top {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }
    onIsOpenChanged: {
        if (isOpen) {
            // positioned via IPC args
        } else {
            root.pendingOpen = false
            root.margins.left = Screen.width + 200
        }
    }
    property real volume: 0.5
    property real displayVolume: 0.5
    Behavior on displayVolume { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    onVolumeChanged: displayVolume = volume
    property bool isMuted: false
    Process {
        id: volumePoller
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                if (lines.length > 0) {
                    var parts = lines[0].split(" ")
                    if (parts.length >= 2) {
                        var parsedVol = parseFloat(parts[1])
                        root.volume = isNaN(parsedVol) ? 0 : parsedVol
                        root.isMuted = lines[0].indexOf("[MUTED]") !== -1
                    }
                }
            }
        }
        running: root.isOpen
    }
    Timer {
        interval: 500
        running: root.isOpen
        repeat: true
        onTriggered: volumePoller.running = true
    }
    function setVolume(vol) {
        root.volume = vol
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol.toFixed(2)])
    }
    function toggleMute() {
        root.isMuted = !root.isMuted
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }
    Item {
        id: panelContainer
        width: root.tokens.panel_width
        height: 45
        anchors.top: parent.top
        anchors.right: parent.right
        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: root.tokens.vol_panel_radius
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
        RowLayout {
            id: volRow
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            Item {
                width: root.tokens.icon_size + 4
                height: root.tokens.icon_size + 4
                Text {
                    id: volIcon
                    anchors.centerIn: parent
                    text: (root.volume > 0.5 ? "\uF028" : root.volume > 0 ? "\uF027" : "\uF026")
                    color: root.isMuted ? root.colors.on_surface_variant : root.colors.primary
                    font.pixelSize: root.tokens.icon_size
                    font.family: "Symbols Nerd Font Mono"
                }
                Rectangle {
                    width: Math.sqrt(parent.width*parent.width + parent.height*parent.height) * 0.8
                    height: 2
                    color: root.colors.error
                    anchors.centerIn: parent
                    rotation: 45
                    opacity: root.isMuted ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMute()
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.tokens.bar_min_height
                radius: root.tokens.bar_radius
                color: Qt.rgba(root.colors.on_surface.r, root.colors.on_surface.g, root.colors.on_surface.b, root.tokens.track_alpha)
                Rectangle {
                    id: volHighlight
                    width: parent.width * root.volume
                    height: parent.height
                    radius: parent.radius
                    color: root.volume > 1.0 ? root.colors.error : root.colors.primary
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on width {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }
                Rectangle {
                    id: volThumb
                    width: root.tokens.thumb_size
                    height: root.tokens.thumb_size
                    radius: root.tokens.thumb_size / 2
                    color: root.colors.on_surface
                    anchors.verticalCenter: parent.verticalCenter
                    x: (parent.width - width) * root.volume
                    scale: thumbMouseArea.pressed || parentMouseArea.pressed ? 1.4 : 1.0
                    Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }
                    Behavior on x {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                    MouseArea {
                        id: thumbMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        property real dragStartX: 0
                        property real dragStartVol: 0
                        onPressed: {
                            dragStartX = mouseX
                            dragStartVol = root.volume
                        }
                        onPositionChanged: {
                            if (pressed) {
                                var delta = (mouseX - dragStartX) / volRow.width
                                var newVol = Math.max(0, Math.min(1.5, dragStartVol + delta))
                                root.setVolume(newVol)
                            }
                        }
                    }
                }
                MouseArea {
                    id: parentMouseArea
                    anchors.fill: parent
                    onPressed: {
                        var newVol = Math.max(0, Math.min(1.5, mouseX / width))
                        root.setVolume(newVol)
                    }
                    onWheel: function(event) {
                        var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                        root.setVolume(Math.max(0, Math.min(1.5, root.volume + delta)))
                    }
                }
            }
            Text {
                text: Math.round(root.displayVolume * 100) + "%"
                color: root.colors.on_surface
                font.pixelSize: root.tokens.font_size_label
                font.weight: Font.Medium
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
    }
    IpcHandler {
        target: "vol"
        function toggle(x: real, y: real): void {
            if (root.isOpen) {
                root.isOpen = false
                root.pendingOpen = false
            } else {
                var pw = root.tokens ? root.tokens.panel_width_vol : 200
                root.margins.left = Math.max(12, Math.min(x - pw / 2, Screen.width - pw - 12))
                root.margins.top = y + 8
                root.pendingOpen = true
                root.isOpen = true
            }
        }
        function open(x: real, y: real): void {
            var pw = root.tokens ? root.tokens.panel_width_vol : 200
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
