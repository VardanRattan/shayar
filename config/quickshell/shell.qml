import QtQuick
import Quickshell

ShellRoot {
    id: shell

    Loader { id: loaderPower; source: "PowerApp/PowerWindow.qml" }
    Loader { id: loaderCalendar; source: "CalendarApp/CalendarWindow.qml" }
    Loader { id: loaderNet; source: "NetApp/NetWindow.qml" }
    Loader { id: loaderBt; source: "BtApp/BtWindow.qml" }
    Loader { id: loaderVol; source: "VolApp/VolWindow.qml" }

    IpcHandler {
        target: "theme-manager"
        function reload(): void {
            if (loaderPower.item) loaderPower.item.reload()
            if (loaderCalendar.item) loaderCalendar.item.reload()
            if (loaderNet.item) loaderNet.item.reload()
            if (loaderBt.item) loaderBt.item.reload()
            if (loaderVol.item) loaderVol.item.reload()
        }
    }
}
