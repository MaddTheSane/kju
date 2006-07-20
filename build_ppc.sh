#
# Q CVS Build script
#



cd ..



# remove obsolete files
rm -r -f tmp/qemu
rm -r -f products/ppc/Q.app



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
patch -p0 -u < ../../q/patches/q_host-cocoa_01.diff

#dns patch
cd slirp
patch -p0 < ../../../q/patches/qemu-dns.patch
cd ..

#rgb support for intel
cd hw
#patch -p0 -u < ../../../q/patches/q_vga.c_02.diff
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
#./configure --prefix=../products/ppc --enable-cocoa --enable-adlib --cc=gcc-3.3 --disable-gcc-check
./configure --prefix=../products/ppc --enable-cocoa --enable-adlib --cc=gcc-3.3 --disable-gcc-check --target-list=i386-softmmu
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


