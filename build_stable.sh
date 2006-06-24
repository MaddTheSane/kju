#
# Q Stable Build script


# get Q Version Number
QEMUVERSION=$(cat qemu_i686/VERSION)
QKJUVERSION=$(cat patches/host-cocoa/qversion.txt)

# mount Q.dmg
hdiutil mount "dmg/Q.dmg"


# update Version files
sed 's/QEMU_VERSION/'$QEMUVERSION'/;s/dQKJU_VERSION/a'$QKJUVERSION'/' patches/host-cocoa/Info.plist > "/Volumes/Q/Q.app/Contents/Info.plist";
		
# unmount Q.dmg
hdiutil eject "/Volumes/Q"


# convert Q.dmg
hdiutil convert -format UDZO -o "dmg/Q-"$QEMUVERSION"a"$QKJUVERSION".dmg" "dmg/Q.dmg"


# add SLA to Q.dmg
hdiutil unflatten "dmg/Q-"$QEMUVERSION"a"$QKJUVERSION".dmg"
/Developer/Tools/DeRez "dmg/sla.rsrc" > "dmg/sla.r"
/Developer/Tools/Rez -a "dmg/sla.r" -o "dmg/Q-"$QEMUVERSION"a"$QKJUVERSION".dmg"
hdiutil flatten "dmg/Q-"$QEMUVERSION"a"$QKJUVERSION".dmg"
