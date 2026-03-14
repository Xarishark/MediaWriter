/*
 * Fedora Media Writer
 * Copyright (C) 2026
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 */

#ifndef HARDWAREDETECTOR_H
#define HARDWAREDETECTOR_H

#include <QObject>

class HardwareDetector : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString detectedGpuFamily READ detectedGpuFamily NOTIFY gpuChanged)
    Q_PROPERTY(QString detectedGpuName READ detectedGpuName NOTIFY gpuChanged)
    Q_PROPERTY(bool needsManualSelection READ needsManualSelection NOTIFY gpuChanged)

public:
    explicit HardwareDetector(QObject *parent = nullptr);

    QString detectedGpuFamily() const;
    QString detectedGpuName() const;
    bool needsManualSelection() const;

    Q_INVOKABLE void detect();
    Q_INVOKABLE void setManualGpuFamily(const QString &family);

signals:
    void gpuChanged();

private:
    QString detectWindowsGpuName() const;
    static QString gpuFamilyFromName(const QString &name);

    QString m_detectedGpuFamily{"unknown"};
    QString m_detectedGpuName{};
    bool m_needsManualSelection{true};
};

#endif // HARDWAREDETECTOR_H
