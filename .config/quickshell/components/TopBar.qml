import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../colors.qml" as C

PanelWindow {
    id: topBar

    anchors {
        top: true
        left: true
        right: true
    }

    height: 32
    color: C.bg

    // ── Layer-shell namespace for Hyprland layer rules ───────────────
    // Hyprland sees: quickshell:bar
    // Usage: layerrule = match:namespace quickshell:bar.*, blur on
    Component.onCompleted: {
        namespace = "quickshell:bar"
    }

    // ── Border line at bottom edge ───────────────────────────────────
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: C.border
    }

    RowLayout {
        anchors.fill: parent
        anchors { leftMargin: 12; rightMargin: 12 }
        spacing: 8

        // ── Workspace Indicators ─────────────────────────────────────
        Repeater {
            model: 10

            Rectangle {
                id: wsBtn
                Layout.alignment: Qt.AlignVCenter
                property int wsNum: index + 1
                property var ws: {
                    var values = Hyprland.workspaces.values
                    for (var i = 0; i < values.length; i++) {
                        if (values[i].id === wsNum) return values[i]
                    }
                    return null
                }
                property bool isActive: {
                    var fw = Hyprland.focusedWorkspace
                    return fw && fw.id === wsNum
                }
                property bool isOccupied: ws !== null && !isActive

                width: 28
                height: 24
                radius: 4
                color: isActive ? C.wsActive
                       : isOccupied ? C.wsOccupied
                       : C.wsEmpty

                // Active indicator dot
                Rectangle {
                    visible: isActive
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: -4
                    }
                    width: 16
                    height: 2
                    radius: 1
                    color: C.wsActive
                }

                Text {
                    anchors.centerIn: parent
                    text: wsNum
                    font {
                        family: C.fontFamily
                        pixelSize: 12
                        bold: isActive
                    }
                    color: isActive ? C.surface : C.fgDim
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsNum)
                }
            }
        }

        // ── Spacer (pushes title + clock to right) ────────────────────
        Item { Layout.fillWidth: true }

        // ── Focused Window Title ─────────────────────────────────────
        Text {
            id: windowTitle
            Layout.alignment: Qt.AlignVCenter
            visible: text !== ""
            text: {
                var fw = Hyprland.focusedWorkspace
                if (!fw || !fw.lastWindowTitle) return ""
                // Truncate long titles
                return fw.lastWindowTitle.length > 50
                    ? fw.lastWindowTitle.substring(0, 47) + "..."
                    : fw.lastWindowTitle
            }
            font {
                family: C.fontFamily
                pixelSize: 12
            }
            color: C.fgDim
            elide: Text.ElideRight
            Layout.maximumWidth: 400
        }

        // ── Spacer ───────────────────────────────────────────────────
        Item { Layout.fillWidth: true }

        // ── Clock ────────────────────────────────────────────────────
        Text {
            id: clock
            Layout.alignment: Qt.AlignVCenter
            font {
                family: C.fontFamily
                pixelSize: 13
                bold: true
            }
            color: C.fg

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    clock.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
            }

            Component.onCompleted: {
                clock.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
    }
}
