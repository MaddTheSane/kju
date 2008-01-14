rm -r -f products
rm -r -f tmp

#get/update libtransmission
svn co -r 480 svn://svn.m0k.org/Transmission/trunk/ Transmission
cp Transmission/mk/lib.mk Transmission/libtransmission/Makefile

#get/update QEMU
export CVS_RSH="ssh"
cvs -z3 -d:pserver:anonymous@cvs.savannah.nongnu.org:/sources/qemu co -r "release_0_9_1" qemu

#get/update [kju:]
svn co http://www.kju-app.org/svn/q/branches/0_9_1 q

mkdir products
mkdir products/i386
mkdir products/ppc
mkdir products/universal
mkdir tmp