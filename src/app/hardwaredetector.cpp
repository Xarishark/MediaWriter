/*
 * Fedora Media Writer
 * Copyright (C) 2026
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 */

#include "hardwaredetector.h"

#include <QProcess>

using namespace Qt::Literals::StringLiterals;

HardwareDetector::HardwareDetector(QObject *parent)
    : QObject(parent)
{
    detect();
}

QString HardwareDetector::detectedGpuFamily() const
{
    return m_detectedGpuFamily;
}

QString HardwareDetector::detectedGpuName() const
{
    return m_detectedGpuName;
}

bool HardwareDetector::needsManualSelection() const
{
    return m_needsManualSelection;
}

void HardwareDetector::detect()
{
    const QString gpuName = detectWindowsGpuName();
    const QString gpuFamily = gpuFamilyFromName(gpuName);

    const bool changed = (m_detectedGpuName != gpuName) || (m_detectedGpuFamily != gpuFamily) || (m_needsManualSelection != (gpuFamily == "unknown"_L1));

    m_detectedGpuName = gpuName;
    m_detectedGpuFamily = gpuFamily;
    m_needsManualSelection = (gpuFamily == "unknown"_L1);

    if (changed)
        emit gpuChanged();
}

void HardwareDetector::setManualGpuFamily(const QString &family)
{
    if (family.isEmpty())
        return;

    const QString normalized = family.toLower();
    if (normalized != "nvidia"_L1 && normalized != "amd-intel"_L1)
        return;

    const bool changed = (m_detectedGpuFamily != normalized) || m_needsManualSelection;
    m_detectedGpuFamily = normalized;
    m_needsManualSelection = false;

    if (changed)
        emit gpuChanged();
}

QString HardwareDetector::detectWindowsGpuName() const
{
#ifdef Q_OS_WIN
    QProcess process;
    process.start("wmic", {"path", "win32_videocontroller", "get", "name"});
    process.waitForFinished(2000);

    QString output = QString::fromLocal8Bit(process.readAllStandardOutput()).trimmed();
    QStringList lines = output.split('\n', Qt::SkipEmptyParts);
    for (QString line : lines) {
        line = line.trimmed();
        if (!line.isEmpty() && line.compare("name", Qt::CaseInsensitive) != 0)
            return line;
    }

    QProcess fallback;
    fallback.start("powershell", {"-NoProfile", "-Command", "(Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty Name)"});
    fallback.waitForFinished(2500);
    output = QString::fromLocal8Bit(fallback.readAllStandardOutput()).trimmed();
    if (!output.isEmpty())
        return output;
#endif

    return QString();
}

QString HardwareDetector::gpuFamilyFromName(const QString &name)
{
    const QString normalized = name.toLower();
    if (normalized.contains("nvidia"_L1))
        return "nvidia"_L1;
    if (normalized.contains("amd"_L1) || normalized.contains("radeon"_L1) || normalized.contains("ati"_L1) || normalized.contains("intel"_L1))
        return "amd-intel"_L1;
    return "unknown"_L1;
}
