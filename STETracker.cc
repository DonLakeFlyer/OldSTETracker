/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
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

#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QQmlEngine>
#include <QtCore/QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "UDPLink.h"
#include "Pulse.h"

int main(int argc, char *argv[])
{
    //QLoggingCategory::setFilterRules(QStringLiteral("qt.bluetooth* = true"));
    QGuiApplication application(argc, argv);
    application.setOrganizationName("LF Software Consulting");
    application.setOrganizationDomain("latestfiasco.com");
    application.setApplicationName("VHF Collar Scanner");

    UDPLink udpLink;

#if 1
    Pulse pulse(true /* captureRawData */);
    pulse.clearFiles();
#else
    Pulse pulse(false /* captureRawData */);
    pulse.startReplay();
#endif

    udpLink.connect(&udpLink,   &UDPLink::pulse,        &pulse,     &Pulse::pulse);
    pulse.connect(&pulse,       &Pulse::setGainSignal,  &udpLink,   &UDPLink::setGain);
    pulse.connect(&pulse,       &Pulse::setFreqSignal,  &udpLink,   &UDPLink::setFreq);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("pulse", &pulse);

    const QString mainQmlApp(QStringLiteral("qrc:/PulseCapture.qml"));

#if 0
    QQuickView view;
    view.setSource(QUrl(mainQmlApp));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
#endif

    engine.load(mainQmlApp);
    if (engine.rootObjects().isEmpty())
        return -1;

    return application.exec();
}
