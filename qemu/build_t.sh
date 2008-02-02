QBUILDDIRECTORY=$(PWD)"/../build"
BUILDCONFIGURATIONS="Debug Release"

for BUILDCONFIGURATION in $BUILDCONFIGURATIONS; do

    #create and copy qemu bins
    rm -rf   "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/bin/*-softmmu" > /dev/null
    mkdir -p "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/bin/"
    cp "/tmp/qemu/i386-softmmu/qemu" "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/bin/i386-softmmu"

    #create and copy bios
    rm -rf   "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/share/qemu" > /dev/null
    mkdir -p "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/share/qemu/"
    cd "/tmp/qemu/pc-bios/"
    cp *.bin "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/share/qemu/"
    cd -

done