// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtTest
import "../contents/ui"
import "../contents/ui/code/tools.js" as Tools

TestCase {
    id: root
    name: "ActionMenu"
    when: windowShown
    visible: true
    width: 400
    height: 300
    function i18n(text) { return text; }

    ActionMenu { id: actions; visualParent: root }
    SignalSpy { id: clicked; target: actions; signalName: "actionClicked" }
    MockApplications { id: favorites }
    QtObject { id: nativePayload; property url url: "file:///tmp/example" }
    QtObject {
        id: activityFavorites
        property bool enabled: true
        property var activities: ({activities: ["work", "play"], runningActivities: ["work"], currentActivity: "work"})
        property string lastActivity: ""
        function linkedActivitiesFor(id) { return ["play"]; }
        function activityNameForId(id) { return id === "work" ? "Work" : "Play"; }
        function addFavoriteTo(id, activity) { lastActivity = activity; }
    }
    function cleanup() {
        actions.close();
        actions.actionList = null;
        clicked.clear();
        favorites.clear();
    }
    function test_native_items_and_nested_submenus() {
        const payload = {url: "file:///tmp/recent-document", marker: 42};
        actions.actionList = [
            {text: "Application", type: "title"},
            {text: "New Window", icon: "window-new", actionId: "new-window", actionArgument: payload},
            {type: "separator"},
            {text: "Activities", subActions: [
                {text: "All Activities", checkable: true, checked: true, actionId: "all"},
                {text: "More", subActions: [{text: "Other Activity", actionId: "other"}]}
            ]},
            {text: "Unavailable", enabled: false, actionId: "disabled"}
        ];
        compare(actions.menu.content.length, 5);
        verify(actions.menu.content[0].section);
        verify(!actions.menu.content[0].enabled);
        verify(actions.menu.content[2].separator);
        verify(!actions.menu.content[4].enabled);
        const submenu = actions.menu.content[3].subMenu;
        verify(submenu !== null);
        compare(submenu.content.length, 2);
        verify(submenu.content[0].checkable);
        verify(submenu.content[0].checked);
        compare(submenu.content[1].subMenu.content.length, 1);
        actions.menu.content[1].action.trigger();
        compare(clicked.count, 1);
        compare(clicked.signalArguments[0][0], "new-window");
        compare(clicked.signalArguments[0][1], payload);
        submenu.content[1].subMenu.content[0].action.trigger();
        compare(clicked.count, 2);
        compare(clicked.signalArguments[1][0], "other");
        actions.actionList = [{text: "Replacement", actionId: "replacement"}];
        compare(actions.menu.content.length, 1);
        compare(actions.menu.content[0].text, "Replacement");
    }
    function test_favorite_action_order_and_native_payload() {
        const payload = {native: "payload"};
        Tools.fillActionMenu(i18n, actions, [
            {text: "New Window", actionId: "new-window", actionArgument: payload},
            {type: "separator"},
            {text: "Add to Desktop", actionId: "addToDesktop"},
            {text: "Edit Application", actionId: "editApplication"}
        ], favorites, "example.desktop");
        compare(actions.menu.content.length, 5);
        compare(actions.menu.content[2].modelData.actionId, "_kicker_favorite_add");
        compare(actions.menu.content[3].modelData.actionId, "addToDesktop");
        actions.menu.content[0].action.trigger();
        compare(clicked.signalArguments[0][1], payload);
        const favorite = actions.menu.content[2].modelData;
        verify(!Tools.triggerAction(null, -1, favorite.actionId, favorite.actionArgument));
        verify(favorites.isFavorite("example.desktop"));
        Tools.fillActionMenu(i18n, actions, [], favorites, "example.desktop");
        compare(actions.menu.content.length, 1);
        compare(actions.menu.content[0].modelData.actionId, "_kicker_favorite_remove");
    }
    function test_activity_submenu_includes_stopped_activities() {
        Tools.fillActionMenu(i18n, actions, [], activityFavorites, "example.desktop");
        compare(actions.menu.content.length, 1);
        const submenu = actions.menu.content[0].subMenu;
        verify(submenu !== null);
        compare(submenu.content.length, 5);
        compare(submenu.content[3].text, "Work");
        compare(submenu.content[4].text, "Play");
        verify(submenu.content[4].checked);
        const current = submenu.content[1].modelData;
        Tools.triggerAction(null, -1, current.actionId, current.actionArgument);
        compare(activityFavorites.lastActivity, "work");
    }
    function test_qobject_action_argument_is_preserved() {
        actions.actionList = [{text: "Opaque argument", actionId: "opaque", actionArgument: nativePayload}];
        actions.menu.content[0].action.trigger();
        compare(clicked.count, 1);
        compare(clicked.signalArguments[0][1], nativePayload);
    }

}
