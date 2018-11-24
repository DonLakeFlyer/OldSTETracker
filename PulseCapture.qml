/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Copyright (C) 2013 BlackBerry Limited. All rights reserved.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the QtBluetooth module.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick          2.11
import QtQuick.Controls 1.4
import QtBluetooth      5.2
import QtQuick.Window   2.11

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

    onChannel0PulsePercentChanged: channel0PulseSlice.requestPaint()
    onChannel1PulsePercentChanged: channel1PulseSlice.requestPaint()
    onChannel2PulsePercentChanged: channel2PulseSlice.requestPaint()
    onChannel3PulsePercentChanged: channel3PulseSlice.requestPaint()

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
                        socket.stringData = gain
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
        if (leftPulse > rightPulse) {
            strongLeft = true
            heading = rgHeading[strongestChannel]
            heading -= 45.0 * leftPulse
        } else {
            strongLeft = false
            heading = rgHeading[strongestChannel]
            heading += 45.0 * leftPulse
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
        }
    }

    Text {
        id:         textMeasure
        text:       "X"
        visible:    false

        property real fontPixelWidth:   contentWidth
        property real fontPixelHeight:  contentHeight
    }

    Text {
        text:           "Gain " + gain
        font.pointSize: textMeasure.font.pointSize * 2
    }

    Column {
        anchors.bottom: parent.bottom

        Repeater {
            id:     channelConnectedRepeater
            model:  4

            Label {
                text: qsTr("Channel %1 - %2").arg(index).arg(rgSockets[index] ? "CONNECTED" : "not connected" )
            }
        }
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

    Rectangle {
        anchors.centerIn:   parent
        width:              _diameter
        height:             _diameter
        radius:             _diameter / 2
        color:              "transparent"
        border.color:       "black"
        border.width:       2

        property real _diameter: Math.min(parent.width, parent.height) - (textMeasure.fontPixelHeight * 2)
        property real _centerX: width / 2
        property real _centerY: width / 2

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
}
