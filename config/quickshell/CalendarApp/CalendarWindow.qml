import ".."
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
    readonly property var colors: ThemeManager.colors
    readonly property var tokens: ThemeManager.tokens
    readonly property bool ready: ThemeManager.ready
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
                var calWidth = root.ready ? root.tokens.calendar_width : 320
                var margin = root.ready ? root.tokens.calendar_margin_left : 12
                root.margins.left = Math.max(margin, Math.min(x - calWidth / 2, Screen.width - calWidth - margin))
                root.margins.top = y + 8
                root.pendingOpen = true
                root.isOpen = true
            }
        }
        function open(x: real, y: real): void {
            var calWidth = root.ready ? root.tokens.calendar_width : 320
            var margin = root.ready ? root.tokens.calendar_margin_left : 12
            root.margins.left = Math.max(margin, Math.min(x - calWidth / 2, Screen.width - calWidth - margin))
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
