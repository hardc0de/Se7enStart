// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kitemmodels as KItemModels
import "code/tools.js" as Tools

// Keep native roles and QVariant action arguments intact. Only filter/map rows.
KItemModels.KSortFilterProxyModel {
    id: proxy
    property var favoritesModel: null
    property bool excludeFavorites: false
    property int maximumCount: -1

    function value(source, row, name) {
        if (!source || row < 0)
            return undefined;
        const role = source.KItemModels.KRoleNames.role(name);
        return role < 0 ? undefined : source.data(source.index(row, 0), role);
    }
    function isPinned(row) {
        if (!excludeFavorites || !favoritesModel)
            return false;
        const id = Tools.canonicalAppId(value(sourceModel, row, "favoriteId"));
        const url = Tools.canonicalAppId(value(sourceModel, row, "url"));
        for (let i = 0; i < favoritesModel.count; ++i) {
            const pinnedId = Tools.canonicalAppId(value(favoritesModel, i, "favoriteId"));
            const pinnedUrl = Tools.canonicalAppId(value(favoritesModel, i, "url"));
            if ((id && (id === pinnedId || id === pinnedUrl)) || (url && (url === pinnedId || url === pinnedUrl)))
                return true;
        }
        return false;
    }
    filterRowCallback: row => {
        if (isPinned(row))
            return false;
        if (maximumCount < 0)
            return true;
        let rank = 0;
        for (let i = 0; i <= row; ++i)
            if (!isPinned(i))
                ++rank;
        return rank <= maximumCount;
    }
    function trigger(row, actionId, argument) {
        if (!sourceModel || row < 0 || row >= count)
            return false;
        const source = mapToSource(index(row, 0));
        return sourceModel.trigger(source.row, actionId, argument);
    }
    function refresh() {
        invalidateFilter();
    }
    onFavoritesModelChanged: Qt.callLater(refresh)
    onExcludeFavoritesChanged: Qt.callLater(refresh)
    onMaximumCountChanged: Qt.callLater(refresh)
    readonly property Connections favoritesWatcher: Connections {
        target: proxy.favoritesModel
        ignoreUnknownSignals: true
        function onCountChanged() {
            Qt.callLater(proxy.refresh);
        }
        function onDataChanged() {
            Qt.callLater(proxy.refresh);
        }
        function onRowsMoved() {
            Qt.callLater(proxy.refresh);
        }
        function onModelReset() {
            Qt.callLater(proxy.refresh);
        }
        function onLayoutChanged() {
            Qt.callLater(proxy.refresh);
        }
        function onFavoritesChanged() {
            Qt.callLater(proxy.refresh);
        }
    }
    readonly property Connections sourceWatcher: Connections {
        target: proxy.sourceModel
        ignoreUnknownSignals: true
        function onRowsInserted() {
            Qt.callLater(proxy.refresh);
        }
        function onRowsRemoved() {
            Qt.callLater(proxy.refresh);
        }
        function onRowsMoved() {
            Qt.callLater(proxy.refresh);
        }
        function onDataChanged() {
            Qt.callLater(proxy.refresh);
        }
        function onModelReset() {
            Qt.callLater(proxy.refresh);
        }
        function onLayoutChanged() {
            Qt.callLater(proxy.refresh);
        }
    }
}
