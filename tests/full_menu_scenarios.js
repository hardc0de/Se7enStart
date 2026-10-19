// Included inside the generated QtTest TestCase by generate_menu_harness.py.
function typeText(text) { for (const character of text) keyClick(character); }
function applicationActions() { return [{text: "New Window", actionId: "new-window", actionArgument: {marker: 17}}]; }
function app(id, text) { return {favoriteId: id, display: text, name: text, decoration: "utilities-terminal", url: "file:///tmp/" + id, group: "Applications", disabled: false, actionList: applicationActions()}; }
function initTestCase() {
    pinned.append(app("applications:pinned.desktop", "Pinned App"));
    for (let i = 0; i < 15; ++i) applications.append(app("app" + i + ".desktop", "Application " + i));
    for (const id of ["shutdown", "reboot", "lock-screen", "suspend", "hibernate", "logout"]) systemActions.append(app(id, id));
    menuContent.recentsGrid.usageModel = applications;
}
function init() {
    root.width = 500; root.height = 740;
    kicker.expanded = true;
    root.showApps = 0;
    searchBar.clear();
    powerButtons.closePopup();
    menuContent.closePopups();
    // Other scenarios remove/reinsert rows and replace nested ListModels.
    // Restore action fixtures rather than retaining QQmlListModel get() objects.
    for (const model of [pinned, applications])
        for (let i = 0; i < model.count; ++i)
            model.setProperty(i, "actionList", applicationActions());
    applications.activations = 0; pinned.activations = 0; systemActions.activations = 0;
    menuContent.favoritesGrid.tryActivate(0, 0);
    waitForRendering(root);
}
function cleanup() {
    powerButtons.closePopup();
    menuContent.closePopups();
    // Native QMenus own a separate window, even with Qt's offscreen platform.
    testCase.Window.window.requestActivate();
    tryCompare(testCase.Window.window, "active", true);
}
function applicationsScrollView() {
    let scroll = menuContent.favoritesGrid.parent;
    while (scroll && !(scroll.availableWidth !== undefined && scroll.contentItem)) scroll = scroll.parent;
    return scroll;
}
function shortcutsScrollView() {
    for (const child of menuContent.sidebar.children)
        if (child.availableWidth !== undefined && child.contentItem) return child;
    return null;
}
function verifyNormalColumnsFit() {
    root.height = root.Layout.minimumHeight;
    waitForRendering(root);
    for (const scroll of [applicationsScrollView(), shortcutsScrollView()]) {
        verify(scroll !== null);
        verify(scroll.contentItem.contentHeight <= scroll.availableHeight + 1,
            "Normal menu contents must fit at the advertised minimum height");
        compare(scroll.contentItem.contentY, 0);
    }
    compare(root.Layout.preferredHeight, root.Layout.minimumHeight);
}
function test_minimum_height_fits_both_columns() {
    verifyNormalColumnsFit();
}
function test_minimum_height_grows_with_favorites_even_on_other_pages() {
    const originalCount = pinned.count;
    const originalMinimum = root.Layout.minimumHeight;
    try {
        root.showApps = 1;
        for (let i = 0; i < 6; ++i) pinned.append(app("extra" + i + ".desktop", "Extra favorite " + i));
        tryCompare(menuContent.favoritesGrid, "count", originalCount + 6);
        tryVerify(() => root.Layout.minimumHeight > originalMinimum);
        const grownMinimum = root.Layout.minimumHeight;
        searchBar.text = "terminal";
        waitForRendering(root);
        compare(root.Layout.minimumHeight, grownMinimum);
        root.returnToFavorites();
        waitForRendering(root);
        compare(root.Layout.minimumHeight, grownMinimum);
        verifyNormalColumnsFit();
    } finally {
        root.returnToFavorites();
        pinned.remove(originalCount, pinned.count - originalCount);
    }
    tryCompare(root.Layout, "minimumHeight", originalMinimum);
}
function test_minimum_height_tracks_recent_rows() {
    const originalCount = pinned.count;
    try {
        // Make the left column determine the minimum with and without recents.
        for (let i = 0; i < 14; ++i) pinned.append(app("extra" + i + ".desktop", "Extra favorite " + i));
        waitForRendering(root);
        const withRecents = root.Layout.minimumHeight;
        const recentHeight = menuContent.recentsGrid.count * menuContent.recentsGrid.cellHeight;
        verify(recentHeight > 0);
        menuContent.recentsGrid.usageModel = null;
        tryCompare(menuContent.recentsGrid, "count", 0);
        tryCompare(root.Layout, "minimumHeight", withRecents - recentHeight);
        verifyNormalColumnsFit();
    } finally {
        menuContent.recentsGrid.usageModel = applications;
        pinned.remove(originalCount, pinned.count - originalCount);
    }
}
function test_typing_and_selection() {
    typeText("terminal");
    compare(searchBar.text, "terminal");
    compare(runnerModel.query, "terminal");
    keyClick(Qt.Key_A, Qt.ControlModifier);
    compare(searchBar.searchField.selectedText, "terminal");
    typeText("console");
    compare(searchBar.text, "console");
}
function test_search_navigation_and_single_activation() {
    typeText("terminal");
    keyClick(Qt.Key_Down);
    compare(menuContent.runnerGrid.currentIndex, 1);
    keyClick(Qt.Key_Return);
    compare(applications.activations, 1);
    compare(applications.lastId, "app1.desktop");
    compare(kicker.expanded, false);
}
function test_power_popup_keyboard_escape_and_native_dispatch() {
    powerButtons.forceActiveFocus();
    keyClick(Qt.Key_Right);
    tryCompare(powerButtons, "popupVisible", true);
    verify(!powerButtons.activeFocus);
    keyClick(Qt.Key_Escape);
    tryCompare(powerButtons, "popupVisible", false);
    verify(kicker.expanded);
    powerButtons.openPopup();
    keyClick(Qt.Key_Return);
    compare(systemActions.activations, 1);
    compare(systemActions.lastId, "reboot");
    compare(kicker.expanded, false);
    compare(mockExecutor.commands.length, 0);
}
function test_power_capabilities_disable_unsupported_actions() {
    systemActions.setProperty(4, "disabled", true);
    verify(!powerButtons.available("hibernate"));
    powerButtons.trigger("hibernate");
    compare(systemActions.activations, 0);
    systemActions.setProperty(4, "disabled", false);
}
function test_navigation_dismisses_power_data() {
    const rows = [];
    for (const page of ["all", "favorites", "back"]) for (const method of ["mouse", "return", "space"]) rows.push({tag: page + method, page: page, method: method});
    return rows;
}
function test_navigation_dismisses_power(data) {
    if (data.page === "favorites") root.showApps = 1;
    if (data.page === "back") typeText("terminal");
    powerButtons.openPopup();
    tryCompare(powerButtons, "popupVisible", true);
    const button = data.page === "back" ? searchBackButton : allAppsButton;
    // A pointer outside the popup dismisses it before activating the button.
    if (data.method === "mouse") mouseClick(button, 60, button.height / 2);
    else {
        button.forceActiveFocus();
        keyClick(data.method === "return" ? Qt.Key_Return : Qt.Key_Space);
    }
    tryCompare(powerButtons, "popupVisible", false);
    compare(root.showApps, data.page === "all" ? 1 : 0);
    verify(kicker.expanded);
    if (data.page === "back") compare(searchBar.text, "");
}
function test_applet_close_resets_all_popups() {
    powerButtons.openPopup();
    tryCompare(powerButtons, "popupVisible", true);
    kicker.expanded = false;
    tryCompare(powerButtons, "popupVisible", false);
    kicker.expanded = true;
    verify(!powerButtons.popupVisible);
}
function test_all_apps_uses_search_back_label_and_icon() {
    root.showApps = 1;
    compare(allAppsButton.text, searchBackButton.text);
    compare(allAppsButton.text, "Back");
    compare(allAppsButton.icon.name, searchBackButton.icon.name);
    compare(allAppsButton.icon.name, "go-previous");
}
function test_all_apps_resets_position_data() {
    return ["button", "left", "search", "close"].map(method => ({tag: method, method: method}));
}
function test_all_apps_resets_position(data) {
    const originalCount = applications.count;
    try {
        for (let i = originalCount; i < 70; ++i) applications.append(app("app" + i + ".desktop", "Application " + i));
        root.showApps = 1;
        const grid = menuContent.allAppsGrid;
        tryCompare(grid, "count", 70);
        grid.tryActivate(grid.count - 1, 0);
        tryVerify(() => grid.view.contentY > grid.view.originY);
        if (data.method === "button") mouseClick(allAppsButton, 60, allAppsButton.height / 2);
        else if (data.method === "left") keyClick(Qt.Key_Left);
        else if (data.method === "search") typeText("terminal");
        else kicker.expanded = false;
        tryCompare(grid, "visible", false);
        compare(grid.currentIndex, -1);
        kicker.expanded = true;
        searchBar.clear();
        root.showApps = 0;
        mouseClick(allAppsButton, 60, allAppsButton.height / 2);
        tryCompare(grid, "visible", true);
        tryVerify(() => Math.abs(grid.view.contentY - grid.view.originY) < 1);
        verify(grid.view.itemAtIndex(0) !== null);
    } finally {
        root.showApps = 0;
        searchBar.clear();
        kicker.expanded = true;
        applications.remove(originalCount, applications.count - originalCount);
    }
}
function test_focus_stays_in_visible_page() {
    root.showApps = 1;
    searchBar.focusSearchField();
    keyClick(Qt.Key_Up);
    verify(menuContent.allAppsGrid.activeFocus);
    verify(!menuContent.recentsGrid.activeFocus);
    typeText("terminal");
    menuContent.sidebar.forceActiveFocus();
    keyClick(Qt.Key_Left);
    verify(menuContent.runnerGrid.activeFocus);
    searchBar.focusSearchField();
    keyClick(Qt.Key_Backtab);
    verify(searchBackButton.activeFocus);
}
function test_sidebar_fits_and_scrolls() {
    root.height = 648;
    waitForRendering(root);
    menuContent.sidebar.forceActiveFocus();
    for (let i = 0; i < 12; ++i) keyClick(Qt.Key_Down);
    waitForRendering(root);
    let scroll = null;
    for (const child of menuContent.sidebar.children) if (child.availableWidth !== undefined && child.contentItem) scroll = child;
    verify(scroll !== null);
    const shortcuts = [];
    function collect(item) {
        if (item.hasDropdown !== undefined && item.activeFocusOnTab) shortcuts.push(item);
        for (const child of item.children || []) collect(child);
    }
    collect(menuContent.sidebar);
    compare(shortcuts.length, 13);
    const last = shortcuts[12];
    verify(last.activeFocus);
    compare(last.width, scroll.availableWidth);
    const position = last.mapToItem(scroll.contentItem, 0, 0);
    verify(position.y >= -1 && position.y + last.height <= scroll.contentItem.height + 1);
}
function test_long_labels_and_canceled_click() {
    applications.setProperty(0, "name", "A very long application title that exceeds the full width of a normal result row");
    typeText("terminal");
    waitForRendering(root);
    const row = menuContent.runnerGrid.currentItem;
    const label = findChild(row, "applicationLabel");
    verify(label.width < row.width);
    verify(label.truncated);
    mousePress(row, 60, row.height / 2);
    mouseRelease(testCase, testCase.width - 1, testCase.height - 1);
    compare(applications.activations, 0);
    applications.setProperty(0, "name", "Application 0");
}
function test_blank_all_apps_right_click_is_ignored() {
    root.showApps = 1;
    menuContent.allAppsGrid.view.positionViewAtEnd();
    // Fifteen rows leave space below the list in the normal-height menu.
    mouseClick(menuContent.allAppsGrid, 60, menuContent.allAppsGrid.height - 10, Qt.RightButton);
    compare(applications.activations, 0);
    verify(kicker.expanded);
}

