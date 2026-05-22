import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../colors.qml" as C

Rectangle {
    id: root
    required property string label
    required property string icon
    required property string command

    Layout.fillWidth: true
    height: 36
    radius: 6
    color: mouseArea.containsMouse ? C.bgHighlight : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors { leftMargin: 12; rightMargin: 12 }
        spacing: 10

        Text {
            text: icon
            font { family: C.fontFamily; pixelSize: 15 }
            color: C.fgDim
        }

        Text {
            text: label
            font { family: C.fontFamily; pixelSize: 13 }
            color: C.fg
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: launcherProc.running = true
    }

    Process {
        id: launcherProc
        command: ["sh", "-c", root.command + " &"]
        running: false
    }
}
