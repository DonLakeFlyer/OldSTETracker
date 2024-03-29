#include <QtGlobal>
#include <QTimer>
#include <QList>
#include <QDebug>
#include <QMutexLocker>
#include <QNetworkProxy>
#include <QNetworkInterface>
#include <iostream>
#include <QHostInfo>

#include "UDPLink.h"

#define REMOVE_GONE_HOSTS 0

static bool contains_target(const QList<UDPCLient*> list, const QHostAddress& address, quint16 port)
{
    for(UDPCLient* target: list) {
        if(target->address == address && target->port == port) {
            return true;
        }
    }
    return false;
}

UDPLink::UDPLink(void)
    : _running      (false)
    , _socket       (Q_NULLPTR)
    , _connectState (false)
{
    for (const QHostAddress &address: QNetworkInterface::allAddresses()) {
        _localAddresses.append(QHostAddress(address));
    }
    moveToThread(this);
    _connect();
}

UDPLink::~UDPLink()
{
    _disconnect();
    // Tell the thread to exit
    _running = false;
    // Clear client list
    qDeleteAll(_sessionTargets);
    _sessionTargets.clear();
    quit();
    // Wait for it to exit
    wait();
    this->deleteLater();
}

void UDPLink::run()
{
    if (_hardwareConnect()) {
        exec();
    }
    if (_socket) {
        _socket->close();
    }
}

bool UDPLink::_isIpLocal(const QHostAddress& add)
{
    // In simulation and testing setups the vehicle and the GCS can be
    // running on the same host. This leads to packets arriving through
    // the local network or the loopback adapter, which makes it look
    // like the vehicle is connected through two different links,
    // complicating routing.
    //
    // We detect this case and force all traffic to a simulated instance
    // onto the local loopback interface.
    // Run through all IPv4 interfaces and check if their canonical
    // IP address in string representation matches the source IP address
    //
    // On Windows, this is a very expensive call only Redmond would know
    // why. As such, we make it once and keep the list locally. If a new
    // interface shows up after we start, it won't be on this list.
    for (const QHostAddress &address: _localAddresses) {
        if (address == add) {
            // This is a local address of the same host
            return true;
        }
    }
    return false;
}

void UDPLink::_writeBytes(const QByteArray data)
{
    if (!_socket) {
        return;
    }

    // Send to all connected systems
    for(UDPCLient* target: _sessionTargets) {
        _writeDataGram(data, target);
    }
}

void UDPLink::_writeDataGram(const QByteArray data, const UDPCLient* target)
{
    //qDebug() << "UDP Out" << target->address << target->port;
    if(_socket->writeDatagram(data, target->address, target->port) < 0) {
        qWarning() << "Error writing to" << target->address << target->port;
    }
}

void UDPLink::_readBytes()
{
    if (!_socket) {
        return;
    }

    while (_socket->hasPendingDatagrams())
    {
        QByteArray      datagram;
        QHostAddress    sender;
        quint16         senderPort;

        datagram.resize(static_cast<int>(_socket->pendingDatagramSize()));

        _socket->readDatagram(datagram.data(), datagram.size(), &sender, &senderPort);

        // Format should be
        //  int -   channel index
        //  float - pulse value
        //  float - cpu temp
        //  int -   freq
        //  int -   gain
        int expectedSize = (sizeof(int) * 3) + (sizeof(float) * 2);
        if (datagram.size() == expectedSize) {
            struct PulseInfo_s {
                int     channelIndex;
                float   pulseValue;
                float   cpuTemp;
                int     freq;
                int     gain;
            };
            const struct PulseInfo_s* pulseInfo = (const struct PulseInfo_s*)datagram.constData();
            //qDebug() << "Pulse" << pulseInfo->channelIndex << pulseInfo->cpuTemp << pulseInfo->pulseValue << pulseInfo->freq;
            emit pulse(pulseInfo->channelIndex, pulseInfo->cpuTemp, pulseInfo->pulseValue, pulseInfo->gain);
        } else {
            qWarning() << "Bad datagram size actual:expected" << datagram.size() << expectedSize;
        }

        QHostAddress asender = sender;
        if (_isIpLocal(sender)) {
            asender = QHostAddress(QString("127.0.0.1"));
        }
        if (!contains_target(_sessionTargets, asender, senderPort)) {
            qDebug() << "Adding target" << asender << senderPort;
            UDPCLient* target = new UDPCLient(asender, senderPort);
            _sessionTargets.append(target);
        }
    }
}

void UDPLink::_disconnect(void)
{
    _running = false;
    quit();
    wait();
    if (_socket) {
        // Make sure delete happen on correct thread
        _socket->deleteLater();
        _socket = Q_NULLPTR;
    }
    _connectState = false;
}

bool UDPLink::_connect(void)
{
    if (this->isRunning() || _running) {
        _running = false;
        quit();
        wait();
    }
    _running = true;
    start(NormalPriority);
    return true;
}

bool UDPLink::_hardwareConnect()
{
    if (_socket) {
        delete _socket;
        _socket = Q_NULLPTR;
    }
    QHostAddress host = QHostAddress::AnyIPv4;
    _socket = new QUdpSocket(this);
    _socket->setProxy(QNetworkProxy::NoProxy);
    _connectState = _socket->bind(host, 5007, QAbstractSocket::ReuseAddressHint | QUdpSocket::ShareAddress);
    if (_connectState) {
        _socket->joinMulticastGroup(QHostAddress("224.0.0.1"));
        _socket->setSocketOption(QAbstractSocket::SendBufferSizeSocketOption,     64 * 1024);
        _socket->setSocketOption(QAbstractSocket::ReceiveBufferSizeSocketOption, 128 * 1024);
        QObject::connect(_socket, &QUdpSocket::readyRead, this, &UDPLink::_readBytes);
    } else {
        qWarning() << "UDP Link Error binding UDP port" << _socket->errorString();
    }
    return _connectState;
}

void UDPLink::setGain(int gain)
{
    QByteArray bytes;
    int command[2];
    command[0] = 1;
    command[1] = gain;
    bytes.setRawData((const char *)&command, sizeof(command));
    //_writeBytes(bytes);
}

void UDPLink::setFreq(int freq)
{
    QByteArray bytes;
    int command[2];
    command[0] = 2;
    command[1] = freq;
    bytes.setRawData((const char *)&command, sizeof(command));
    //_writeBytes(bytes);
}
