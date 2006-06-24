#
# Q DMG Build script
#

cd ..

VERSION=$(cat qemu/VERSION)"d"$(cat q/version.txt)


# mount Q.dmg
hdiutil mount "dmg/Q.dmg"


# remove old files
rm -rf "/Volumes/Q/Q.app"


# copy new files
cp -r "products/universal/Q.app" "/Volumes/Q/Q.app"
cp "q/changelog.txt" "/Volumes/Q/changelog.txt"


# unmount Q.dmg
hdiutil eject "/Volumes/Q"


# convert Q.dmg
hdiutil convert -format UDZO -o "dmg/Q-"$VERSION".dmg" "dmg/Q.dmg"


# add SLA to Q.dmg
hdiutil unflatten "dmg/Q-"$VERSION".dmg"
/Developer/Tools/DeRez "dmg/sla.rsrc" > "dmg/sla.r"
/Developer/Tools/Rez -a "dmg/sla.r" -o "dmg/Q-"$VERSION".dmg"
hdiutil flatten "dmg/Q-"$VERSION".dmg"
