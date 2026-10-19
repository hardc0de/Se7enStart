// SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtCore
import org.kde.plasma.components as PC3
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

PC3.Button {
    id: powerButtons
    property var systemModel: nativeSystem
    property bool actionInProgress: false
    property int modelRevision: 0
    readonly property bool popupVisible: systemActionsMenu.visible
    property alias popup: systemActionsMenu
    signal actionTriggered
    signal screenOffRequested
    signal keyNavUp
    signal keyNavDown
    signal keyNavLeft
    Accessible.name: i18n("Shut Down")
    focus: true
    activeFocusOnTab: true
    Kicker.SystemModel {
        id: nativeSystem
    }
    Connections {
        target: powerButtons.systemModel
        ignoreUnknownSignals: true
        function onDataChanged() {
            ++powerButtons.modelRevision;
        }
        function onModelReset() {
            ++powerButtons.modelRevision;
        }
        function onCountChanged() {
            ++powerButtons.modelRevision;
        }
    }
    function value(row, role) {
        const number = systemModel.KItemModels.KRoleNames.role(role);
        return systemModel.data(systemModel.index(row, 0), number);
    }
    function rowFor(id) {
        if (!systemModel)
            return -1;
        for (let row = 0; row < systemModel.count; ++row)
            if (String(value(row, "favoriteId")) === id)
                return row;
        return -1;
    }
    function available(id) {
        const revision = modelRevision;
        const row = rowFor(id);
        return row >= 0 && !value(row, "disabled") && !actionInProgress;
    }
    function trigger(id) {
        if (!available(id))
            return;
        systemModel.trigger(rowFor(id), "", null);
        closePopup();
        actionTriggered();
    }
    function closePopup() {
        systemActionsMenu.close();
    }
    function openPopup() {
        if (systemActionsMenu.visible) {
            closePopup();
            return;
        }
        systemActionsMenu.open();
        for (let i = 0; i < systemActionsMenu.count; ++i) {
            if (systemActionsMenu.itemAt(i).enabled) {
                systemActionsMenu.currentIndex = i;
                break;
            }
        }
        systemActionsMenu.forceActiveFocus(Qt.PopupFocusReason);
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up) {
            event.accepted = true;
            keyNavUp();
        } else if (event.key === Qt.Key_Down) {
            event.accepted = true;
            keyNavDown();
        } else if (event.key === Qt.Key_Left) {
            event.accepted = true;
            keyNavLeft();
        } else if (event.key === Qt.Key_Right) {
            event.accepted = true;
            openPopup();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            event.accepted = true;
            trigger("shutdown");
        }
    }
    PC3.Button {
        id: shutdownButton
        anchors {
            left: parent.left
            leftMargin: 8
            top: parent.top
            bottom: parent.bottom
        }
        width: parent.width - dropdownButton.width - 8
        text: i18n("Shut Down")
        icon.name: "system-shutdown"
        enabled: powerButtons.available("shutdown")
        background: Item {}
        onClicked: powerButtons.trigger("shutdown")
    }
    PC3.Button {
        id: dropdownButton
        objectName: "shutdownMenuButton"
        anchors {
            right: parent.right
            rightMargin: 8
            top: parent.top
            bottom: parent.bottom
        }
        width: Kirigami.Units.gridUnit
        icon.name: "arrow-down-symbolic"
        Accessible.role: Accessible.ButtonMenu
        Accessible.expandable: true
        Accessible.expanded: powerButtons.popupVisible
        Accessible.name: i18n("Power and session actions")
        Accessible.description: powerButtons.popupVisible ? i18n("Menu expanded") : i18n("Menu collapsed")
        background: Item {}
        onClicked: powerButtons.openPopup()
        Keys.onRightPressed: powerButtons.openPopup()
    }
    PC3.Menu {
        id: systemActionsMenu
        objectName: "systemActionsMenu"
        x: powerButtons.width - width
        y: -height - Kirigami.Units.smallSpacing
        width: Math.max(Kirigami.Units.gridUnit * 12, implicitWidth)
        modal: false
        focus: true
        onClosed: dropdownButton.forceActiveFocus(Qt.PopupFocusReason)
        background: KSvg.FrameSvgItem {
            imagePath: "solid/dialogs/background"
            implicitWidth: Kirigami.Units.gridUnit * 10
        }
        PC3.MenuItem {
            text: i18n("Restart")
            icon.name: "system-reboot"
            enabled: powerButtons.available("reboot")
            onTriggered: powerButtons.trigger("reboot")
        }
        PC3.MenuItem {
            text: i18n("Turn Off Screen")
            icon.name: "video-display"
            enabled: StandardPaths.findExecutable("kscreen-doctor") !== ""
            onTriggered: {
                powerButtons.screenOffRequested();
                powerButtons.closePopup();
            }
        }
        PC3.MenuItem {
            text: i18n("Lock Screen")
            icon.name: "system-lock-screen"
            enabled: powerButtons.available("lock-screen")
            onTriggered: powerButtons.trigger("lock-screen")
        }
        PC3.MenuItem {
            text: i18n("Sleep")
            icon.name: "system-suspend"
            enabled: powerButtons.available("suspend")
            onTriggered: powerButtons.trigger("suspend")
        }
        PC3.MenuItem {
            text: i18n("Hibernate")
            icon.name: "system-suspend-hibernate"
            enabled: powerButtons.available("hibernate")
            onTriggered: powerButtons.trigger("hibernate")
        }
        PC3.MenuItem {
            text: i18n("Log Out")
            icon.name: "system-log-out"
            enabled: powerButtons.available("logout")
            onTriggered: powerButtons.trigger("logout")
        }
    }
}
