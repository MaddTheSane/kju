rm -r -f products
rm -r -f tmp

#get/update QEMU
export CVS_RSH="ssh"
cvs -z3 -d:pserver:anonymous@cvs.savannah.nongnu.org:/sources/qemu co -r "release_0_9_0" qemu

mkdir products
mkdir products/i386
mkdir products/ppc
mkdir products/universal
mkdir tmp