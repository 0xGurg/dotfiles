import QtQuick
import Quickshell
import "components"

ShellRoot {
    // Multi-monitor: one TopBar per screen, SidePanel on primary screen only

    Variants {
        model: Quickshell.screens

        TopBar {
            required property var modelData
            screen: modelData
        }

    // Side panel only on the primary monitor
    SidePanel {
        required property var modelData
        visible: modelData.isPrimary
        screen: modelData
    }
    }
}
