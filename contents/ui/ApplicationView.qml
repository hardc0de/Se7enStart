// SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
// SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import "code/tools.js" as Tools

PC3.ScrollView {
    id: itemGrid
    property var model: null
    property var favoritesModel: model && model.favoritesModel !== undefined ? model.favoritesModel : null
    property var dragHandler: null
    property var dragHost: null
    property bool dragEnabled: true
    property bool dropEnabled: false
    property bool showLabels: true
    property bool mergedResults: false
    property bool naturalHeight: false
    property bool showSections: false
    property bool autoSelectFirst: false
    property int rowHeight: 24
    property int appIconSize: 16
    readonly property int cellHeight: rowHeight
    readonly property int iconSize: appIconSize
    readonly property real cellWidth: listView.width
    readonly property var displayModel: mergedResults ? (model && model.count ? model.modelForRow(0) : null) : model
    property int actionsRevision: 0
    property point lastPointerPosition: Qt.point(-1, -1)
    property bool selectionFromPointer: false
    property alias view: listView
    property alias currentIndex: listView.currentIndex
    property alias currentItem: listView.currentItem
    property alias count: listView.count
    property alias interactive: listView.interactive
    property var horizontalScrollBarPolicy: PC3.ScrollBar.AlwaysOff
    property var verticalScrollBarPolicy: naturalHeight ? PC3.ScrollBar.AlwaysOff : PC3.ScrollBar.AlwaysOn
    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown
    signal itemActivated(int index, string actionId, var argument)
    signal closeRequested

    // The large rows live inside the main page's outer scrolling viewport.
    // A nested ScrollView must not consume its wheel events.
    function updateWheelHandlers() {
        for (const child of data) {
            if (child.verticalStepSize !== undefined && child.horizontalStepSize !== undefined)
                child.target = naturalHeight ? null : listView;
        }
    }
    Component.onCompleted: updateWheelHandlers()
    onNaturalHeightChanged: updateWheelHandlers()

    WheelHandler {
        enabled: itemGrid.naturalHeight
        target: null
        onWheel: event => {
            let outer = itemGrid.parent;
            while (outer && !(outer.availableWidth !== undefined && outer.contentItem && outer.contentItem.contentY !== undefined))
                outer = outer.parent;
            if (!outer) {
                event.accepted = false;
                return;
            }
            const viewport = outer.contentItem;
            const delta = event.pixelDelta.y || event.angleDelta.y / 120 * Qt.styleHints.wheelScrollLines * 20;
            const next = Math.max(0, Math.min(viewport.contentHeight - viewport.height, viewport.contentY - delta));
            event.accepted = next !== viewport.contentY;
            viewport.contentY = next;
        }
    }

    function actionsFor(row) {
        if (!displayModel || row < 0 || row >= count)
            return [];
        const role = displayModel.KItemModels.KRoleNames.role("actionList");
        return role < 0 ? [] : (displayModel.data(displayModel.index(row, 0), role) || []);
    }
    function refreshActions() {
        ++actionsRevision;
    }
    function closePopups() {
        actionMenu.close();
        recentMenu.close();
    }
    function currentRow() {
        return currentIndex;
    }
    function currentCol() {
        return currentIndex < 0 ? -1 : 0;
    }
    function lastRow() {
        return count - 1;
    }
    function forceLayout() {
        listView.forceLayout();
    }
    function resetSelection() {
        selectionFromPointer = false;
        currentIndex = autoSelectFirst && count ? 0 : -1;
    }
    function selectFromPointer(row, position) {
        // Ignore hover synthesis when keyboard scrolling moves rows beneath a stationary pointer.
        if (position.x === lastPointerPosition.x && position.y === lastPointerPosition.y)
            return;
        lastPointerPosition = position;
        selectionFromPointer = true;
        currentIndex = row;
    }
    function clearPointerSelection(row) {
        if (selectionFromPointer && currentIndex === row && !actionMenu.opened && !recentMenu.opened) {
            currentIndex = -1;
            selectionFromPointer = false;
            lastPointerPosition = Qt.point(-1, -1);
        }
    }
    function focusCurrentItem(reason) {
        if (currentItem)
            currentItem.forceActiveFocus(reason);
        else
            listView.forceActiveFocus(reason);
        listView.positionViewAtIndex(currentIndex, ListView.Contain);
    }
    function tryActivate(row, col) {
        if (!count)
            return false;
        selectionFromPointer = false;
        currentIndex = Math.max(0, Math.min(row, count - 1));
        focusCurrentItem(Qt.TabFocusReason);
        return true;
    }
    function moveSelection(direction) {
        if (!count)
            return;
        selectionFromPointer = false;
        const next = currentIndex < 0 ? (direction > 0 ? 0 : count - 1) : currentIndex + direction;
        if (next < 0)
            keyNavUp();
        else if (next >= count)
            keyNavDown();
        else {
            currentIndex = next;
            focusCurrentItem(Qt.TabFocusReason);
        }
    }
    function triggerItem(row, actionId, argument) {
        if (!displayModel || row < 0 || row >= count)
            return;
        const close = Tools.triggerAction(displayModel, row, actionId || "", argument);
        itemActivated(row, actionId || "", argument);
        refreshActions();
        if (close)
            closeRequested();
    }
    function activateCurrentItem() {
        if (currentIndex < 0 && count)
            currentIndex = 0;
        triggerItem(currentIndex, "", null);
    }
    function dropApplication(source, destination) {
        if (!dropEnabled || !favoritesModel || !source || !source.favoriteId)
            return false;
        const id = source.favoriteId;
        const role = favoritesModel.KItemModels.KRoleNames.role("favoriteId");
        const urlRole = favoritesModel.KItemModels.KRoleNames.role("url");
        const sourceId = Tools.canonicalAppId(id);
        const sourceUrl = Tools.canonicalAppId(source.url);
        let existing = -1;
        for (let i = 0; i < favoritesModel.count; ++i) {
            const index = favoritesModel.index(i, 0);
            const pinnedId = Tools.canonicalAppId(favoritesModel.data(index, role));
            const pinnedUrl = Tools.canonicalAppId(favoritesModel.data(index, urlRole));
            if (sourceId === pinnedId || sourceId === pinnedUrl || (sourceUrl && (sourceUrl === pinnedId || sourceUrl === pinnedUrl))) {
                existing = i;
                break;
            }
        }
        const target = Math.max(0, Math.min(destination, favoritesModel.count));
        if (existing >= 0)
            favoritesModel.moveRow(existing, Math.min(target, favoritesModel.count - 1));
        else
            favoritesModel.addFavorite(id, target);
        return true;
    }
    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return;
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            event.accepted = true;
            moveSelection(event.key === Qt.Key_Up ? -1 : 1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true;
            activateCurrentItem();
        }
    }
    Connections {
        target: itemGrid.model
        ignoreUnknownSignals: true
        function onQueryChanged() {
            itemGrid.resetSelection();
        }
    }
    Connections {
        target: itemGrid.displayModel
        ignoreUnknownSignals: true
        function onModelAboutToBeReset() {
            itemGrid.closePopups();
        }
        function onRowsAboutToBeRemoved() {
            itemGrid.closePopups();
        }
        function onRowsAboutToBeMoved() {
            itemGrid.closePopups();
        }
    }
    ActionMenu {
        id: actionMenu
        onActionClicked: (actionId, argument) => {
            if (visualParent)
                itemGrid.triggerItem(visualParent.itemIndex, actionId, argument);
        }
    }
    ActionMenu {
        id: recentMenu
        onActionClicked: (actionId, argument) => {
            if (visualParent)
                itemGrid.triggerItem(visualParent.itemIndex, actionId, argument);
        }
    }
    PC3.ScrollBar.horizontal.policy: horizontalScrollBarPolicy
    PC3.ScrollBar.vertical.policy: verticalScrollBarPolicy
    contentItem: ListView {
        id: listView
        model: itemGrid.displayModel
        property real cellWidth: width
        readonly property int cellHeight: itemGrid.cellHeight
        readonly property int iconSize: itemGrid.iconSize
        focus: true
        clip: true
        interactive: !itemGrid.naturalHeight && height < contentHeight
        currentIndex: itemGrid.autoSelectFirst && count ? 0 : -1
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: false
        highlightMoveDuration: 0
        highlightResizeDuration: 0
        onCountChanged: {
            if (!activeFocus)
                itemGrid.resetSelection();
            else if (currentIndex >= count)
                currentIndex = count - 1;
        }
        onCurrentIndexChanged: if (currentIndex >= 0)
            positionViewAtIndex(currentIndex, ListView.Contain)
        Keys.onUpPressed: itemGrid.moveSelection(-1)
        Keys.onDownPressed: itemGrid.moveSelection(1)
        Keys.onLeftPressed: itemGrid.keyNavLeft()
        Keys.onRightPressed: itemGrid.keyNavRight()
        Keys.onReturnPressed: itemGrid.activateCurrentItem()
        Keys.onEnterPressed: itemGrid.activateCurrentItem()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                event.accepted = true;
                itemGrid.tryActivate(event.key === Qt.Key_Home ? 0 : count - 1, 0);
            }
        }
        section.property: itemGrid.showSections ? "group" : ""
        section.delegate: Kirigami.Heading {
            required property string section
            width: listView.width
            height: implicitHeight + Kirigami.Units.largeSpacing
            leftPadding: Kirigami.Units.smallSpacing
            level: 4
            text: section
            textFormat: Text.PlainText
            elide: Text.ElideRight
        }
        highlight: PlasmaExtras.Highlight {
            visible: listView.currentItem !== null
            hovered: true
            pressed: listView.currentItem ? listView.currentItem.pressed : false
        }
        delegate: ItemGridDelegate {
            owner: itemGrid
            contextMenu: actionMenu
            documentMenu: recentMenu
        }
    }
    DropArea {
        anchors.fill: parent
        enabled: itemGrid.dropEnabled
        onEntered: drag => {
            drag.accepted = !!(drag.source || (itemGrid.dragHost && itemGrid.dragHost.dragSource));
        }
        onDropped: drop => {
            const source = drop.source && drop.source.favoriteId ? drop.source : (itemGrid.dragHost ? itemGrid.dragHost.dragSource : null);
            const pos = mapToItem(listView.contentItem, drop.x, drop.y);
            const row = listView.indexAt(pos.x, pos.y);
            drop.accepted = itemGrid.dropApplication(source, row < 0 ? itemGrid.count : row);
        }
    }
    onVisibleChanged: if (!visible)
        closePopups()
}
