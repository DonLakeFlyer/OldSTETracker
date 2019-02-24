import QtQuick                  2.11
import QtQuick.Controls         1.4
import QtBluetooth              5.2
import QtQuick.Window           2.11
import Qt.labs.settings         1.0
import QtQuick.Layouts          1.11
import QtQuick.Controls.Styles  1.4

Window {
    id:     root
    visible: true
    width: 640
    height: 480
    title: qsTr("STE Tracker")


    readonly property real maxRawPulse:                     20
    readonly property real minRawPulse:                     0.0001
    //readonly property real log10PulseRange:                 pulse.log10(maxRawPulse) - pulse.log10(minRawPulse)
    readonly property real pulseRange:                      maxRawPulse - minRawPulse
    readonly property real gainTargetPulsePercent:          0.5
    readonly property real gainTargetPulsePercentWindow:    0.1
    readonly property int  minGain:                         1
    readonly property int  maxGain:                         15
    readonly property int  channelTimeoutMSecs:             10000
    readonly property var   dbRadiationPct:                 [ 1.0,  .97,    .94,    .85,    .63,    .40,    .10,    .20,    .30,    .40,    .45,    0.5,    0.51 ]
    readonly property real  dbRadiationMinPulse:            maxRawPulse * 0.25
    readonly property var   dbRadiationAngle:               [ 0,    15,     30,     45,     60,     75,     90,     105,    120,    135,    150,    165,    180 ]
    readonly property real  dbRadiationAngleInc:            15

    property bool autoGain: true
    property int  gain:     21
    property real heading:  0

    property bool channel0FirstFreqSent: false
    property bool channel1FirstFreqSent: false
    property bool channel2FirstFreqSent: false
    property bool channel3FirstFreqSent: false

    property bool channel0Active:   false
    property bool channel1Active:   false
    property bool channel2Active:   false
    property bool channel3Active:   false

    property int channel0CPUTemp:  0
    property int channel1CPUTemp:  0
    property int channel2CPUTemp:  0
    property int channel3CPUTemp:  0

    property real channel0PulseValue:   0
    property real channel1PulseValue:   0
    property real channel2PulseValue:   0
    property real channel3PulseValue:   0

    property real channel0PulsePercent: 0
    property real channel1PulsePercent: 0
    property real channel2PulsePercent: 0
    property real channel3PulsePercent: 0

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

    onChannel0PulseValueChanged: { channel0Background.color = "green"; channel0Animate.restart() }
    onChannel1PulseValueChanged: { channel1Background.color = "green"; channel1Animate.restart() }
    onChannel2PulseValueChanged: { channel2Background.color = "green"; channel2Animate.restart() }
    onChannel3PulseValueChanged: { channel3Background.color = "green"; channel3Animate.restart() }

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
        pulse.setFreq(settings.frequency * 1000)
    }

    function _handlePulse(channelIndex, cpuTemp, pulseValue) {
        //console.log("Pulse", channelIndex, cpuTemp.toFixed(0), pulseValue.toFixed(5), pulse.log10(pulseValue))
        //console.log("log pulse %", (pulse.log10(pulseValue) - pulse.log10(minRawPulse)) / log10PulseRange)
        var pulsePercent
        if (pulseValue == 0) {
            pulsePercent = 0
        } else {
            //pulsePercent = (pulse.log10(pulseValue) - pulse.log10(minRawPulse)) / log10PulseRange
            pulsePercent = (pulseValue - minRawPulse) / pulseRange
        }
        if (channelIndex === 0) {
            channel0Active = true
            channel0PulseValue = pulseValue
            channel0PulsePercent = pulsePercent
            channel0CPUTemp = cpuTemp
            channel0NoPulseTimer.restart()
            if (!channel0FirstFreqSent) {
                channel0FirstFreqSent = true
                setFrequencyFromDigits()
            }
        } else if (channelIndex === 1) {
            channel1Active = true
            channel1PulseValue = pulseValue
            channel1PulsePercent = pulsePercent
            channel1CPUTemp = cpuTemp
            channel1NoPulseTimer.restart()
            if (!channel1FirstFreqSent) {
                channel1FirstFreqSent = true
                setFrequencyFromDigits()
            }
        } else if (channelIndex === 2) {
            channel2Active = true
            channel2PulseValue = pulseValue
            channel2PulsePercent = pulsePercent
            channel2CPUTemp = cpuTemp
            channel2NoPulseTimer.restart()
            if (!channel2FirstFreqSent) {
                channel2FirstFreqSent = true
                setFrequencyFromDigits()
            }
        } else if (channelIndex === 3) {
            channel3Active = true
            channel3PulseValue = pulseValue
            channel3PulsePercent = pulsePercent
            channel3CPUTemp = cpuTemp
            channel3NoPulseTimer.restart()
            if (!channel3FirstFreqSent) {
                channel3FirstFreqSent = true
                setFrequencyFromDigits()
            }
        }
        updateHeading()
    }

    Connections {
        target: pulse

        onPulse: _handlePulse(channelIndex, cpuTemp, pulseValue)
    }

    Timer {
        id:             pulseSimulator
        running:        true
        interval:       2000
        repeat:         true

        property real heading:          0
        property real headingIncrement: 5

        onTriggered: pulseSimulator.nextHeading()

        function generatePulse(channel, heading) {
            console.log("original", heading)
            if ( heading > 180) {
                heading = 180 - (heading - 180)
            }

            var radiationIndex
            if (heading == 0) {
                radiationIndex = 1
            } else {
                radiationIndex = Math.ceil(heading / dbRadiationAngleInc)
            }

            var powerLow = dbRadiationPct[radiationIndex-1]
            var powerHigh = dbRadiationPct[radiationIndex]
            var powerRange = powerHigh - powerLow
            var slicePct = (heading - ((radiationIndex - 1) * dbRadiationAngleInc)) / dbRadiationAngleInc
            var powerHeading = powerLow + (powerRange * slicePct)

            //console.log(qsTr("heading(%1) radiationIndex(%2) powerLow(%3) powerHigh(%4) powerRange(%5) slicePct(%6) powerHeading(%7)").arg(heading).arg(radiationIndex).arg(powerLow).arg(powerHigh).arg(powerRange).arg(slicePct).arg(powerHeading))

            var pulseValue = dbRadiationMinPulse + ((maxRawPulse - dbRadiationMinPulse) * powerHeading)
            console.log("heading:pulse", heading, pulseValue)

            _handlePulse(channel, 0, pulseValue)
        }

        function normalizeHeading(heading) {
            if (heading >= 360.0) {
                heading = heading - 360.0
            } else if (heading < 0) {
                heading = heading + 360
            }
            return heading
        }

        function nextHeading() {
            pulseSimulator.heading = pulseSimulator.normalizeHeading(pulseSimulator.heading + pulseSimulator.headingIncrement)
            console.log("Simulated Heading", heading)
            pulseSimulator.generatePulse(0, pulseSimulator.heading)
            pulseSimulator.generatePulse(1, pulseSimulator.normalizeHeading(pulseSimulator.heading - 90))
            pulseSimulator.generatePulse(2, pulseSimulator.normalizeHeading(pulseSimulator.heading - 180))
            pulseSimulator.generatePulse(3, pulseSimulator.normalizeHeading(pulseSimulator.heading - 270))
        }
    }

    Settings {
        id: settings

        property int frequency: 146000
    }

    Timer {
        id:             channel0NoPulseTimer
        running:        true
        interval:       channelTimeoutMSecs
        onTriggered: {
            channel0FirstFreqSent = false
            channel0Active = false
            channel0PulsePercent = 0
            channel0CPUTemp = 0
            updateHeading()
        }
    }

    Timer {
        id:             channel1NoPulseTimer
        running:        true
        interval:       channelTimeoutMSecs
        onTriggered: {
            channel0FirstFreqSent = false
            channel1Active = false
            channel1PulsePercent = 0
            channel1CPUTemp = 0
            updateHeading()
        }
    }

    Timer {
        id:             channel2NoPulseTimer
        running:        true
        interval:       channelTimeoutMSecs
        onTriggered: {
            channel0FirstFreqSent = false
            channel2Active = false
            channel2PulsePercent = 0
            channel2CPUTemp = 0
            updateHeading()
        }
    }

    Timer {
        id:             channel3NoPulseTimer
        running:        true
        interval:       channelTimeoutMSecs
        onTriggered: {
            channel0FirstFreqSent = false
            channel3Active = false
            channel3PulsePercent = 0
            channel3CPUTemp = 0
            updateHeading()
        }
    }

    // Determine max pulse strength and adjust gain
    Timer {
        running:    true
        interval:   15000
        repeat:     true

        onTriggered: {
            if (!autoGain) {
                return
            }

            var maxPulsePct = Math.max(channel0PulsePercent, Math.max(channel1PulsePercent, Math.max(channel2PulsePercent, channel3PulsePercent)))
            //console.log("maxPulsePct", maxPulsePct)
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
                pulse.setGain(gain)
            }
        }
    }

    function updateHeading() {
        // Find strongest channel
        var strongestChannel = -1
        var strongestPulsePct = -1
        var rgPulse = [ channel0PulsePercent, channel1PulsePercent, channel2PulsePercent, channel3PulsePercent ]
        for (var index=0; index<rgPulse.length; index++) {
            if (rgPulse[index] > strongestPulsePct) {
                strongestChannel = index
                strongestPulsePct = rgPulse[index]
            }
        }

        var rgLeft = [ 3, 0, 1, 2 ]
        var rgRight = [ 1, 2, 3, 0 ]
        var rgHeading = [ 0.0, 90.0, 180.0, 270.0 ]
        var strongLeft
        var secondaryStrength
        var leftPulse = rgPulse[rgLeft[strongestChannel]]
        var rightPulse = rgPulse[rgRight[strongestChannel]]

        var headingAdjust
        if (rightPulse > leftPulse) {
            headingAdjust = (1 - (leftPulse / rightPulse)) / 0.5
            heading = rgHeading[strongestChannel] + (45.0 * headingAdjust)
        } else {
            headingAdjust = (1 - (rightPulse / leftPulse)) / 0.5
            heading = rgHeading[strongestChannel] - (45.0 * headingAdjust)
        }
        //console.log(qsTr("rightPulse(%1) leftPulse(%2) headingAdjust(%3)").arg(rightPulse).arg(leftPulse).arg(headingAdjust))

        //var strongestPulseMultipler = 100.0 / strongestPulsePct

        /*
        if (leftPulse > rightPulse) {
            //console.log("updateHeading", strongestChannel, "left")
            strongLeft = true
            heading = rgHeading[strongestChannel]
            heading -= 45.0 * strongestPulsePct * leftPulse
        } else {
            //console.log("updateHeading", strongestChannel, "right")
            strongLeft = false
            heading = rgHeading[strongestChannel]
            heading += 45.0 * strongestPulsePct * rightPulse
        }*/

        if (heading > 360) {
            heading -= 360
        } else if (heading < 0) {
            heading += 360
        }
        console.log("Estimated Heading:", heading)
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

    Text {
        id:             textMeasureExtraLarge
        text:           "X"
        font.pointSize: 72
        visible:        false

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
            anchors.left:       parent.left
            anchors.right:      parent.right
            text:               (autoGain ? "Auto" : "Manual") + " Gain " + gain
            font.pointSize:     100
            fontSizeMode:       Text.HorizontalFit

            MouseArea {
                anchors.fill:   parent
                onClicked:      gainEditor.visible = true
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


    GridLayout {
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        columns:        2

        Rectangle {
            id:     channel0Background
            width:  label0.width
            height: label0.height
            color:  "green"

            ColorAnimation on color {
                id:         channel0Animate
                to:         "white"
                duration:   500
            }

            Label { id: label0; text: "Channel 0" }
        }
        Label { text: channel0Active ? (qsTr("%1 %2 %3").arg(channel0PulseValue.toFixed(6)).arg(channel0PulsePercent.toFixed(2)).arg(channel0CPUTemp)) : "DISCONNECTED" }

        Rectangle {
            id:     channel1Background
            width:  label1.width
            height: label1.height
            color:  "green"

            ColorAnimation on color {
                id:         channel1Animate
                to:         "white"
                duration:   500
            }

            Label { id: label1; text: "Channel 1" }
        }
        Label { text: channel1Active ? (qsTr("%1 %2 %3").arg(channel1PulseValue.toFixed(6)).arg(channel1PulsePercent.toFixed(2)).arg(channel1CPUTemp)) : "DISCONNECTED" }

        Rectangle {
            id:     channel2Background
            width:  label2.width
            height: label2.height
            color:  "green"

            ColorAnimation on color {
                id:         channel2Animate
                to:         "white"
                duration:   500
            }

            Label { id: label2; text: "Channel 2" }
        }
        Label { text: channel2Active ? (qsTr("%1 %2 %3").arg(channel2PulseValue.toFixed(6)).arg(channel2PulsePercent.toFixed(2)).arg(channel2CPUTemp)) : "DISCONNECTED" }

        Rectangle {
            id:     channel3Background
            width:  label3.width
            height: label3.height
            color:  "green"

            ColorAnimation on color {
                id:         channel3Animate
                to:         "white"
                duration:   500
            }

            Label { id: label3; text: "Channel 3" }
        }
        Label { text: channel3Active ? (qsTr("%1 %2 %3").arg(channel3PulseValue.toFixed(6)).arg(channel3PulsePercent.toFixed(2)).arg(channel3CPUTemp)) : "DISCONNECTED" }
    }

    Component {
        id: digitSpinnerComponent

        Rectangle {
            width:  textMeasureExtraLarge.fontPixelWidth * 1.25
            height: textMeasureExtraLarge.fontPixelHeight * 2
            color:  "black"

            property alias value: list.currentIndex

            ListView {
                id:                         list
                anchors.fill:               parent
                highlightRangeMode:         ListView.StrictlyEnforceRange
                preferredHighlightBegin:    textMeasureExtraLarge.fontPixelHeight * 0.5
                preferredHighlightEnd:      textMeasureExtraLarge.fontPixelHeight * 0.5
                clip:                       true
                spacing:                    -textMeasureDefault.fontPixelHeight * 0.25
                model:                      [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]

                delegate: Text {
                    font.pointSize:             textMeasureExtraLarge.font.pointSize
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
                sourceComponent:        digitSpinnerComponent
                Component.onCompleted:  item.value = freqDigit1

                Connections {
                    target:         loader1.item
                    onValueChanged: freqDigit1 = loader1.item.value
                }
            }

            Loader {
                id:                     loader2
                sourceComponent:        digitSpinnerComponent
                Component.onCompleted:  item.value = freqDigit2

                Connections {
                    target:         loader2.item
                    onValueChanged: freqDigit2 = loader2.item.value
                }
            }

            Loader {
                id:                     loader3
                sourceComponent:        digitSpinnerComponent
                Component.onCompleted:  item.value = freqDigit3

                Connections {
                    target:         loader3.item
                    onValueChanged: freqDigit3 = loader3.item.value
                }
            }

            Loader {
                id:                     loader4
                sourceComponent:        digitSpinnerComponent
                Component.onCompleted:  item.value = freqDigit4

                Connections {
                    target:         loader4.item
                    onValueChanged: freqDigit4 = loader4.item.value
                }
            }

            Loader {
                id:                     loader5
                sourceComponent:        digitSpinnerComponent
                Component.onCompleted:  item.value = freqDigit5

                Connections {
                    target:         loader5.item
                    onValueChanged: freqDigit5 = loader5.item.value
                }
            }

            Loader {
                id:                     loader6
                sourceComponent:        digitSpinnerComponent
                Component.onCompleted:  item.value = freqDigit6

                Connections {
                    target:         loader6.item
                    onValueChanged: freqDigit6 = loader6.item.value
                }
            }
        }
    }

    Rectangle {
        id:             gainEditor
        anchors.fill:   parent
        visible:        false

        CheckBox {
            id:         autoGainCheckbox
            text:       "Auto-Gain"
            checked:    autoGain

            style: CheckBoxStyle {
                id: checkboxStyle
                label: Label {
                    text:           checkboxStyle.control.text
                    font.pointSize: textMeasureLarge.font.pointSize
                }
            }

            onClicked:  autoGain = checked
        }

        Button {
            anchors.right:  parent.right
            text:           "Close"
            onClicked:      gainEditor.visible = false
        }

        Rectangle {
            anchors.centerIn:   parent
            width:              textMeasureExtraLarge.fontPixelWidth * 2.25
            height:             textMeasureExtraLarge.fontPixelHeight * 2
            color:              "black"
            enabled:            !autoGainCheckbox.checked

            property alias value: list.currentIndex

            ListView {
                id:                         list
                anchors.fill:               parent
                highlightRangeMode:         ListView.StrictlyEnforceRange
                preferredHighlightBegin:    textMeasureExtraLarge.fontPixelHeight * 0.5
                preferredHighlightEnd:      textMeasureExtraLarge.fontPixelHeight * 0.5
                clip:                       true
                spacing:                    -textMeasureDefault.fontPixelHeight * 0.25
                currentIndex:               gain
                model:                      [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 ]

                delegate: Text {
                    font.pointSize:             textMeasureExtraLarge.font.pointSize
                    color:                      "white"
                    text:                       index
                    anchors.horizontalCenter:   parent.horizontalCenter
                }

                onCurrentIndexChanged: {
                    gain = currentIndex
                    pulse.setGain(gain)
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
}
