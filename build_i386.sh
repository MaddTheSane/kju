#
# Q CVS Build script
#



cd ..

# remove obsolete files
rm -r -f tmp/qemu
rm -r -f products/i386/Q.app



#make libtransmission
cd Transmission
#make clean
./configure
./version.sh
cd libtransmission
make
cd ..
cd ..



#make qemu
cp -R qemu tmp/qemu


# patch qemu sources
cd tmp/qemu

#Q
patch -p0 -u < ../../q/patches/q_host-cocoa_02.diff

#gcc4 patches
patch -p1 -u < ../../q/patches/qemu-0.9.0-gcc4.patch
patch -p1 -u < ../../q/patches/qemu-0.7.2-dyngen-check-stack-clobbers.patch
patch -p1 -u < ../../q/patches/qemu-0.7.2-gcc4-opts.patch
patch -p1 -u < ../../q/patches/qemu-0.8.0-gcc4-hacks.patch

#OS X86 patches
patch -p1 -u < ../../q/patches/qemu-0.9.0-enforce-16byte-stack-boundary.patch
patch -p1 -u -f < ../../q/patches/qemu-0.9.0-i386-FORCE_RET.patch
patch -p1 -u < ../../q/patches/qemu-0.9.0-osx-intel-port.patch

patch -p1 -u < ../../q/patches/qemu-0.8.0-osx-bugfix.patch

#rgb support for intel
cd hw
patch -p0 -u < ../../../q/patches/q_vga.c_02.diff
cd ..

#add 2nd Bootdevice
cd hw
patch -p0 -u < ../../../q/patches/qemu-2ndbootdevice_03.diff
cd ..

#add HDLED
patch -p0 -u < ../../q/patches/q_block_int.h_hdled_1.diff
patch -p0 -u < ../../q/patches/q_block.c_hdled_1.diff

# merge Q
cp -r ../../q/host-cocoa/ host-cocoa/


# configure and make
#./configure --prefix=../products/i386 --enable-cocoa --enable-adlib --cc=gcc-3.3 --disable-gcc-check
./configure --prefix=../products/i386 --enable-cocoa --enable-adlib --disable-gcc-check --target-list=i386-softmmu
#./configure --prefix=../products/i386 --enable-cocoa --enable-adlib --disable-gcc-check
#./configure --prefix=../products/i386 --enable-cocoa --enable-adlib --disable-gcc-check --target-list=i386-softmmu,ppc-softmmu,sparc-softmmu,mips-softmmu,arm-softmmu
make
cd ..
cd ..



#make Q Control
cd q
cd qcontrol
#make clean
make
make app
cd ..


