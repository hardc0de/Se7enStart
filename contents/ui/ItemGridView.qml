// SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
// SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

ApplicationView {
    function resetToBeginning() {
        view.cancelFlick();
        resetSelection();
        lastPointerPosition = Qt.point(-1, -1);
        view.positionViewAtBeginning();
    }
}
