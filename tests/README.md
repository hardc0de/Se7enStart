Run the QML regression tests from the project root with Qt 6 development packages (Widgets, QuickTest, pkg-config, and a C++ compiler) and the Plasma 6 QML modules installed:

```sh
c++ -fPIC -o /tmp/se7en-qmltests tests/quicktest_main.cpp \
    $(pkg-config --cflags --libs Qt6Widgets Qt6QuickTest)
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    QT_QPA_PLATFORMTHEME=generic QT_STYLE_OVERRIDE=Fusion \
    /tmp/se7en-qmltests -input tests
```

The custom runner creates a QApplication because PlasmaExtras.Menu uses native QWidget menus, as it does in plasmashell. The stock qmltestrunner creates only a QGuiApplication and cannot run native-menu tests safely.

Tests use a mock merged result model and never launch applications. They cover typing without search focus, selection and cursor editing, navigation across result sections, Enter, Escape, delayed results, mouse activation, and scrolling. They also verify that queries follow typing without an added delay and that a thousand results create only delegates around the visible area.

The view-size tests verify rendered icons and row heights, and check that opening search or All Programs leaves the hidden favorites and recents at 32 px icons and 48 px rows. Search results keep 16 px icons and 24 px rows.

All Programs rows and highlights must fit the viewport beside the scrollbar at different menu widths. These checks also cover keyboard movement and pointer input at the right edge of a row.

Pointer-exit checks cover favorites, recents, All Applications, and search: hover selection disappears on exit, while arrow-key selection remains usable. Search scrollbar checks cover short results, overflowing results, and shrinking back to a short list.

Navigation tests verify that the applications and search pages own separate buttons, and that button highlights follow hover/press state without staying on after keyboard focus or activation.

Model tests verify named roles, filtered action forwarding, pin/unpin/reorder synchronization, preferred-application identity, and native recent-file payloads. Component smoke tests load the applet/settings, inspect installed Kicker roles without invoking actions, and check avatar fallback.

Run the full-menu and packaging checks with:

```sh
python3 tests/generate_menu_harness.py /tmp/se7en-full-menu-tests
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic QT_STYLE_OVERRIDE=Fusion \
    /tmp/se7en-qmltests -input /tmp/se7en-full-menu-tests
python3 tests/test_package.py
```

The generator uses the current fullRepresentation and mock backends. It never launches applications or executes power actions. Scenarios include popup focus/dismissal, capabilities, navigation, empty sections, sidebar scrolling, wheel scrolling, long labels, canceled clicks, and blank-space right-clicks. All Applications checks cover its Back label/icon and scroll reset after leaving through the button, keyboard, search, or closing the applet. Keep full_menu_scenarios.js alongside the generator.

Minimum-height checks verify that favorites, recents, and shortcuts fit without scrolling at the advertised menu minimum. The minimum follows favorite and recent row counts and stays consistent across the normal, All Applications, and search pages. Scrolling checks below that minimum cover constrained popup heights.

Before packaging checks after translation changes, rebuild catalogs using `sh translate/build.sh` (requires gettext; does not restart Plasma).

Native context-menu checks cover item registration, titles/separators, disabled/checkable actions, recursive submenus, activity favorites (including stopped activities), and opaque QObject action arguments. Full-menu scenarios open menus with right-click, Menu, and Shift+F10 in favorites, recents, All Applications, and search. They verify pin/unpin, native application actions, filtered recent-row dispatch, and right-clicking the recent-files arrow. No applications are launched.

Keyboard scenarios cover immediate search focus after reopening from each section or the power popup, leading spaces, typing from all sections, Ctrl+A/Ctrl+F, cursor editing, and Escape. Modifier-only keys, Caps Lock, function keys, and media keys must leave the query unchanged. Native popups own separate windows; tests restore the main test window's activation after closing them. The offscreen plugin may report unsupported keyboard grabs/raising when a native menu opens.

Global shortcuts grabbed by the compositor never reach the applet. When a context/power menu is open, it owns keyboard navigation and mnemonics. Space/Enter on a focused button retain button activation; ordinary typing bubbles to the native search field. Text editing shortcuts stay native, and Ctrl+F focuses search. Input-method composition and physical AltGr layouts should additionally be checked in a live Plasma session; reopening now focuses the actual text input so it can receive those events directly.
