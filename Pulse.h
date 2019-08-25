#pragma once

#include <QObject>
#include <QGeoCoordinate>

class Pulse : public QObject
{
    Q_OBJECT

public:
    Pulse(void);
    ~Pulse();

    void clearPulseTrajectory(void);

    Q_INVOKABLE void    setFreq         (int freq);
    Q_INVOKABLE void    setGain         (int gain);
    Q_INVOKABLE double  log10           (double value);
    Q_INVOKABLE void    pulseTrajectory (const QGeoCoordinate coord, double travelHeading, double pulseHeading);

signals:
    void pulse(int channelIndex, float cpuTemp, float pulseValue);
    void setGainSignal(int gain);
    void setFreqSignal(int freq);
};

