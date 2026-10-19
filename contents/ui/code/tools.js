/*
    SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
    SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
    SPDX-FileCopyrightText: 2013-2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2017 Ivan Cukic <ivan.cukic@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

.pragma library

function fillActionMenu(i18n, actionMenu, actionList, favoriteModel, favoriteId) {
    // Match Kickoff's AbstractKickoffItemDelegate: favorite actions belong with
    // the native Add to Desktop/Panel/Task Manager actions. Keep QVariant payloads.
    let actions = actionArray(actionList);
    const favorites = createFavoriteActions(i18n, favoriteModel, favoriteId);
    if (favorites) {
        const addToIndex = actions.findIndex(action =>
            ["addToDesktop", "addToTaskManager", "addToPanel"].includes(action.actionId));
        if (addToIndex >= 0)
            actions.splice(addToIndex, 0, ...favorites);
        else if (actions.length)
            actions.push({ type: "separator" }, ...favorites);
        else
            actions = favorites;
    }
    actionMenu.actionList = actions;
}

function createFavoriteActions(i18n, favoriteModel, favoriteId) {
    if (!favoriteModel || !favoriteModel.enabled || !favoriteId) {
        return null;
    }


    if (favoriteModel.activities === undefined ||
        favoriteModel.activities.activities.length <= 1) {
        var action = {};

        if (favoriteModel.isFavorite(favoriteId)) {
            action.text = i18n("Remove from Favorites");
            action.icon = "bookmark-remove";
            action.actionId = "_kicker_favorite_remove";
        } else if (favoriteModel.maxFavorites === -1 || favoriteModel.count < favoriteModel.maxFavorites) {
            action.text = i18n("Add to Favorites");
            action.icon = "bookmark-new";
            action.actionId = "_kicker_favorite_add";
        } else {
            return null;
        }

        action.actionArgument = { favoriteModel: favoriteModel, favoriteId: favoriteId };

        return [action];

    } else {
        var actions = [];

        var linkedActivities = favoriteModel.linkedActivitiesFor(favoriteId);

        var activities = favoriteModel.activities.activities;

        // Adding the item to link/unlink to all activities

        var linkedToAllActivities =
            !(linkedActivities.indexOf(":global") === -1);

        actions.push({
            text      : i18n("On All Activities"),
            checkable : true,

            actionId  : linkedToAllActivities ?
                             "_kicker_favorite_remove_from_activity" :
                             "_kicker_favorite_set_to_activity",
            checked   : linkedToAllActivities,

            actionArgument : {
                favoriteModel: favoriteModel,
                favoriteId: favoriteId,
                favoriteActivity: ""
            }
        });


        // Adding items for each activity separately

        var addActivityItem = function(activityId, activityName) {
            var linkedToThisActivity =
                !(linkedActivities.indexOf(activityId) === -1);

            actions.push({
                text      : activityName,
                checkable : true,
                checked   : linkedToThisActivity && !linkedToAllActivities,

                actionId :
                    // If we are on all activities, and the user clicks just one
                    // specific activity, unlink from everything else
                    linkedToAllActivities ? "_kicker_favorite_set_to_activity" :

                    // If we are linked to the current activity, just unlink from
                    // that single one
                    linkedToThisActivity ? "_kicker_favorite_remove_from_activity" :

                    // Otherwise, link to this activity, but do not unlink from
                    // other ones
                    "_kicker_favorite_add_to_activity",

                actionArgument : {
                    favoriteModel    : favoriteModel,
                    favoriteId       : favoriteId,
                    favoriteActivity : activityId
                }
            });
        };

        // Adding the item to link/unlink to the current activity

        addActivityItem(favoriteModel.activities.currentActivity, i18n("On the Current Activity"));

        actions.push({
            type: "separator",
            actionId: "_kicker_favorite_separator"
        });

        // Adding the items for each activity

        activities.forEach(function(activityId) {
            addActivityItem(activityId, favoriteModel.activityNameForId(activityId));
        });

        return [{
            text       : i18n("Show in Favorites"),
            icon       : "favorite",
            subActions : actions
        }];
    }
}

function triggerAction(model, index, actionId, actionArgument) {
    function startsWith(txt, needle) {
        return txt.substr(0, needle.length) === needle;
    }

    if (startsWith(actionId, "_kicker_favorite_")) {
        handleFavoriteAction(actionId, actionArgument);
        return false; // Pinning changes the model without closing the launcher.
    }

    // Check if model has trigger function before calling it
    if (model && typeof model.trigger === "function") {
        var closeRequested = model.trigger(index, actionId, actionArgument);

        if (closeRequested) {
            return true;
        }
    }

    return false;
}

function handleFavoriteAction(actionId, actionArgument) {
    if (!actionArgument || !actionArgument.favoriteModel || !actionArgument.favoriteId) return;
    var favoriteId = actionArgument.favoriteId;
    var favoriteModel = actionArgument.favoriteModel;

    if (favoriteModel === null || favoriteId === null) {
        return null;
    }

    if (actionId === "_kicker_favorite_remove") {
        favoriteModel.removeFavorite(favoriteId);
    } else if (actionId === "_kicker_favorite_add") {
        favoriteModel.addFavorite(favoriteId);
    } else if (actionId === "_kicker_favorite_remove_from_activity") {
        favoriteModel.removeFavoriteFrom(favoriteId, actionArgument.favoriteActivity);
    } else if (actionId === "_kicker_favorite_add_to_activity") {
        favoriteModel.addFavoriteTo(favoriteId, actionArgument.favoriteActivity);
    } else if (actionId === "_kicker_favorite_set_to_activity") {
        favoriteModel.setFavoriteOn(favoriteId, actionArgument.favoriteActivity);
    }
}

// Native KDE actions retain opaque QVariant arguments; never copy them to ListModel.
function recentDocumentActions(actions) {
    return actionArray(actions).filter(action => action.actionId === "_kicker_recentDocument" || action.actionId === "_kicker_forgetRecentDocuments");
}
function canonicalAppId(value) {
    if (!value) return "";
    let id = String(value);
    if (id.startsWith("applications:")) id = id.slice("applications:".length);
    if (id.startsWith("file:")) id = id.slice(id.lastIndexOf("/") + 1);
    try { return decodeURIComponent(id); } catch (e) { return id; }
}

function actionArray(actions) {
    if (!actions) return [];
    if (actions.length !== undefined) return Array.from(actions);
    const result = [];
    if (actions.count !== undefined && actions.get) for (let i = 0; i < actions.count; ++i) result.push(Object.assign({}, actions.get(i)));
    return result;
}
