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
#import "QQvmManager.h"


@implementation QDocumentEditVMController
- (void)showEditVMPanel:(id)sender
{
	Q_DEBUG(@"showEditVMPanel");


	if (![editVMPanel isVisible]) {
	
		// populate panel
		
		// reset and populate Panel
		document = (QDocument *)sender;
		VM = [document configuration];
		[self resetPanel:self];
		[self populatePanel:self];
		
		// open sheet
		[NSApp beginSheet:editVMPanel
			modalForWindow:[[document screenView] window]
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

- (NSPanel *) editVMPanel { return editVMPanel;}

- (void) resetPanel:(id)sender
{
	Q_DEBUG(@"resetPanel");
	
	// Tab 1
	[grabless setState:NSOffState];
	[qDrivers setState:NSOffState];
	[pauseWhileInactive setState:NSOffState];
	[smb selectItemAtIndex:0];
	
	// Tab 2
	[M selectItemAtIndex:0];
	[cpu selectItemAtIndex:0];
	[smp setStringValue:@"1"];
	[m setStringValue:@"128"]; // 128
	[vga selectItemAtIndex:0];
	[pcspk setState:NSOffState];
	[adlib setState:NSOffState];
	[sb16 setState:NSOffState];
	[es1370 setState:NSOffState];
	[nicModel1 selectItemAtIndex:0];
	[nicModel2 selectItemAtIndex:0];
	[fda selectItemAtIndex:0];
	[cdrom selectItemAtIndex:0];
	[hda selectItemAtIndex:0];
	[boot selectItemAtIndex:2]; // c
	
	// Tab 3
	
	// Tab 4
	[hdb selectItemAtIndex:0];
	[hdc selectItemAtIndex:0];
	[hdd selectItemAtIndex:0];
	[localtime setState:NSOffState];
	[win2kHack setState:NSOffState];
	[kernel selectItemAtIndex:0];
	[append setStringValue:@""];
	[initrd selectItemAtIndex:0];
	[onlyOptional setState:NSOffState];
	[optional setStringValue:@""];
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
		[grabless setState:NSOffState];
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
		[smp setStringValue:argument];
		return TRUE;
		
	// m
	} else if ([key isEqual:@"-m"]) {
		[m setStringValue:argument];
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
			[pcspk setState:NSOnState];
		if ([argument rangeOfString:@"adlib"].location != NSNotFound)
			[adlib setState:NSOnState];
		if ([argument rangeOfString:@"sb16"].location != NSNotFound)
			[sb16 setState:NSOnState];
		if ([argument rangeOfString:@"es1370"].location != NSNotFound)
			[es1370 setState:NSOnState];
		return true;
	
	// networkcards
	} else if ([key isEqual:@"-nic"]) {
		// we can only handle the first to nics with the gui
		niccount++;
		id nicModel;
		if (niccount == 1) {
			nicModel = nicModel1;
		} else if (niccount == 2) {
			nicModel = nicModel1;
		} else {
			return false;
		}
        if ([argument isEqual:@"i82551"]) {
            [nicModel selectItemAtIndex:1];
        } else if ([argument isEqual:@"i82557b"]) {
            [nicModel selectItemAtIndex:2];
        } else if ([argument isEqual:@"i82559er"]) {
            [nicModel selectItemAtIndex:3];
        } else if ([argument isEqual:@"ne2k_pci"]) {
            [nicModel selectItemAtIndex:4];
        } else if ([argument isEqual:@"ne2k_isa"]) {
            [nicModel selectItemAtIndex:5];
        } else if ([argument isEqual:@"rtl8139"]) {
            [nicModel selectItemAtIndex:6];
        } else if ([argument isEqual:@"smc91c111"]) {
            [nicModel selectItemAtIndex:7];
        } else if ([argument isEqual:@"lance"]) {
            [nicModel selectItemAtIndex:8];
        } else if ([argument isEqual:@"mcf_fec"]) {
            [nicModel selectItemAtIndex:9];
        }
		return TRUE;

	// fda
	// TODO:
	
	// cdrom
	// TODO:
	
	// hda
	// TODO:
	
	// hdb
	// TODO:
	
	// hdc
	// TODO:
	
	// hdd
	// TODO:
	
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
		[localtime setState:NSOnState];
		return true;
	
	// win2khack
	} else if ([key isEqual:@"-win2khack"]) {
		[win2kHack setState:NSOnState];
		return true;
	
	// kernel
	// TODO:
	
	// append
	} else if ([key isEqual:@"-append"]) {
		[append setStringValue:argument];
		return TRUE;
	
	// initrd
	// TODO:

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
	for (i = 0; i < [[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] count]; i++) {
		if ([[[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i] characterAtIndex:0] == '-') { // key
			if (key) { // store previous key
				if (![self setOption:key withArgument:@""]) {
					[optionalArguments appendFormat:@"%@ ", key];
				}
			}
			key = [[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i];
		} else { // argument
				if (![self setOption:key withArgument:[[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i]]) {
					[optionalArguments appendFormat:@"%@ ", key];
					[optionalArguments appendFormat:@"%@ ", [[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i]];
				}
			key = nil;
		}
	}
	if (key) { // store previous key
		if ([self setOption:key withArgument:[[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i]]) {
			[optionalArguments appendFormat:@"%@", key];
		}
	}
	
	// add unknown arguments to "optional"
	[optional setStringValue:optionalArguments];	

}
@end
