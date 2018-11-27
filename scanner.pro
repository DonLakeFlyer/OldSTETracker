QT = core bluetooth quick svg xml gui

SOURCES += \
    qmlscanner.cpp

TARGET = qml_scanner
TEMPLATE = app

RESOURCES += \
    scanner.qrc

OTHER_FILES += \
    PulseCapture.qml \
    scanner.qml \
    default.png

android {
    DEFINES += __android__
    QT += androidextras
}
