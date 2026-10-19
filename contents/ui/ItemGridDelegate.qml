// SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
// SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import "code/tools.js" as Tools

Item {
    id: entry
    required property var model
    required property int index
    required property var owner
    required property var contextMenu
    required property var documentMenu
    readonly property var itemView: ListView.view
    readonly property int itemIndex: index
    readonly property string favoriteId: model.favoriteId || ""
    readonly property url url: model.url || ""
    readonly property var icon: model.decoration || ""
    readonly property bool pressed: pointer.pressed || documentPointer.pressed
    readonly property var recentActions: {
        const revision = owner.actionsRevision;
        const changed = model.actionList;
        return owner.naturalHeight ? Tools.recentDocumentActions(owner.actionsFor(index)) : [];
    }
    width: itemView ? itemView.width : 0
    height: owner.cellHeight
    enabled: !model.disabled
    Accessible.role: Accessible.MenuItem
    Accessible.name: label.text
    Accessible.onPressAction: owner.triggerItem(index, "", null)
    HoverHandler {
        onHoveredChanged: if (!hovered)
            owner.clearPointerSelection(index)
    }
    function openActionMenu(x, y) {
        Tools.fillActionMenu(i18n, contextMenu, owner.actionsFor(index), owner.favoritesModel, favoriteId);
        contextMenu.visualParent = entry;
        contextMenu.open(x, y);
    }
    function actionTriggered(actionId, argument) {
        owner.triggerItem(index, actionId, argument);
    }
    function openDocuments() {
        if (!recentActions.length)
            return;
        documentMenu.actionList = recentActions;
        documentMenu.visualParent = entry;
        documentMenu.openRelative();
    }
    Kirigami.Icon {
        id: applicationIcon
        objectName: "applicationIcon"
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        width: owner.iconSize
        height: width
        animated: false
        source: entry.icon
    }
    PC3.Label {
        id: label
        objectName: "applicationLabel"
        anchors.left: applicationIcon.right
        anchors.leftMargin: owner.iconSize / 2
        anchors.right: documents.left
        anchors.rightMargin: 5
        height: parent.height
        visible: owner.showLabels
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: 1
        elide: Text.ElideRight
        text: model.name || model.display || ""
        textFormat: Text.PlainText
    }
    PC3.ToolTip.text: label.text
    PC3.ToolTip.visible: pointer.containsMouse && label.truncated
    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
    MouseArea {
        id: pointer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: documents.left
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property point pressPosition: Qt.point(-1, -1)
        property bool dragged: false
        onPressed: mouse => {
            owner.selectionFromPointer = true;
            owner.currentIndex = index;
            entry.forceActiveFocus(Qt.MouseFocusReason);
            pressPosition = Qt.point(mouse.x, mouse.y);
            dragged = false;
            if (mouse.button === Qt.RightButton)
                entry.openActionMenu(mouse.x, mouse.y);
        }
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && !dragged && mouse.x >= 0 && mouse.x < width && mouse.y >= 0 && mouse.y < height)
                owner.triggerItem(index, "", null);
        }
        onReleased: {
            pressPosition = Qt.point(-1, -1);
            if (!containsMouse)
                owner.clearPointerSelection(index);
        }
        onCanceled: {
            pressPosition = Qt.point(-1, -1);
            dragged = true;
        }
        onPositionChanged: mouse => {
            const pos = mapToItem(itemView, mouse.x, mouse.y);
            if (!pressed)
                owner.selectFromPointer(index, pos);
            if (pressed && (pressedButtons & Qt.LeftButton) && !dragged && owner.dragEnabled && owner.dragHandler && pressPosition.x >= 0 && owner.dragHandler.isDrag(pressPosition.x, pressPosition.y, mouse.x, mouse.y)) {
                dragged = true;
                if (owner.dragHost)
                    owner.dragHost.dragSource = entry;
                owner.dragHandler.startDrag(owner.dragHost || entry, entry.url, entry.icon);
            }
        }
    }
    Item {
        id: documents
        objectName: "recentFilesButton"
        anchors.right: parent.right
        height: parent.height
        width: entry.recentActions.length ? 30 : 0
        visible: width > 0
        Accessible.role: Accessible.ButtonMenu
        Accessible.expandable: true
        Accessible.expanded: documentMenu.opened && documentMenu.visualParent === entry
        Accessible.name: i18n("Recent files for %1", label.text)
        Accessible.onPressAction: entry.openDocuments()
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 16
            height: 16
            source: "arrow-right"
        }
        MouseArea {
            id: documentPointer
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPositionChanged: mouse => owner.selectFromPointer(index, mapToItem(itemView, mouse.x, mouse.y))
            onPressed: mouse => {
                if (mouse.button === Qt.RightButton) {
                    owner.currentIndex = index;
                    entry.forceActiveFocus(Qt.MouseFocusReason);
                    const position = mapToItem(entry, mouse.x, mouse.y);
                    entry.openActionMenu(position.x, position.y);
                }
            }
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    entry.openDocuments();
            }
        }
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier)) {
            event.accepted = true;
            openActionMenu();
        } else if (event.key === Qt.Key_Right && recentActions.length) {
            event.accepted = true;
            openDocuments();
        }
    }
}
