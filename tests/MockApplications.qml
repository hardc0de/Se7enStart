// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../contents/ui/code/tools.js" as Tools

ListModel {
    id: source
    dynamicRoles: true
    property bool enabled: true
    property int maxFavorites: -1
    property int activations: 0
    property string lastId: ""
    property string lastAction: ""
    property var lastArgument: null
    property var favoritesModel: null
    function trigger(row, action, argument) {
        ++activations;
        lastId = get(row).favoriteId;
        lastAction = action;
        lastArgument = argument;
        return action !== "_kicker_forgetRecentDocuments";
    }
    function isFavorite(id) {
        for (let i = 0; i < count; ++i)
            if (Tools.canonicalAppId(get(i).favoriteId) === Tools.canonicalAppId(id))
                return true;
        return false;
    }
    function addFavorite(id, destination) {
        insert(destination === undefined ? count : destination, {
            display: id,
            name: id,
            decoration: "utilities-terminal",
            favoriteId: id,
            url: "file:///tmp/" + id,
            disabled: false
        });
    }
    function removeFavorite(id) {
        for (let i = count - 1; i >= 0; --i)
            if (Tools.canonicalAppId(get(i).favoriteId) === Tools.canonicalAppId(id))
                remove(i);
    }
    function moveRow(from, to) {
        move(from, to, 1);
    }
}
