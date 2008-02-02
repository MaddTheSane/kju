#
# Q CVS Build script
#



QEMUROOT=$(PWD)
QEMUBUILDDIRECTORY="/tmp"
QBUILDDIRECTORY=$(PWD)"/../build"
BUILDCONFIGURATIONS="Debug Release"

# remove obsolete files
rm -r -f "$QEMUBUILDDIRECTORY/qemu"



#make qemu
mkdir -p   "$QEMUBUILDDIRECTORY/qemu"
cp -R qemu "$QEMUBUILDDIRECTORY"


# patch qemu sources
cd "$QEMUBUILDDIRECTORY/qemu"
echo $(PWD)
#patch -p0 -u < "$QEMUROOT/patches/qemu-img-CF+IO.diff"
#patch -p0 -u < "$QEMUROOT/patches/Leopard-dyngen.dSYM.diff"
#patch -p1 -u < "$QEMUROOT/patches/qemu-osx.patch"


echo "Q ***** gcc4 patches"
patch -p1 -u < "$QEMUROOT/patches/qemu-0.9.1-gcc4.patch"
patch -p1 -u < "$QEMUROOT/patches/qemu-0.7.2-dyngen-check-stack-clobbers.patch"
patch -p1 -u < "$QEMUROOT/patches/qemu-0.9.1-gcc4-opts.patch"
patch -p1 -u < "$QEMUROOT/patches/qemu-0.9.1-gcc4-hacks.patch"

echo "Q ***** osx86 patches"
patch -p1 -u <    "$QEMUROOT/patches/qemu-0.9.1-enforce-16byte-stack-boundary.patch"
patch -p1 -u -f < "$QEMUROOT/patches/qemu-0.9.0-i386-FORCE_RET.patch"
patch -p1 -u <    "$QEMUROOT/patches/qemu-0.9.1-osx-intel-port.patch"

patch -p1 -u <    "$QEMUROOT/patches/qemu-0.9.1-osx-bugfix.patch"

echo "Q ***** Leopard patches"
patch -p0 -u <    "$QEMUROOT/patches/Leopard-dyngen.dSYM.diff"
patch -p0 -u <    "$QEMUROOT/patches/qemu-img-CF+IO.diff"

patch -p1 -u <    "$QEMUROOT/patches/qemu-0.9.1-always_inline.patch"

#echo "Q ***** add 2nd Bootdevice"
#patch -p0 -u <   "$QEMUROOT/patches/qemu-2ndbootdevice_04.diff"

#echo "Q ***** use custom cocoa.m"
cp "$QEMUROOT/patches/cocoa.m" "$QEMUBUILDDIRECTORY/qemu/cocoa.m"

#echo "Q ***** "add Harddisc Led support"
patch -p0 -u <    "$QEMUROOT/patches/q_block_int.h_hdled_1.diff"
patch -p0 -u <    "$QEMUROOT/patches/q_block.c_hdled_1.diff"



# configure and make
#./configure --prefix=../products/i386 --enable-cocoa --enable-adlib --disable-gcc-check --target-list=i386-softmmu,ppc-softmmu,sparc-softmmu,mips-softmmu,arm-softmmu
./configure --prefix=.. --enable-cocoa --enable-adlib --disable-gcc-check --target-list=i386-softmmu
make
#cp i386-softmmu/qemu /qemutest/qemu
cd -

for BUILDCONFIGURATION in $BUILDCONFIGURATIONS; do

    #create and copy qemu bins
    rm -rf   "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/bin/*-softmmu" > /dev/null
    mkdir -p "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/bin/"
    cp "$QEMUBUILDDIRECTORY/qemu/i386-softmmu/qemu" "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/bin/i386-softmmu"

    #create and copy bios
    rm -rf   "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/share/qemu" > /dev/null
    mkdir -p "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/share/qemu/"
    cd "$QEMUBUILDDIRECTORY/qemu/pc-bios/"
    cp *.bin "$QBUILDDIRECTORY/$BUILDCONFIGURATION/Q.app/Contents/Resources/share/qemu/"
    cd -

done