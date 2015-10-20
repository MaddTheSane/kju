/*
 * Q Document Edit VM Controller
 * 
 * Copyright (c) 2007 - 2008 Mike Kronenberg
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "QDocumentEditVMController.h"

#import "QDocument.h"
#import "QDocumentOpenGLView.h"

#import "Q-Swift.h"

@implementation QDocumentEditVMController
{
	// Document
	__weak QDocument *document; //weak
	NSMutableDictionary *VM;
	
	// niccount
	int niccount;
}
@synthesize editVMPanel;
@synthesize editVMPanelButtonOK;
@synthesize editVMPanelButtonCancel;
@synthesize grabless;
@synthesize qDrivers;
@synthesize pauseWhileInactive;
@synthesize smb;
@synthesize M;
@synthesize cpu;
@synthesize smp;
@synthesize m;
@synthesize vga;
@synthesize pcspk;
@synthesize adlib;
@synthesize sb16;
@synthesize es1370;
@synthesize nicModel1;
@synthesize nicModel2;
@synthesize fda;
@synthesize cdrom;
@synthesize hda;
@synthesize boot;
@synthesize hdb;
@synthesize hdc;
@synthesize hdd;
@synthesize localtime;
@synthesize win2kHack;
@synthesize kernel;
@synthesize append;
@synthesize initrd;
@synthesize onlyOptional;
@synthesize optional;

- (void)showEditVMPanel:(QDocument*)sender
{
	Q_DEBUG(@"showEditVMPanel");


	if (!editVMPanel.visible) {
	
		// populate panel
		
		// reset and populate Panel
		document = sender;
		VM = [document configuration];
		[self resetPanel:self];
		[self populatePanel:self];
		
		// open sheet
		[NSApp beginSheet:editVMPanel
			modalForWindow:document.screenView.window
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];
	}
}

- (IBAction)OK:(id)sender
{
	Q_DEBUG(@"OK");

	[NSApp endSheet:editVMPanel];
	[editVMPanel orderOut:self];

}

- (IBAction)cancel:(id)sender
{
	Q_DEBUG(@"cancel");

	[NSApp endSheet:editVMPanel];
	[editVMPanel orderOut:self];
}

- (void) resetPanel:(id)sender
{
	Q_DEBUG(@"resetPanel");

	NSString *diskImageFile;
	NSDirectoryEnumerator *directoryEnumerator;
	NSArray *fileTypes;
	
	fileTypes = [[NSArray alloc] initWithArrayOfAllowedFileTypes];
	
	// Tab 1
	// -tablet
	grabless.state = NSOffState;

	// qdrivers
	qDrivers.state = NSOffState;

	// pause while inactive
	pauseWhileInactive.state = NSOffState;

	// -smb
	while(![smb itemAtIndex:2].separatorItem)
		[smb removeItemAtIndex:2];
	[smb selectItemAtIndex:0];
	
	// Tab 2
	[M selectItemAtIndex:0];
	[cpu selectItemAtIndex:0];
	smp.stringValue = @"1";
	m.stringValue = @"128"; // 128
	[vga selectItemAtIndex:0];
	pcspk.state = NSOffState;
	adlib.state = NSOffState;
	sb16.state = NSOffState;
	es1370.state = NSOffState;
	[nicModel1 selectItemAtIndex:0];
	[nicModel2 selectItemAtIndex:0];

	// -fda
	while(![fda itemAtIndex:1].separatorItem)
		[fda removeItemAtIndex:1];
	[fda selectItemAtIndex:0];

	// -cdrom
	while(![cdrom itemAtIndex:2].separatorItem)
		[cdrom removeItemAtIndex:2];
	[cdrom selectItemAtIndex:0];


	// cleanup -hdb and add Harddisks located in Package to Menu
	while(![hda itemAtIndex:1].separatorItem)
		[hda removeItemAtIndex:1];
	if (hda.numberOfItems > 8) {
		while(![hda itemAtIndex:2].separatorItem)
			[hda removeItemAtIndex:2];
	} else {
		[hda.menu insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[VM[@"Temporary"][@"URL"] path]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:diskImageFile.pathExtension])
			[hda insertItemWithTitle:diskImageFile.lastPathComponent atIndex:2];
	}
	if([hda itemAtIndex:2].separatorItem)
		[hda removeItemAtIndex:2];
	[hda selectItemAtIndex:0];

	// -boot
	[boot selectItemAtIndex:2]; // c


	
	// Tab 3


	
	// Tab 4
	// cleanup -hdb and add Harddisks located in Package to Menu
	while(![hdb itemAtIndex:1].separatorItem)
		[hdb removeItemAtIndex:1];
	if (hdb.numberOfItems > 8) {
		while(![hdb itemAtIndex:2].separatorItem)
			[hdb removeItemAtIndex:2];
	} else {
		[hdb.menu insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[VM[@"Temporary"][@"URL"] path]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:diskImageFile.pathExtension])
			[hdb insertItemWithTitle:diskImageFile.lastPathComponent atIndex:2];
	}
	if([hdb itemAtIndex:2].separatorItem)
		[hdb removeItemAtIndex:2];
	[hdb selectItemAtIndex:0];

	// cleanup -hdc and add Harddisks located in Package to Menu
	while(![hdc itemAtIndex:1].separatorItem)
		[hdc removeItemAtIndex:1];
	if (hdc.numberOfItems > 8) {
		while(![hdc itemAtIndex:2].separatorItem)
			[hdc removeItemAtIndex:2];
	} else {
		[hdc.menu insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[VM[@"Temporary"][@"URL"] path]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:diskImageFile.pathExtension])
			[hdc insertItemWithTitle:diskImageFile.lastPathComponent atIndex:2];
	}
	if([hdc itemAtIndex:2].separatorItem)
		[hdc removeItemAtIndex:2];
	[hdc selectItemAtIndex:0];

	// cleanup -hdd and add Harddisks located in Package to Menu
	while(![hdd itemAtIndex:1].separatorItem)
		[hdd removeItemAtIndex:1];
	if (hdd.numberOfItems > 8) {
		while(![hdd itemAtIndex:2].separatorItem)
			[hdd removeItemAtIndex:2];
	} else {
		[hdd.menu insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[VM[@"Temporary"][@"URL"] path]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:diskImageFile.pathExtension])
			[hdd insertItemWithTitle:diskImageFile.lastPathComponent atIndex:2];
	}
	if([hdd itemAtIndex:2].separatorItem)
		[hdd removeItemAtIndex:2];
	[hdd selectItemAtIndex:0];

	// -localtime
	localtime.state = NSOffState;

	// -win2khack
	win2kHack.state = NSOffState;

	// kernel
	while(![kernel itemAtIndex:1].separatorItem)
		[kernel removeItemAtIndex:1];
	[kernel selectItemAtIndex:0];

	append.stringValue = @"";

	// initrd
	while(![initrd itemAtIndex:1].separatorItem)
		[initrd removeItemAtIndex:1];
	[initrd selectItemAtIndex:0];

	onlyOptional.state = NSOffState;
	optional.stringValue = @"";
}

- (void) setMachine:(QDocumentEditVMMachine)machine
{
	// here, we show the items available for this machine
}

- (BOOL)setOption:(NSString *)key withArgument:(NSString *)argument
{
	Q_DEBUG(@"setOption:%@ withArgument:%@", key, argument);

	// grabless (-usbdevice tablet)
	if ([key isEqual:@"-usbdevice"] && [argument isEqual:@"tablet"]) {
		grabless.state = NSOffState;
		return TRUE;
/*
	// TODO: see if we can add a second CD ROM with the drivers, else make floppy
	// Q Windows driver
	} else if ([key isEqual:@"-usb"] && [argument isEqual:@"tablet"]) {
		[grabless setState:NSOffState];
		return TRUE;
*/
	// -smb
	} else if ([key isEqual:@"-smb"]) {
        if ([argument isEqual:@"~/Desktop/Q Shared Files/"]) {
            [smb selectItemAtIndex:1];
        } else {
            [smb insertItemWithTitle:[NSString stringWithString:argument] atIndex:2];
            [smb selectItemAtIndex:2];
        }
		return TRUE;

	// TODO: add other machines
	// select machine
	} else if ([key isEqual:@"-M"]) {
        if ([argument isEqual:@"pc"]) {
            [M selectItemAtIndex:1];
			[self setMachine:QDocumentEditVMMachinePc];
        } else if ([argument isEqual:@"isapc"]) {
            [M selectItemAtIndex:2];
			[self setMachine:QDocumentEditVMMachineIsapc];
        }
		return TRUE;

	// TODO: if we have other machines, we must make shure the correct machine is selected
	// select cpu
	} else if ([key isEqual:@"-cpu"]) {
        if ([argument isEqual:@"qemu32"]) {
            [cpu selectItemAtIndex:0];
        } else if ([argument isEqual:@"486"]) {
            [cpu selectItemAtIndex:1];
        } else if ([argument isEqual:@"pentium"]) {
            [cpu selectItemAtIndex:2];
        } else if ([argument isEqual:@"pentium2"]) {
            [cpu selectItemAtIndex:3];
        } else if ([argument isEqual:@"pentium3"]) {
            [cpu selectItemAtIndex:4];
        }
		return TRUE;

	// smp
	} else if ([key isEqual:@"-smp"]) {
		smp.stringValue = argument;
		return TRUE;

	// m
	} else if ([key isEqual:@"-m"]) {
		m.stringValue = argument;
		return TRUE;		

	// graphicscards
	} else if ([key isEqual:@"-std-vga"]) {
		[vga selectItemAtIndex:1];
		return true;
	} else if ([key isEqual:@"-vmwarevga"]) {
		[vga selectItemAtIndex:2];
		return true;

	// soundcards
	} else if ([key isEqual:@"-soundhw"]) {
		if ([argument rangeOfString:@"pcspk"].location != NSNotFound)
			pcspk.state = NSOnState;
		if ([argument rangeOfString:@"adlib"].location != NSNotFound)
			adlib.state = NSOnState;
		if ([argument rangeOfString:@"sb16"].location != NSNotFound)
			sb16.state = NSOnState;
		if ([argument rangeOfString:@"es1370"].location != NSNotFound)
			es1370.state = NSOnState;
		return true;

	// networkcards
	} else if ([key isEqual:@"-net"]) {
		// we can only handle the first to nics with the gui
		niccount++;
		id nicModel;
		if (niccount == 1) {
			nicModel = nicModel1;
		} else if (niccount == 2) {
			nicModel = nicModel2;
		} else {
			return false;
		}
        if ([argument rangeOfString:@"i82551"].location != NSNotFound) {
            [nicModel selectItemAtIndex:1];
        } else if ([argument rangeOfString:@"i82557b"].location != NSNotFound) {
            [nicModel selectItemAtIndex:2];
        } else if ([argument rangeOfString:@"i82559er"].location != NSNotFound) {
            [nicModel selectItemAtIndex:3];
        } else if ([argument rangeOfString:@"ne2k_pci"].location != NSNotFound) {
            [nicModel selectItemAtIndex:4];
        } else if ([argument rangeOfString:@"ne2k_isa"].location != NSNotFound) {
            [nicModel selectItemAtIndex:5];
        } else if ([argument rangeOfString:@"rtl8139"].location != NSNotFound) {
            [nicModel selectItemAtIndex:6];
        } else if ([argument rangeOfString:@"smc91c111"].location != NSNotFound) {
            [nicModel selectItemAtIndex:7];
        } else if ([argument rangeOfString:@"lance"].location != NSNotFound) {
            [nicModel selectItemAtIndex:8];
        } else if ([argument rangeOfString:@"mcf_fec"].location != NSNotFound) {
            [nicModel selectItemAtIndex:9];
        } else if ([argument rangeOfString:@"nic"].location != NSNotFound) { // default is rtl8139
            [nicModel selectItemAtIndex:6];
		} else if ([argument isEqual:@"user"]) { // user networking
            //Todo: what should we do
		}
		return TRUE;

	// fda
	} else if ([key isEqual:@"-fda"]) {
		[fda insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
		[fda selectItemAtIndex:1];
		return TRUE;

	// cdrom
	} else if ([key isEqual:@"-cdrom"]) {
		if ([argument isEqual:@"/dev/cdrom"]) {
			[cdrom selectItemAtIndex:1];
		} else {
			[cdrom insertItemWithTitle:[NSString stringWithString:argument] atIndex:2];
			[cdrom selectItemAtIndex:2];
		}
		return TRUE;
	
	// hda
	} else if ([key isEqual:@"-hda"]) {
		if ([hda indexOfItemWithTitle:argument] > -1) {
			[hda selectItemWithTitle:argument];
		} else {
/* TODO: new Image
			int intResult;
			NSString *stringValue;
			NSScanner *scanner = [NSScanner scannerWithString: argument];
			
			if ([scanner scanString:@"createNew" intoString:&stringValue]) {
				[scanner scanInt:&intResult];
				customImagePopUpButtonTemp = hda;
				[self setCustomDIType:@"qcow" size:intResult];
			} else {*/
				[hda insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
				[hda selectItemAtIndex:1];
//			}
		}
		return TRUE;
	
	// hdb
	} else if ([key isEqual:@"-hdb"]) {
		 if ([hdb indexOfItemWithTitle:argument] > -1) {
			 [hdb selectItemWithTitle:argument];
		 } else {
			 [hdb insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
			 [hdb selectItemAtIndex:1];
		 }
		 return TRUE;

	// hdc
	} else if ([key isEqual:@"-hdc"]) {
		 if ([hdc indexOfItemWithTitle:argument] > -1) {
			 [hdc selectItemWithTitle:argument];
		 } else {
			 [hdc insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
			 [hdc selectItemAtIndex:1];
		 }
		 return TRUE;

	// hdd
	} else if ([key isEqual:@"-hdd"]) {
		 if ([hdd indexOfItemWithTitle:argument] > -1) {
			 [hdd selectItemWithTitle:argument];
		 } else {
			 [hdd insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
			 [hdd selectItemAtIndex:1];
		 }
		 return TRUE;

	// boot
	} else if ([key isEqual:@"-boot"]) {
        if ([argument isEqual:@"a"]) {
            [boot selectItemAtIndex:0];
        } else if ([argument isEqual:@"c"]) {
            [boot selectItemAtIndex:1];
        } else if ([argument isEqual:@"d"]) {
            [boot selectItemAtIndex:2];
        } else if ([argument isEqual:@"n"]) {
            [boot selectItemAtIndex:3];
        }
		return TRUE;

	// localtime
	} else if ([key isEqual:@"-localtime"]) {
		localtime.state = NSOnState;
		return true;

	// win2khack
	} else if ([key isEqual:@"-win2khack"]) {
		win2kHack.state = NSOnState;
		return true;

	// kernel
	} else if ([key isEqual:@"-kernel"]) {
		[kernel insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
		[kernel	selectItemAtIndex:1];
		return TRUE;

	// append
	} else if ([key isEqual:@"-append"]) {
		append.stringValue = argument;
		return TRUE;

	// initrd
	} else if ([key isEqual:@"-initrd"]) {
		[initrd insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
		[initrd	selectItemAtIndex:1];
		return TRUE;

	}
	return FALSE;
}

- (void) populatePanel:(id)sender
{
	Q_DEBUG(@"populatePanel:%@", sender);
	
	int i;
	NSMutableString *optionalArguments;
	NSString *key;
	
	niccount = 0;

	optionalArguments = [NSMutableString stringWithString:@""];
	key = nil;
	for (i = 0; i < [VM[@"Temporary"][@"explodedArguments"] count]; i++) {
		if ([VM[@"Temporary"][@"explodedArguments"][i] characterAtIndex:0] == '-') { // key
			if (key) { // store previous key
				if (![self setOption:key withArgument:@""]) {
					[optionalArguments appendFormat:@"%@ ", key];
				}
			}
			key = VM[@"Temporary"][@"explodedArguments"][i];
		} else { // argument
				if (![self setOption:key withArgument:VM[@"Temporary"][@"explodedArguments"][i]]) {
					[optionalArguments appendFormat:@"%@ ", key];
					[optionalArguments appendFormat:@"%@ ", VM[@"Temporary"][@"explodedArguments"][i]];
				}
			key = nil;
		}
	}
	if (key) { // store previous key
		if ([self setOption:key withArgument:VM[@"Temporary"][@"explodedArguments"][i]]) {
			[optionalArguments appendFormat:@"%@", key];
		}
	}
	
	// add unknown arguments to "optional"
	optional.stringValue = optionalArguments;	

}
@end
