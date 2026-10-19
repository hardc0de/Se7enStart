// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels
import "../contents/ui"
import "../contents/ui/parts" as Parts

TestCase {
    id: root
    name: "ComponentSmoke"
    when: windowShown
    visible: true
    width: 300
    height: 200
    function i18n(text) {
        return text;
    }
    Kicker.RootModel {
        id: nativeRoot
        showAllApps: true
        flat: true
        showSeparators: false
    }
    ApplicationModel {
        id: nativeProxy
        sourceModel: nativeRoot.count ? nativeRoot.modelForRow(0) : null
    }
    function test_native_model_role_contract() {
        if (!nativeProxy.count)
            skip("No installed applications available to inspect");
        const native = nativeProxy.sourceModel;
        for (const role of ["favoriteId", "url", "actionList"]) {
            const number = native.KItemModels.KRoleNames.role(role);
            verify(number >= 0);
            const expected = native.data(native.index(0, 0), number);
            const forwarded = nativeProxy.value(nativeProxy, 0, role);
            if (role !== "actionList")
                compare(String(forwarded), String(expected));
            else
                verify(forwarded !== undefined);
        }
    }
    Parts.PersonalPortrait {
        id: portrait
        isExpanded: true
    }
    function test_components_load_data() {
        return [
            {
                tag: "applet",
                path: "../contents/ui/main.qml"
            },
            {
                tag: "configuration",
                path: "../contents/ui/ConfigGeneral.qml"
            },
            {
                tag: "power",
                path: "../contents/ui/parts/PowerButtons.qml"
            }
        ];
    }
    function test_components_load(data) {
        const component = Qt.createComponent(Qt.resolvedUrl(data.path));
        tryCompare(component, "status", Component.Ready);
        compare(component.errorString(), "");
    }
    function test_configuration_instantiates() {
        const component = Qt.createComponent(Qt.resolvedUrl("../contents/ui/ConfigGeneral.qml"));
        compare(component.status, Component.Ready);
        const page = component.createObject(root);
        verify(page !== null);
        page.destroy();
    }
    function test_avatar_handles_missing_picture() {
        portrait.userFaceIconUrl = "file:///tmp/se7en-missing-user-picture.png";
        const fallback = findChild(portrait, "userFallbackIcon");
        const image = findChild(portrait, "userImage");
        tryCompare(image, "status", Image.Error);
        verify(fallback.visible);
        verify(!image.visible);
        portrait.userFaceIconUrl = "";
    }
}
