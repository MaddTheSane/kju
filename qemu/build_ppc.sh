#
# Q CVS Build script
#



cd ..

# remove obsolete files
rm -r -f tmp/qemu



#make qemu
cp -R qemu tmp/qemu


# patch qemu sources
cd tmp/qemu

#qemu cvs backport for qcow2
patch -p0 -u < ../../q/patches/qemu-0.9.0-qcow2.diff

#qemu cvs backport rgb support for bigendian
patch -p1 -u < ../../q/patches/qemu-0.9.0-big_endian_display4.diff

#qemu add 2nd Bootdevice
patch -p0 -u < ../../q/patches/qemu-2ndbootdevice_04.diff

#qemu add HDLED
patch -p0 -u < ../../q/patches/q_block_int.h_hdled_1.diff
patch -p0 -u < ../../q/patches/q_block.c_hdled_1.diff



# configure and make
#./configure --prefix=../products/ppc --enable-cocoa --enable-adlib --cc=gcc-3.3 --disable-gcc-check --target-list=i386-softmmu,ppc-softmmu,sparc-softmmu,mips-softmmu,arm-softmmu,x86_64-softmmu
./configure --prefix=../products/ppc --enable-cocoa --enable-adlib --cc=gcc-3.3 --disable-gcc-check --target-list=i386-softmmu
MACOSX_DEPLOYMENT_TARGET=10.3 make
cd ..
cd ..