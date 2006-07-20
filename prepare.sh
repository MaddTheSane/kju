rm -r -f products
rm -r -f tmp

#get/update libtransmission
svn co -r 638 svn://svn.m0k.org/Transmission/trunk/ Transmission
cp Transmission/mk/lib.mk Transmission/libtransmission/Makefile

#get/update QEMU
export CVS_RSH="ssh"
cvs -z3 -d:pserver:anonymous@cvs.savannah.nongnu.org:/sources/qemu co qemu

#get/update [kju:]
svn co svn://svn.kju-app.org/q/trunk q

mkdir products
mkdir products/i386
mkdir products/ppc
mkdir products/universal
mkdir tmp