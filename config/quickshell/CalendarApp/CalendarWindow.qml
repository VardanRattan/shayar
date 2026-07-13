import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    anchors.left: true
    anchors.top: true

    implicitWidth: root.ready ? root.tokens.calendar_width : 320
    implicitHeight: root.ready ? root.tokens.calendar_height : 380
    color: "transparent"

    margins {
        left: root.ready ? root.tokens.calendar_margin_left : 12
        top: root.ready ? root.tokens.waybar_clearance : 42
    }

    Behavior on margins.left {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }
    Behavior on margins.top {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }

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
    property bool ready: false
    property bool colorsLoaded: false
    property bool tokensLoaded: false

    onIsOpenChanged: {
        if (isOpen) {
            var now = new Date()
            todayDate = now.getDate()
            todayMonth = now.getMonth()
            todayYear = now.getFullYear()
            currentMonth = todayMonth
            currentYear = todayYear
            updateCalendar(currentYear, currentMonth)
        } else {
            root.pendingOpen = false
            root.margins.left = -400
        }
    }

    visible: ready && (isOpen || root.pendingOpen || popAnim.running)

    property QtObject colors: QtObject {
        property color background: "#12131b"
        property color primary: "#acc7ff"
        property color on_primary: "#062f64"
        property color surface_bright: "#393842"
        property color surface_dim: "#12131b"
        property color surface_container: "#1f1f28"
        property color surface_container_high: "#292932"
        property color shadow: "#000000"
        property color on_surface: "#e4e1ee"
        property color on_surface_variant: "#c4c6d1"
        property color error: "#ffb4ab"
        property color tertiary: "#ffb3b0"

        function updateFromJson(jsonString) {
            try {
                var c = JSON.parse(jsonString)
                if (!c || Object.keys(c).length === 0) return false
                if (c.background) background = c.background
                if (c.primary) primary = c.primary
                if (c.on_primary) on_primary = c.on_primary
                if (c.surface_bright) surface_bright = c.surface_bright
                if (c.surface_dim) surface_dim = c.surface_dim
                if (c.surface_container) surface_container = c.surface_container
                if (c.surface_container_high) surface_container_high = c.surface_container_high
                if (c.shadow) shadow = c.shadow
                if (c.on_surface) on_surface = c.on_surface
                if (c.on_surface_variant) on_surface_variant = c.on_surface_variant
                if (c.error) error = c.error
                if (c.tertiary) tertiary = c.tertiary
                return true
            } catch (e) {
                console.log("Failed to parse quickshell colors: " + e)
                return false
            }
        }
    }

    property QtObject tokens: QtObject {
        property real panel_bg_alpha: 0.7
        property real blur_strength: 0.7
        property real gradient_top_alpha: 0.12
        property real gradient_mid_alpha: 0.04
        property real border_alpha: 0.15
        property int border_width: 1
        property real shadow_alpha: 0.4
        property real blur_saturation: 0.0
        property real gradient_lower_alpha: 0.01
        property int shadow_blur: 24
        property int waybar_clearance: 42
        property int calendar_width: 320
        property int calendar_height: 380
        property int calendar_margin_left: 12
        property int calendar_radius: 24
        property int calendar_inner_margin: 20
        property int calendar_spacing: 10
        property int font_size_title: 16
        property int font_size_small: 11
        property int font_size_body: 12
        property int icon_size: 18
        property real primary_alpha: 0.9

        function updateFromJson(jsonString) {
            try {
                var t = JSON.parse(jsonString)
                if (!t || Object.keys(t).length === 0) return false
                if (t.panel_bg_alpha !== undefined) panel_bg_alpha = t.panel_bg_alpha
                if (t.blur_strength !== undefined) blur_strength = t.blur_strength
                if (t.gradient_top_alpha !== undefined) gradient_top_alpha = t.gradient_top_alpha
                if (t.gradient_mid_alpha !== undefined) gradient_mid_alpha = t.gradient_mid_alpha
                if (t.border_alpha !== undefined) border_alpha = t.border_alpha
                if (t.border_width !== undefined) border_width = t.border_width
                if (t.shadow_alpha !== undefined) shadow_alpha = t.shadow_alpha
                if (t.blur_saturation !== undefined) blur_saturation = t.blur_saturation
                if (t.gradient_lower_alpha !== undefined) gradient_lower_alpha = t.gradient_lower_alpha
                if (t.shadow_blur !== undefined) shadow_blur = t.shadow_blur
                if (t.waybar_clearance !== undefined) waybar_clearance = t.waybar_clearance
                if (t.calendar_width !== undefined) calendar_width = t.calendar_width
                if (t.calendar_height !== undefined) calendar_height = t.calendar_height
                if (t.calendar_margin_left !== undefined) calendar_margin_left = t.calendar_margin_left
                if (t.calendar_radius !== undefined) calendar_radius = t.calendar_radius
                if (t.calendar_inner_margin !== undefined) calendar_inner_margin = t.calendar_inner_margin
                if (t.calendar_spacing !== undefined) calendar_spacing = t.calendar_spacing
                if (t.font_size_title !== undefined) font_size_title = t.font_size_title
                if (t.font_size_small !== undefined) font_size_small = t.font_size_small
                if (t.font_size_body !== undefined) font_size_body = t.font_size_body
                if (t.icon_size !== undefined) icon_size = t.icon_size
                if (t.primary_alpha !== undefined) primary_alpha = t.primary_alpha
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

    property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property int todayDate: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()

    ListModel { id: dayModel }
    ListModel { id: weekModel }

    Component.onCompleted: updateCalendar(currentYear, currentMonth)

    function prevMonth() {
        if (currentMonth === 0) { currentMonth = 11; currentYear-- }
        else currentMonth--
        updateCalendar(currentYear, currentMonth)
    }

    function nextMonth() {
        if (currentMonth === 11) { currentMonth = 0; currentYear++ }
        else currentMonth++
        updateCalendar(currentYear, currentMonth)
    }

    function goToday() {
        currentMonth = todayMonth
        currentYear = todayYear
        updateCalendar(currentYear, currentMonth)
    }

    function updateCalendar(year, month) {
        dayModel.clear()
        weekModel.clear()

        var firstDay = new Date(year, month, 1)
        var startingDayOfWeek = firstDay.getDay()
        var startCell = startingDayOfWeek === 0 ? 6 : startingDayOfWeek - 1

        var daysInMonth = new Date(year, month + 1, 0).getDate()
        var daysInPrevMonth = new Date(year, month, 0).getDate()

        for (var row = 0; row < 6; row++) {
            var dateInRow = new Date(year, month, 1 + (row * 7) - startCell)
            var d = new Date(Date.UTC(dateInRow.getFullYear(), dateInRow.getMonth(), dateInRow.getDate()))
            d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7))
            var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
            var weekNo = Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
            weekModel.append({ weekNumber: weekNo })
        }

        for (var i = 0; i < 42; i++) {
            if (i < startCell) {
                dayModel.append({ day: daysInPrevMonth - startCell + i + 1, isCurrentMonth: false, isToday: false })
            } else if (i >= startCell && i < startCell + daysInMonth) {
                var dayNum = i - startCell + 1
                var isTod = (dayNum === todayDate && month === todayMonth && year === todayYear)
                dayModel.append({ day: dayNum, isCurrentMonth: true, isToday: isTod })
            } else {
                dayModel.append({ day: i - startCell - daysInMonth + 1, isCurrentMonth: false, isToday: false })
            }
        }
    }

    component ActionIcon: Button {
        property string iconSrc: ""
        implicitWidth: 28; implicitHeight: 28
        background: Rectangle { color: "transparent" }
        contentItem: Image {
            source: iconSrc
            width: root.tokens.icon_size; height: root.tokens.icon_size
            sourceSize.width: root.tokens.icon_size; sourceSize.height: root.tokens.icon_size
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: root.colors.primary
            }
        }
    }

    component TodayButton: Button {
        text: "Today"
        implicitHeight: 28
        opacity: (currentMonth !== todayMonth || currentYear !== todayYear) ? 1 : 0
        enabled: opacity > 0
        visible: opacity > 0
        onClicked: goToday()

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

        background: Rectangle {
            color: "transparent"
            border.color: root.colors.primary
            border.width: root.tokens.border_width
            radius: 8
        }
        contentItem: Text {
            text: parent.text
            font.pixelSize: root.tokens.font_size_body
            color: root.colors.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 4; leftPadding: 10; rightPadding: 10
        }
    }

    Item {
        id: popContainer
        anchors.fill: parent
        anchors.margins: 0

        property real popScale: root.isOpen ? 1.0 : 0.85
        property real popOpacity: root.isOpen ? 1.0 : 0.0

        Behavior on popScale {
            NumberAnimation { id: popAnim; duration: 200; easing.type: Easing.OutBack }
        }
        Behavior on popOpacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        transform: Scale { origin.x: 0; origin.y: 0; xScale: popContainer.popScale; yScale: popContainer.popScale }
        opacity: popContainer.popOpacity

        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: root.tokens.calendar_radius
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
            anchors.fill: parent
            anchors.margins: root.tokens.calendar_inner_margin
            spacing: root.tokens.calendar_spacing

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                ActionIcon { iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/chevron-left.svg"; onClicked: prevMonth() }

                Text {
                    Layout.preferredWidth: 130
                    text: monthNames[currentMonth] + " " + currentYear
                    color: root.colors.on_surface
                    font.pixelSize: root.tokens.font_size_title; font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }

                ActionIcon { iconSrc: Quickshell.env("HOME") + "/.config/quickshell/icons/chevron-right.svg"; onClicked: nextMonth() }

                Item { Layout.fillWidth: true }

                TodayButton {}
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.colors.primary; opacity: 0.2 }

            RowLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8

                ColumnLayout {
                    Layout.fillHeight: true; spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: "Wk"
                        color: root.colors.on_surface_variant; opacity: 0.7
                        font.pixelSize: root.tokens.font_size_small; font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        Layout.bottomMargin: 3
                    }
                    Repeater {
                        model: weekModel
                        Text {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            text: model.weekNumber
                            color: root.colors.primary; opacity: 0.6
                            font.pixelSize: root.tokens.font_size_small
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Rectangle { implicitWidth: 1; Layout.fillHeight: true; color: root.colors.primary; opacity: 0.2 }

                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        Repeater {
                            model: root.dayNames
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                color: (index >= 5) ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : root.colors.primary
                                font.pixelSize: root.tokens.font_size_body; font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    GridLayout {
                        columns: 7
                        Layout.fillWidth: true; Layout.fillHeight: true
                        rowSpacing: 3; columnSpacing: 3

                        Repeater {
                            model: dayModel

                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                radius: width / 2
                                color: model.isToday ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, root.tokens.primary_alpha) : dayHoverArea.containsMouse ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.08) : "transparent"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width; height: parent.height
                                    radius: width / 2
                                    color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.4)
                                    visible: model.isToday
                                    SequentialAnimation on scale {
                                        running: model.isToday
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 1.5; duration: 1500; easing.type: Easing.OutSine }
                                        NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InSine }
                                    }
                                    SequentialAnimation on opacity {
                                        running: model.isToday
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.0; duration: 1500; easing.type: Easing.OutSine }
                                        NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InSine }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: model.day
                                    font.pixelSize: root.tokens.font_size_body
                                    font.weight: model.isToday ? Font.Bold : Font.Normal
                                    color: model.isToday ? root.colors.surface_dim : ((index % 7 >= 5) ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.8) : root.colors.on_surface)
                                    opacity: model.isCurrentMonth ? 1 : 0.3
                                }

                                Rectangle {
                                    width: 3; height: 3; radius: 1.5
                                    color: root.colors.primary
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: model.isCurrentMonth && !model.isToday && (model.day % 6 === 0)
                                }

                                MouseArea {
                                    id: dayHoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(x: real, y: real): void {
            if (root.isOpen) {
                root.isOpen = false
                root.pendingOpen = false
            } else {
                root.margins.left = x - 20
                root.margins.top = y + 8
                root.pendingOpen = true
                root.isOpen = true
            }
        }
        function open(x: real, y: real): void {
            root.margins.left = x - 20
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
