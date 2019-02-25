#include "Pulse.h"

#include <QDebug>

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
