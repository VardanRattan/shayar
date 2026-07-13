import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: shell

    Loader { id: loaderPower; source: "PowerApp/PowerWindow.qml" }
    Loader { id: loaderCalendar; source: "CalendarApp/CalendarWindow.qml" }
    Loader { id: loaderNet; source: "NetApp/NetWindow.qml" }
    Loader { id: loaderBt; source: "BtApp/BtWindow.qml" }
    Loader { id: loaderVol; source: "VolApp/VolWindow.qml" }
    Loader { id: loaderWelcome; source: "WelcomeApp/WelcomeWindow.qml" }

    IpcHandler {
        target: "theme-manager"
        function reload(): void {
            ThemeManager.reload();
        }
    }
}
