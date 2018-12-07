import QtQuick          2.11
import QtQuick.Controls 1.4
import QtBluetooth      5.2
import QtQuick.Window   2.11
import Qt.labs.settings 1.0
import QtQuick.Layouts  1.11

Rectangle {
    id:     root
    color:  "white"

    readonly property real maxRawPulse:                     78
    readonly property real gainTargetPulsePercent:          0.5
    readonly property real gainTargetPulsePercentWindow:    0.1
    readonly property int  minGain:                         1
    readonly property int  maxGain:                         15

    property real channel0PulsePercent: 0
    property real channel1PulsePercent: 0
    property real channel2PulsePercent: 0
    property real channel3PulsePercent: 0
    property int  gain:                 15
    property var  deviceList:           [ ]
    property var  rgSockets:            [ null, null, null, null ]
    property real heading:              0
    property int  freqDigit1
    property int  freqDigit2
    property int  freqDigit3
    property int  freqDigit4
    property int  freqDigit5
    property int  freqDigit6
    property int  freqInt
    property real fontPixelWidth:       textMeasureDefault.fontPixelWidth
    property real fontPixelHeight:      textMeasureDefault.fontPixelHeight
    property real fontPixelWidthLarge:  textMeasureLarge.fontPixelWidth
    property real fontPixelHeightLarge: textMeasureLarge.fontPixelHeight

    onChannel0PulsePercentChanged: channel0PulseSlice.requestPaint()
    onChannel1PulsePercentChanged: channel1PulseSlice.requestPaint()
    onChannel2PulsePercentChanged: channel2PulseSlice.requestPaint()
    onChannel3PulsePercentChanged: channel3PulseSlice.requestPaint()

    Component.onCompleted: {
        var rgDigits = [ 0, 0, 0, 0, 0, 0 ]
        var digitIndex = 5
        freqInt = settings.frequency
        while (freqInt > 0) {
            rgDigits[digitIndex] = freqInt % 10
            freqInt = freqInt / 10;
            digitIndex--
        }
        freqDigit1 = rgDigits[0]
        freqDigit2 = rgDigits[1]
        freqDigit3 = rgDigits[2]
        freqDigit4 = rgDigits[3]
        freqDigit5 = rgDigits[4]
        freqDigit6 = rgDigits[5]
    }

    onFreqDigit1Changed: setFrequencyFromDigits()
    onFreqDigit2Changed: setFrequencyFromDigits()
    onFreqDigit3Changed: setFrequencyFromDigits()
    onFreqDigit4Changed: setFrequencyFromDigits()
    onFreqDigit5Changed: setFrequencyFromDigits()
    onFreqDigit6Changed: setFrequencyFromDigits()

    function setFrequencyFromDigits() {
        settings.frequency = (freqDigit1 * 100000) + (freqDigit2 * 10000) + (freqDigit3 * 1000) + (freqDigit4 * 100) + (freqDigit5 * 10) + (freqDigit6)
        rgSockets.forEach(function(socket) {
            if (socket) {
                socket.stringData = "freq " + (settings.frequency * 100) + " "
            }
        })
    }

    Settings {
        id: settings

        property int frequency: 146000
    }

    Timer {
        id:             channel0NoPulseTimer
        running:        true
        interval:       3000
        onTriggered:    channel0PulsePercent = 0
    }

    Timer {
        id:             channel1NoPulseTimer
        running:        true
        interval:       3000
        onTriggered:    channel1PulsePercent = 0
    }

    Timer {
        id:             channel2NoPulseTimer
        running:        true
        interval:       3000
        onTriggered:    channel2PulsePercent = 0
    }

    Timer {
        id:             channel3NoPulseTimer
        running:        true
        interval:       3000
        onTriggered:    channel3PulsePercent = 0
    }

    Timer {
        running:    true
        interval:   15000
        repeat:     true

        onTriggered: {
            // Determine max pulse strength and adjust gain
            var maxPulsePct = Math.max(channel0PulsePercent, Math.max(channel1PulsePercent, Math.max(channel2PulsePercent, channel3PulsePercent)))
            console.log("maxPulsePct", maxPulsePct)
            var newGain = gain
            if (maxPulsePct > gainTargetPulsePercent + gainTargetPulsePercentWindow) {
                if (gain > minGain) {
                    newGain = gain - 1
                }
            } else if (maxPulsePct < gainTargetPulsePercent - gainTargetPulsePercentWindow) {
                if (gain < maxGain) {
                    newGain = gain + 1
                }
            }
            if (newGain !== gain) {
                console.log("Adjusting gain", newGain)
                gain = newGain
                rgSockets.forEach(function(socket) {
                    if (socket) {
                        socket.stringData = "gain " + gain + " "
                    }
                })
            }
        }
    }

    BluetoothDiscoveryModel {
        id:             btModel
        running:        true
        discoveryMode:  BluetoothDiscoveryModel.FullServiceDiscovery

        readonly property string _pulseServerUUID: "{94f39d29-7d6d-437d-973b-fba39e49d4ee}"

        onServiceDiscovered: {
            var serviceName = service.deviceName
            if (service.serviceUuid == _pulseServerUUID) {
                var channel = parseInt(serviceName.split(" ")[1])
                console.log(qsTr("Found PulseServer %1 %2 %3 %4 channel(%5)").arg(service.deviceAddress).arg(service.deviceName).arg(serviceName).arg(service.serviceUuid).arg(channel));
                console.log(rgSockets[channel])
                if (!rgSockets[channel]) {
                    console.log("Connecting to server")
                    rgSockets[channel] = btSocketComponent.createObject(root, {"channel": channel, "connected": true, "service": service})
                    channelConnectedRepeater.model = 0
                    channelConnectedRepeater.model = 4
                } else {
                    console.log("Already connected to server")
                }
            }
        }

        onErrorChanged: {
            switch (btModel.error) {
            case BluetoothDiscoveryModel.PoweredOffError:
                console.log("Error: Bluetooth device not turned on"); break;
            case BluetoothDiscoveryModel.InputOutputError:
                console.log("Error: Bluetooth I/O Error"); break;
            case BluetoothDiscoveryModel.InvalidBluetoothAdapterError:
                console.log("Error: Invalid Bluetooth Adapter Error"); break;
            case BluetoothDiscoveryModel.NoError:
                break;
            default:
                console.log("Error: Unknown Error"); break;
            }
        }

        onRunningChanged: {
            if (!running && deviceList.length < 4) {
                running = true
            }
        }
    }

    function updateHeading() {
        // Find strongest channel
        var strongestChannel = -1
        var strongestPulse = -1
        var rgPulse = [ channel0PulsePercent, channel1PulsePercent, channel2PulsePercent, channel3PulsePercent ]
        for (var index=0; index<rgPulse.length; index++) {
            if (rgPulse[index] > strongestPulse) {
                strongestChannel = index
                strongestPulse = rgPulse[index]
            }
        }

        // Is second strongest to the left/right heading-wise
        var rgLeft = [ 3, 0, 1, 2 ]
        var rgRight = [ 1, 2, 3, 0 ]
        var rgHeading = [ 0.0, 90.0, 180.0, 270.0 ]
        var strongLeft
        var secondaryStrength
        var leftPulse = rgPulse[rgLeft[strongestChannel]]
        var rightPulse = rgPulse[rgRight[strongestChannel]]
        var strongestPulseMultipler = 100.0 / strongestPulse
        if (leftPulse > rightPulse) {
            strongLeft = true
            heading = rgHeading[strongestChannel]
            heading -= 45.0 * strongestPulseMultipler * leftPulse
        } else {
            strongLeft = false
            heading = rgHeading[strongestChannel]
            heading += 45.0 * strongestPulseMultipler* leftPulse
        }

        if (heading > 360) {
            heading -= 360
        } else if (heading < 0) {
            heading += 360
        }
    }

    function processStringData(channel, stringData) {
        var split = stringData.split(" ")
        var pulse = parseInt(split[1])
        var temp = parseInt(split[2])
        //console.log("Data", stringData, channel, parseInt(split[0]), pulse, temp)
        pulse = Math.min(pulse, maxRawPulse)
        var pulsePercent = pulse / maxRawPulse
        if (channel === 0) {
            channel0PulsePercent = pulsePercent
            channel0NoPulseTimer.restart()
        } else if (channel === 1) {
            channel1PulsePercent = pulsePercent
            channel1NoPulseTimer.restart()
        } else if (channel === 2) {
            channel2PulsePercent = pulsePercent
            channel2NoPulseTimer.restart()
        } else if (channel === 3) {
            channel3PulsePercent = pulsePercent
            channel3NoPulseTimer.restart()
        }
        updateHeading()
    }

    Component {
        id: btSocketComponent

        BluetoothSocket {
            connected:              true
            onStringDataChanged:    processStringData(channel, stringData)

            property int channel: 0

            onConnectedChanged: {
                if (!connected) {
                    console.log(qsTr("Socket disconnected channel(%1)".arg(channel)))
                    rgSockets[channel] = null
                    channelConnectedRepeater.model = 0
                    channelConnectedRepeater.model = 4
                    destroy()
                }
            }

            onStateChanged: {
                if (state === Connected) {
                    stringData = "freq " + (settings.frequency * 100) * " "
                }
            }
        }
    }

    Text {
        id:         textMeasureDefault
        text:       "X"
        visible:    false

        property real fontPixelWidth:   contentWidth
        property real fontPixelHeight:  contentHeight
    }

    Text {
        id:             textMeasureLarge
        text:           "X"
        visible:        false
        font.pointSize: textMeasureDefault.font.pointSize * 2

        property real fontPixelWidth:   contentWidth
        property real fontPixelHeight:  contentHeight
    }

    function drawSlice(channel, ctx, centerX, centerX, radius) {
        var startPi = [ Math.PI * 1.25, Math.PI * 1.75, Math.PI * 0.25, Math.PI * 0.75 ]
        var stopPi = [ Math.PI * 1.75, Math.PI * 0.25, Math.PI * 0.75, Math.PI * 1.25 ]
        ctx.beginPath();
        ctx.fillStyle = "black";
        ctx.strokeStyle = "white";
        ctx.moveTo(centerX, centerX);
        ctx.arc(centerX, centerX, radius, startPi[channel], stopPi[channel], false);
        ctx.lineTo(centerX, centerX);
        ctx.fill();
        ctx.stroke()
    }

    Column {
        anchors.left:   parent.left
        anchors.right:  headingIndicator.left

        Text {
            anchors.left:   parent.left
            anchors.right:  parent.right
            text:           settings.frequency
            font.pointSize: 100
            fontSizeMode:   Text.HorizontalFit

            MouseArea {
                anchors.fill:   parent
                onClicked:      freqEditor.visible = true
            }
        }

        Text {
            anchors.margins:    parent.width / 4
            anchors.left:       parent.left
            anchors.right:      parent.right
            text:               "Gain " + gain
            font.pointSize:     100
            fontSizeMode:       Text.HorizontalFit

            MouseArea {
                anchors.fill:   parent
                onClicked:      console.log("Gain")
            }
        }
    }

    // Heading Indicator
    Rectangle {
        id:                 headingIndicator
        anchors.margins:    fontPixelWidth
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        width:              height
        radius:             height / 2
        color:              "transparent"
        border.color:       "black"
        border.width:       2

        property real _centerX: width / 2
        property real _centerY: height / 2

        Canvas {
            id:             channel0PulseSlice
            anchors.fill:   parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                drawSlice(0, ctx, parent._centerX, parent._centerY, parent.radius * channel0PulsePercent)
            }
        }

        Canvas {
            id:             channel1PulseSlice
            anchors.fill:   parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                drawSlice(1, ctx, parent._centerX, parent._centerY, parent.radius * channel1PulsePercent)
            }
        }

        Canvas {
            id:             channel2PulseSlice
            anchors.fill:   parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                drawSlice(2, ctx, parent._centerX, parent._centerY, parent.radius * channel2PulsePercent)
            }
        }

        Canvas {
            id:             channel3PulseSlice
            anchors.fill:   parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                drawSlice(3, ctx, parent._centerX, parent._centerY, parent.radius * channel3PulsePercent)
            }
        }

        Image {
            id:                     pointer
            source:                 "qrc:/attitudePointer.svg"
            mipmap:                 true
            fillMode:               Image.PreserveAspectFit
            anchors.leftMargin:     _pointerMargin
            anchors.rightMargin:    _pointerMargin
            anchors.topMargin:      _pointerMargin
            anchors.bottomMargin:   _pointerMargin
            anchors.fill:           parent
            sourceSize.height:      parent.height

            transform: Rotation {
                origin.x:       pointer.width  / 2
                origin.y:       pointer.height / 2
                angle:          heading
            }

            readonly property real _pointerMargin: -10
        }
    }

    Column {
        anchors.left:   parent.left
        anchors.bottom: parent.bottom

        Repeater {
            id:     channelConnectedRepeater
            model:  4

            Label {
                text: qsTr("Channel %1 - %2").arg(index).arg(rgSockets[index] ? "CONNECTED" : "not connected" )
            }
        }
    }

    Component {
        id: spinnerComponent

        Rectangle {
            width:  textMeasureLarge.fontPixelWidth * 1.25
            height: textMeasureLarge.fontPixelHeight * 2
            color:  "black"

            property alias value: list.currentIndex

            Text {
                id:             textMeasureLarge
                text:           "X"
                font.pointSize: 72
                visible:        false

                property real fontPixelWidth:   contentWidth
                property real fontPixelHeight:  contentHeight
            }

            ListView {
                id:                         list
                anchors.fill:               parent
                highlightRangeMode:         ListView.StrictlyEnforceRange
                preferredHighlightBegin:    textMeasureLarge.fontPixelHeight * 0.5
                preferredHighlightEnd:      textMeasureLarge.fontPixelHeight * 0.5
                clip:                       true
                spacing:                    -textMeasureDefault.fontPixelHeight * 0.25
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
                    GradientStop { position: 0.3; color: "#00000000" }
                    GradientStop { position: 0.7; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#FF000000" }
                }
            }
        }
    }

    Rectangle {
        id:             freqEditor
        anchors.fill:   parent
        visible:        false

        Button {
            anchors.right:  parent.right
            text:           "Close"
            onClicked:      freqEditor.visible = false
        }

        Row {
            anchors.centerIn:   parent
            spacing:            fontPixelWidth / 2

            Loader {
                id:                     loader1
                sourceComponent:        spinnerComponent
                Component.onCompleted:  item.value = freqDigit1

                Connections {
                    target:         loader1.item
                    onValueChanged: freqDigit1 = loader1.item.value
                }
            }

            Loader {
                id:                     loader2
                sourceComponent:        spinnerComponent
                Component.onCompleted:  item.value = freqDigit2

                Connections {
                    target:         loader2.item
                    onValueChanged: freqDigit2 = loader2.item.value
                }
            }

            Loader {
                id:                     loader3
                sourceComponent:        spinnerComponent
                Component.onCompleted:  item.value = freqDigit3

                Connections {
                    target:         loader3.item
                    onValueChanged: freqDigit3 = loader3.item.value
                }
            }

            Loader {
                id:                     loader4
                sourceComponent:        spinnerComponent
                Component.onCompleted:  item.value = freqDigit4

                Connections {
                    target:         loader4.item
                    onValueChanged: freqDigit4 = loader4.item.value
                }
            }

            Loader {
                id:                     loader5
                sourceComponent:        spinnerComponent
                Component.onCompleted:  item.value = freqDigit5

                Connections {
                    target:         loader5.item
                    onValueChanged: freqDigit5 = loader5.item.value
                }
            }

            Loader {
                id:                     loader6
                sourceComponent:        spinnerComponent
                Component.onCompleted:  item.value = freqDigit6

                Connections {
                    target:         loader6.item
                    onValueChanged: freqDigit6 = loader6.item.value
                }
            }
        }
    }
}
