include ../../tmp/qemu/config-host.mak
OPT_LANGUAGES=French German pl
QVERSION=$(shell svn info | grep "Revision:" | sed s/"Revision: "/""/)

all: qemu-control$(EXESUF)

qemu-control$(EXESUF): cocoaControlMain.m cocoaControlController.m cocoaControlDiskImage.m cocoaControlNewPCAssistant.m cocoaControlEditPC.m cocoaControlPreferences.m cocoaControlDOServer.m cocoaDownload.m cocoaDownloadController.m QControlTableView.m
	gcc -Wall -O4 -F/System/Library/Frameworks -framework Carbon -framework Cocoa ../../Transmission/libtransmission/libtransmission.a -lcrypto -o $@ $^

clean:
	rm -f *.o *.a qemu-control$(EXESUF) *.pod *~ */*~

# generate OS X .app Packages
app:
	rm -rf "../$(prefix)/Q.app";
	mkdir -p "../$(prefix)/Q.app/Contents/MacOS/";
	mkdir -p "../$(prefix)/Q.app/Contents/Resources/";
	install -m 755 -s ../../tmp/qemu/qemu-img "../$(prefix)/Q.app/Contents/MacOS/";
	install -m 755 -s qemu-control "../$(prefix)/Q.app/Contents/MacOS/";
	sed 's/QEMU_VERSION/$(VERSION)/;s/QKJU_VERSION/$(QVERSION)/' Info.plist > "../$(prefix)/Q.app/Contents/Info.plist";
	echo "APPLQKJU" > "../$(prefix)/Q.app/Contents/PkgInfo";
	cp -R Resources/* "../$(prefix)/Q.app/Contents/Resources/";
	install -m 644 ../../tmp/qemu/qemu-doc.html "../$(prefix)/Q.app/Contents/Resources/English.lproj/Q Help/html/";
	install -m 644 ../../tmp/qemu/qemu-tech.html "../$(prefix)/Q.app/Contents/Resources/English.lproj/Q Help/html/";

	for d in $(OPT_LANGUAGES); do \
		install -m 644 ../../tmp/qemu/qemu-doc.html "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/Q Help/html/"; \
		install -m 644 ../../tmp/qemu/qemu-tech.html "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/Q Help/html/"; \
		nibtool -d "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControl.strings" "../$(prefix)/Q.app/Contents/Resources/English.lproj/cocoaControl.nib" -W "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControl.nib"; \
		nibtool -d "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlDiskImage.strings" "../$(prefix)/Q.app/Contents/Resources/English.lproj/cocoaControlDiskImage.nib" -W "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlDiskImage.nib"; \
		nibtool -d "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlEditPC.strings" "../$(prefix)/Q.app/Contents/Resources/English.lproj/cocoaControlEditPC.nib" -W "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlEditPC.nib"; \
		nibtool -d "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlNewPCAssistant.strings" "../$(prefix)/Q.app/Contents/Resources/English.lproj/cocoaControlNewPCAssistant.nib" -W "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlNewPCAssistant.nib"; \
		nibtool -d "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlPreferences.strings" "../$(prefix)/Q.app/Contents/Resources/English.lproj/cocoaControlPreferences.nib" -W "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaControlPreferences.nib"; \
		nibtool -d "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaDownload.strings" "../$(prefix)/Q.app/Contents/Resources/English.lproj/cocoaDownload.nib" -W "../$(prefix)/Q.app/Contents/Resources/"$$d".lproj/cocoaDownload.nib"; \
        done

	for d in $(TARGET_DIRS); do \
		mkdir -p "../$(prefix)/Q.app/Contents/MacOS//"$$d".app/Contents/MacOS/"; \
		mkdir -p "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		cp -R ../../tmp/qemu/host-cocoa/Resources/* "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/"; \
		echo "APPLQEMU" > "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/PkgInfo"; \
		sed 's/QEMU_TARGET/'$$d'/;s/QEMU_VERSION/$(VERSION)/;s/QKJU_VERSION/$(QVERSION)/' ../../tmp/qemu/host-cocoa/Info.plist > "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Info.plist"; \
		case "$$d" in \
			i386-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			x86_64-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-x86_64 "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			ppc-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-ppc "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d; \
				install -m 644 ../../tmp/qemu/pc-bios/ppc_rom.bin "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/" \
			;; \
			sparc-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-sparc "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			mips-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-mips "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			arm-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-arm "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
		esac; \
		install -m 644 ../../tmp/qemu/pc-bios/bios.bin "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/vgabios.bin "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/vgabios-cirrus.bin "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/video.x "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/linux_boot.bin "../$(prefix)/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		done

# generate OS X .app Packages and install it to /applications
install:
	rm -rf "/Applications/Q.app";
	mkdir -p "/Applications/Q.app/Contents/MacOS/";
	mkdir -p "/Applications/Q.app/Contents/Resources/English.lproj/Q Help/";
	install -m 755 -s ../../tmp/qemu/qemu-img "/Applications/Q.app/Contents/MacOS/";
	install -m 755 -s qemu-control "/Applications/Q.app/Contents/MacOS/";
	sed 's/QEMU_VERSION/$(VERSION)/;s/QKJU_VERSION/$(QVERSION)/' Info.plist > "/Applications/Q.app/Contents/Info.plist";
	echo "APPLQKJU" > "/Applications/Q.app/Contents/PkgInfo";
	cp -R Resources/* "/Applications/Q.app/Contents/Resources/";
	install -m 644 ../../tmp/qemu/qemu-doc.html "/Applications/Q.app/Contents/Resources/English.lproj/Q Help/html/";
	install -m 644 ../../tmp/qemu/qemu-tech.html "/Applications/Q.app/Contents/Resources/English.lproj/Q Help/html/";

	for d in $(TARGET_DIRS); do \
		mkdir -p "/Applications/Q.app/Contents/MacOS//"$$d".app/Contents/MacOS/"; \
		mkdir -p "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		cp -R ../../tmp/qemu/host-cocoa/Resources/* "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/"; \
		echo "APPLQEMU" > "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/PkgInfo"; \
		sed 's/QEMU_TARGET/'$$d'/;s/QEMU_VERSION/$(VERSION)/;s/QKJU_VERSION/$(QVERSION)/' ../../tmp/qemu/host-cocoa/Info.plist > "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Info.plist"; \
		case "$$d" in \
			i386-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			x86_64-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-x86_64 "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			ppc-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-ppc "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d; \
				install -m 644 ../../tmp/qemu/pc-bios/ppc_rom.bin "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/" \
			;; \
			sparc-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-sparc "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			mips-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-mips "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
			arm-softmmu) \
				install -m 755 -s ../../tmp/qemu/$$d/qemu-system-arm "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/MacOS/"$$d \
			;; \
		esac; \
		install -m 644 ../../tmp/qemu/pc-bios/bios.bin "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/vgabios.bin "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/vgabios-cirrus.bin "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/video.x "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		install -m 644 ../../tmp/qemu/pc-bios/linux_boot.bin "/Applications/Q.app/Contents/MacOS/"$$d".app/Contents/Resources/qemu/"; \
		done
