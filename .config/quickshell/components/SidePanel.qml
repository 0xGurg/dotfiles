import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../colors.qml" as C

PanelWindow {
    id: sidePanel

    anchors {
        right: true
        top: true
        bottom: true
    }

    width: 340
    color: C.bg

    Component.onCompleted: {
        namespace = "quickshell:sidebar"
    }

    // Border at left edge
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 1
        color: C.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 18

        // Header: Clock + Date
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                id: panelClock
                Layout.alignment: Qt.AlignHCenter
                font {
                    family: C.fontFamily
                    pixelSize: 42
                    bold: true
                }
                color: C.fg

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: panelClock.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
                Component.onCompleted: panelClock.text = Qt.formatDateTime(new Date(), "HH:mm")
            }

            Text {
                id: panelDate
                Layout.alignment: Qt.AlignHCenter
                font {
                    family: C.fontFamily
                    pixelSize: 14
                }
                color: C.fgDim
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: C.border
        }

        // System Stats
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "System"
                font {
                    family: C.fontFamily
                    pixelSize: 11
                    bold: true
                }
                color: C.fgMuted
            }

            StatRow {
                label: "CPU"
                value: cpuUsage
                icon: " "
                accentColor: C.blue
            }

            StatRow {
                label: "RAM"
                value: memUsage
                icon: " "
                accentColor: C.cyan
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: C.border
        }

        // Quick Launchers
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Quick Launch"
                font {
                    family: C.fontFamily
                    pixelSize: 11
                    bold: true
                }
                color: C.fgMuted
            }

            QuickLaunch {
                label: "Terminal"
                icon: " "
                command: "ghostty"
            }

            QuickLaunch {
                label: "Browser"
                icon: " "
                command: "brave"
            }

            QuickLaunch {
                label: "Files"
                icon: " "
                command: "nautilus"
            }

            QuickLaunch {
                label: "Launcher"
                icon: " "
                command: "hyprlauncher"
            }
        }

        // Spacer
        Item { Layout.fillHeight: true }
    }

    // System stat properties
    property string cpuUsage: "--%"
    property string memUsage: "--%"

    // CPU usage via /proc/stat
    Process {
        id: cpuProc
        command: ["grep", "cpu ", "/proc/stat"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 5) {
                    var user = parseInt(parts[1])
                    var nice = parseInt(parts[2])
                    var system = parseInt(parts[3])
                    var idle = parseInt(parts[4])
                    var total = user + nice + system + idle
                    if (total > 0) {
                        sidePanel.cpuUsage = Math.round(100 * (user + nice + system) / total) + "%"
                    }
                }
            }
        }
    }

    // Memory usage via /proc/meminfo
    Process {
        id: memProc
        command: ["grep", "-E", "^(MemTotal|MemAvailable):", "/proc/meminfo"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                var lines = data.trim().split("\n")
                var total = 0, avail = 0
                for (var i = 0; i < lines.length; i++) {
                    var m = lines[i].match(/(\d+)/)
                    if (m) {
                        if (lines[i].indexOf("MemTotal") >= 0) total = parseInt(m[1])
                        else if (lines[i].indexOf("MemAvailable") >= 0) avail = parseInt(m[1])
                    }
                }
                if (total > 0) {
                    sidePanel.memUsage = Math.round(100 * (total - avail) / total) + "%"
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
        }
    }

    Component.onCompleted: {
        cpuProc.running = true
        memProc.running = true
    }
}
