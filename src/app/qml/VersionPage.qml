/*
 * Fedora Media Writer
 * Copyright (C) 2024 Jan Grulich <jgrulich@redhat.com>
 * Copyright (C) 2021-2022 Evžen Gasta <evzen.ml@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 6.6
import QtQuick.Controls 6.6 as QQC2
import QtQuick.Layouts 6.6

Page {
    id: versionPage

    property string selectedGpuFamily: hardwareDetector.detectedGpuFamily
    property string selectedDe: "KDE"
    property bool gameModeEnabled: true

    text: qsTr("Configure Bazzite Image")

    Heading {
        text: qsTr("Base Image")
        level: 1
    }

    QQC2.ComboBox {
        id: selectFromComboBox
        Layout.fillWidth: true
        textRole: "name"
        valueRole: "sourceIndex"
        model: releases
        enabled: count > 0
        onCurrentValueChanged: {
            updateSelectedIndex()
            applyBazziteSelection()
        }
    }

    QQC2.Label {
        visible: selectFromComboBox.count === 0
        Layout.fillWidth: true
        wrapMode: QQC2.Label.Wrap
        text: qsTr("No Bazzite releases were found in the current catalog source.")
    }

    Heading {
        text: qsTr("Hardware Detection")
        level: 1
    }

    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: QQC2.Label.Wrap
        text: hardwareDetector.detectedGpuName.length > 0
            ? qsTr("Detected GPU: %1").arg(hardwareDetector.detectedGpuName)
            : qsTr("Detected GPU: Unknown")
    }

    QQC2.ComboBox {
        id: gpuSelector
        Layout.fillWidth: true
        model: [qsTr("NVIDIA"), qsTr("AMD/Intel")]
        currentIndex: selectedGpuFamily === "nvidia" ? 0 : 1
        onCurrentIndexChanged: {
            selectedGpuFamily = currentIndex === 0 ? "nvidia" : "amd-intel"
            hardwareDetector.setManualGpuFamily(selectedGpuFamily)
            applyBazziteSelection()
        }
    }

    Heading {
        text: qsTr("Desktop Environment")
        level: 1
    }

    QQC2.ComboBox {
        id: deSelector
        Layout.fillWidth: true
        model: ["KDE", "GNOME"]
        onCurrentTextChanged: {
            selectedDe = currentText
            applyBazziteSelection()
        }
    }

    QQC2.CheckBox {
        text: qsTr("Enable GameMode build")
        checked: gameModeEnabled
        onToggled: {
            gameModeEnabled = checked
            applyBazziteSelection()
        }
    }

    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: QQC2.Label.Wrap
        text: qsTr("Selected artifact: %1").arg(selectedVariantDescription())
    }

    Connections {
        target: hardwareDetector
        function onGpuChanged() {
            selectedGpuFamily = hardwareDetector.detectedGpuFamily
            applyBazziteSelection()
        }
    }

    Component.onCompleted: {
        releases.filterSource = Units.Source.Product
        releases.filterText = "Bazzite"
        applyBazziteSelection()
    }

    function updateSelectedIndex() {
        // Guard passing an invalid value we get when resetting
        // index while changing filter above
        if (selectFromComboBox.currentValue) {
            releases.selectedIndex = parseInt(selectFromComboBox.currentValue)
        }
    }

    function selectedVariantDescription() {
        if (!releases.selected || !releases.selected.version || !releases.selected.version.variant)
            return qsTr("No compatible artifact found")
        const variant = releases.selected.version.variant
        return variant.name + " | " + variant.url
    }

    function gpuMatches(text) {
        if (selectedGpuFamily === "nvidia")
            return text.indexOf("nvidia") >= 0
        return text.indexOf("amd") >= 0 || text.indexOf("radeon") >= 0 || text.indexOf("intel") >= 0
    }

    function applyBazziteSelection() {
        if (selectFromComboBox.count === 0)
            return

        let bestIndex = selectFromComboBox.currentIndex >= 0 ? selectFromComboBox.currentIndex : 0
        let bestScore = -1

        for (let i = 0; i < selectFromComboBox.count; ++i) {
            const haystack = selectFromComboBox.textAt(i).toLowerCase()

            let score = 0
            if (gpuMatches(haystack))
                score += 40

            if (selectedDe.toLowerCase() === "kde" && haystack.indexOf("kde") >= 0)
                score += 25
            if (selectedDe.toLowerCase() === "gnome" && haystack.indexOf("gnome") >= 0)
                score += 25

            const hasGameModeTag = haystack.indexOf("steam gaming mode") >= 0 || haystack.indexOf("gamemode") >= 0 || haystack.indexOf("game-mode") >= 0
            if (gameModeEnabled && hasGameModeTag)
                score += 20
            if (!gameModeEnabled && !hasGameModeTag)
                score += 10

            if (score > bestScore) {
                bestScore = score
                bestIndex = i
            }
        }

        if (selectFromComboBox.currentIndex !== bestIndex)
            selectFromComboBox.currentIndex = bestIndex

        updateSelectedIndex()

        if (releases.selected && releases.selected.version)
            releases.selected.version.variantIndex = 0
    }

    onPreviousButtonClicked: selectedPage -= 1
    nextButtonEnabled: selectFromComboBox.count > 0

    onNextButtonClicked: {
        applyBazziteSelection()
        selectedPage += 1
    }
}
