#
# Q CVS Build script
#

cd ..

# lipo Files
cp -r products/i386/Q.app products/universal/Q.app
cp -r -n products/ppc/Q.app/Contents/MacOS/* products/universal/Q.app/Contents/MacOS/

lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu" -arch ppc "products/ppc/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu" -o "products/universal/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu"
lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/x86_64-softmmu.app/Contents/MacOS/x86_64-softmmu" -arch ppc "products/ppc/Q.app/Contents/MacOS/x86_64-softmmu.app/Contents/MacOS/x86_64-softmmu" -o "products/universal/Q.app/Contents/MacOS/x86_64-softmmu.app/Contents/MacOS/x86_64-softmmu"
lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/ppc-softmmu.app/Contents/MacOS/ppc-softmmu" -arch ppc "products/ppc/Q.app/Contents/MacOS/ppc-softmmu.app/Contents/MacOS/ppc-softmmu" -o "products/universal/Q.app/Contents/MacOS/ppc-softmmu.app/Contents/MacOS/ppc-softmmu"

lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/arm-softmmu.app/Contents/MacOS/arm-softmmu" -arch ppc "products/ppc/Q.app/Contents/MacOS/arm-softmmu.app/Contents/MacOS/arm-softmmu" -o "products/universal/Q.app/Contents/MacOS/arm-softmmu.app/Contents/MacOS/arm-softmmu"
lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/mips-softmmu.app/Contents/MacOS/mips-softmmu" -arch ppc "products/ppc/Q.app/Contents/MacOS/mips-softmmu.app/Contents/MacOS/mips-softmmu" -o "products/universal/Q.app/Contents/MacOS/mips-softmmu.app/Contents/MacOS/mips-softmmu"
lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/mipsel-softmmu.app/Contents/MacOS/mipsel-softmmu" -arch ppc "products/ppc/Q.app/Contents/MacOS/mipsel-softmmu.app/Contents/MacOS/mipsel-softmmu" -o "products/universal/Q.app/Contents/MacOS/mipsel-softmmu.app/Contents/MacOS/mipsel-softmmu"
lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/sparc-softmmu.app/Contents/MacOS/sparc-softmmu" -arch ppc "products/ppc/Q.app/Contents/MacOS/sparc-softmmu.app/Contents/MacOS/sparc-softmmu" -o "products/universal/Q.app/Contents/MacOS/sparc-softmmu.app/Contents/MacOS/sparc-softmmu"

lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/qemu-img" -arch ppc "products/ppc/Q.app/Contents/MacOS/qemu-img" -o "products/universal/Q.app/Contents/MacOS/qemu-img"
lipo -create -arch i386 "products/i386/Q.app/Contents/MacOS/qemu-control" -arch ppc "products/ppc/Q.app/Contents/MacOS/qemu-control" -o "products/universal/Q.app/Contents/MacOS/qemu-control"