function test_empty_sections_have_visible_focus_fallback() {
    const saved = pinned.get(0);
    const favorite = { favoriteId: saved.favoriteId, name: saved.name, display: saved.display, decoration: saved.decoration, url: saved.url, disabled: false };
    pinned.clear();
    menuContent.recentsGrid.usageModel = null;
    waitForRendering(root);
    searchBar.focusSearchField();
    keyClick(Qt.Key_Up);
    verify(allAppsButton.activeFocus);
    pinned.append(favorite);
    menuContent.recentsGrid.usageModel = applications;
}
function test_favorites_outer_scroll_accepts_wheel() {
    pinned.append(app("second.desktop", "Second pinned app"));
    root.height = 648;
    waitForRendering(root);
    // Find the outer ScrollView instead of relying on its implementation depth.
    let outer = menuContent.favoritesGrid.parent;
    while (outer && !(outer.availableWidth !== undefined && outer.contentItem)) outer = outer.parent;
    verify(outer !== null);
    outer.contentItem.contentY = 0;
    mouseWheel(outer, 30, 200, 0, -120);
    tryVerify(() => outer.contentItem.contentY > 0);
    pinned.remove(pinned.count - 1);
}

function test_reopening_focuses_search_data() {
    return ["favorites", "recents", "applications", "results", "sidebar", "avatar", "power", "powerPopup"]
        .map(place => ({tag: place, place: place}));
}
function focusPlace(place) {
    if (place === "favorites") menuContent.favoritesGrid.tryActivate(0, 0);
    else if (place === "recents") menuContent.recentsGrid.tryActivate(0, 0);
    else if (place === "applications") {
        root.showApps = 1;
        menuContent.allAppsGrid.tryActivate(0, 0);
    } else if (place === "results") {
        searchBar.text = "term";
        menuContent.runnerGrid.tryActivate(0, 0);
    } else if (place === "sidebar") menuContent.sidebar.forceActiveFocus();
    else if (place === "avatar") floatingAvatar.forceActiveFocus();
    else if (place === "power") powerButtons.forceActiveFocus();
    else if (place === "powerPopup") powerButtons.openPopup();
    else allAppsButton.forceActiveFocus();
}
function test_reopening_focuses_search(data) {
    focusPlace(data.place);
    kicker.expanded = false;
    kicker.expanded = true;
    verify(searchBar.searchField.activeFocus, "Reopening must restore search focus immediately");
    // Leading Space must edit the query rather than activate the previous control.
    keyClick(Qt.Key_Space);
    typeText("terminal");
    compare(searchBar.text, " terminal");
    compare(runnerModel.query, " terminal");
    compare(applications.activations + pinned.activations + systemActions.activations, 0);
}
function test_typing_from_every_section_data() {
    return ["favorites", "recents", "applications", "results", "sidebar", "avatar", "power", "navigation"]
        .map(place => ({tag: place, place: place}));
}
function test_typing_from_every_section(data) {
    focusPlace(data.place);
    typeText("x");
    compare(searchBar.text, data.place === "results" ? "termx" : "x");
    verify(searchBar.searchField.activeFocus);
    compare(applications.activations + pinned.activations + systemActions.activations, 0);
}
function test_native_search_shortcuts_from_results() {
    typeText("terminal");
    keyClick(Qt.Key_Down);
    keyClick(Qt.Key_A, Qt.ControlModifier);
    compare(searchBar.searchField.selectedText, "terminal");
    typeText("console");
    compare(searchBar.text, "console");
    keyClick(Qt.Key_Down);
    keyClick(Qt.Key_F, Qt.ControlModifier);
    verify(searchBar.searchField.activeFocus);
    keyClick(Qt.Key_Home);
    keyClick(Qt.Key_Delete);
    compare(searchBar.text, "onsole");
}
function test_special_keys_do_not_start_search_data() {
    return [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta,
        Qt.Key_CapsLock, Qt.Key_F2, Qt.Key_F5, Qt.Key_F10, Qt.Key_VolumeUp]
        .map(key => ({tag: String(key), key: key}));
}
function test_special_keys_do_not_start_search(data) {
    menuContent.favoritesGrid.tryActivate(0, 0);
    keyClick(data.key);
    compare(searchBar.text, "");
    compare(applications.activations + pinned.activations + systemActions.activations, 0);
}
function test_escape_from_results_clears_once() {
    typeText("term");
    menuContent.runnerGrid.tryActivate(0, 0);
    keyClick(Qt.Key_Escape);
    compare(searchBar.text, "");
    verify(kicker.expanded);
    keyClick(Qt.Key_Escape);
    verify(!kicker.expanded);
}

