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
            activeConnFetcher.running = true
            if (!wifiScan.running) wifiScan.running = true
        } else {
            root.pendingOpen = false
            root.netStatus = ""
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
    property bool isScanning: false
    property bool isManualScan: false
    property string netStatus: ""
    property string activeIp: ""
    ListModel { id: wifiModel }
    Timer {
        id: netStatusTimer
        interval: 2000
        onTriggered: root.netStatus = ""
    }
    Timer {
        id: minScanDurationTimer
        interval: 1500
        onTriggered: {
            if (root.isManualScan && !wifiScan.running) {
                root.isManualScan = false
                root.isScanning = false
            }
        }
    }
    function restartScan() {
        root.isManualScan = true
        root.isScanning = true
        minScanDurationTimer.restart()
        Quickshell.execDetached(["bash", "-c", "nmcli device wifi rescan"])
        scanDelay.restart()
    }
    Timer {
        id: scanDelay
        interval: 2000
        onTriggered: wifiScan.running = true
    }
    Timer {
        id: autoRefreshTimer
        interval: 3000
        running: root.isOpen && !wifiScan.running
        repeat: true
        onTriggered: wifiScan.running = true
    }
    Process {
        id: wifiScan
        command: ["timeout", "10", "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,BSSID,FREQ", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.isManualScan && !minScanDurationTimer.running) {
                    root.isManualScan = false
                    root.isScanning = false
                }
                parseWifi(this.text.trim())
            }
        }
    }
    Process {
        id: activeConnFetcher
        command: ["bash", "-c", "dev=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | grep ':wifi$' | head -1 | cut -d: -f1); [ -n \"$dev\" ] && nmcli -t -f IP4.ADDRESS device show \"$dev\" 2>/dev/null | head -1 | cut -d: -f2 | cut -d/ -f1 || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeIp = this.text.trim()
            }
        }
    }
    function freqBand(freq) {
        if (!freq) return ""
        var mhz = parseInt(freq)
        if (isNaN(mhz)) return ""
        if (mhz < 3000) return "2.4G"
        if (mhz < 6000) return "5G"
        return "6G"
    }
    function parseWifi(text) {
        wifiModel.clear()
        if (!text) return
        var seen = {}
        var entries = []
        text.split("\n").forEach(function (line) {
            if (!line) return
            var p = line.split(":")
            var inUse = p[0] === "*"
            var ssid = p[1] || "(hidden)"
            var signal = parseInt(p[2]) || 0
            var security = p[3] || ""
            var bssid = p.slice(4, 10).join(":").replace(/\\/g, "")
            var freq = p.length > 10 ? p[10] || "" : ""
            if (seen[ssid]) {
                if (signal > seen[ssid].signal || inUse) {
                    seen[ssid].signal = Math.max(signal, seen[ssid].signal)
                    seen[ssid].inUse = inUse || seen[ssid].inUse
                    seen[ssid].secured = security !== "" && security !== "--"
                }
                return
            }
            var entry = {
                inUse: inUse,
                ssid: ssid,
                signal: signal,
                secured: security !== "" && security !== "--",
                bssid: bssid,
                freq: freqBand(freq),
                signalLabel: signal + "%"
            }
            seen[ssid] = entry
            entries.push(entry)
        })
        entries.sort(function (a, b) {
            if (a.inUse && !b.inUse) return -1
            if (!a.inUse && b.inUse) return 1
            return b.signal - a.signal
        })
        entries.forEach(function (e) { wifiModel.append(e) })
    }
    Item {
        id: panelContainer
        width: root.tokens.panel_width_wide
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
                            width: 36; height: 36; radius: 18
                            color: mouseAreaToggle.containsMouse
                                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3)
                                : root.wifiEnabled
                                    ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15)
                                    : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                            border.color: root.wifiEnabled ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.4) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text {
                                anchors.centerIn: parent
                                text: root.wifiEnabled ? "\uF1EB" : "\uF057"
                                color: root.wifiEnabled ? root.colors.primary : root.colors.on_surface_variant
                                font.pixelSize: root.tokens.list_icon_size + 2
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
                                        restartScan()
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: mouseAreaRefresh.containsMouse
                                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3)
                                : Qt.rgba(root.colors.surface_container_high.r, root.colors.surface_container_high.g, root.colors.surface_container_high.b, 0.6)
                            border.color: root.isScanning ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.4) : "transparent"
                            border.width: 1
                            Text {
                                id: refreshIcon
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
                                    target: refreshIcon
                                    property: "rotation"
                                    from: 0; to: 360
                                    duration: 1200
                                    easing.type: Easing.InOutQuad
                                }
                            }
                            MouseArea {
                                id: mouseAreaRefresh
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
                model: wifiModel
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: model.inUse ? root.tokens.row_height + 16 : root.tokens.row_height
                    radius: 14
                    scale: model.inUse ? 1.01 : 1.0
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.2 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                    color: rowMouse.containsMouse
                        ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.row_hover_alpha + (model.inUse ? 0.08 : 0.05))
                        : model.inUse
                            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.14)
                            : "transparent"
                    border.color: model.inUse ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.45) : "transparent"
                    border.width: model.inUse ? 1 : 0

                    // Left active indicator marker bar
                    Rectangle {
                        visible: model.inUse
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
                        anchors.leftMargin: model.inUse ? root.tokens.list_row_margin + 4 : root.tokens.list_row_margin
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
                                    font.pixelSize: model.inUse ? root.tokens.font_size_label + 1 : root.tokens.font_size_label
                                    font.weight: model.inUse ? Font.Bold : Font.Medium
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    visible: model.inUse
                                    height: 18
                                    radius: 9
                                    color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
                                    border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.45)
                                    border.width: 1
                                    implicitWidth: wifiBadgeRow.implicitWidth + 12
                                    RowLayout {
                                        id: wifiBadgeRow
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
                                    text: model.inUse
                                        ? ((root.activeIp !== "" ? root.activeIp + "  •  " : "") + (model.freq !== "" ? model.freq + "  •  " : "") + model.signalLabel)
                                        : model.signalLabel
                                    color: model.inUse ? root.colors.on_surface_variant : (model.signal > 70 ? root.colors.primary : model.signal > 40 ? root.colors.tertiary : root.colors.error)
                                    font.pixelSize: root.tokens.font_size_small
                                    font.weight: model.inUse ? Font.Medium : Font.Normal
                                }
                                Text {
                                    visible: model.freq !== "" && !model.inUse
                                    text: model.freq
                                    color: root.colors.on_surface_variant
                                    font.pixelSize: root.tokens.font_size_small - 1
                                    font.weight: Font.Normal
                                }
                                Text {
                                    text: model.secured ? "\uF023" : ""
                                    color: root.colors.on_surface_variant
                                    font.pixelSize: 10
                                    font.family: root.ready && root.tokens.icon_font_family ? root.tokens.icon_font_family : "Symbols Nerd Font Mono"
                                    visible: !model.inUse
                                }
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
                                root.netStatus = "Disconnecting..."
                                netStatusTimer.restart()
                                Quickshell.execDetached(["bash", "-c", "nmcli device disconnect \"$(nmcli -t -f DEVICE,TYPE device status | grep wifi | cut -d: -f1)\""])
                            } else {
                                root.netStatus = "Connecting to " + model.ssid + "..."
                                netStatusTimer.restart()
                                Quickshell.execDetached(["bash", "-c", "nmcli device wifi connect \"" + model.bssid + "\""])
                            }
                            wifiScan.running = true
                        }
                    }
                }
            }
            Text {
                visible: wifiModel.count === 0 && root.wifiEnabled && !root.isScanning
                text: "No networks found \u2014 tap scan to discover"
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
                visible: !root.wifiEnabled
                text: "Wi-Fi is disabled"
                color: root.colors.on_surface_variant
                font.pixelSize: root.tokens.font_size_label
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16
            }
            Rectangle {
                visible: root.netStatus !== ""
                Layout.fillWidth: true
                height: 28
                radius: 8
                color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.12)
                Text {
                    anchors.centerIn: parent
                    text: root.netStatus
                    color: root.colors.primary
                    font.pixelSize: root.tokens.font_size_small
                    font.weight: Font.Medium
                }
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
