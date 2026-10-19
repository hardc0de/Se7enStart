// SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.plasma.private.kicker as Kicker
import ".."

FavoritesGridView {
    id: recents
    property var usageModel: nativeUsage
    model: filteredApps
    Kicker.RecentUsageModel {
        id: nativeUsage
        ordering: Kicker.RecentUsageModel.Popular
        shownItems: Kicker.RecentUsageModel.OnlyApps
    }
    ApplicationModel {
        id: filteredApps
        sourceModel: recents.usageModel
        favoritesModel: recents.favoritesModel
        excludeFavorites: true
        maximumCount: 10
    }
}
