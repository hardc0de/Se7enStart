// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtTest
import "../contents/ui"
import "../contents/ui/parts" as Parts

TestCase {
    id: root
    name: "MenuViewSizes"
    when: windowShown
    visible: true
    width: 500
    height: 740

    function i18n(text) {
        return text;
    }
    function toggle() {
    }
    QtObject {
        id: kicker
        property bool expanded: true
    }
    QtObject {
        id: dragHelper
        property bool dragging: false
    }
    QtObject {
        id: highlightItemSvg
        property var margins: ({
                top: 0
            })
    }
    QtObject {
        id: searchBar
        function focusSearchField() {
        }
    }
    Item {
        id: toolTipDelegate
    }

    ListModel {
        id: applications
        ListElement {
            display: "Terminal"
            name: "Terminal"
            group: "Applications"
            decoration: "utilities-terminal"
            disabled: false
            favoriteId: "terminal.desktop"
        }
        ListElement {
            display: "Files"
            name: "Files"
            group: "Applications"
            decoration: "system-file-manager"
            disabled: false
            favoriteId: "files.desktop"
        }
    }
    ListModel {
        id: runnerModel
        property string query: ""
        function modelForRow(row) {
            return applications;
        }
        ListElement {
            display: "Search results"
        }
    }
    MenuContent {
        id: menu
        anchors.fill: parent
        navigationButton: searching ? backButton : allAppsButton
        applicationsNavigation: Parts.MenuNavigationButton {
            id: allAppsButton
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            text: "Wszystkie programy"
        }
        searchNavigation: Parts.MenuNavigationButton {
            id: backButton
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            text: "Wstecz"
        }
        Component.onCompleted: {
            // Keep displayed items independent of the user's actual usage history.
            favoritesGrid.model = applications;
            recentsGrid.model = applications;
            allAppsGrid.model = applications;
            runnerGrid.model = runnerModel;
        }
    }
    SignalSpy {
        id: favoritesHeightChanges
        target: menu.favoritesGrid
        signalName: "heightChanged"
    }
    SignalSpy {
        id: recentsHeightChanges
        target: menu.recentsGrid
        signalName: "heightChanged"
    }

    function init() {
        root.width = 500;
        root.height = 740;
        menu.searching = false;
        menu.showApps = 0;
        menu.favoritesGrid.currentIndex = 0;
        menu.recentsGrid.currentIndex = 0;
        waitForRendering(menu);
        favoritesHeightChanges.clear();
        recentsHeightChanges.clear();
    }

    function checkRenderedSizes(view, iconSize, rowHeight) {
        compare(view.iconSize, iconSize);
        compare(view.cellHeight, rowHeight);
        tryVerify(() => view.currentItem !== null);
        compare(view.currentItem.height, rowHeight);
        const icon = findChild(view.currentItem, "applicationIcon");
        verify(icon !== null);
        compare(icon.width, iconSize);
        compare(icon.height, iconSize);
    }

    function checkLargeViewsUnchanged() {
        compare(menu.favoritesGrid.iconSize, 32);
        compare(menu.favoritesGrid.cellHeight, 48);
        compare(menu.favoritesGrid.height, applications.count * 48);
        compare(menu.recentsGrid.iconSize, 32);
        compare(menu.recentsGrid.cellHeight, 48);
        compare(menu.recentsGrid.height, applications.count * 48);
        compare(favoritesHeightChanges.count, 0);
        compare(recentsHeightChanges.count, 0);
    }

    function belongsTo(item, container) {
        for (let parent = item.parent; parent; parent = parent.parent) {
            if (parent === container)
                return true;
        }
        return false;
    }

    function test_navigation_buttons_belong_to_separate_pages() {
        verify(belongsTo(allAppsButton, menu.applicationsPage));
        verify(belongsTo(menu.favoritesComponent, menu.applicationsPage));
        verify(belongsTo(backButton, menu.searchPage));
        verify(belongsTo(menu.runnerGrid, menu.searchPage));
        verify(allAppsButton.visible);
        verify(!backButton.visible);
        compare(menu.navigationButton, allAppsButton);
        const normalButtonPosition = allAppsButton.mapToItem(menu, 0, 0);
        menu.searching = true;
        waitForRendering(menu);
        verify(!allAppsButton.visible);
        verify(backButton.visible);
        compare(menu.navigationButton, backButton);
        compare(backButton.mapToItem(menu, 0, 0), normalButtonPosition);
        menu.searching = false;
        verify(allAppsButton.visible);
        verify(!backButton.visible);
    }

    function test_search_does_not_resize_favorites_or_recents() {
        checkRenderedSizes(menu.favoritesGrid, 32, 48);
        checkRenderedSizes(menu.recentsGrid, 32, 48);
        menu.searching = true;
        waitForRendering(menu);
        verify(menu.runnerGrid.visible);
        verify(!menu.favoritesComponent.visible);
        checkLargeViewsUnchanged();
        checkRenderedSizes(menu.runnerGrid, 16, 24);
        menu.searching = false;
        waitForRendering(menu);
        checkLargeViewsUnchanged();
        checkRenderedSizes(menu.favoritesGrid, 32, 48);
        checkRenderedSizes(menu.recentsGrid, 32, 48);
    }

    function test_all_programs_does_not_resize_favorites_or_recents() {
        menu.showApps = 1;
        menu.allAppsGrid.currentIndex = 0;
        waitForRendering(menu);
        checkLargeViewsUnchanged();
        checkRenderedSizes(menu.allAppsGrid, 16, 24);
    }

    function test_all_programs_rows_fit_viewport_data() {
        return [
            {
                tag: "minimum",
                width: 468,
                height: 648
            },
            {
                tag: "normal",
                width: 500,
                height: 740
            },
            {
                tag: "wide",
                width: 680,
                height: 740
            }
        ];
    }

    function test_pointer_exit_clears_highlight_data() {
        return [
            {
                tag: "favorites",
                section: "favoritesGrid"
            },
            {
                tag: "recents",
                section: "recentsGrid"
            },
            {
                tag: "allApps",
                section: "allAppsGrid"
            },
            {
                tag: "search",
                section: "runnerGrid"
            }
        ];
    }

    function test_pointer_exit_clears_highlight(data) {
        menu.showApps = data.section === "allAppsGrid" ? 1 : 0;
        menu.searching = data.section === "runnerGrid";
        const section = menu[data.section];
        section.currentIndex = 0;
        waitForRendering(menu);
        mouseMove(root, root.width - 2, root.height - 2);
        mouseMove(section.currentItem, 60, section.cellHeight / 2);
        tryCompare(section, "selectionFromPointer", true);
        compare(section.currentIndex, 0);
        verify(section.view.highlightItem.visible);
        mouseMove(root, root.width - 2, root.height - 2);
        tryCompare(section, "currentIndex", -1);
        verify(!section.view.highlightItem || !section.view.highlightItem.visible);

        // Arrow navigation must still select rows when the pointer is elsewhere.
        section.tryActivate(0, 0);
        keyClick(Qt.Key_Down);
        compare(section.currentIndex, 1);
        verify(section.view.highlightItem.visible);
    }

    function test_all_programs_rows_fit_viewport(data) {
        root.width = data.width;
        root.height = data.height;
        menu.showApps = 1;
        menu.allAppsGrid.currentIndex = 0;
        waitForRendering(menu);
        const row = menu.allAppsGrid.currentItem;
        const view = row.itemView;
        // The scrollbar reserves space inside the outer container.
        verify(view.width < menu.allAppsGrid.width);
        compare(row.width, view.width);
        compare(view.highlightItem.width, view.width);
        verify(view.highlightItem.x + view.highlightItem.width <= view.width);

        menu.allAppsGrid.forceActiveFocus();
        keyClick(Qt.Key_Down);
        compare(menu.allAppsGrid.currentIndex, 1);

        // The last pixels of the row must also receive pointer input.
        menu.allAppsGrid.currentIndex = -1;
        mousePress(row, row.width - 2, row.height / 2);
        compare(menu.allAppsGrid.currentIndex, 0);
        compare(view.highlightItem.width, view.width);
        mouseRelease(root, root.width - 1, root.height - 1);
        root.width = 500;
        root.height = 740;
    }
}
