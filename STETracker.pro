QT = core bluetooth quick svg xml gui positioning

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
    default.png \
    android\AndroidManifest.xml

android {
    DEFINES += __android__
    QT += androidextras

DISTFILES += \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat

contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}
}
