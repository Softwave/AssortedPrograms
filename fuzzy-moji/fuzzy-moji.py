#!/usr/bin/env python

# This file is part of FuzzyMoji
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


import sys
from PyQt5.QtCore import *
from PyQt5.QtGui import *
from PyQt5.QtWidgets import *
import json
from fuzzywuzzy import fuzz

class EmojiListApp(QMainWindow):
    def __init__(self):
        super().__init__()

        # Load the font for emoji rendering (This font must support emojis)
        QFontDatabase.addApplicationFont("NotoColorEmoji-Regular.ttf")

        # Read the emoji list from the JSON file
        with open("emoji.json", "r", encoding="utf-8") as f:
            self.emoji_list = json.load(f)
        
        # Initialize the GUI
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("FuzzyMoji Finder")
        self.setGeometry(100, 100, 300, 400)

        # Create the search bar
        self.search_bar = QLineEdit()
        self.search_bar.setPlaceholderText("Search...")
        self.search_bar.textChanged.connect(self.perform_search)

        # Create the list widget to display emojis
        self.emoji_list_widget = QListWidget()

        # Add emojis to the list
        self.add_emojis_to_list()

        # Create a copy button to copy selected emoji to clipboard
        self.copy_button = QPushButton("Copy Emoji to Clipboard")
        self.copy_button.clicked.connect(self.copy_selected_emoji)

        # Create a layout and add widgets to it
        layout = QVBoxLayout()
        layout.addWidget(self.search_bar)
        layout.addWidget(self.emoji_list_widget)
        layout.addWidget(self.copy_button)

        # Create a central widget and set the layout on it
        central_widget = QWidget()
        central_widget.setLayout(layout)
        self.setCentralWidget(central_widget)

    def add_emojis_to_list(self):
        for emoji_data in self.emoji_list:
            emoji = emoji_data["emoji"]
            description = emoji_data["description"]
            list_item = QListWidgetItem(f"{emoji} - {description}")
            self.emoji_list_widget.addItem(list_item)


    def perform_search(self):
        search_text = self.search_bar.text().strip().lower()

        if not search_text:  # If the search bar is totally empty
            self.emoji_list_widget.clear()
            self.add_emojis_to_list()
        else:
            self.emoji_list_widget.clear()
            for emoji_data in self.emoji_list:
                emoji = emoji_data["emoji"]
                description = emoji_data["description"]
                # Check if the search_text matches the emoji or description using fuzzy matching
                if fuzz.partial_ratio(search_text, emoji.lower()) >= 70 or fuzz.partial_ratio(search_text, description.lower()) >= 70:
                    list_item = QListWidgetItem(f"{emoji} - {description}")
                    self.emoji_list_widget.addItem(list_item)

    

    def copy_selected_emoji(self):
        selected_item = self.emoji_list_widget.currentItem()
        if selected_item:
            emoji_text = selected_item.text().split(" - ")[0]
            clipboard = QGuiApplication.clipboard()
            clipboard.setText(emoji_text)
            QMessageBox.information(self, "Copied", f"Emoji {emoji_text} copied to clipboard!")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = EmojiListApp()
    window.show()
    sys.exit(app.exec_())
