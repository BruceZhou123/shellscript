#! /bin/bash
# author:BruceZhou123
# created date:2018/10/18

cd ~/home/xwp/.config/sublime-text-3/Packages

echo Install...
echo ==================================================

echo === Package Control ===
rm -rf "Package Control"
git clone https://github.com/JustQyx/Sublime-Text-Package-Control.git "Package Control"

echo === AdvancedNewFile ===
rm -rf "AdvancedNewFile"
git clone https://github.com/skuroda/Sublime-AdvancedNewFile.git "AdvancedNewFile"

echo === emmet ===
rm -rf "emmet"
git clone https://github.com/sergeche/emmet-sublime.git "emmet"

echo === SideBarEnhancements ===
rm -rf "SideBarEnhancements"
git clone https://github.com/SideBarEnhancements-org/SideBarEnhancements.git "SideBarEnhancements"

echo === SublimeCodeIntel ===
rm -rf "SublimeCodeIntel"
git clone https://github.com/SublimeCodeIntel/SublimeCodeIntel.git "SublimeCodeIntel"

echo === ColorPicker===
rm -rf "ColorPicker"
git clone https://github.com/weslly/ColorPicker.git "ColorPicker"

echo "you can install HTML/CSS/JS Prettify,Python PEP8 Autoformat,Djaneiro...else..."