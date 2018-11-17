QT = core bluetooth quick
SOURCES += qmlscanner.cpp

TARGET = qml_scanner
TEMPLATE = app

RESOURCES += \
    scanner.qrc

OTHER_FILES += \
    PulseCapture.qml \
    scanner.qml \
    default.png

#DEFINES += QMLJSDEBUGGER

target.path = $$[QT_INSTALL_EXAMPLES]/bluetooth/scanner
INSTALLS += target