function contextGrid(place) {
    if (place === "favorites") return menuContent.favoritesGrid;
    if (place === "recents") return menuContent.recentsGrid;
    if (place === "applications") return menuContent.allAppsGrid;
    return menuContent.runnerGrid;
}
function test_native_context_menus_data() {
    const cases = [];
    for (const place of ["favorites", "recents", "applications", "results"])
        for (const method of ["mouse", "menuKey", "shiftF10"])
            cases.push({tag: place + "-" + method, place: place, method: method});
    return cases;
}
function test_native_context_menus(data) {
    testCase.Window.window.requestActivate();
    tryCompare(testCase.Window.window, "active", true);
    focusPlace(data.place);
    const grid = contextGrid(data.place);
    waitForRendering(grid);
    const row = grid.currentItem;
    verify(row !== null);
    verify(row.activeFocus);
    const id = row.favoriteId;
    if (data.method === "mouse") mouseClick(row, 60, row.height / 2, Qt.RightButton);
    else keyClick(data.method === "menuKey" ? Qt.Key_Menu : Qt.Key_F10,
        data.method === "menuKey" ? Qt.NoModifier : Qt.ShiftModifier);
    const popup = row.contextMenu;
    tryCompare(popup, "opened", true);
    verify(kicker.expanded);
    const favorite = Array.from(popup.menu.content).find(item =>
        item.modelData.actionId === (data.place === "favorites" ? "_kicker_favorite_remove" : "_kicker_favorite_add"));
    verify(favorite !== undefined, "Native context menu must contain the appropriate favorite action");
    compare(applications.activations + pinned.activations, 0);
    favorite.action.trigger();
    if (data.place === "favorites") {
        verify(!pinned.isFavorite(id));
        pinned.append(app(id, "Pinned App"));
    } else {
        verify(pinned.isFavorite(id));
        pinned.removeFavorite(id);
    }
    menuContent.closePopups();
    verify(kicker.expanded, "Pinning must leave the launcher open");
}
function test_recent_context_action_maps_filtered_row() {
    // First recent is applications[0], while the pinned row has another ID.
    // Pinning applications[0] must remap the first recent to applications[1].
    pinned.append(app(applications.get(0).favoriteId, "Temporarily pinned"));
    try {
        tryVerify(() => menuContent.recentsGrid.displayModel.value(menuContent.recentsGrid.displayModel, 0, "favoriteId") === applications.get(1).favoriteId);
        menuContent.recentsGrid.tryActivate(0, 0);
        const row = menuContent.recentsGrid.currentItem;
        compare(row.favoriteId, applications.get(1).favoriteId);
        row.openActionMenu();
        const popup = row.contextMenu;
        tryCompare(popup, "opened", true);
        // Invoke the model's backend action through the native menu.
        popup.menu.content[0].action.trigger();
        compare(applications.lastId, applications.get(1).favoriteId);
        compare(applications.lastAction, "new-window");
        compare(applications.lastArgument.marker, 17);
    } finally {
        pinned.removeFavorite(applications.get(0).favoriteId);
    }
}

