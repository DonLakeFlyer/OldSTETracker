import QtQuick          2.11
import QtQuick.Controls 1.4

Rectangle {
    width:  _width
    height: _height
    color:  "black"

    Component.onCompleted: console.log(_width, _height)

    property alias value: list.currentIndex

    ListView {
        id:                         list
        anchors.fill:               parent
        highlightRangeMode:         ListView.StrictlyEnforceRange
        preferredHighlightBegin:    height/3
        preferredHighlightEnd:      height/3
        clip:                       true
        model:                      [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]

        delegate: Text {
            font.pointSize:             textMeasureLarge.font.pointSize
            color:                      "white"
            text:                       index
            anchors.horizontalCenter:   parent.horizontalCenter
        }
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FF000000" }
            GradientStop { position: 0.2; color: "#00000000" }
            GradientStop { position: 0.8; color: "#00000000" }
            GradientStop { position: 1.0; color: "#FF000000" }
        }
    }
}
