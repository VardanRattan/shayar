import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Scope {
    Component.onCompleted: {
        // Force critical singletons to load on shell init instead of lazily
        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;

        // Weather.reload() removed from shell init to prevent unneeded network polling at idle.
        // It loads on demand if the dashboard weather widget is ever opened.

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