function test_native_application_context_action_data() {
    return ["favorites", "recents", "applications", "results"].map(place => ({tag: place, place: place}));
}
function test_native_application_context_action(data) {
    focusPlace(data.place);
    const grid = contextGrid(data.place);
    const row = grid.currentItem;
    const id = row.favoriteId;
    row.openActionMenu();
    const popup = row.contextMenu;
    tryCompare(popup, "opened", true);
    const action = Array.from(popup.menu.content).find(item => item.modelData.actionId === "new-window");
    verify(action !== undefined);
    action.action.trigger();
    const backend = data.place === "favorites" ? pinned : applications;
    compare(backend.lastId, id);
    compare(backend.lastAction, "new-window");
    compare(backend.lastArgument.marker, 17);
    compare(backend.activations, 1);
    verify(!kicker.expanded, "A successfully launched application closes the launcher");
}
function test_context_menu_on_recent_document_arrow() {
    const original = applicationActions();
    try {
        pinned.setProperty(0, "actionList", original.concat([{text: "Recent file", actionId: "_kicker_recentDocument", actionArgument: "file:///tmp/example"}]));
        menuContent.refreshActions();
        const row = menuContent.favoritesGrid.currentItem;
        const arrow = findChild(row, "recentFilesButton");
        tryCompare(arrow, "width", 30);
        mouseClick(arrow, arrow.width / 2, arrow.height / 2, Qt.RightButton);
        tryCompare(row.contextMenu, "opened", true);
        verify(!row.documentMenu.opened);
        compare(pinned.activations, 0);
    } finally {
        pinned.setProperty(0, "actionList", original);
        menuContent.refreshActions();
    }
}

function test_modified_typing_uses_native_text_handling_data() {
    return [
        {tag: "control", key: Qt.Key_B, modifiers: Qt.ControlModifier},
        {tag: "alt", key: Qt.Key_B, modifiers: Qt.AltModifier},
        {tag: "meta", key: Qt.Key_B, modifiers: Qt.MetaModifier},
        {tag: "control-alt", key: Qt.Key_T, modifiers: Qt.ControlModifier | Qt.AltModifier},
        {tag: "shift", key: Qt.Key_X, modifiers: Qt.ShiftModifier}
    ];
}
function test_modified_typing_uses_native_text_handling(data) {
    // Compare forwarding with Qt's native text field instead of synthesizing
    // query characters or assuming that every modified printable key is text.
    searchBar.focusSearchField();
    keyClick(data.key, data.modifiers);
    const nativeText = searchBar.text;
    searchBar.clear();
    menuContent.favoritesGrid.tryActivate(0, 0);
    keyClick(data.key, data.modifiers);
    compare(searchBar.text, nativeText);
    compare(applications.activations + pinned.activations + systemActions.activations, 0);
}
