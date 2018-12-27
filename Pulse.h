#pragma once

#include <QObject>

class Pulse : public QObject
{
    Q_OBJECT

public:
    Pulse(void);
    ~Pulse();

    Q_INVOKABLE void setFreq(int freq);
    Q_INVOKABLE void setGain(int gain);
    Q_INVOKABLE double log10(double value);

    void emitPulse(int channelIndex, float cpuTemp, float pulseValue);

signals:
    void pulse(int channelIndex, float cpuTemp, float pulseValue);
    void setGainSignal(int gain);
    void setFreqSignal(int freq);
};

