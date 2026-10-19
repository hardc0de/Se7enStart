// SPDX-License-Identifier: GPL-2.0-or-later
#include <QApplication>
#include <QtQuickTest/quicktest.h>

int main(int argc, char **argv)
{
    // PlasmaExtras.Menu wraps QMenu, so native menu tests need Qt Widgets.
    QApplication app(argc, argv);
    return quick_test_main(argc, argv, "se7enstart", nullptr);
}
