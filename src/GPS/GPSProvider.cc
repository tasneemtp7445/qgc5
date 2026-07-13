#include "GPSProvider.h"

#include "GPSDriver.h"
#include "QGCLoggingCategory.h"
#include "RTCMMavlink.h"
#include "SerialGPSTransport.h"

#include <utility>

QGC_LOGGING_CATEGORY(GPSProviderLog, "GPS.GPSProvider")

GPSProvider::GPSProvider(const QString &device, GPSType type, const GPSReceiverConfig &config, const std::atomic_bool &requestStop, QObject *parent)
    : QThread(parent)
    , _device(device)
    , _type(type)
    , _requestStop(requestStop)
    , _config(config)
{
    qCDebug(GPSProviderLog) << QStringLiteral("Survey in accuracy: %1 | duration: %2").arg(_config.surveyInAccMeters).arg(_config.surveyInDurationSecs);
}

void GPSProvider::run()
{
#ifdef SIMULATE_RTCM_OUTPUT
    RTCMMavlink rtcm;
    rtcm.sendSimulatedData(_requestStop);
    return;
#endif

    SerialGPSTransport transport(_device, _requestStop);
    if (!transport.open()) {
        if (!_requestStop) {
            emit connectionError(GPSConnectionError::OpenFailed);
        }
        return;
    }

    bool gotData = false;
    GPSDriverSinks sinks;
    sinks.onPosition = [this](const sensor_gps_s &message) { emit sensorGpsUpdate(message); };
    sinks.onSatelliteInfo = [this](const satellite_info_s &message) { emit satelliteInfoUpdate(message); };
    sinks.onRTCM = [this, &gotData](const QByteArray &message) {
        gotData = true;
        emit RTCMDataUpdate(message);
    };
    sinks.onSurveyIn = [this, &gotData](const GPSSurveyInStatus &status) {
        gotData = true;
        qCDebug(GPSProviderLog) << QStringLiteral("Survey-in: %1s accuracy: %2mm valid: %3 active: %4")
                                       .arg(status.durationSecs).arg(status.meanAccuracyMM).arg(status.valid).arg(status.active);
        emit surveyInStatus(status);
    };

    GPSDriver driver(_type, transport, _config, std::move(sinks));

    bool configErrorReported = false;
    while (!_requestStop) {
        if (!driver.configure()) {
            if (_requestStop) {
                break; // disconnect aborted configure mid-flight; not a real failure
            }
            if (!configErrorReported) {
                emit connectionError(GPSConnectionError::ConfigFailed);
                configErrorReported = true;
            }
            msleep(kConfigRetryDelayMs);
            continue;
        }
        configErrorReported = false;

        uint8_t idleCycles = 0;
        while (!_requestStop && (idleCycles < kMaxIdleReceiveCycles)) {
            gotData = false;
            const int ret = driver.receive(kGPSReceiveTimeout);
            const bool progress = (ret > 0) || gotData; // position/sat (ret) or RTCM/survey-in (sinks)
            idleCycles = progress ? 0 : (idleCycles + 1);
        }

        if (transport.fatalError()) {
            emit connectionError(GPSConnectionError::DeviceError);
            break;
        }
    }

<<<<<<< HEAD
    delete gpsDriver;
    gpsDriver = nullptr;

    delete _serial;
    _serial = nullptr;

    qCDebug(GPSProviderLog) << Q_FUNC_INFO << "Exiting GPS thread";
}

bool GPSProvider::_connectSerial()
{
    _serial = new QSerialPort();
    _serial->setPortName(_device);
    if (!_serial->open(QIODevice::ReadWrite)) {
        // Give the device some time to come up. In some cases the device is not
        // immediately accessible right after startup for some reason. This can take 10-20s.
        uint32_t retries = 60;
        while ((retries-- > 0) && (_serial->error() == QSerialPort::PermissionError)) {
            qCDebug(GPSProviderLog) << "Cannot open device... retrying";
            msleep(500);
            if (_serial->open(QIODevice::ReadWrite)) {
                _serial->clearError();
                break;
            }
        }

        if (_serial->error() != QSerialPort::NoError) {
            qCWarning(GPSProviderLog) << "GPS: Failed to open Serial Device" << _device << _serial->errorString();
            return false;
        }
    }

    (void) _serial->setBaudRate(QSerialPort::Baud9600);
    (void) _serial->setDataBits(QSerialPort::Data8);
    (void) _serial->setParity(QSerialPort::NoParity);
    (void) _serial->setStopBits(QSerialPort::OneStop);
    (void) _serial->setFlowControl(QSerialPort::NoFlowControl);

    return true;
}

GPSBaseStationSupport *GPSProvider::_connectGPS()
{
    GPSBaseStationSupport *gpsDriver = nullptr;
    uint32_t baudrate = 0;
    switch(_type) {
    case GPSType::trimble:
        gpsDriver = new GPSDriverAshtech(&_callbackEntry, this, &_sensorGps, &_satelliteInfo);
        baudrate = 115200;
        break;
    case GPSType::septentrio:
        gpsDriver = new GPSDriverSBF(&_callbackEntry, this, &_sensorGps, &_satelliteInfo, kGPSHeadingOffset);
        baudrate = 0;
        break;
    case GPSType::u_blox:
        {
        GPSDriverUBX::Settings settings{};

        gpsDriver = new GPSDriverUBX(
        GPSDriverUBX::Interface::UART,
        &_callbackEntry,
        this,
        &_sensorGps,
        &_satelliteInfo,
        settings);

        baudrate = 0;
        break;
        }
    case GPSType::femto:
        gpsDriver = new GPSDriverFemto(&_callbackEntry, this, &_sensorGps, &_satelliteInfo);
        baudrate = 0;
        break;
    default:
        // GPSDriverEmlidReach, GPSDriverMTK, GPSDriverNMEA
        qCWarning(GPSProviderLog) << "Unsupported GPS Type:" << static_cast<int>(_type);
        return nullptr;
    }

    gpsDriver->setSurveyInSpecs(_rtkData.surveyInAccMeters * 10000.f, _rtkData.surveyInDurationSecs);

    if (_rtkData.useFixedBaseLoction) {
        gpsDriver->setBasePosition(_rtkData.fixedBaseLatitude, _rtkData.fixedBaseLongitude, _rtkData.fixedBaseAltitudeMeters, _rtkData.fixedBaseAccuracyMeters * 1000.0f);
    }

    _gpsConfig.output_mode = GPSHelper::OutputMode::RTCM;

    if (gpsDriver->configure(baudrate, _gpsConfig) != 0) {
        return nullptr;
    }

    return gpsDriver;
}

void GPSProvider::_sendRTCMData()
{
    RTCMMavlink *const rtcm = new RTCMMavlink(this);

    const int fakeMsgLengths[3] = { 30, 170, 240 };
    const uint8_t* const fakeData = new uint8_t[fakeMsgLengths[2]];
    while (!_requestStop) {
        for (int i = 0; i < 3; ++i) {
            const QByteArray message(reinterpret_cast<const char*>(fakeData), fakeMsgLengths[i]);
            rtcm->RTCMDataUpdate(message);
            msleep(4);
        }
        msleep(100);
    }
    delete[] fakeData;
=======
    qCDebug(GPSProviderLog) << "Exiting GPS thread";
>>>>>>> 76e02ed47cfbb341a780befd7d0dc21db30a5b60
}
