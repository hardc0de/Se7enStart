#!/usr/bin/env python3
"""Build a test harness from the current fullRepresentation, not a copied menu."""
from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("directory", type=Path)
args = parser.parse_args()
main = (ROOT / "contents/ui/main.qml").read_text()
imports = main[:main.index("PlasmoidItem {")].replace('import "parts" as Parts', f'import "{(ROOT / "contents/ui/parts").as_uri()}" as Parts')
imports += f'import QtTest\nimport "{(ROOT / "contents/ui").as_uri()}"\nimport "{(ROOT / "tests").as_uri()}" as Mocks\n'
start = main.index("fullRepresentation: FocusScope {") + len("fullRepresentation: ")
menu = main[start:main.index("\n    Kicker.RootModel {", start)].strip()
menu = menu.replace("id: root", "id: root\n        width: 500\n        height: 740", 1)
menu = menu.replace("taskManagerCommand: Plasmoid.configuration.taskManagerCommand", 'taskManagerCommand: "MOCK_TASK_MANAGER"')
menu = menu.replace("id: powerButtons", "id: powerButtons\n                    systemModel: systemActions")
context = '''
TestCase {
    id: testCase
    name: "FullMenu"
    width: 500; height: 740; visible: true; when: windowShown
    function i18n(text, argument) { return argument === undefined ? text : text.replace("%1", argument); }
    QtObject {
        id: kicker
        property bool expanded: true
        property var executable: mockExecutor
        property var globalFavorites: pinned
        property var dragSource: null
        property Item searchInput: null
    }
    QtObject { id: kuser; property string faceIconUrl: "" }
    QtObject {
        id: mockExecutor
        property var commands: []
        signal exited(string cmd, int code, int status, string out, string err)
        function exec(cmd) { commands.push(cmd); }
    }
    QtObject {
        id: dragHelper
        property bool dragging: false
        function isDrag(x, y, xx, yy) { return Math.abs(x - xx) + Math.abs(y - yy) > 20; }
        function startDrag(host, url, icon) { dragging = true; }
    }
    Mocks.MockApplications { id: pinned }
    Mocks.MockApplications { id: applications; favoritesModel: pinned }
    Mocks.MockApplications { id: systemActions }
    QtObject { id: rootModel; property int count: 1; signal refreshed(); function modelForRow(row) { return applications; } }
    ListModel {
        id: runnerModel
        property string query: kicker.searchInput ? kicker.searchInput.text : ""
        function modelForRow(row) { return applications; }
        ListElement { display: "Results" }
    }
'''
scenarios = (ROOT / "tests/full_menu_scenarios.js").read_text()
args.directory.mkdir(parents=True, exist_ok=True)
(args.directory / "tst_full_menu.qml").write_text(imports + context + menu + "\n" + scenarios + "\n}\n")
