#include "Pulse.h"

#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <QFile>

#include <cmath>

Pulse::Pulse(void)
{

}

Pulse::~Pulse()
{

}

void Pulse::setFreq(int freq)
{
    //qDebug() << "Pulse::setFreq" << freq;
    emit setFreqSignal(freq);
}

void Pulse::setGain(int gain)
{
    emit setGainSignal(gain);
}

double Pulse::log10(double value)
{
    return ::log10(value);
}

void Pulse::clearPulseTrajectory(void)
{
    QDir    writeDir(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));
    QFile   file(writeDir.filePath(QStringLiteral("pulse.csv")));
    file.remove();
}


void Pulse::pulseTrajectory(const QGeoCoordinate coord, double travelHeading, double pulseHeading)
{
    QDir    writeDir(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));
    QFile   file(writeDir.filePath(QStringLiteral("pulse.csv")));

    //qDebug() << writeDir;
    if (file.open(QIODevice::WriteOnly | QIODevice::Append)) {
        file.write((QStringLiteral("%1,%2,%3,%4\n").arg(coord.latitude()).arg(coord.longitude()).arg(travelHeading).arg(pulseHeading)).toUtf8().constData());
    } else {
        qDebug() << "Pulse file open failed" << writeDir << writeDir.exists() << file.fileName() << file.errorString();
    }

    qDebug() << coord << travelHeading << pulseHeading;
}
