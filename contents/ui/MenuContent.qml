/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-FileCopyrightText: zayronxio
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami as Kirigami
import QtCore
import "parts" as Parts

Item {
    id: contentRoot

    // Keep the normal menu's minimum even when its application sections are hidden.
    readonly property real minimumLeftColumnHeight: favoritesGrid.count * favoritesGrid.cellHeight
        + recentsGrid.count * recentsGrid.cellHeight
        + (favoritesGrid.count > 0 ? favoritesSeparatorTop.height + favoritesSeparator.height + favoritesSeparatorBottom.height : 0)
        + applicationsScroll.topPadding + applicationsScroll.bottomPadding
        + Math.max(applicationsNavigation.implicitHeight, searchNavigation.implicitHeight)
        + applicationControls.implicitHeight
    readonly property real minimumRightColumnHeight: Math.max(portraitContainer.implicitHeight, portraitContainer.Layout.preferredHeight)
        + sidebarColumn.implicitHeight
        + sidebarScroll.anchors.topMargin + sidebarScroll.anchors.bottomMargin
        + sidebarScroll.topPadding + sidebarScroll.bottomPadding
        + Math.max(sessionControls.implicitHeight, sessionControls.Layout.minimumHeight, sessionControls.Layout.preferredHeight)
    implicitHeight: Math.ceil(Math.max(minimumLeftColumnHeight, minimumRightColumnHeight))

    // Properties passed from parent
    property int showApps: 0
    property bool searching: false
    property alias favoritesComponent: favoritesContainer
    property alias allAppsGrid: allAppsGrid
    property alias runnerGrid: runnerGrid
    property alias mainColumn: mainColumn
    property alias sidebar: sidebar
    property alias favoritesGrid: favoritesGrid
    property alias recentsGrid: recentsGrid

    // Controls supplied by main.qml remain in their corresponding column.
    property alias applicationControls: applicationControls.data
    property alias applicationsNavigation: applicationsNavigation.data
    property alias searchNavigation: searchNavigation.data
    property alias applicationsPage: applicationsPage
    property alias searchPage: searchPage
    property Item navigationButton: null
    property Item searchField: null

    property alias userPortrait: portraitContainer.data
    property alias sessionControls: sessionControls.data
    property var executable
    property var favoriteModel: null
    property var applicationsModel: null
    property var searchModel: null
    property var dragHandler: null
    property var dragHost: null
    property string taskManagerCommand: "missioncenter || plasma-systemmonitor"
    signal closeRequested
    signal showAppsRequested(int page)

    function focusNavigationButton() {
        if (navigationButton)
            navigationButton.forceActiveFocus(Qt.TabFocusReason);
    }

    function focusApplications(last) {
        if (searching && runnerGrid.count)
            return runnerGrid.tryActivate(last ? runnerGrid.count - 1 : 0, 0);
        if (!searching && showApps === 1 && allAppsGrid.count)
            return allAppsGrid.tryActivate(last ? allAppsGrid.count - 1 : 0, 0);
        if (!searching && showApps === 0) {
            if (last && recentsGrid.count)
                return recentsGrid.tryActivate(recentsGrid.count - 1, 0);
            if (favoritesGrid.count)
                return favoritesGrid.tryActivate(last ? favoritesGrid.count - 1 : 0, 0);
            if (recentsGrid.count)
                return recentsGrid.tryActivate(last ? recentsGrid.count - 1 : 0, 0);
        }
        focusNavigationButton();
        return false;
    }
    function closePopups() {
        favoritesGrid.closePopups();
        recentsGrid.closePopups();
        allAppsGrid.closePopups();
        runnerGrid.closePopups();
    }
    function refreshActions() {
        favoritesGrid.refreshActions();
        recentsGrid.refreshActions();
        allAppsGrid.refreshActions();
    }
    function openDirectory(location) {
        const paths = StandardPaths.standardLocations(location);
        if (paths.length) {
            Qt.openUrlExternally(paths[0]);
            closeRequested();
        }
    }

    // Main Content Area
    RowLayout {
        anchors {
            top: parent.top
            topMargin: 0
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        spacing: Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: leftColumn
            Layout.preferredWidth: contentRoot.width * 0.55
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            spacing: 0

            Item {
                id: mainArea
                // Keep forwarding outside the search field's ancestor chain,
                // as in Kickoff's contentItemStackView and header layout.
                Keys.priority: Keys.AfterItem
                Keys.forwardTo: contentRoot.searchField ? [contentRoot.searchField] : []
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0

                // The normal page owns both application sections and its navigation button.
                ColumnLayout {
                    id: applicationsPage
                    anchors.fill: parent
                    visible: !contentRoot.searching
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 0

                        Item {
                            id: favoritesContainer
                            visible: showApps === 0 && !searching
                            anchors {
                                top: parent.top
                                left: parent.left
                            }
                            width: parent.width
                            height: parent.height

                            property alias model: favoritesGrid.externalFavoritesModel

                            function ensureCurrentItemVisible(grid) {
                                if (grid.currentIndex < 0 || !grid.activeFocus)
                                    return;
                                var flickable = applicationsScroll.contentItem;
                                var itemTop = grid.mapToItem(flickable.contentItem, 0, grid.currentIndex * grid.cellHeight).y;
                                var targetY = flickable.contentY;
                                if (itemTop < targetY) {
                                    targetY = itemTop;
                                } else if (itemTop + grid.cellHeight > targetY + flickable.height) {
                                    targetY = itemTop + grid.cellHeight - flickable.height;
                                }
                                flickable.contentY = Math.max(0, Math.min(targetY, flickable.contentHeight - flickable.height));
                            }

                            function tryActivate(row, col) {
                                var favoritesRows = favoritesGrid.count;
                                if (row < favoritesRows) {
                                    favoritesGrid.tryActivate(row, col);
                                } else {
                                    var adjustedRow = row - favoritesRows;
                                    recentsGrid.tryActivate(adjustedRow, col);
                                }
                            }

                            PC3.ScrollView {
                                id: applicationsScroll
                                anchors.fill: parent
                                contentWidth: availableWidth
                                contentHeight: applicationList.implicitHeight
                                clip: true
                                onHeightChanged: Qt.callLater(function () {
                                    favoritesContainer.ensureCurrentItemVisible(favoritesGrid);
                                    favoritesContainer.ensureCurrentItemVisible(recentsGrid);
                                })
                                PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff
                                PC3.ScrollBar.vertical.policy: PC3.ScrollBar.AsNeeded

                                Column {
                                    id: applicationList
                                    width: applicationsScroll.availableWidth
                                    spacing: 0

                                    // Favorites Grid
                                    Parts.FavoritesRow {
                                        id: favoritesGrid
                                        externalFavoritesModel: contentRoot.favoriteModel
                                        dragHandler: contentRoot.dragHandler
                                        dragHost: contentRoot.dragHost
                                        width: parent.width
                                        height: count * cellHeight
                                        dragEnabled: true
                                        dropEnabled: true

                                        onCurrentIndexChanged: favoritesContainer.ensureCurrentItemVisible(favoritesGrid)
                                        onActiveFocusChanged: {
                                            if (activeFocus)
                                                favoritesContainer.ensureCurrentItemVisible(favoritesGrid);
                                        }

                                        onKeyNavDown: {
                                            if (recentsGrid.count)
                                                recentsGrid.tryActivate(0, 0);
                                            else
                                                contentRoot.focusNavigationButton();
                                        }

                                        onKeyNavUp: {
                                            contentRoot.focusNavigationButton();
                                        }

                                        onKeyNavRight: {
                                            sidebar.forceActiveFocus();
                                        }

                                        onCloseRequested: contentRoot.closeRequested()
                                    }

                                    // Separator

                                    Rectangle {
                                        id: favoritesSeparatorTop
                                        width: parent.width * 0.9
                                        height: 10
                                        color: Kirigami.Theme.textColor || "#eff0f1"
                                        opacity: 0
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: favoritesGrid.count > 0
                                    }

                                    Rectangle {
                                        id: favoritesSeparator
                                        height: 1
                                        color: Kirigami.Theme.textColor || "#eff0f1"
                                        opacity: 0.2
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            leftMargin: Kirigami.Units.smallSpacing * 2
                                            rightMargin: Kirigami.Units.smallSpacing
                                        }
                                        visible: favoritesGrid.count > 0
                                    }

                                    Rectangle {
                                        id: favoritesSeparatorBottom
                                        width: parent.width * 0.9
                                        height: 10
                                        color: Kirigami.Theme.textColor || "#eff0f1"
                                        opacity: 0
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: favoritesGrid.count > 0
                                    }

                                    // Recents Grid
                                    Parts.RecentsRow {
                                        id: recentsGrid
                                        dragHandler: contentRoot.dragHandler
                                        dragHost: contentRoot.dragHost
                                        width: parent.width
                                        // Guarantee enough height for ALL recents rows (single column: cellWidth == width)
                                        height: count * cellHeight
                                        favoritesModel: favoritesGrid.externalFavoritesModel

                                        onCurrentIndexChanged: favoritesContainer.ensureCurrentItemVisible(recentsGrid)
                                        onActiveFocusChanged: {
                                            if (activeFocus)
                                                favoritesContainer.ensureCurrentItemVisible(recentsGrid);
                                        }

                                        onKeyNavUp: {
                                            if (favoritesGrid.count > 0) {
                                                favoritesGrid.tryActivate(favoritesGrid.count - 1, 0);
                                            } else
                                                contentRoot.focusNavigationButton();
                                        }

                                        onKeyNavDown: {
                                            searchBar.focusSearchField();
                                        }

                                        onKeyNavRight: {
                                            sidebar.forceActiveFocus();
                                        }

                                        onCloseRequested: contentRoot.closeRequested()
                                    }
                                }
                            }
                        }

                        Item {
                            id: mainGrids
                            visible: showApps === 1 && !searching
                            onVisibleChanged: if (!visible && allAppsGrid)
                                allAppsGrid.resetToBeginning()
                            anchors {
                                top: parent.top
                                left: parent.left
                            }
                            width: parent.width
                            height: parent.height

                            Item {
                                id: mainColumn
                                anchors.fill: parent
                                property Item visibleGrid: allAppsGrid

                                // Regular apps grid
                                ItemGridView {
                                    id: allAppsGrid
                                    model: contentRoot.applicationsModel
                                    favoritesModel: contentRoot.favoriteModel
                                    dragHandler: contentRoot.dragHandler
                                    dragHost: contentRoot.dragHost
                                    onCloseRequested: contentRoot.closeRequested()
                                    anchors.fill: parent
                                    enabled: parent.visible
                                    z: enabled ? 5 : -1

                                    onKeyNavUp: {
                                        contentRoot.focusNavigationButton();
                                    }

                                    onKeyNavDown: {
                                        contentRoot.focusNavigationButton();
                                    }

                                    onKeyNavLeft: {
                                        contentRoot.showAppsRequested(0);
                                        Qt.callLater(function () {
                                            contentRoot.focusApplications(false);
                                        });
                                    }

                                    onKeyNavRight: {
                                        sidebar.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: applicationsNavigation
                        Layout.fillWidth: true
                        spacing: 0
                    }
                }

                // Search has an independent page and Back button above the shared search field.
                ColumnLayout {
                    id: searchPage
                    anchors.fill: parent
                    visible: contentRoot.searching
                    spacing: 0

                    Item {
                        id: searchContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 0

                        // Search results have their own fixed-size list view.
                        SearchResultsView {
                            id: runnerGrid
                            model: contentRoot.searchModel
                            favoritesModel: contentRoot.favoriteModel
                            dragHandler: contentRoot.dragHandler
                            dragHost: contentRoot.dragHost
                            onCloseRequested: contentRoot.closeRequested()
                            anchors.fill: parent
                            enabled: parent.visible
                            z: enabled ? 5 : -1
                            onKeyNavUp: searchBar.focusSearchField()
                            onKeyNavDown: contentRoot.focusNavigationButton()
                            onKeyNavRight: sidebar.forceActiveFocus()
                        }
                    }

                    ColumnLayout {
                        id: searchNavigation
                        Layout.fillWidth: true
                        spacing: 0
                    }
                }
            }

            ColumnLayout {
                id: applicationControls
                Layout.fillWidth: true
                spacing: 0
            }
        }

        ColumnLayout {
            id: rightColumn
            Keys.priority: Keys.AfterItem
            Keys.forwardTo: contentRoot.searchField ? [contentRoot.searchField] : []
            Layout.preferredWidth: contentRoot.width * 0.4
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            spacing: 0

            ColumnLayout {
                id: portraitContainer
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                spacing: 0
            }

            FocusScope {
                id: sidebar
                objectName: "sidebar"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                Layout.rightMargin: Kirigami.Units.smallSpacing
                focus: false

                // Navigation signals
                signal keyNavUp
                signal keyNavDown
                signal keyNavLeft

                // Keyboard navigation
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                        keyNavLeft();
                    }
                }

                onKeyNavLeft: contentRoot.focusApplications(false)

                function ensureVisible(item) {
                    const view = sidebarScroll.contentItem;
                    const position = item.mapToItem(view.contentItem, 0, 0);
                    if (position.y < view.contentY)
                        view.contentY = position.y;
                    else if (position.y + item.height > view.contentY + view.height)
                        view.contentY = position.y + item.height - view.height;
                    view.contentY = Math.max(0, Math.min(view.contentY, view.contentHeight - view.height));
                }

                // When sidebar receives focus, focus first child
                onActiveFocusChanged: {
                    if (activeFocus && sidebarColumn.children.length > 0) {
                        // Find first SidebarItem in children
                        for (var i = 0; i < sidebarColumn.children.length; i++) {
                            var child = sidebarColumn.children[i];
                            if (child && child.activeFocusOnTab) {
                                child.forceActiveFocus();
                                break;
                            }
                        }
                    }
                }

                PC3.ScrollView {
                    id: sidebarScroll
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    anchors.leftMargin: Kirigami.Units.smallSpacing * 2

                    PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff
                    PC3.ScrollBar.vertical.policy: PC3.ScrollBar.AsNeeded

                    Column {
                        id: sidebarColumn
                        width: sidebarScroll.availableWidth
                        spacing: 4

                        // SEÇÃO 1: Pastas do usuário
                        Repeater {
                            model: ListModel {
                                ListElement {
                                    text: QT_TR_NOOP("Home")
                                    icon: "user-home"
                                    location: StandardPaths.HomeLocation
                                    type: "folder"
                                }
                                ListElement {
                                    text: QT_TR_NOOP("Documents")
                                    icon: "folder-documents"
                                    location: StandardPaths.DocumentsLocation
                                    type: "folder"
                                }
                                ListElement {
                                    text: QT_TR_NOOP("Pictures")
                                    icon: "folder-pictures"
                                    location: StandardPaths.PicturesLocation
                                    type: "folder"
                                }
                                ListElement {
                                    text: QT_TR_NOOP("Music")
                                    icon: "folder-music"
                                    location: StandardPaths.MusicLocation
                                    type: "folder"
                                }
                                ListElement {
                                    text: QT_TR_NOOP("Videos")
                                    icon: "folder-videos"
                                    location: StandardPaths.MoviesLocation
                                    type: "folder"
                                }
                                ListElement {
                                    text: QT_TR_NOOP("Downloads")
                                    icon: "folder-downloads"
                                    location: StandardPaths.DownloadLocation
                                    type: "folder"
                                }
                            }

                            delegate: SidebarItem {
                                text: i18n(model.text)
                                icon: model.icon
                                onClicked: {
                                    contentRoot.openDirectory(model.location);
                                }
                            }
                        }

                        // Separador 1
                        Rectangle {
                            height: 1
                            color: Kirigami.Theme.separatorColor || "#3c4043"
                            opacity: 0.5
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: Kirigami.Units.smallSpacing * 2
                                rightMargin: Kirigami.Units.smallSpacing
                            }
                        }

                        SidebarItem {
                            text: i18n("Computer")
                            icon: "computer"
                            onClicked: {
                                if (contentRoot.executable) {
                                    contentRoot.executable.exec("dolphin --new-window");
                                    contentRoot.closeRequested();
                                }
                            }
                        }

                        SidebarItem {
                            text: i18n("Network")
                            icon: "network-workgroup"
                            onClicked: {
                                if (contentRoot.executable) {
                                    contentRoot.executable.exec("dolphin smb://");
                                    contentRoot.closeRequested();
                                }
                            }
                        }

                        // Separador 2
                        Rectangle {
                            height: 1
                            color: Kirigami.Theme.separatorColor || "#3c4043"
                            opacity: 0.5
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: Kirigami.Units.smallSpacing * 2
                                rightMargin: Kirigami.Units.smallSpacing
                            }
                        }

                        SidebarItem {
                            text: i18n("Settings")
                            icon: "settings"
                            onClicked: {
                                if (contentRoot.executable) {
                                    contentRoot.executable.exec("systemsettings");
                                    contentRoot.closeRequested();
                                }
                            }
                        }

                        SidebarItem {
                            text: i18n("Printers")
                            icon: "printer"
                            onClicked: {
                                if (contentRoot.executable) {
                                    contentRoot.executable.exec("kcmshell6 kcm_printer_manager");
                                    contentRoot.closeRequested();
                                }
                            }
                        }

                        SidebarItem {
                            text: i18n("Default Applications")
                            icon: "emblem-default-symbolic"
                            onClicked: {
                                if (contentRoot.executable) {
                                    contentRoot.executable.exec("kcmshell6 kcm_componentchooser");
                                    contentRoot.closeRequested();
                                }
                            }
                        }

                        SidebarItem {
                            text: i18n("Task Manager")
                            icon: "office-chart-line"
                            onClicked: {
                                if (contentRoot.executable) {
                                    contentRoot.executable.exec(contentRoot.taskManagerCommand);
                                    contentRoot.closeRequested();
                                }
                            }
                        }

                        SidebarItem {
                            text: i18n("Run Command")
                            icon: "system-run"
                            onClicked: {
                                if (contentRoot.executable) {
                                    contentRoot.executable.exec("krunner");
                                    contentRoot.closeRequested();
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: sessionControls
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                Layout.minimumHeight: Kirigami.Units.gridUnit * 2.5
                spacing: 0
            }
        }
    }

    // Componente para items da sidebar
    component SidebarItem: Item {
        id: sidebarItem
        width: parent.width
        height: 36

        property string text: ""
        property string icon: ""
        property bool hasDropdown: false

        signal clicked
        Accessible.role: Accessible.MenuItem
        Accessible.name: text
        Accessible.onPressAction: clicked()
        onActiveFocusChanged: if (activeFocus)
            Qt.callLater(function () {
                sidebar.ensureVisible(sidebarItem);
            })

        // Make focusable
        focus: true
        activeFocusOnTab: true

        // Keyboard navigation
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                event.accepted = true;
                sidebarItem.clicked();
            } else if (event.key === Qt.Key_Right && sidebarItem.hasDropdown) {
                event.accepted = true;
                sidebarItem.clicked();
            } else if (event.key === Qt.Key_Left) {
                event.accepted = true;
                sidebar.keyNavLeft();
            } else if (event.key === Qt.Key_Down) {
                event.accepted = true;
                var myIndex = -1;
                for (var i = 0; i < parent.children.length; i++) {
                    if (parent.children[i] === sidebarItem) {
                        myIndex = i;
                        break;
                    }
                }
                var isLastFocusable = true;
                for (var k = myIndex + 1; k < parent.children.length; k++) {
                    if (parent.children[k] && parent.children[k].activeFocusOnTab) {
                        isLastFocusable = false;
                        break;
                    }
                }
                if (isLastFocusable) {
                    sidebar.keyNavDown();
                } else if (myIndex >= 0 && myIndex < parent.children.length - 1) {
                    for (var j = myIndex + 1; j < parent.children.length; j++) {
                        var nextChild = parent.children[j];
                        if (nextChild && nextChild.activeFocusOnTab) {
                            nextChild.forceActiveFocus();
                            break;
                        }
                    }
                }
            } else if (event.key === Qt.Key_Up) {
                event.accepted = true;
                var myIndex = -1;
                for (var i = 0; i < parent.children.length; i++) {
                    if (parent.children[i] === sidebarItem) {
                        myIndex = i;
                        break;
                    }
                }
                var isFirstFocusable = true;
                for (var k = 0; k < myIndex; k++) {
                    if (parent.children[k] && parent.children[k].activeFocusOnTab) {
                        isFirstFocusable = false;
                        break;
                    }
                }
                if (isFirstFocusable) {
                    sidebar.keyNavUp();
                } else if (myIndex > 0) {
                    for (var j = myIndex - 1; j >= 0; j--) {
                        var prevChild = parent.children[j];
                        if (prevChild && prevChild.activeFocusOnTab) {
                            prevChild.forceActiveFocus();
                            break;
                        }
                    }
                }
            }
        }

        PlasmaExtras.Highlight {
            anchors.fill: parent
            visible: sidebarItem.activeFocus || mouseArea.containsMouse
            hovered: true
            pressed: mouseArea.pressed
        }

        RowLayout {
            anchors.fill: parent
            anchors.rightMargin: 8
            spacing: 12
            anchors.leftMargin: 10

            Kirigami.Icon {
                id: itemIcon
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                source: sidebarItem.icon
                color: Kirigami.Theme.textColor || "#eff0f1"
            }

            PC3.Label {
                id: itemLabel
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                text: sidebarItem.text
                color: Kirigami.Theme.textColor || "#eff0f1"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Seta para dropdown
            Kirigami.Icon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                source: "arrow-right"
                color: Kirigami.Theme.textColor || "#eff0f1"
                opacity: 0.7
                visible: sidebarItem.hasDropdown
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: sidebarItem.clicked()
        }
    }
}
