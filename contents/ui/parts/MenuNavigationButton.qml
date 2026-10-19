// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras

PlasmaComponents.Button {
    id: button
    checkable: false
    hoverEnabled: true
    activeFocusOnTab: true
    // The standard button derives padding from its own background type.
    // Our list highlight replaces that background, so provide content insets explicitly.
    leftPadding: Kirigami.Units.smallSpacing * 2
    rightPadding: Kirigami.Units.smallSpacing * 2
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()

    // Keyboard focus may remain after a click; it must not keep the highlight on.
    background: PlasmaExtras.Highlight {
        anchors.fill: parent
        visible: button.hovered || button.pressed
        hovered: button.hovered
        pressed: button.pressed
    }
}
