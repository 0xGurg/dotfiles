import QtQuick
import QtQuick.Layouts
import "../colors.qml" as C

RowLayout {
    required property string label
    required property string value
    required property string icon
    required property color accentColor

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: icon
        font { family: C.fontFamily; pixelSize: 14 }
        color: accentColor
    }

    Text {
        text: label
        font { family: C.fontFamily; pixelSize: 13 }
        color: C.fgDim
    }

    Item { Layout.fillWidth: true }

    Text {
        text: value
        font { family: C.fontFamily; pixelSize: 13; bold: true }
        color: C.fg
    }

    Rectangle {
        Layout.preferredWidth: 80
        Layout.preferredHeight: 4
        radius: 2
        color: C.bgHighlight

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: {
                var pct = parseFloat(value)
                return isNaN(pct) ? 0 : Math.min(parent.width * pct / 100, parent.width)
            }
            radius: 2
            color: accentColor
        }
    }
}
