// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtTest
import "../contents/ui/parts" as Parts

TestCase {
    id: root
    name: "MenuNavigationButton"
    when: windowShown
    visible: true
    width: 400
    height: 140

    Parts.MenuNavigationButton {
        id: button
        x: 20
        y: 20
        width: 240
        height: 36
        text: "Wstecz"
    }
    SignalSpy {
        id: clicks
        target: button
        signalName: "clicked"
    }

    function moveOutside() {
        mouseMove(root, root.width - 2, root.height - 2);
        tryCompare(button, "hovered", false);
    }
    function init() {
        button.width = 240;
        button.height = 36;
        moveOutside();
        clicks.clear();
    }
    function test_highlight_fills_button_when_hovered_and_resized() {
        mouseMove(button, button.width / 2, button.height / 2);
        tryCompare(button, "hovered", true);
        compare(button.background.x, 0);
        compare(button.background.y, 0);
        compare(button.background.width, button.width);
        compare(button.background.height, button.height);
        button.width = 300;
        button.height = 42;
        waitForRendering(button);
        compare(button.background.width, button.width);
        compare(button.background.height, button.height);
    }
    function test_focus_does_not_highlight() {
        button.forceActiveFocus();
        verify(button.activeFocus);
        verify(!button.pressed);
        verify(!button.background.visible);
    }
    function test_hover_and_press_highlight() {
        mouseMove(button, button.width / 2, button.height / 2);
        tryCompare(button, "hovered", true);
        verify(button.background.visible);
        mousePress(button, button.width / 2, button.height / 2);
        verify(button.pressed);
        verify(button.background.visible);
        mouseRelease(button, button.width / 2, button.height / 2);
        compare(clicks.count, 1);
        verify(!button.pressed);
        moveOutside();
        verify(button.activeFocus);
        verify(!button.background.visible);
        verify(!button.checked);
    }
    function test_keyboard_activation_does_not_leave_highlight() {
        button.forceActiveFocus();
        keyPress(Qt.Key_Space);
        verify(button.pressed);
        verify(button.background.visible);
        keyRelease(Qt.Key_Space);
        compare(clicks.count, 1);
        verify(!button.pressed);
        verify(!button.background.visible);
        keyClick(Qt.Key_Return);
        compare(clicks.count, 2);
        verify(!button.background.visible);
    }
}
