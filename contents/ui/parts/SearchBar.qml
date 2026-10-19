/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

/**
 * Search bar component for the Windows 7 Start Menu
 * Provides text input for searching applications and files
 */
FocusScope {
    id: searchBar

    // Layout properties
    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
    Layout.minimumHeight: Kirigami.Units.gridUnit * 2.5
    Layout.maximumHeight: Kirigami.Units.gridUnit * 2.5

    // Properties
    property alias text: searchField.text
    property alias searchField: searchField
    property bool isSearching: text !== ""
    property var menuContentRef: null
    property Item navigationButton: null
    property int currentShowApps: 0
    signal navigateBackwards

    // Signals
    signal escapePressed
    signal navigateToResults

    // Public functions
    function clear() {
        searchField.clear();
    }

    function focusSearchField() {
        searchField.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    // Search field
    PlasmaExtras.SearchField {
        id: searchField
        focus: true

        height: Kirigami.Units.gridUnit * 1.8

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Kirigami.Units.smallSpacing * 2
            rightMargin: Kirigami.Units.smallSpacing
            verticalCenter: parent.verticalCenter
        }

        placeholderText: i18n("Type here to search…")

        onTextEdited: forceActiveFocus(Qt.ShortcutFocusReason)

        // As in Kickoff, native text editing gets the first chance to handle keys.
        Keys.priority: Keys.AfterItem
        Keys.forwardTo: searchBar.isSearching && searchBar.menuContentRef ? [searchBar.menuContentRef.runnerGrid] : []

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (searchBar.isSearching) {
                    clear();
                } else {
                    searchBar.escapePressed();
                }
            } else if (event.key === Qt.Key_Up) {
                if (searchBar.isSearching)
                    return;
                event.accepted = true;
                if (searchBar.menuContentRef && searchBar.menuContentRef.focusApplications)
                    searchBar.menuContentRef.focusApplications(true);
            } else if (event.key === Qt.Key_Down) {
                if (searchBar.isSearching)
                    return;
                event.accepted = true;
                // Go to All Apps button
                if (searchBar.navigationButton) {
                    searchBar.navigationButton.forceActiveFocus(Qt.TabFocusReason);
                } else {
                    // Fallback to navigate to results
                    searchBar.navigateToResults();
                }
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                event.accepted = true;
                if (event.key === Qt.Key_Backtab || event.modifiers & Qt.ShiftModifier)
                    searchBar.navigateBackwards();
                else
                    searchBar.navigateToResults();
            }
        }
    }
}
