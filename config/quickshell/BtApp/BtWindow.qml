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
            root.isScanning = false
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
    property bool isScanning: false
    property bool isManualScan: false
    property string btStatus: ""
    property string btStatusType: "info"
    ListModel { id: btModel }
    Timer {
        id: statusClearTimer
        interval: 3000
        onTriggered: root.btStatus = ""
    }
    Timer {
        id: autoRefreshTimer
        interval: 5000
        running: root.isOpen && !btScan.running
        repeat: true
        onTriggered: btScan.running = true
    }
    function restartScan() {
        root.isManualScan = true
        root.isScanning = true
        minDurationTimer.restart()
        if (btScan.running) btScan.running = false
        Quickshell.execDetached(["bash", "-c", "bluetoothctl --timeout 12 scan on"])
        scanDelay.restart()
    }
    Timer {
        id: scanDelay
        interval: 2000
        onTriggered: btScan.running = true
    }
    Timer {
        id: minDurationTimer
        interval: 1500
        onTriggered: {
            if (root.isManualScan && !btScan.running) {
                root.isManualScan = false
                root.isScanning = false
            }
        }
    }
    function deviceTypeIcon(classHex) {
        if (!classHex) return "\uF1AD"
        var major = parseInt(classHex.substring(0, 4), 16) >> 8 & 0xFF
        switch (major) {
        case 0x04: return "\uF025"
        case 0x05: return "\uF11C"
        case 0x07: return "\uF095"
        case 0x02: return "\uF109"
        default: return "\uF1AD"
        }
    }
    Process {
        id: btScan
        command: ["timeout", "10", "bash", "-c", "echo \"POWERED:$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')\"; bluetoothctl devices 2>/dev/null | head -30 | while read -r prefix mac name; do [ \"$prefix\" != \"Device\" ] && continue; info=$(bluetoothctl info \"$mac\" 2>/dev/null); paired=$(echo \"$info\" | grep -q 'Paired: yes' && echo yes || echo no); connected=$(echo \"$info\" | grep -q 'Connected: yes' && echo yes || echo no); trusted=$(echo \"$info\" | grep -q 'Trusted: yes' && echo yes || echo no); battery=$(echo \"$info\" | grep 'Battery Percentage' | grep -oP '\\d+(?=\\))' || echo ''); class=$(echo \"$info\" | grep 'Class:' | awk '{print $2}' || echo ''); echo \"DEVICE:$mac:$name:$paired:$connected:$trusted:$battery:$class\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.isManualScan && !minDurationTimer.running) {
                    root.isManualScan = false
                    root.isScanning = false
                }
                parseBt(this.text.trim())
            }
        }
    }
    function parseBt(text) {
        btModel.clear()
        if (!text) return
        var seen = {}
        var entries = []
        text.split("\n").forEach(function (line) {
            if (!line) return
            if (line.indexOf("POWERED:") === 0) {
                root.btEnabled = line.substring(8) === "yes"
                return
            }
            if (line.indexOf("DEVICE:") !== 0) return
            var body = line.substring(7)
            var mac = body.substring(0, 17)
            var rest = body.substring(18)
            var parts = rest.split(":")
            var name = parts[0] || "Unknown"
            var paired = parts[1] === "yes"
            var connected = parts[2] === "yes"
            var trusted = parts[3] === "yes"
            var battery = parts[4] || ""
            var classHex = parts[5] || ""
            if (seen[mac]) return
            seen[mac] = true
            entries.push({
                mac: mac,
                name: name || "Unknown",
                paired: paired,
                connected: connected,
                trusted: trusted,
                battery: battery,
                classHex: classHex,
                deviceIcon: deviceTypeIcon(classHex)
            })
        })
        entries.sort(function (a, b) {
            if (a.connected && !b.connected) return -1
            if (!a.connected && b.connected) return 1
            if (a.paired && !b.paired) return -1
            if (!a.paired && b.paired) return 1
            return a.name.localeCompare(b.name)
        })
        entries.forEach(function (e) { btModel.append(e) })
    }
    Item {
        id: panelContainer
        width: root.tokens.panel_width_wide
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
                spacing: 0
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.4)
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8
                        Text {
                            text: "\uF1AD"
                            color: root.colors.primary
                            font.pixelSize: root.tokens.icon_size + 4
                            font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
                        }
                        Text {
                            text: "Bluetooth"
                            color: root.colors.on_surface
                            font.pixelSize: root.tokens.font_size_label + 2
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: mouseAreaBtToggle.containsMouse
                                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3)
                                : root.btEnabled
                                    ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15)
                                    : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                            border.color: root.btEnabled ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.4) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text {
                                anchors.centerIn: parent
                                text: root.btEnabled ? "\uF1AD" : "\uF057"
                                color: root.btEnabled ? root.colors.primary : root.colors.on_surface_variant
                                font.pixelSize: root.tokens.list_icon_size + 2
                                font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
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
                                        restartScan()
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: mouseAreaBtScan.containsMouse
                                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3)
                                : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                            border.color: root.isScanning ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.4) : "transparent"
                            border.width: 1
                            Text {
                                id: scanIcon
                                anchors.centerIn: parent
                                text: "\uF021"
                                color: root.colors.on_surface
                                font.pixelSize: root.tokens.list_icon_size + 2
                                font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
                            }
                            SequentialAnimation {
                                id: scanSpinAnimation
                                loops: Animation.Infinite
                                running: root.isScanning
                                NumberAnimation {
                                    target: scanIcon
                                    property: "rotation"
                                    from: 0; to: 360
                                    duration: 1200
                                    easing.type: Easing.InOutQuad
                                }
                            }
                            MouseArea {
                                id: mouseAreaBtScan
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    restartScan()
                                }
                            }
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
                    Layout.preferredHeight: model.connected ? root.tokens.row_height + 16 : root.tokens.row_height
                    radius: 14
                    scale: model.connected ? 1.01 : 1.0
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.2 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                    color: btRowMouse.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_hover_alpha + (model.connected ? 0.08 : 0.05))
                        : model.connected
                            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.14)
                            : "transparent"
                    border.color: model.connected ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.45) : "transparent"
                    border.width: model.connected ? 1 : 0

                    // Left active indicator marker bar
                    Rectangle {
                        visible: model.connected
                        width: 3
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        radius: 2
                        color: root.colors.primary
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root.tokens.list_row_margin
                        anchors.leftMargin: model.connected ? root.tokens.list_row_margin + 4 : root.tokens.list_row_margin
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
                                text: model.deviceIcon
                                color: model.connected ? root.colors.on_primary : root.colors.on_surface
                                font.pixelSize: root.tokens.list_icon_size
                                font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
                            }
                            Rectangle {
                                width: 12; height: 12; radius: 6
                                color: root.colors.surface_container
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                visible: model.trusted
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uF028"
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
                                    text: model.name
                                    color: model.connected ? root.colors.primary : root.colors.on_surface
                                    font.pixelSize: model.connected ? root.tokens.font_size_label + 1 : root.tokens.font_size_label
                                    font.weight: model.connected ? Font.Bold : Font.Medium
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    visible: model.connected
                                    height: 18
                                    radius: 9
                                    color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.45)
                                    border.width: 1
                                    implicitWidth: btBadgeRow.implicitWidth + 12
                                    RowLayout {
                                        id: btBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: root.colors.primary
                                            SequentialAnimation on opacity {
                                                loops: Animation.Infinite
                                                NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                                                NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                                            }
                                        }
                                        Text {
                                            text: "Connected"
                                            color: root.colors.primary
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                spacing: 6
                                Text {
                                    text: model.mac
                                    color: root.colors.on_surface_variant
                                    font.pixelSize: root.tokens.font_size_small
                                }
                                Rectangle {
                                    visible: !model.connected && model.paired
                                    height: 16
                                    radius: 8
                                    color: Qt.rgba(root.colors.surface_bright.r, root.colors.surface_bright.g, root.colors.surface_bright.b, root.tokens.badge_paired_alpha)
                                    implicitWidth: pairedLabel.implicitWidth + 8
                                    Text {
                                        id: pairedLabel
                                        anchors.centerIn: parent
                                        text: "Paired"
                                        color: root.colors.on_surface_variant
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                    }
                                }
                                Rectangle {
                                    visible: model.battery !== ""
                                    height: 16
                                    radius: 8
                                    color: Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                                    border.color: Qt.rgba(root.colors.outline_variant.r, root.colors.outline_variant.g, root.colors.outline_variant.b, 0.3)
                                    border.width: 1
                                    implicitWidth: btBatteryRow.implicitWidth + 8
                                    RowLayout {
                                        id: btBatteryRow
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Text {
                                            text: parseInt(model.battery) > 80 ? "\uF240" : parseInt(model.battery) > 50 ? "\uF241" : parseInt(model.battery) > 20 ? "\uF242" : "\uF243"
                                            color: parseInt(model.battery) > 20 ? root.colors.primary : root.colors.error
                                            font.pixelSize: 9
                                            font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
                                        }
                                        Text {
                                            text: model.battery + "%"
                                            color: root.colors.on_surface
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                        }
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
                                root.btStatus = "Disconnecting..."
                                root.btStatusType = "info"
                                statusClearTimer.restart()
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl disconnect " + model.mac])
                            } else if (model.paired) {
                                root.btStatus = "Connecting..."
                                root.btStatusType = "info"
                                statusClearTimer.restart()
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl connect " + model.mac])
                            } else {
                                root.btStatus = "Pairing..."
                                root.btStatusType = "info"
                                statusClearTimer.restart()
                                Quickshell.execDetached(["bash", "-c", "bluetoothctl pair " + model.mac + " && bluetoothctl trust " + model.mac + " && bluetoothctl connect " + model.mac])
                            }
                            btScan.running = true
                        }
                    }
                }
            }
            Text {
                visible: btModel.count === 0 && root.btEnabled && !btScan.running
                text: "No devices found \u2014 tap scan to discover"
                color: root.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16
                Rectangle {
                    anchors.top: parent.bottom
                    anchors.topMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 40; height: 3; radius: 2
                    color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                }
            }
            Text {
                visible: !root.btEnabled
                text: "Bluetooth is disabled"
                color: root.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16
            }
            Rectangle {
                visible: root.btStatus !== ""
                Layout.fillWidth: true
                height: 28
                radius: 8
                color: root.btStatusType === "error"
                    ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.15)
                    : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15)
                Text {
                    anchors.centerIn: parent
                    text: root.btStatus
                    color: root.btStatusType === "error" ? root.colors.error : root.colors.primary
                    font.pixelSize: root.tokens.font_size_small
                    font.weight: Font.Medium
                }
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
