QT = core bluetooth quick svg xml gui

HEADERS += \
    UDPLink.h \
    Pulse.h \

SOURCES += \
    STETracker.cc \
    UDPLink.cc \
    Pulse.cc \

TARGET = STETracker
TEMPLATE = app

RESOURCES += \
    STETracker.qrc

OTHER_FILES += \
    PulseCapture.qml \
    default.png

android {
    DEFINES += __android__
    QT += androidextras
}
