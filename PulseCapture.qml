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

import QtQuick 2.0
import QtQuick.Controls 1.4
import QtBluetooth 5.2

Rectangle {
    color: "white"

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
    property var  rgSockets:            [ btSocketChannel0, btSocketChannel1, btSocketChannel2, btSocketChannel3 ]

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
            if (maxPulsePct > gainTargetPulsePercent + gainTargetPulsePercentWindow) {
                if (gain > minGain) {
                    gain = gain - 1
                    if (btSocketChannel0.connected) {
                        btSocketChannel0.stringData = gain
                    }
                    if (btSocketChannel1.connected) {
                        btSocketChannel1.stringData = gain
                    }
                    if (btSocketChannel2.connected) {
                        btSocketChannel2.stringData = gain
                    }
                    if (btSocketChannel3.connected) {
                        btSocketChannel3.stringData = gain
                    }
                }
            } else if (maxPulsePct < gainTargetPulsePercent - gainTargetPulsePercentWindow) {
                if (gain < maxGain) {
                    gain = gain + 1
                    if (btSocketChannel0.connected) {
                        btSocketChannel0.stringData = gain
                    }
                    if (btSocketChannel1.connected) {
                        btSocketChannel1.stringData = gain
                    }
                    if (btSocketChannel2.connected) {
                        btSocketChannel2.stringData = gain
                    }
                    if (btSocketChannel3.connected) {
                        btSocketChannel3.stringData = gain
                    }
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter:   parent.horizontalCenter
        text:                       "Gain " + gain
        font.pointSize:             textMeasure.font.pointSize * 2
    }

    BluetoothDiscoveryModel {
        id:             btModel
        running:        true
        discoveryMode:  BluetoothDiscoveryModel.FullServiceDiscovery

        readonly property string _pulseServerUUID: "{94f39d29-7d6d-437d-973b-fba39e49d4ee}"

        onServiceDiscovered: {
            var serviceName = service.serviceName
            //console.log("Found new service", service.deviceAddress, service.deviceName, serviceName, service.serviceUuid);
            if (service.serviceUuid == _pulseServerUUID) {
                console.log("Found PulseServer", service.deviceAddress, service.deviceName, serviceName, service.serviceUuid);
                if (deviceList.indexOf(service.deviceAddress) != -1) {
                    console.log("Already connected to server")
                    return
                }
                console.log("Connecting to server")
                var channel = parseInt(serviceName[serviceName.length - 1])
                console.log("Found PulseServer", serviceName, channel, service.deviceAddress)
                console.log("rgSockets", rgSockets[channel].service)
                rgSockets[channel].service = service
                deviceList.push(service.deviceAddress)
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
    }

    Component {
        id: btSocketComponent

        BluetoothSocket {
            connected:              true
            onStringDataChanged:    processStringData(channel, stringData)

            property int channel: 0

            property string _deviceAddress

            onServiceChanged: {
                if (service) {
                    deviceAddress = service.deviceAddress
                }
            }

            onConnectedChanged: {
                if (!connected) {
                    console.log("Socket disconnected", deviceAddress, deviceList.indexOf(deviceAddress))
                    var index = deviceList.indexOf(deviceAddress)
                    deviceList = deviceList.splice(index)
                }
            }
        }
    }

    BluetoothSocket {
        id:                     btSocketChannel1
        connected:              true
        onStringDataChanged:    processStringData(1, stringData)
    }

    BluetoothSocket {
        id:                     btSocketChannel2
        connected:              true
        onStringDataChanged:    processStringData(2, stringData)
    }

    BluetoothSocket {
        id:                     btSocketChannel3
        connected:              true
        onStringDataChanged:    processStringData(3, stringData)
    }

    Text {
        id:         textMeasure
        text:       "X"
        visible:    false

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
    }
}
