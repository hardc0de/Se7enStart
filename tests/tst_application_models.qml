// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import "../contents/ui"
import "../contents/ui/parts" as Parts
import "../contents/ui/code/tools.js" as Tools

TestCase {
    id: root
    name: "ApplicationModels"
    when: windowShown
    visible: true
    width: 500
    height: 400
    function i18n(text) {
        return text;
    }
    MockApplications {
        id: pinned
    }
    MockApplications {
        id: source
        favoritesModel: pinned
    }
    ApplicationModel {
        id: proxy
        sourceModel: source
        favoritesModel: pinned
        excludeFavorites: true
        maximumCount: 10
    }
    Parts.RecentsRow {
        id: recents
        width: 300
        height: 480
        usageModel: source
        favoritesModel: pinned
    }
    Parts.FavoritesRow {
        id: favorites
        width: 300
        height: 96
        externalFavoritesModel: pinned
    }
    function entry(id, name) {
        return {
            display: name || id,
            name: name || id,
            favoriteId: id,
            url: "file:///tmp/" + id,
            decoration: "utilities-terminal",
            disabled: false,
            actionList: [
                {
                    text: "Recent file",
                    actionId: "_kicker_recentDocument",
                    actionArgument: "native"
                }
            ]
        };
    }
    function init() {
        source.clear();
        pinned.clear();
        source.activations = 0;
        pinned.activations = 0;
        pinned.append(entry("applications:app0.desktop"));
        for (let i = 0; i < 14; ++i)
            source.append(entry("app" + i + ".desktop", i === 1 ? "绘图" : undefined));
        tryCompare(proxy, "count", 10);
    }
    function test_named_roles_identity_and_native_forwarding() {
        compare(proxy.value(proxy, 0, "favoriteId"), "app1.desktop");
        compare(proxy.value(proxy, 0, "url").toString(), "file:///tmp/app1.desktop");
        compare(proxy.value(proxy, 0, "display"), "绘图");
        proxy.trigger(0, "desktop-action", {
            example: "argument"
        });
        compare(source.activations, 1);
        compare(source.lastId, "app1.desktop");
        compare(source.lastAction, "desktop-action");
        compare(source.lastArgument.example, "argument");
    }
    function test_filter_updates_after_pinning_and_reordering() {
        pinned.append(entry("applications:app1.desktop"));
        tryCompare(proxy, "count", 10);
        tryVerify(() => proxy.value(proxy, 0, "favoriteId") === "app2.desktop");
        source.move(2, 13, 1);
        tryVerify(() => proxy.value(proxy, 0, "favoriteId") === "app3.desktop");
        proxy.trigger(0, "", null);
        compare(source.lastId, "app3.desktop");
        source.clear();
        tryCompare(proxy, "count", 0);
    }
    function test_favorites_source_actions_and_persistent_drop() {
        favorites.triggerItem(0, "new-window", "native-argument");
        compare(pinned.activations, 1);
        compare(pinned.lastAction, "new-window");
        verify(favorites.dropApplication({
            favoriteId: "app5.desktop"
        }, 0));
        compare(pinned.get(0).favoriteId, "app5.desktop");
        compare(favorites.model, pinned);
        verify(favorites.dropApplication({
            favoriteId: "app5.desktop"
        }, 1));
        compare(pinned.get(1).favoriteId, "app5.desktop");
        compare(pinned.count, 2);
        pinned.removeFavorite("app5.desktop");
        compare(favorites.count, 1);
    }
    QtObject {
        id: mockDocumentMenu
        property var actionList: []
        property var visualParent: null
        property bool opened: false
        property int opens: 0
        function openRelative() {
            ++opens;
            opened = true;
        }
    }
    function test_recent_arrow_has_no_application_overlap() {
        favorites.currentIndex = 0;
        waitForRendering(favorites);
        const row = favorites.currentItem;
        row.documentMenu = mockDocumentMenu;
        mockDocumentMenu.opens = 0;
        const arrow = findChild(row, "recentFilesButton");
        compare(arrow.width, 30);
        mouseClick(arrow, 2, arrow.height / 2);
        mouseClick(arrow, arrow.width - 2, arrow.height / 2);
        compare(mockDocumentMenu.opens, 2);
        compare(pinned.activations, 0);
    }
    function test_preferred_application_is_not_pinned_twice() {
        pinned.setProperty(0, "favoriteId", "preferred://browser");
        pinned.setProperty(0, "url", "file:///tmp/app1.desktop");
        tryVerify(() => proxy.value(proxy, 0, "favoriteId") === "app0.desktop");
        verify(favorites.dropApplication({
            favoriteId: "applications:app1.desktop",
            url: "file:///tmp/app1.desktop"
        }, 0));
        compare(pinned.count, 1);
        compare(pinned.get(0).favoriteId, "preferred://browser");
    }

    function test_recent_documents_keep_arguments_and_refresh() {
        const actions = [
            {
                text: "Example",
                actionId: "_kicker_recentDocument",
                actionArgument: ["file:///tmp/a%20b.txt", "text/plain"]
            },
            {
                text: "Forget",
                actionId: "_kicker_forgetRecentDocuments"
            },
            {
                text: "Other",
                actionId: "other"
            }
        ];
        const documents = Tools.recentDocumentActions(actions);
        compare(documents.length, 2);
        compare(documents[0].actionArgument[0], "file:///tmp/a%20b.txt");
        source.setProperty(1, "actionList", actions);
        recents.currentIndex = 0;
        recents.refreshActions();
        tryVerify(() => recents.currentItem !== null);
        tryCompare(findChild(recents.currentItem, "recentFilesButton"), "width", 30);
        recents.triggerItem(0, documents[0].actionId, documents[0].actionArgument);
        compare(source.lastAction, "_kicker_recentDocument");
        compare(source.lastArgument[0], "file:///tmp/a%20b.txt");
    }
}
