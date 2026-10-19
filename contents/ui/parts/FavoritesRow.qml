// SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import ".."

FavoritesGridView {
    id: favorites
    property var externalFavoritesModel: null
    model: externalFavoritesModel
    favoritesModel: externalFavoritesModel
    dropEnabled: true
}
