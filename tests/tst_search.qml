// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtTest
import org.kde.plasma.components as PC3
import "../contents/ui"
import "../contents/ui/parts" as Parts

TestCase {
    id: root
    name: "SearchKeyboard"
    when: windowShown
    width: 500
    height: 400
    visible: true

    property int closedCount: 0
    property string lastActivated: ""
    property var savedMatches: []
    function i18n(text) {
        return text;
    }
    function toggle() {
        ++closedCount;
    }

    // Supply the applet context used by the real result delegates.
    QtObject {
        id: highlightItemSvg
        property var margins: ({
                top: 0
            })
    }
    Item {
        id: toolTipDelegate
    }
    QtObject {
        id: kicker
        property bool expanded: true
    }
    QtObject {
        id: dragHelper
        property bool dragging: false
    }

    ListModel {
        id: matches
        function trigger(index, action, argument) {
            root.lastActivated = get(index).display;
            return true;
        }
        ListElement {
            display: "Terminal One"
            name: "Terminal One"
            group: "Applications"
            decoration: "utilities-terminal"
            disabled: false
            favoriteId: "one.desktop"
        }
        ListElement {
            display: "Terminal Two"
            name: "Terminal Two"
            group: "Applications"
            decoration: "utilities-terminal"
            disabled: false
            favoriteId: "two.desktop"
        }
        ListElement {
            display: "Terminal Three"
            name: "Terminal Three"
            group: "Applications"
            decoration: "utilities-terminal"
            disabled: false
            favoriteId: "three.desktop"
        }
        ListElement {
            display: "Terminal Notes"
            name: "Terminal Notes"
            group: "Files"
            decoration: "text-plain"
            disabled: false
            favoriteId: "notes"
        }
        ListElement {
            display: "Terminal Guide"
            name: "Terminal Guide"
            group: "Files"
            decoration: "text-plain"
            disabled: false
            favoriteId: "guide"
        }
    }
    ListModel {
        id: runnerModel
        // Match Kickoff's direct binding to the search text and merged result model.
        property string query: searchBar.text
        function modelForRow(row) {
            return row === 0 ? matches : null;
        }
        ListElement {
            display: "Search results"
        }
    }
    SignalSpy {
        id: queryChanges
        target: runnerModel
        signalName: "queryChanged"
    }

    // Forward from a sibling of search, matching the real menu's content area.
    Item {
        width: 300
        height: 240
        Keys.priority: Keys.AfterItem
        Keys.forwardTo: [searchBar.searchField]
        Item {
            id: neutralFocus
            focus: true
        }
        SearchResultsView {
            id: results
            onCloseRequested: root.toggle()
            width: 300
            height: 240
            model: runnerModel
            onKeyNavUp: searchBar.focusSearchField()
            onKeyNavDown: searchBar.focusSearchField()
        }
    }
    Parts.SearchBar {
        id: searchBar
        y: 280
        width: 300
        height: 45
        menuContentRef: QtObject {
            property var runnerGrid: results
        }
        onEscapePressed: root.toggle()
        onNavigateToResults: results.tryActivate(0, 0)
    }
    function typeText(text) {
        for (const character of text)
            keyClick(character);
    }

    function initTestCase() {
        for (let i = 0; i < matches.count; ++i)
            savedMatches.push(Object.assign({}, matches.get(i)));
    }

    function init() {
        searchBar.clear();
        lastActivated = "";
        closedCount = 0;
        results.resetSelection();
        neutralFocus.forceActiveFocus();
        wait(20);
        queryChanges.clear();
    }

    function cleanup() {
        matches.clear();
        for (const item of savedMatches)
            matches.append(item);
    }

    function test_typing_without_search_focus() {
        verify(!searchBar.searchField.activeFocus);
        typeText("terminal");
        compare(searchBar.text, "terminal");
        compare(runnerModel.query, "terminal");
        verify(searchBar.searchField.activeFocus);
    }

    function test_query_binding_has_no_added_delay() {
        keyClick("t");
        compare(runnerModel.query, "t");
        keyClick("e");
        compare(runnerModel.query, "te");
        compare(queryChanges.count, 2);
        compare(results.view.model, matches);
    }

    function test_select_all_and_replace() {
        typeText("terminal");
        keyClick(Qt.Key_A, Qt.ControlModifier);
        compare(searchBar.text, "terminal");
        compare(searchBar.searchField.selectedText, "terminal");
        typeText("console");
        compare(searchBar.text, "console");
    }

    function test_edit_at_cursor() {
        typeText("termnal");
        keyClick(Qt.Key_Home);
        for (let i = 0; i < 4; ++i)
            keyClick(Qt.Key_Right);
        typeText("i");
        compare(searchBar.text, "terminal");
        keyClick(Qt.Key_Backspace);
        compare(searchBar.text, "termnal");
    }

    function test_navigation_and_typing_from_results() {
        typeText("terminal");
        compare(results.currentIndex, 0);
        keyClick(Qt.Key_Down);
        compare(results.currentIndex, 1);
        verify(results.activeFocus);
        keyClick(Qt.Key_Down);
        compare(results.currentIndex, 2);
        keyClick(Qt.Key_Down);
        compare(results.currentIndex, 3);
        compare(matches.get(results.currentIndex).group, "Files");
        keyClick(Qt.Key_Up);
        compare(results.currentIndex, 2);
        typeText("s");
        compare(searchBar.text, "terminals");
        verify(searchBar.searchField.activeFocus);
    }

    function test_enter_uses_selected_match() {
        typeText("terminal");
        keyClick(Qt.Key_Down);
        keyClick(Qt.Key_Return);
        compare(lastActivated, "Terminal Two");
        compare(closedCount, 1);
    }

    function test_enter_from_search_field() {
        typeText("terminal");
        keyClick(Qt.Key_Return);
        compare(lastActivated, "Terminal One");
        compare(closedCount, 1);
    }

    function test_escape_clears_then_closes() {
        typeText("terminal");
        keyClick(Qt.Key_Escape);
        compare(searchBar.text, "");
        compare(closedCount, 0);
        compare(runnerModel.query, "");
        keyClick(Qt.Key_Escape);
        compare(closedCount, 1);
    }

    function test_results_arriving_after_typing() {
        matches.clear();
        typeText("terminal");
        keyClick(Qt.Key_Down);
        verify(searchBar.searchField.activeFocus);
        matches.append(savedMatches[0]);
        matches.append(savedMatches[1]);
        tryCompare(results, "currentIndex", 0);
        verify(searchBar.searchField.activeFocus);
        keyClick(Qt.Key_Down);
        compare(results.currentIndex, 1);
    }

    function test_late_results_preserve_navigation() {
        typeText("terminal");
        keyClick(Qt.Key_Down);
        matches.append(savedMatches[4]);
        wait(20);
        compare(results.currentIndex, 1);
    }

    function test_long_results_scroll_into_view() {
        for (let i = 0; i < 15; ++i)
            matches.append(savedMatches[4]);
        typeText("terminal");
        for (let i = 0; i < matches.count - 1; ++i)
            keyClick(Qt.Key_Down);
        compare(results.currentIndex, matches.count - 1);
        tryVerify(() => {
            const position = results.currentItem.mapToItem(results.view, 0, 0);
            return position.y >= -1 && position.y + results.currentItem.height <= results.view.height + 1;
        });
    }

    function test_only_visible_results_create_delegates() {
        for (let i = 0; i < 1000; ++i)
            matches.append(savedMatches[4]);
        typeText("terminal");
        waitForRendering(results);
        compare(results.count, 1005);
        verify(results.view.contentItem.children.length < 100, "A long result list should instantiate only delegates around the viewport");
    }

    function test_mouse_launches_selected_match() {
        typeText("terminal");
        waitForRendering(results);
        const firstItem = results.currentItem;
        mouseClick(firstItem, 60, firstItem.height / 2);
        compare(lastActivated, "Terminal One");
        compare(closedCount, 1);
    }

    function test_scrollbar_only_appears_for_overflow() {
        typeText("terminal");
        const scrollbar = results.PC3.ScrollBar.vertical;
        tryVerify(() => results.view.contentHeight <= results.view.height);
        tryCompare(scrollbar, "visible", false);
        for (let i = 0; i < 20; ++i)
            matches.append(savedMatches[0]);
        tryVerify(() => results.view.contentHeight > results.view.height);
        tryCompare(scrollbar, "visible", true);
        matches.clear();
        matches.append(savedMatches[0]);
        tryVerify(() => results.view.contentHeight <= results.view.height);
        tryCompare(scrollbar, "visible", false);
    }
}
