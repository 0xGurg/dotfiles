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

        // Side panel only on the primary monitor (or first if none marked primary)
        SidePanel {
            required property var modelData
            visible: {
                if (!modelData) return index === 0
                return modelData.isPrimary || index === 0
            }
            screen: modelData
        }
    }
}
