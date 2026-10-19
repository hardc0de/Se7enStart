// SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import org.kde.draganddrop as DragDrop
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configGeneral
    property string cfg_icon: "start-here-kde"
    property bool cfg_useCustomButtonImage: false
    property string cfg_customButtonImage: ""
    property alias cfg_useExtraRunners: extraRunners.checked
    property alias cfg_taskManagerCommand: taskManager.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        Button {
            id: iconButton
            Kirigami.FormData.label: i18n("Icon:")
            icon.name: configGeneral.cfg_useCustomButtonImage ? configGeneral.cfg_customButtonImage : configGeneral.cfg_icon
            text: i18n("Choose…")
            onClicked: iconMenu.open()
            DragDrop.DropArea {
                anchors.fill: parent
                property bool acceptable: false
                onDragEnter: event => {
                    const url = event.mimeData.url.toString();
                    acceptable = url.startsWith("file:///") && /\.(png|xpm|svg|svgz)$/i.test(url);
                    if (!acceptable)
                        event.ignore();
                }
                onDragLeave: acceptable = false
                onDrop: event => {
                    if (acceptable) {
                        configGeneral.cfg_customButtonImage = event.mimeData.url.toString();
                        configGeneral.cfg_useCustomButtonImage = true;
                    }
                    acceptable = false;
                }
            }
            KIconThemes.IconDialog {
                id: iconDialog
                onIconNameChanged: {
                    configGeneral.cfg_icon = iconName;
                    configGeneral.cfg_useCustomButtonImage = false;
                }
            }
            Menu {
                id: iconMenu
                y: iconButton.height
                MenuItem {
                    text: i18n("Choose…")
                    onTriggered: iconDialog.open()
                }
                MenuItem {
                    text: i18n("Reset Icon")
                    onTriggered: {
                        configGeneral.cfg_icon = "start-here-kde";
                        configGeneral.cfg_useCustomButtonImage = false;
                        configGeneral.cfg_customButtonImage = "";
                    }
                }
            }
        }
        CheckBox {
            id: extraRunners
            text: i18n("Include files and bookmarks in search")
        }
        TextField {
            id: taskManager
            Kirigami.FormData.label: i18n("Task manager command:")
            Accessible.name: i18n("Task manager command")
        }
        Label {
            text: i18n("The default tries Mission Center, then Plasma System Monitor.")
            wrapMode: Text.WordWrap
            Kirigami.FormData.isSection: true
        }
    }
}
