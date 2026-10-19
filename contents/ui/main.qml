/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.notification as KNotification
import "parts" as Parts

PlasmoidItem {
    id: kicker

    preferredRepresentation: compactRepresentation
    property Item dragSource: null
    property Item searchInput: null
    clip: false

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    property QtObject globalFavorites: rootModel ? rootModel.favoritesModel : null

    KCoreAddons.KUser {
        id: kuser
    }

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

    compactRepresentation: Item {
        Kirigami.Icon {
            id: buttonIcon
            anchors.fill: parent
            source: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon
            active: mouseArea.containsMouse
            smooth: true
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                kicker.expanded = !kicker.expanded;
            }
        }
    }

    fullRepresentation: FocusScope {
        id: root

        Layout.minimumWidth: Kirigami.Units.gridUnit * 26
        Layout.minimumHeight: Math.max(Kirigami.Units.gridUnit * 36,
            menuContent.implicitHeight + menuContent.anchors.topMargin + menuContent.anchors.bottomMargin)
        Layout.preferredWidth: Kirigami.Units.gridUnit * 28
        Layout.preferredHeight: Layout.minimumHeight

        property int showApps: 0
        property bool searching: searchBar.text !== ""

        function toggle() {
            kicker.expanded = false;
            showApps = 0;
            searchBar.clear();
        }

        function returnToFavorites() {
            root.showApps = 0;
            searchBar.clear();
            searchBar.focusSearchField();
        }

        clip: false

        MenuContent {
            id: menuContent
            anchors.fill: parent
            anchors.topMargin: Kirigami.Units.gridUnit * 0.5
            anchors.bottomMargin: Kirigami.Units.gridUnit * 0.5
            showApps: root.showApps
            searching: root.searching
            searchField: searchBar.searchField
            navigationButton: root.searching ? searchBackButton : allAppsButton
            executable: kicker.executable
            dragHandler: dragHelper
            dragHost: kicker
            taskManagerCommand: Plasmoid.configuration.taskManagerCommand
            onCloseRequested: root.toggle()
            onShowAppsRequested: page => root.showApps = page

            property int applicationsRevision: 0
            favoriteModel: kicker.globalFavorites
            searchModel: runnerModel
            applicationsModel: {
                const revision = applicationsRevision;
                return rootModel.count ? rootModel.modelForRow(0) : null;
            }
            Connections {
                target: rootModel
                function onRefreshed() {
                    ++menuContent.applicationsRevision;
                }
            }

            userPortrait: Item {
                id: profilePicWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3.5
                z: 99999
                visible: kicker.expanded

                // Highlight background - visible when ProfilePic has keyboard focus
                PlasmaExtras.Highlight {
                    anchors.fill: floatingAvatar
                    visible: floatingAvatar.activeFocus
                    hovered: true
                    pressed: false
                }

                Parts.PersonalPortrait {
                    id: floatingAvatar
                    anchors.centerIn: parent

                    userFaceIconUrl: kuser.faceIconUrl
                    isExpanded: kicker.expanded
                    executable: kicker.executable

                    onClicked: {
                        root.toggle();
                    }

                    onKeyNavDown: {
                        if (menuContent && menuContent.sidebar) {
                            menuContent.sidebar.forceActiveFocus();
                        }
                    }

                    onKeyNavUp: {
                        if (powerButtons) {
                            powerButtons.forceActiveFocus();
                        }
                    }

                    onKeyNavLeft: menuContent.focusApplications(false)
                }
            }

            applicationsNavigation: Parts.MenuNavigationButton {
                id: allAppsButton
                objectName: "allAppsButton"
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing
                text: root.showApps === 0 ? i18n("All Programs") : i18n("Back")
                icon.name: root.showApps === 0 ? "applications-all" : "go-previous"

                activeFocusOnTab: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        if (root.showApps === 0) {
                            searchBar.focusSearchField();
                        } else {
                            if (menuContent.allAppsGrid) {
                                menuContent.allAppsGrid.currentIndex = menuContent.allAppsGrid.count - 1;
                                menuContent.allAppsGrid.forceActiveFocus();
                            }
                        }
                        return;
                    }

                    if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        if (root.showApps === 0) {
                            if (menuContent.favoritesComponent) {
                                menuContent.focusApplications(false);
                            }
                        } else {
                            if (menuContent.allAppsGrid) {
                                menuContent.allAppsGrid.currentIndex = 0;
                                menuContent.allAppsGrid.forceActiveFocus();
                            }
                        }
                        return;
                    }

                    if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        if (root.showApps === 0) {
                            powerButtons.closePopup();
                            root.showApps = 1;
                            if (menuContent.allAppsGrid && rootModel) {
                                var appModel = rootModel.modelForRow(0);
                                if (appModel) {
                                    menuContent.allAppsGrid.model = appModel;
                                }
                            }
                            Qt.callLater(function () {
                                menuContent.allAppsGrid.currentIndex = 0;
                                menuContent.allAppsGrid.forceActiveFocus();
                            });
                        }
                        return;
                    }

                    if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                        if (root.showApps === 1) {
                            powerButtons.closePopup();
                            root.showApps = 0;
                            if (menuContent.favoritesComponent) {
                                var favGrid = menuContent.favoritesGrid;
                                if (favGrid && favGrid.count > 0) {
                                    favGrid.currentIndex = 0;
                                    Qt.callLater(function () {
                                        favGrid.forceActiveFocus();
                                    });
                                }
                            }
                        }
                        return;
                    }
                }

                onClicked: {
                    powerButtons.closePopup();
                    var newValue = root.showApps === 0 ? 1 : 0;

                    root.showApps = newValue;

                    if (newValue === 1) {
                        if (menuContent.allAppsGrid && rootModel) {
                            var appModel = rootModel.modelForRow(0);
                            if (appModel) {
                                menuContent.allAppsGrid.model = appModel;
                            }
                        }
                    } else {
                        if (menuContent.favoritesComponent && kicker.globalFavorites) {
                            menuContent.favoritesComponent.model = kicker.globalFavorites;
                        }
                    }
                }
            }

            searchNavigation: Parts.MenuNavigationButton {
                id: searchBackButton
                objectName: "searchBackButton"
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.rightMargin: Kirigami.Units.smallSpacing
                text: i18n("Back")
                icon.name: "go-previous"
                onClicked: {
                    powerButtons.closePopup();
                    root.returnToFavorites();
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        menuContent.runnerGrid.tryActivate(menuContent.runnerGrid.count - 1, 0);
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        searchBar.focusSearchField();
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        menuContent.sidebar.forceActiveFocus();
                    }
                }
            }

            applicationControls: Parts.SearchBar {
                id: searchBar

                menuContentRef: menuContent
                navigationButton: menuContent.navigationButton
                currentShowApps: root.showApps

                Binding {
                    target: kicker
                    property: "searchInput"
                    value: searchBar.searchField
                    restoreMode: Binding.RestoreBinding
                }

                onEscapePressed: {
                    root.toggle();
                }

                onNavigateBackwards: menuContent.focusNavigationButton()

                onNavigateToResults: {
                    menuContent.focusApplications(false);
                }
            }

            sessionControls: Item {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6.5
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.75

                // Highlight background - visible when PowerButtons has keyboard focus
                PlasmaExtras.Highlight {
                    anchors.fill: parent
                    anchors.left: parent.left
                    visible: powerButtons.activeFocus
                    hovered: true
                    pressed: false
                }

                Parts.PowerButtons {
                    id: powerButtons
                    anchors.fill: parent

                    onActionTriggered: root.toggle()
                    onScreenOffRequested: {
                        kicker.executable.exec("kscreen-doctor --dpms off");
                        root.toggle();
                    }

                    onKeyNavUp: {
                        if (menuContent && menuContent.sidebar) {
                            menuContent.sidebar.forceActiveFocus();
                        }
                    }

                    onKeyNavDown: {
                        floatingAvatar.forceActiveFocus();
                    }

                    onKeyNavLeft: {
                        menuContent.focusNavigationButton();
                    }
                }
            }
        }

        Connections {
            target: menuContent.sidebar

            function onKeyNavUp() {
                floatingAvatar.forceActiveFocus();
            }

            function onKeyNavDown() {
                powerButtons.forceActiveFocus();
            }
        }

        // Child content forwards unhandled keys to search without forwarding
        // rejected search-field events back to the field a second time.
        Keys.priority: Keys.AfterItem
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (root.searching) {
                    searchBar.clear();
                } else {
                    kicker.expanded = false;
                }
                return;
            }

            // Navigate to the current page's navigation button
            if (event.key === Qt.Key_Up) {
                event.accepted = true;
                menuContent.focusNavigationButton();
                return;
            }

            if (event.key === Qt.Key_Down) {
                event.accepted = true;
                menuContent.focusApplications(false);
                return;
            }

            // Navigate Left/Right between columns
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                // This will be handled by individual grids via keyNavLeft/keyNavRight signals
            }
        }

        Connections {
            target: kicker

            function onExpandedChanged() {
                if (!kicker.expanded) {
                    powerButtons.closePopup();
                }

                root.showApps = 0;

                menuContent.closePopups();
                if (kicker.expanded)
                    menuContent.refreshActions();
                searchBar.clear();
                if (kicker.expanded)
                    searchBar.focusSearchField();
            }
        }

        // Full representations can be created lazily after expandedChanged.
        Component.onCompleted: if (kicker.expanded) searchBar.focusSearchField()
        focus: true
    }

    Kicker.RootModel {
        id: rootModel
        autoPopulate: true
        appNameFormat: 0
        flat: true
        sorted: true
        showSeparators: true
        appletInterface: kicker
        showAllApps: true
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id);

            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favoriteApps);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }

            refresh();
        }
    }

    Connections {
        target: globalFavorites
        function onFavoritesChanged() {
            if (target) {
                Plasmoid.configuration.favoriteApps = target.favorites;
            }
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onFavoriteAppsChanged() {
            if (globalFavorites) {
                globalFavorites.favorites = Plasmoid.configuration.favoriteApps;
            }
        }
    }

    Kicker.RunnerModel {
        id: runnerModel
        // Match Kickoff: one manager and one combined, sectioned result model.
        mergeResults: true
        query: kicker.searchInput ? kicker.searchInput.text : ""
        onRequestUpdateQuery: query => {
            if (kicker.searchInput)
                kicker.searchInput.text = query;
        }
        appletInterface: kicker
        favoritesModel: globalFavorites
        runners: {
            const results = ["krunner_services", "krunner_systemsettings", "krunner_sessions", "krunner_powerdevil", "calculator", "unitconverter"];

            if (Plasmoid.configuration.useExtraRunners) {
                results.push(...Plasmoid.configuration.extraRunners);
            }
            return results;
        }
    }

    KNotification.Notification {
        id: launchFailure
        componentName: "plasma_workspace"
        eventId: "notification"
        title: i18n("Could not start the requested action")
        iconName: "dialog-error"
    }

    property P5Support.DataSource executable: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var exitCode = data["exit code"];
            var exitStatus = data["exit status"];
            var stdout = data["stdout"];
            var stderr = data["stderr"];
            if (exitCode !== 0) {
                launchFailure.text = stderr || i18n("The requested program is unavailable or could not be started.");
                launchFailure.sendEvent();
            }
            exited(sourceName, exitCode, exitStatus, stdout, stderr);
            disconnectSource(sourceName);
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd);
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner
    }

    function resetDragSource() {
        dragSource = null;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = true;
        }

        dragHelper.dropped.connect(resetDragSource);
    }
}
