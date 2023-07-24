#!/usr/bin/env python

# This file is part of Pigment Picker
# Copyright (c) 2023 Jessica Leyba
# This program is free software: you can redistribute it and/or modify  
# it under the terms of the GNU General Public License as published by  
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


from PyQt5.QtGui import *
from PyQt5.QtWidgets import *
import os
import sys

app = QApplication([])
app.setQuitOnLastWindowClosed(False)

# Create the icon
icon = QIcon(os.path.join("images", "colour.png"))

clipboard = QApplication.clipboard()
dialog = QColorDialog()


def copy_color_hex():
    if dialog.exec_():
        color = dialog.currentColor()
        clipboard.setText(color.name())


def copy_color_rgb():
    if dialog.exec_():
        color = dialog.currentColor()
        clipboard.setText("rgb(%d, %d, %d)" % (
            color.red(), color.green(), color.blue()
        ))

def show_about_dialog():
    QMessageBox.about(None, "About Pigment Picker", "A teeny, tiny colour picker utility.\n© Jessica Leyba 2023.\nSee the README and LICENSE files for more information.")


def quit_application():
    app.quit()


# Create the tray
tray = QSystemTrayIcon()
tray.setIcon(icon)
tray.setVisible(True)

# Create the menu
menu = QMenu()

action1 = QAction("Hex")
action1.triggered.connect(copy_color_hex)
menu.addAction(action1)

action2 = QAction("RGB")
action2.triggered.connect(copy_color_rgb)
menu.addAction(action2)

# Add the "About" option to the menu
action_about = QAction("About")
action_about.triggered.connect(show_about_dialog)
menu.addAction(action_about)

# Add the "Quit" option to the menu
action_quit = QAction("Quit")
action_quit.triggered.connect(quit_application)
menu.addAction(action_quit)

# Add the menu to the tray
tray.setContextMenu(menu)

app.exec_()

