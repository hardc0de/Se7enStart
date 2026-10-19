/*
    SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
    SPDX-FileCopyrightText: 2014-2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
    SPDX-FileCopyrightText: 2024 ivan tkachenko <me@ratijas.tk>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.extras as PlasmaExtras

// Kickoff's native QMenu construction, with per-view ownership and action routing.
Item {
    id: root

    property Item visualParent
    property var actionList: null
    readonly property bool opened: menu.status !== PlasmaExtras.Menu.Closed
    readonly property PlasmaExtras.Menu menu: PlasmaExtras.Menu {
        visualParent: root.visualParent
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }

    visible: false

    signal actionClicked(string actionId, var actionArgument)
    signal closed

    onOpenedChanged: if (!opened) closed()

    function open(x, y) {
        if (!actionList || !items.count)
            return;
        menu.placement = PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        if (x !== undefined && y !== undefined)
            menu.open(x, y);
        else
            menu.openRelative();
    }

    function openRelative() {
        if (!actionList || !items.count)
            return;
        menu.placement = PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        menu.openRelative();
    }

    function close() {
        if (opened)
            menu.close();
        visualParent = null;
    }

    Instantiator {
        id: items
        active: root.actionList !== null
        model: root.actionList
        delegate: menuItemComponent
        onObjectAdded: (index, object) => menu.addMenuItem(object)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }

    Component {
        id: menuComponent
        PlasmaExtras.Menu {}
    }

    Component {
        id: menuItemComponent

        PlasmaExtras.MenuItem {
            id: menuItem
            required property var modelData
            readonly property PlasmaExtras.Menu subMenu: modelData.subActions
                ? menuComponent.createObject(this, { visualParent: action }) as PlasmaExtras.Menu
                : null

            text: modelData.text ?? ""
            enabled: modelData.type !== "title" && (modelData.enabled ?? true)
            separator: modelData.type === "separator"
            section: modelData.type === "title"
            icon: modelData.icon ?? null
            checkable: modelData.checkable ?? false
            checked: modelData.checked ?? false

            readonly property Instantiator __instantiator: Instantiator {
                active: menuItem.subMenu !== null
                model: menuItem.modelData.subActions
                delegate: menuItemComponent
                onObjectAdded: (index, object) => menuItem.subMenu.addMenuItem(object)
                onObjectRemoved: (index, object) => menuItem.subMenu.removeMenuItem(object)
            }

            onClicked: root.actionClicked(modelData.actionId ?? "", modelData.actionArgument)
        }
    }
}
