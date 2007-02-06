/*
 * QEMU Cocoa Control PC Editor Window
 * 
 * Copyright (c) 2005 - 2007 Mike Kronenberg
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

#import "cocoaControlEditPC.h"

//#import "AppleHelp.h"
#import "Carbon/Carbon.h"

#import "cocoaControlController.h"
#import "cocoaControlDiskImage.h"

@implementation cocoaControlEditPC
- (id) init
{
//	NSLog(@"cocoaControlEditPC: init");

	if ((self = [super init])) {
		userDefaults = [NSUserDefaults standardUserDefaults];
		fileTypes = [[NSArray arrayWithObjects:@"qcow2", @"qcow", @"raw", @"cow", @"vmdk", @"cloop", @"img", @"iso", @"dsk", @"dmg", @"cdr", @"toast", @"flp", @"fs", nil] retain];

		return self;
	}

	return nil;
}

- (void) dealloc
{
//	NSLog(@"cocoaControlEditPC: dealloc");

	[fileTypes release];
	[super dealloc];
}

- (NSPanel *) editPCPanel
{
//	NSLog(@"cocoaControlEditPC: editPCPanel");

	return editPCPanel;
}

- (void) viewGeneral:(id)sender
{
//	NSLog(@"cocoaControlEditPC: viewGeneral");

	if ([viewHardware superview]) {
		[viewHardware retain];
		[viewHardware removeFromSuperview];
	}
	if ([viewAdvanced superview]) {
		[viewAdvanced retain];
		[viewAdvanced removeFromSuperview];
	}
		if ([viewNetwork superview]) {
        [viewNetwork retain];
        [viewNetwork removeFromSuperview];
    }
	
	[editPCPanel setTitle:[NSString stringWithFormat: NSLocalizedStringFromTable(@"viewGeneral:title", @"Localizable", @"cocoaControlEditPC"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
	[editPCPanel setFrame:NSMakeRect(
		[editPCPanel frame].origin.x,
		[editPCPanel frame].origin.y + [editPCPanel frame].size.height - [viewGeneral bounds].size.height - 140,
		[editPCPanel frame].size.width,
		[viewGeneral bounds].size.height + 140
	) display:YES animate:YES];
	
	[[editPCPanel contentView] addSubview:viewGeneral];
	[viewGeneral setFrameOrigin:NSMakePoint(0,60)];
}

- (void) viewHardware:(id)sender
{
//	NSLog(@"cocoaControlEditPC: viewHardware");

	if ([viewGeneral superview]) {
		[viewGeneral retain];
		[viewGeneral removeFromSuperview];
	}
	if ([viewAdvanced superview]) {
		[viewAdvanced retain];
		[viewAdvanced removeFromSuperview];
	}
		if ([viewNetwork superview]) {
        [viewNetwork retain];
        [viewNetwork removeFromSuperview];
    }
		
	[editPCPanel setTitle:[NSString stringWithFormat: NSLocalizedStringFromTable(@"viewHardware:title", @"Localizable", @"cocoaControlEditPC"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
	[editPCPanel setFrame:NSMakeRect(
		[editPCPanel frame].origin.x,
		[editPCPanel frame].origin.y + [editPCPanel frame].size.height - [viewHardware bounds].size.height - 140,
		[editPCPanel frame].size.width,
		[viewHardware bounds].size.height + 140
	) display:YES animate:YES];
	
	[[editPCPanel contentView] addSubview:viewHardware];
	[viewHardware setFrameOrigin:NSMakePoint(0,60)];
}

- (void) viewAdvanced:(id)sender
{
//	NSLog(@"cocoaControlEditPC: viewAdvanced");

	if ([viewHardware superview]) {
		[viewHardware retain];
		[viewHardware removeFromSuperview];
	}
	if ([viewGeneral superview]) {
		[viewGeneral retain];
		[viewGeneral removeFromSuperview];
	}
	if ([viewNetwork superview]) {
        [viewNetwork retain];
        [viewNetwork removeFromSuperview];
    }
		
	[editPCPanel setTitle:[NSString stringWithFormat: NSLocalizedStringFromTable(@"viewAdvanced:title", @"Localizable", @"cocoaControlEditPC"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
	[editPCPanel setFrame:NSMakeRect(
		[editPCPanel frame].origin.x,
		[editPCPanel frame].origin.y + [editPCPanel frame].size.height - [viewAdvanced bounds].size.height - 140,
		[editPCPanel frame].size.width,
		[viewAdvanced bounds].size.height + 140
	) display:YES animate:YES];
	
	[[editPCPanel contentView] addSubview:viewAdvanced];
	[viewAdvanced setFrameOrigin:NSMakePoint(0,60)];
}

- (void) viewNetwork:(id)sender
{
    if ([viewHardware superview]) {
        [viewHardware retain];
        [viewHardware removeFromSuperview];
    }
    if ([viewGeneral superview]) {
        [viewGeneral retain];
        [viewGeneral removeFromSuperview];
    }
    if ([viewAdvanced superview]) {
        [viewAdvanced retain];
        [viewAdvanced removeFromSuperview];
    }
        
    [editPCPanel setTitle:[NSString stringWithFormat: NSLocalizedStringFromTable(@"viewNetwork:title", @"Localizable", @"cocoaControlEditPC"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
    [editPCPanel setFrame:NSMakeRect(
        [editPCPanel frame].origin.x,
        [editPCPanel frame].origin.y + [editPCPanel frame].size.height - [viewNetwork bounds].size.height - 140,
        [editPCPanel frame].size.width,
        [viewNetwork bounds].size.height + 140
    ) display:YES animate:YES];
    
    [[editPCPanel contentView] addSubview:viewNetwork];
    [viewNetwork setFrameOrigin:NSMakePoint(0,60)];
}

- (void) setOption:(id)option argument:(id)argument
{
//	NSLog(@"cocoaControlEditPC: setOption:%@ argument:%@", option, argument);
			
	/* -m */
	if ([option isEqual:@"-m"]) {
		[textFieldRAM setStringValue:[NSString stringWithString:argument]];
	
	/* -std-vga */
	} else if ([option isEqual:@"-std-vga"]) {
		[popUpButtonVGA selectItemAtIndex:1];
	
	/* -soundhw */
	} else if ([option isEqual:@"-soundhw"]) {
		if ([argument rangeOfString:@"adlib" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			[buttonEnableAdlib setState:NSOnState];
		}
		if ([argument rangeOfString:@"sb16" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			[buttonEnableSB16 setState:NSOnState];
		}
		if ([argument rangeOfString:@"es1370" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			[buttonEnableES1370 setState:NSOnState];
		}
		
		
	/* -usbdevice */
	} else if ([option isEqual:@"-usbdevice"]) {
		if ([argument isEqual:@"tablet"]) {
			[buttonEnableUSBTablet setState:NSOnState];
		}

	/* -localtime */
	} else if ([option isEqual:@"-localtime"]) {
		[buttonLocaltime setState:NSOnState];
	
	/* -net */
	} else if ([option isEqual:@"-net"]) {
		if ([argument isEqual:@"nic"]) {
			[buttonNetNicNe2000 setState:NSOnState];
		} else if ([argument isEqual:@"nic,model=rtl8139"]) {
			[buttonNetNicRtl8139 setState:NSOnState];
		} else if ([argument isEqual:@"nic,model=pcnet"]) {
			[buttonNetNicPcnet setState:NSOnState];
		}
		if ([argument isEqual:@"user"]) {
			[buttonNetUser setState:NSOnState];
		}
	
	/* -smb */
	} else if ([option isEqual:@"-smb"]) {
		if ([argument isEqual:@"~/Desktop/Q Shared Files/"]) {
			[popUpButtonSmbFilesharing selectItemAtIndex:1];
		} else {
			[popUpButtonSmbFilesharing insertItemWithTitle:[NSString stringWithString:argument] atIndex:2];
			[popUpButtonSmbFilesharing selectItemAtIndex:2];
		}
	
	/* -fda */
	} else if ([option isEqual:@"-fda"]) {
		[popUpButtonFda insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
		[popUpButtonFda selectItemAtIndex:1];

	/* -hda */
	} else if ([option isEqual:@"-hda"]) {
		if ([popUpButtonHda indexOfItemWithTitle:argument]	 > -1) {
			[popUpButtonHda selectItemWithTitle:argument];
		} else {
			int intResult;
			NSString *stringValue;
			NSScanner *scanner = [NSScanner scannerWithString: argument];
			
			if ([scanner scanString:@"createNew" intoString:&stringValue]) {
				[scanner scanInt:&intResult];
				customImagePopUpButtonTemp = popUpButtonHda;
				[self setCustomDIType:@"qcow2" size:intResult];
			} else {
				[popUpButtonHda insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
				[popUpButtonHda selectItemAtIndex:1];
			}
		}

	/* -hdb */
	} else if ([option isEqual:@"-hdb"]) {
		 if ([popUpButtonHdb indexOfItemWithTitle:argument]	 > -1) {
			 [popUpButtonHdb selectItemWithTitle:argument];
		 } else {
			 [popUpButtonHdb insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
			 [popUpButtonHdb selectItemAtIndex:1];
		 }

	/* -hdc */
	} else if ([option isEqual:@"-hdc"]) {
		 if ([popUpButtonHdc indexOfItemWithTitle:argument]	 > -1) {
			 [popUpButtonHdc selectItemWithTitle:argument];
		 } else {
			 [popUpButtonHdc insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
			 [popUpButtonHdc selectItemAtIndex:1];
		 }

	/* -hdd */
	} else if ([option isEqual:@"-hdd"]) {
		 if ([popUpButtonHdd indexOfItemWithTitle:argument]	 > -1) {
			 [popUpButtonHdd selectItemWithTitle:argument];
		 } else {
			 [popUpButtonHdd insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
			 [popUpButtonHdd selectItemAtIndex:1];
		 }
		 
	/* -cdrom */
	} else if ([option isEqual:@"-cdrom"]) {
		if ([argument isEqual:@"/dev/cdrom"]) {
			[popUpButtonCdrom selectItemAtIndex:1];
		} else {
			[popUpButtonCdrom insertItemWithTitle:[NSString stringWithString:argument] atIndex:2];
			[popUpButtonCdrom selectItemAtIndex:2];
		}
	
	/* -boot */
	} else if ([option isEqual:@"-boot"]) {
		switch ([argument characterAtIndex:0]) {
			case 'a':
				[popUpButtonBoot selectItemAtIndex:0];
				break;
			case 'd':
				[popUpButtonBoot selectItemAtIndex:2];
				break;
			default:
				[popUpButtonBoot selectItemAtIndex:1];
				break;
		}
		
	/* -win2k-hack */
	} else if ([option isEqual:@"-win2k-hack"]) {
		[buttonWin2kHack setState:NSOnState];
	
	/* -kernel */
	} else if ([option isEqual:@"-kernel"]) {
		[popUpButtonKernel insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
		[popUpButtonKernel selectItemAtIndex:1];

	/* -append */
	} else if ([option isEqual:@"-append"]) {
		[textFieldAppend setStringValue:[NSString stringWithString:argument]];
			
	/* -initrd */
	} else if ([option isEqual:@"-initrd"]) {
		[popUpButtonInitrd insertItemWithTitle:[NSString stringWithString:argument] atIndex:1];
		[popUpButtonInitrd selectItemAtIndex:1];
    
    /* -redir */
    } else if ([option isEqual:@"-redir"]) {
        // we do not have to do anything about it here, because the information is already saved in the configuration.plist		
	/* -M */
	} else if ([option isEqual:@"-M"]) {
	
	/* free Arguments */
	} else {
		[textFieldArguments setStringValue:[[textFieldArguments stringValue] stringByAppendingString:[NSString stringWithFormat:@" %@ %@", option, argument]]];
	}
}

- (void) prepareEditPCPanel:(NSMutableDictionary *)aPC newPC:(BOOL)newPC sender:(id)sender
{
//	NSLog(@"cocoaControlEditPC: prepareEditPCPanel");

	thisPC = aPC;
	qSender = sender;
	[thisPC retain];
	
	/* prepare panel */
	[self viewGeneral:self];
	[[editPCPanel toolbar] setSelectedItemIdentifier:@"general"];
	
	/* Name */
	[textFieldName setTextColor:[NSColor blackColor]];
	[textFieldName setStringValue: [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];
	
	/* WMStopWhenInactive */
	if ([[thisPC objectForKey:@"Temporary"] objectForKey:@"WMStopWhenInactive"]) {
		[buttonWMStopWhenInactive setState:NSOnState];
	} else {
		[buttonWMStopWhenInactive setState:NSOffState];
	}
	
	/* Q Windows Drivers */
	if ([[thisPC objectForKey:@"Temporary"] objectForKey:@"QWinDrivers"]) {
		[buttonQWinDrivers setState:NSOnState];
	} else {
		[buttonQWinDrivers setState:NSOffState];
	}

	/* Platform */
	if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"x86"]) {
		[popUpButtonCPU selectItemAtIndex:0];
	} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"x86-64"]) {
		[popUpButtonCPU selectItemAtIndex:1];
	} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"PowerPC"] && [[[thisPC objectForKey:@"Temporary"] objectForKey:@"-M"] isEqual:@"prep"]) {
		[popUpButtonCPU selectItemAtIndex:3];
	} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"PowerPC"]) {
		[popUpButtonCPU selectItemAtIndex:2];
	} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"SPARC"]) {
		[popUpButtonCPU selectItemAtIndex:4];
	} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"MIPS"]) {
		[popUpButtonCPU selectItemAtIndex:5];
	} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"ARM"]) {
		[popUpButtonCPU selectItemAtIndex:6];
	}
	
	/* reset Textfields */
	[textFieldAppend setStringValue:@""];
	
	/* reset Buttons */
	[popUpButtonVGA selectItemAtIndex:0];
	[buttonEnableAdlib setState:NSOffState];
	[buttonEnableSB16 setState:NSOffState];
	[buttonEnableES1370 setState:NSOffState];
	[buttonEnableUSBTablet setState:NSOffState];
	[buttonLocaltime setState:NSOffState];
	[buttonNetNicNe2000 setState:NSOffState];
	[buttonNetNicRtl8139 setState:NSOffState];
	[buttonNetNicPcnet setState:NSOffState];
	[buttonNetUser setState:NSOffState];
	[buttonWin2kHack setState:NSOffState];
	[popUpButtonBoot selectItemAtIndex:1];
	
	/* cleanup -smb */
	while(![[popUpButtonSmbFilesharing itemAtIndex:2] isSeparatorItem])
		[popUpButtonSmbFilesharing removeItemAtIndex:2];
	[popUpButtonSmbFilesharing selectItemAtIndex:0];
	
	/* cleanup -fda */
	while(![[popUpButtonFda itemAtIndex:1] isSeparatorItem])
		[popUpButtonFda removeItemAtIndex:1];
	[popUpButtonFda selectItemAtIndex:0];
	
	NSString *diskImageFile;
	NSDirectoryEnumerator *directoryEnumerator;
	
	/* cleanup -hda and add Harddisks located in Package to Menu */
	while(![[popUpButtonHda itemAtIndex:1] isSeparatorItem])
		[popUpButtonHda removeItemAtIndex:1];
	if ([popUpButtonHda numberOfItems] > 8) {
		while(![[popUpButtonHda itemAtIndex:2] isSeparatorItem])
			[popUpButtonHda removeItemAtIndex:2];
	} else {
		[[popUpButtonHda menu] insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:[diskImageFile pathExtension]])
			[popUpButtonHda insertItemWithTitle:[diskImageFile lastPathComponent] atIndex:2];
	}
	if([[popUpButtonHda itemAtIndex:2] isSeparatorItem])
		[popUpButtonHda removeItemAtIndex:2];
	[popUpButtonHda selectItemAtIndex:4];
	
	/* cleanup -hdb and add Harddisks located in Package to Menu */
	while(![[popUpButtonHdb itemAtIndex:1] isSeparatorItem])
		[popUpButtonHdb removeItemAtIndex:1];
	if ([popUpButtonHdb numberOfItems] > 8) {
		while(![[popUpButtonHdb itemAtIndex:2] isSeparatorItem])
			[popUpButtonHdb removeItemAtIndex:2];
	} else {
		[[popUpButtonHdb menu] insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:[diskImageFile pathExtension]])
			[popUpButtonHdb insertItemWithTitle:[diskImageFile lastPathComponent] atIndex:2];
	}
	if([[popUpButtonHdb itemAtIndex:2] isSeparatorItem])
		[popUpButtonHdb removeItemAtIndex:2];
	[popUpButtonHdb selectItemAtIndex:0];
	
	/* cleanup -hdc and add Harddisks located in Package to Menu */
	while(![[popUpButtonHdc itemAtIndex:1] isSeparatorItem])
		[popUpButtonHdc removeItemAtIndex:1];
	if ([popUpButtonHdc numberOfItems] > 8) {
		while(![[popUpButtonHdc itemAtIndex:2] isSeparatorItem])
			[popUpButtonHdc removeItemAtIndex:2];
	} else {
		[[popUpButtonHdc menu] insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:[diskImageFile pathExtension]])
			[popUpButtonHdc insertItemWithTitle:[diskImageFile lastPathComponent] atIndex:2];
	}
	if([[popUpButtonHdc itemAtIndex:2] isSeparatorItem])
		[popUpButtonHdc removeItemAtIndex:2];
	[popUpButtonHdc selectItemAtIndex:0];
	
	/* cleanup -hdd and add Harddisks located in Package to Menu */
	while(![[popUpButtonHdd itemAtIndex:1] isSeparatorItem])
		[popUpButtonHdd removeItemAtIndex:1];
	if ([popUpButtonHdd numberOfItems] > 8) {
		while(![[popUpButtonHdd itemAtIndex:2] isSeparatorItem])
			[popUpButtonHdd removeItemAtIndex:2];
	} else {
		[[popUpButtonHdd menu] insertItem:[NSMenuItem separatorItem] atIndex:2];
	}
	directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]];
	while ((diskImageFile = [directoryEnumerator nextObject])) {
		if ([fileTypes containsObject:[diskImageFile pathExtension]])
			[popUpButtonHdd insertItemWithTitle:[diskImageFile lastPathComponent] atIndex:2];
	}
	if([[popUpButtonHdd itemAtIndex:2] isSeparatorItem])
		[popUpButtonHdd removeItemAtIndex:2];
	[popUpButtonHdd selectItemAtIndex:0];
		
	/* cleanup -cdrom */
	while(![[popUpButtonCdrom itemAtIndex:2] isSeparatorItem])
		[popUpButtonCdrom removeItemAtIndex:2];
	[popUpButtonCdrom selectItemAtIndex:0];
	
	/* cleanup -kernel */
	while(![[popUpButtonKernel itemAtIndex:1] isSeparatorItem])
		[popUpButtonKernel removeItemAtIndex:1];
	[popUpButtonKernel selectItemAtIndex:0];
	
	/* cleanup -initrd */
	while(![[popUpButtonInitrd itemAtIndex:1] isSeparatorItem])
		[popUpButtonInitrd removeItemAtIndex:1];
	[popUpButtonInitrd selectItemAtIndex:0];
	
	/* cleanup free qemu Arguments */
	[textFieldArguments setStringValue:@""];
	
    /* init firewall configuration */
	[self initFirewallSettings];
	
	/* Arguments of thisPC */
	NSArray *array = [[thisPC objectForKey:@"Arguments"] componentsSeparatedByString:@" "];
	NSMutableString *option = [[NSMutableString alloc] initWithString:@""];
	NSMutableString *argument = [[NSMutableString alloc] init];
	int i;
	for (i = 0; i < [array count]; i++) {
		if ([[array objectAtIndex:i] cString][0] != '-') { //Teil eines Arguments
			[argument appendFormat:[NSString stringWithFormat:@" %@", [array objectAtIndex:i]]];
		} else {
			if ([option length] > 0) {
				if ([argument isEqual:@""]) {
					[self setOption:option argument:@""];
				} else {
					[self setOption:option argument:[argument substringFromIndex:1]];
				}
			}
			[option setString:[array objectAtIndex:i]];
			[argument setString:@""];
		}
	}
	if ([argument isEqual:@""]) {
		[self setOption:option argument:@""];
	} else {
		[self setOption:option argument:[argument substringFromIndex:1]];
	}
	
	if (newPC) {
		[buttonOk setTitle: NSLocalizedStringFromTable(@"prepareEditPCPanel:newPC", @"Localizable", @"cocoaControlEditPC")];
	} else {
		[buttonOk setTitle: NSLocalizedStringFromTable(@"prepareEditPCPanel:updatePC", @"Localizable", @"cocoaControlEditPC")];
	}
}

-(void) awakeFromNib
{
//	NSLog(@"cocoaControlEditPC: awakeFromNib");

	NSToolbar *editPCPanelToolbar = [[[NSToolbar alloc] initWithIdentifier: @"editPCPanelToolbarIdentifier"] autorelease];
	[editPCPanelToolbar setAllowsUserCustomization: NO]; //allow customisation
	[editPCPanelToolbar setAutosavesConfiguration: NO]; //autosave changes
	[editPCPanelToolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel]; //what is shown
	[editPCPanelToolbar setSizeMode:NSToolbarSizeModeRegular]; //default Toolbar Size
	[editPCPanelToolbar setDelegate: self]; // We are the delegate
	[editPCPanel setToolbar: editPCPanelToolbar]; // Attach the toolbar to the document window
	[firewallPortTable setDelegate:self];
	[firewallPortTable setDataSource:self];
}

/* Toolbar Delegates*/
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
	if ([itemIdent isEqual: @"general"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:general", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:general", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:general", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setImage: [NSImage imageNamed: @"cocoa_tb_general.png"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( viewGeneral: )];
	} else if ([itemIdent isEqual: @"hardware"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:hardware", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:hardware", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:hardware", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setImage: [NSImage imageNamed: @"cocoa_tb_hardware.png"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( viewHardware: )];
	} else if ([itemIdent isEqual: @"advanced"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:advanced", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:advanced", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:advanced", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setImage: [NSImage imageNamed: @"cocoa_tb_advanced.png"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( viewAdvanced: )];
    } else if ([itemIdent isEqual: @"network"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:network", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:network", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:network", @"Localizable", @"cocoaControlEditPC")];
		[toolbarItem setImage: [NSImage imageNamed: @"cocoa_tb_network.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( viewNetwork: )];
	} else {
		toolbarItem = nil;
	}
	
	return toolbarItem;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
		@"general",
		@"hardware",
		@"network",
		@"advanced",
		nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		@"general",
		@"hardware",
		@"network",
		@"advanced",
		nil];
}

- (NSArray *) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
		@"general",
		@"hardware",
		@"network",
		@"advanced",
		nil];	
}

- (void) genericFolderSelectPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//	NSLog(@"cocoaControlEditPC: genericFolderSelectPanelDidEnd");

	/* hide Save Sheet */
	[ sheet orderOut:self ];
		
	/* smbFilesharing */
	if ([[contextInfo menu] isEqual:[popUpButtonSmbFilesharing menu]]) {
		if ( returnCode == NSOKButton ) {
			if (![[popUpButtonSmbFilesharing itemAtIndex:2] isSeparatorItem])
				[popUpButtonSmbFilesharing removeItemAtIndex:2];
			[popUpButtonSmbFilesharing insertItemWithTitle:[sheet filename] atIndex:2];
			[popUpButtonSmbFilesharing selectItemAtIndex:2];
		} else {
			[popUpButtonSmbFilesharing selectItemAtIndex:0];
		}
	}
}

- (IBAction) genericFolderSelectPanel:(id)sender
{
//	NSLog(@"cocoaControlEditPC: genericFolderSelectPanel");

	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel beginSheetForDirectory:nil
		file:nil
		types:nil
		modalForWindow:editPCPanel
		modalDelegate:self
		didEndSelector:@selector(genericFolderSelectPanelDidEnd:returnCode:contextInfo:)
		contextInfo:sender];
}

- (void) genericImageSelectPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//	NSLog(@"cocoaControlEditPC: genericImageSelectPanelDidEnd");

	/* hide Save Sheet */
	[ sheet orderOut:self ];
		
	/* -fda */
	if ([[contextInfo menu] isEqual:[popUpButtonFda menu]]) {
		if(returnCode == NSOKButton) {
			if (![[popUpButtonFda itemAtIndex:1] isSeparatorItem])
				[popUpButtonFda removeItemAtIndex:1];
			[popUpButtonFda insertItemWithTitle:[sheet filename] atIndex:1];
			[popUpButtonFda selectItemAtIndex:1];
		} else {
			[popUpButtonFda selectItemAtIndex:0];
		}
	/* -hda */
	} else if ([[contextInfo menu] isEqual:[popUpButtonHda menu]]) {
		if (returnCode == NSOKButton) {
			if (![[popUpButtonHda itemAtIndex:1] isSeparatorItem])
				[popUpButtonHda removeItemAtIndex:1];
			[popUpButtonHda insertItemWithTitle:[sheet filename] atIndex:1];
			[popUpButtonHda selectItemAtIndex:1];
		} else {
			[popUpButtonHda selectItemAtIndex:0];
		}
	/* -hdb */
	} else if ([[contextInfo menu] isEqual:[popUpButtonHdb menu]]) {
		if (returnCode == NSOKButton) {
			if (![[popUpButtonHdb itemAtIndex:1] isSeparatorItem])
				[popUpButtonHdb removeItemAtIndex:1];
			[popUpButtonHdb insertItemWithTitle:[sheet filename] atIndex:1];
			[popUpButtonHdb selectItemAtIndex:1];
		} else {
			[popUpButtonHdb selectItemAtIndex:0];
		}
	/* -hdc */
	} else if ([[contextInfo menu] isEqual:[popUpButtonHdc menu]]) {
		if (returnCode == NSOKButton) {
			if (![[popUpButtonHdc itemAtIndex:1] isSeparatorItem])
				[popUpButtonHdc removeItemAtIndex:1];
			[popUpButtonHdc insertItemWithTitle:[sheet filename] atIndex:1];
			[popUpButtonHdc selectItemAtIndex:1];
		} else {
			[popUpButtonHdc selectItemAtIndex:0];
		}
	/* -hdd */
	} else if ([[contextInfo menu] isEqual:[popUpButtonHdd menu]]) {
		if (returnCode == NSOKButton) {
			if (![[popUpButtonHdd itemAtIndex:1] isSeparatorItem])
				[popUpButtonHdd removeItemAtIndex:1];
			[popUpButtonHdd insertItemWithTitle:[sheet filename] atIndex:1];
			[popUpButtonHdd selectItemAtIndex:1];
		} else {
			[popUpButtonHdd selectItemAtIndex:0];
		}
	/* -cdrom */
	} else if ([[contextInfo menu] isEqual:[popUpButtonCdrom menu]]) {
		if (returnCode == NSOKButton) {
			if (![[popUpButtonCdrom itemAtIndex:2] isSeparatorItem])
				[popUpButtonCdrom removeItemAtIndex:2];
			[popUpButtonCdrom insertItemWithTitle:[sheet filename] atIndex:2];
			[popUpButtonCdrom selectItemAtIndex:2];
		} else {
			[popUpButtonCdrom selectItemAtIndex:0];
		}
	/* -kernel */
	} else if ([[contextInfo menu] isEqual:[popUpButtonKernel menu]]) {
		if(returnCode == NSOKButton) {
			if (![[popUpButtonKernel itemAtIndex:1] isSeparatorItem])
				[popUpButtonKernel removeItemAtIndex:1];
			[popUpButtonKernel insertItemWithTitle:[sheet filename] atIndex:1];
			[popUpButtonKernel selectItemAtIndex:1];
		} else {
			[popUpButtonKernel selectItemAtIndex:0];
		}
	/* -initrd */
	} else if ([[contextInfo menu] isEqual:[popUpButtonInitrd menu]]) {
		if(returnCode == NSOKButton) {
			if (![[popUpButtonInitrd itemAtIndex:1] isSeparatorItem])
				[popUpButtonInitrd removeItemAtIndex:1];
			[popUpButtonInitrd insertItemWithTitle:[sheet filename] atIndex:1];
			[popUpButtonInitrd selectItemAtIndex:1];
		} else {
			[popUpButtonInitrd selectItemAtIndex:0];
		}
	}
}

- (IBAction) genericImageSelectPanel:(id)sender
{
//	NSLog(@"cocoaControlEditPC: genericImageSelectPanel");

	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
		[openPanel beginSheetForDirectory:nil
			file:nil
			types:fileTypes
			modalForWindow:editPCPanel
			modalDelegate:self
			didEndSelector:@selector(genericImageSelectPanelDidEnd:returnCode:contextInfo:)
			contextInfo:sender];
}

/* dIWindow */
- (IBAction) menuItemNewImage:(id)sender
{
//	NSLog(@"cocoaControlEditPC: menuItemNewImage");

	cocoaControlDiskImage *dI = [[cocoaControlDiskImage alloc] init];
	[NSBundle loadNibNamed:@"cocoaControlDiskImage" owner:dI];
	[dI setQSender:self];
	
	[NSApp beginSheet:[dI dIWindow]
		modalForWindow:editPCPanel 
		modalDelegate:dI
		didEndSelector:@selector(dIPanelDidEnd:returnCode:contextInfo:)
		contextInfo:nil];
	
	if ([[popUpButtonHda menu]isEqual:[sender menu]]) {
		customImagePopUpButtonTemp = popUpButtonHda;
	} else if ([[popUpButtonHdb menu]isEqual:[sender menu]]) {
		customImagePopUpButtonTemp = popUpButtonHdb;
	} else if ([[popUpButtonHdc menu]isEqual:[sender menu]]) {
		customImagePopUpButtonTemp = popUpButtonHdc;
	} else if ([[popUpButtonHdd menu]isEqual:[sender menu]]) {
		customImagePopUpButtonTemp = popUpButtonHdd;
	}
}

- (void) setCustomDIType:(NSString *)string size:(int)size
{
//	NSLog(@"cocoaControlEditPC: setCustomDIType");

	if (![[customImagePopUpButtonTemp itemAtIndex:1] isSeparatorItem])
		[customImagePopUpButtonTemp removeItemAtIndex:1];
	[customImagePopUpButtonTemp insertItemWithTitle:[NSString stringWithFormat:@"%@: %dMB %@", NSLocalizedStringFromTable(@"setCustomDIType:title", @"Localizable", @"cocoaControlEditPC"), size, string] atIndex:1];
	[customImagePopUpButtonTemp selectItemAtIndex:1];
	
	if ([customImagePopUpButtonTemp isEqual:popUpButtonHda]) {
		customImageSizeHda = size;
		if (customImageTypeHda)
			[customImageTypeHda release];
		customImageTypeHda = [[NSString alloc] initWithString:string];
	} else if ([customImagePopUpButtonTemp isEqual:popUpButtonHdb]) {
		customImageSizeHdb = size;
		if (customImageTypeHdb)
			[customImageTypeHdb release];
		customImageTypeHdb = [[NSString alloc] initWithString:string];
	} else if ([customImagePopUpButtonTemp isEqual:popUpButtonHdc]) {
			customImageSizeHdc = size;
		if (customImageTypeHdc)
			[customImageTypeHdc release];
		customImageTypeHdc = [[NSString alloc] initWithString:string];
	} else if ([customImagePopUpButtonTemp isEqual:popUpButtonHdd]) {
		customImageSizeHdd = size;
		if (customImageTypeHdd)
			[customImageTypeHdd release];
		customImageTypeHdd = [[NSString alloc] initWithString:string];
	}
}

- (IBAction) closeEditPCPanel:(id)sender
{
//	NSLog(@"cocoaControlEditPC: closeEditPCPanel");

	[NSApp stopModal];
	[editPCPanel close];
}


- (IBAction) editPCEditPCPanel:(id)sender;
{
//	NSLog(@"cocoaControlEditPC: editPCEditPCPanel");
	
	/* Check data */
	[textFieldName setTextColor:[NSColor blackColor]];
	[textFieldRAM setTextColor:[NSColor blackColor]];
	
	/* no empty PC Name */
	if ([[textFieldName stringValue] isEqual:@""]) {
		[textFieldName setStringValue: NSLocalizedStringFromTable(@"editPCEditPCPanel:name", @"Localizable", @"cocoaControlEditPC")];
		[textFieldName setTextColor:[NSColor redColor]];
		return;
	}
	
	/* no ":", ".", "/" in Names */
	int i,ii;
	unichar tChar;
	BOOL checkOK = 1;
	NSString *tForbidden = [NSString stringWithString:@":./"];
	NSString *tName = [NSString stringWithString:[textFieldName stringValue]];
	for (i = 0; i < [tName length]; i++) {
		tChar = [tName characterAtIndex:i];
		for (ii=0; ii < [tForbidden length]; ii++) {
			if (tChar == [tForbidden characterAtIndex:ii])
				checkOK = 0;
		}
	}
	if (!checkOK) {
		[textFieldName setStringValue: NSLocalizedStringFromTable(@"editPCEditPCPanel:charName", @"Localizable", @"cocoaControlEditPC")];
		[textFieldName setTextColor:[NSColor redColor]];
		return;
	}
	
	/* no double PC Name */
	if ( [[buttonOk title] isEqualTo: NSLocalizedStringFromTable(@"prepareEditPCPanel:newPC", @"Localizable", @"cocoaControlEditPC")]) {
		if ( ![qSender checkPC:thisPC name:[textFieldName stringValue] create:YES] ) {
			[textFieldName setStringValue: NSLocalizedStringFromTable(@"prepareEditPCPanel:otherName", @"Localizable", @"cocoaControlEditPC")];
			[textFieldName setTextColor:[NSColor redColor]];
			return;
		}
	} else {
		if ( ![qSender checkPC:thisPC name:[textFieldName stringValue] create:NO] ) {
			[textFieldName setStringValue: NSLocalizedStringFromTable(@"prepareEditPCPanel:otherName", @"Localizable", @"cocoaControlEditPC")];
			[textFieldName setTextColor:[NSColor redColor]];
			return;
		}
	}
	
	/* no 0 mb RAM */
	if ( [textFieldRAM intValue] < 1 ) {
		[textFieldRAM setStringValue:@"0"];
		[textFieldRAM setTextColor:[NSColor redColor]];
		return;
	}
	
	/* prepare Files */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	/* creating files if PC is new */	
	if ([[buttonOk title] isEqualTo: NSLocalizedStringFromTable(@"prepareEditPCPanel:newPC", @"Localizable", @"cocoaControlEditPC")]) {
		if ([fileManager fileExistsAtPath: [NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [textFieldName stringValue]]] == NO)
			[fileManager createDirectoryAtPath: [NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [textFieldName stringValue]] attributes: nil];		
	/* moving files if PC was renamed */	
	} else {
		if ([fileManager fileExistsAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]])
			[fileManager movePath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"] toPath:[NSString stringWithFormat:@"%@/%@.qvm", [[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"] stringByDeletingLastPathComponent], [textFieldName stringValue]] handler:nil];
	}
	[[thisPC objectForKey:@"Temporary"] setObject:[NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [textFieldName stringValue]] forKey:@"-cocoapath"];

	/* cleanup Dics */
	[[thisPC objectForKey:@"Arguments"] setString:@""];
	[[thisPC objectForKey:@"Temporary"] removeObjectForKey:@"-cocoaquickdraw"];
	[[thisPC objectForKey:@"Temporary"] removeObjectForKey:@"QWinDrivers"];
	[[thisPC objectForKey:@"Temporary"] removeObjectForKey:@"WMStopWhenInactive"];
	[[thisPC objectForKey:@"Temporary"] removeObjectForKey:@"-m"];
	[[thisPC objectForKey:@"Temporary"] removeObjectForKey:@"-M"];
	[[thisPC objectForKey:@"Temporary"] removeObjectForKey:@"-soundhw"];
	
	/* setting Settings :) */
	[[thisPC objectForKey:@"PC Data"] setObject:[textFieldName stringValue] forKey:@"name"];
	
	/* WMStopWhenInactive */
	if ([buttonWMStopWhenInactive state] == NSOnState)
		[[thisPC objectForKey:@"Temporary"] setObject:[NSNumber numberWithBool:true] forKey:@"WMStopWhenInactive"];
	
	/* Q Windows Drivers */
	if ([buttonQWinDrivers state] == NSOnState)
		[[thisPC objectForKey:@"Temporary"] setObject:[NSNumber numberWithBool:true] forKey:@"QWinDrivers"];
	
	/* platform */
	switch ([popUpButtonCPU indexOfSelectedItem]) {
		case 0:
			[[thisPC objectForKey:@"PC Data"] setObject:@"x86" forKey:@"architecture"];
			break;
		case 1:
			[[thisPC objectForKey:@"PC Data"] setObject:@"x86-64" forKey:@"architecture"];
			break;
		case 2:
			[[thisPC objectForKey:@"PC Data"] setObject:@"PowerPC" forKey:@"architecture"];
			break;
		case 3:
			[[thisPC objectForKey:@"PC Data"] setObject:@"PowerPC" forKey:@"architecture"];
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -M prep"]];
			break;
		case 4:
			[[thisPC objectForKey:@"PC Data"] setObject:@"SPARC" forKey:@"architecture"];
			break;
		case 5:
			[[thisPC objectForKey:@"PC Data"] setObject:@"MIPS" forKey:@"architecture"];
			break;
		case 6:
			[[thisPC objectForKey:@"PC Data"] setObject:@"ARM" forKey:@"architecture"];
			break;
	}
	
	/* -m */
	[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -m %D", [textFieldRAM intValue]]];

	/* VGA */
	if ([popUpButtonVGA indexOfSelectedItem] == 1) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -std-vga"]];
	}
	
	/* -soundhw */
	NSMutableArray *soundhw = [NSMutableArray arrayWithCapacity:4];
	if ([buttonEnableAdlib state] == NSOnState)
		[soundhw addObject:@"adlib"];
	if ([buttonEnableSB16 state] == NSOnState)
		[soundhw addObject:@"sb16"];
	if ([buttonEnableES1370 state] == NSOnState)
		[soundhw addObject:@"es1370"];
	if ([soundhw count] > 0)
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -soundhw %@", [soundhw componentsJoinedByString:@","]]];

	/* -localtime */
	if ([buttonLocaltime state] == NSOnState)
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -localtime"]];

	/* -usbdevice */
	if ([buttonEnableUSBTablet state] == NSOnState) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -usbdevice tablet"]];
	}

	/* -net */
	if ([buttonNetNicNe2000 state] == NSOnState) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -net nic"]];
    }
	if ([buttonNetNicRtl8139 state] == NSOnState) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -net nic,model=rtl8139"]];
    }
	if ([buttonNetNicPcnet state] == NSOnState) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -net nic,model=pcnet"]];
	}
	if ([buttonNetUser state] == NSOnState) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -net user"]];
	}

	/* -smb */
	if ([popUpButtonSmbFilesharing indexOfSelectedItem] == 1) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -smb ~/Desktop/Q Shared Files/"]];
	} else if ([popUpButtonSmbFilesharing indexOfSelectedItem] == 2) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -smb %@", [popUpButtonSmbFilesharing titleOfSelectedItem]]];
	}

	/* -fda */
	if ([popUpButtonFda indexOfSelectedItem] == 1) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -fda %@", [popUpButtonFda titleOfSelectedItem]]];
	}

	/* -hda */
	if ([popUpButtonHda indexOfSelectedItem] > 0) {
		if ([popUpButtonHda indexOfSelectedItem] == [popUpButtonHda indexOfItemWithTag:200]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [self createDI:@"qcow2" withSize:10]]];
		} else if ([popUpButtonHda indexOfSelectedItem] == [popUpButtonHda indexOfItemWithTag:201]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [self createDI:@"qcow2" withSize:100]]];
		} else if ([popUpButtonHda indexOfSelectedItem] == [popUpButtonHda indexOfItemWithTag:202]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [self createDI:@"qcow2" withSize:4000]]];
		} else if ([popUpButtonHda indexOfSelectedItem] == [popUpButtonHda indexOfItemWithTag:203]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [self createDI:@"raw" withSize:4000]]];
		} else if ([[popUpButtonHda titleOfSelectedItem] rangeOfString: NSLocalizedStringFromTable(@"setCustomDIType:title", @"Localizable", @"cocoaControlEditPC")].location != NSNotFound) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [self createDI:customImageTypeHda withSize:customImageSizeHda]]];
		} else {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [popUpButtonHda titleOfSelectedItem]]];
		}
	}
	
	/* -hdb */
	if ([popUpButtonHdb indexOfSelectedItem] > 0) {
		if ([popUpButtonHdb indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:200]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdb %@", [self createDI:@"qcow2" withSize:10]]];
		} else if ([popUpButtonHdb indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:201]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdb %@", [self createDI:@"qcow2" withSize:100]]];
		} else if ([popUpButtonHdb indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:202]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdb %@", [self createDI:@"qcow2" withSize:4000]]];
		} else if ([popUpButtonHdb indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:203]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdb %@", [self createDI:@"raw" withSize:4000]]];
		} else if ([[popUpButtonHdb titleOfSelectedItem] rangeOfString:@"Custom Image:"].location != NSNotFound) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdb %@", [self createDI:customImageTypeHdb withSize:customImageSizeHdb]]];
		} else {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdb %@", [popUpButtonHdb titleOfSelectedItem]]];
		}
	}
	
	/* -hdc */
	if ([popUpButtonHdc indexOfSelectedItem] > 0) {
		if ([popUpButtonHdc indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:200]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdc %@", [self createDI:@"qcow2" withSize:10]]];
		} else if ([popUpButtonHdc indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:201]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdc %@", [self createDI:@"qcow2" withSize:100]]];
		} else if ([popUpButtonHdc indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:202]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdc %@", [self createDI:@"qcow2" withSize:4000]]];
		} else if ([popUpButtonHdc indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:203]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdc %@", [self createDI:@"raw" withSize:4000]]];
		} else if ([[popUpButtonHdc titleOfSelectedItem] rangeOfString:@"Custom Image:"].location != NSNotFound) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdc %@", [self createDI:customImageTypeHdc withSize:customImageSizeHdc]]];
		} else {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdc %@", [popUpButtonHdc titleOfSelectedItem]]];
		}
	}
	
	/* -hdd */
	if ([popUpButtonHdd indexOfSelectedItem] > 0) {
		if ([popUpButtonHdd indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:200]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdd %@", [self createDI:@"qcow2" withSize:10]]];
		} else if ([popUpButtonHdd indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:201]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdd %@", [self createDI:@"qcow2" withSize:100]]];
		} else if ([popUpButtonHdd indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:202]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdd %@", [self createDI:@"qcow2" withSize:4000]]];
		} else if ([popUpButtonHdd indexOfSelectedItem] == [popUpButtonHdb indexOfItemWithTag:203]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdd %@", [self createDI:@"raw" withSize:4000]]];
		} else if ([[popUpButtonHdd titleOfSelectedItem] rangeOfString:@"Custom Image:"].location != NSNotFound) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdd %@", [self createDI:customImageTypeHdd withSize:customImageSizeHdd]]];
		} else {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hdd %@", [popUpButtonHdd titleOfSelectedItem]]];
		}
	}
	
	/* -cdrom */
	if ([popUpButtonCdrom indexOfSelectedItem] == 1) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -cdrom /dev/cdrom"]];
	} else if ([popUpButtonCdrom indexOfSelectedItem] == 2) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -cdrom %@", [popUpButtonCdrom titleOfSelectedItem]]];
	}
	
	/* -boot */
	[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -boot %C", [@"acd" characterAtIndex:[popUpButtonBoot indexOfSelectedItem]]]];
	
		
	/* -win2k-hack */
	if ([buttonWin2kHack state] == NSOnState)
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -win2k-hack"]];
		
	/* -kernel */
	if ([popUpButtonKernel indexOfSelectedItem] == 1) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -kernel %@", [popUpButtonKernel titleOfSelectedItem]]];
	}
	
	/* -append */
	if (![[textFieldAppend stringValue] isEqual:@""])
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -append %@", [textFieldAppend stringValue]]];

	/* -initrd */
	if ([popUpButtonInitrd indexOfSelectedItem] == 1) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -initrd %@", [popUpButtonInitrd titleOfSelectedItem]]];
	}
	
	/* -redir */
	// first save to configuration.plist, then add to arguments
	[self saveFirewallPortList];
	[[thisPC objectForKey:@"Arguments"] appendFormat:@"%@",[self constructFirewallArguments]];
	
	/* qemu arguments */
	[[thisPC objectForKey:@"Arguments"] appendFormat:@" %@",[textFieldArguments stringValue]];
	
	/* save PC */
	[qSender savePCConfiguration:thisPC];
	[qSender loadConfigurations];
	
	/* cleanup */
	[thisPC release];
	
	/* hide sheet */
	[NSApp stopModal];
	[editPCPanel close];
}

- (IBAction) showHelp:(id)sender
{
//	NSLog(@"cocoaControlEditPC: showHelp");

	AHGotoPage (CFSTR("Q Help"), CFSTR("html/editPC.html"), nil);
}

- (NSString *) createDI:(NSString *)type withSize:(int)size
{
//	NSLog(@"cocoaControlEditPC: createDI");

	/* search a free Name */
	int i = 1;
	NSString *name;
	NSString *path = [NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [textFieldName stringValue]];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", path, [NSString stringWithFormat:@"Harddisk_%d.%@", i, type]]])
		i++;
	name = [NSString stringWithFormat:@"Harddisk_%d.%@", i, type];
	
	/* create diskImage */
	NSArray *arguments = [NSArray arrayWithObjects:@"create",@"-f", type, [NSString stringWithFormat:@"%@/%@", path, name], [NSString stringWithFormat:@"%dM", size], nil];
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: [NSString stringWithFormat:@"%@/MacOS/qemu-img", [[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent]]];
	[task setArguments: arguments];
	[task launch];
	[task waitUntilExit];
	[task release];
	
	return name;
}

/* Network Methods */
/* Firewall Port Tableview Delegates */

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [firewallPortList count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{	
	id thisPort;
	thisPort = [firewallPortList objectAtIndex:row];

	if ([[tableColumn identifier] isEqualToString:@"status"]) {
        return [thisPort objectForKey:@"Enabled"];
    } else if ([[tableColumn identifier] isEqualToString:@"name"]) {
        return [thisPort objectForKey:@"Name"];
	} else {
		return @"";
	}
	return nil;
}

// for setting the checkbox status to the configuration file
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)theValue forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"status"]) {
        // set the new "enabled" status in firewallPortList
        [[firewallPortList objectAtIndex:rowIndex] setObject:theValue forKey:@"Enabled"];
        // calls table reloadData automatically
    }
}
    
- (void)initFirewallSettings
{
    firewallPortTableEnabled = YES;
    if(firewallPortList == nil) {
        firewallPortList = [[[NSMutableArray alloc] init] retain];
    } else {
        [firewallPortList removeAllObjects];
    }
    // load defaults into array
    NSArray * firewallDefaults = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-defaults" ofType:@"plist"]];
    NSMutableArray * tempArray = [NSMutableArray arrayWithCapacity:5];
    [firewallPortList addObjectsFromArray:firewallDefaults];
    // load customs from thisPC
    if([[thisPC objectForKey:@"Network"] objectForKey:@"Redirect"]) {
        // enumerate through entries and check for defaults
        int i;
        int ii;
        int found = 0;
        for(i=0; i<[[[thisPC objectForKey:@"Network"] objectForKey:@"Redirect"] count]; i++) {
            for(ii=0; ii<[firewallPortList count]; ii++) {
                if([[[[[thisPC objectForKey:@"Network"] objectForKey:@"Redirect"] objectAtIndex:i] objectForKey:@"Name"] isEqualTo:[[firewallDefaults objectAtIndex:ii] objectForKey:@"Name"]]) {
                    // found equal entry in customs, set enabled status in firewallPortList
                    [[firewallPortList objectAtIndex:ii] setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
                    found = 1;
                }
            }
            // check if previously found
            if(found == 0) {
                // not found, add entry to firewallPortList
                [tempArray addObject:[[[thisPC objectForKey:@"Network"] objectForKey:@"Redirect"] objectAtIndex:i]];
            }
            found = 0;
        }
        if([tempArray count] > 0) [firewallPortList addObjectsFromArray:tempArray];
    }
        
    // load additionals into additional selector
    NSArray * firewallAdditionalServices = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-additionals" ofType:@"plist"]];
    
    int i;
    [popUpButtonFirewallAdditionalPorts removeAllItems];
    for(i=0; i<[firewallAdditionalServices count]; i++) {
        [popUpButtonFirewallAdditionalPorts addItemWithTitle:[[firewallAdditionalServices objectAtIndex:i] valueForKey:@"Name"]];
    }
    [[popUpButtonFirewallAdditionalPorts menu] addItem:[NSMenuItem separatorItem]];
    [popUpButtonFirewallAdditionalPorts addItemWithTitle:  NSLocalizedStringFromTable(@"initFirewallSettings:popUpButtonFirewallAdittionalPortsCustom", @"Localizable", @"cocoaControlEditPC")];
	[popUpButtonFirewallAdditionalPorts selectItemAtIndex:0];
	
    [firewallPortTable reloadData];
    [firewallPortTable selectRow:0 byExtendingSelection:NO];
}

- (IBAction) startShowNewPort:(id)sender
{
    [self startEditPort:YES];
}
- (IBAction) startShowEditPort:(id)sender
{
    int restrictedPort = 0;
    NSArray * additionalPorts = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-additionals" ofType:@"plist"]];
    if([firewallPortTable selectedRow] >= 0) {
        int i;
        for(i=0; i<=[additionalPorts count]-1; i++) {
            if([[[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] objectForKey:@"Name"] isEqualTo:[[additionalPorts objectAtIndex:i] objectForKey:@"Name"]]) {
                restrictedPort = 1;
            }
        }
        if([firewallPortTable selectedRow] >= 0 && [firewallPortTable selectedRow] < [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-defaults" ofType:@"plist"]] count]) {
            restrictedPort = 1;
        }
        if(restrictedPort == 1) {
            NSString * redirectedPorts;
            if(![[[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"TCP-Ports-Host"] isEqualToString:@""] && ![[[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"UDP-Ports-Host"] isEqualToString:@""]) {
                // tcp and udp
                redirectedPorts = [NSString stringWithFormat: NSLocalizedStringFromTable(@"startShowEditPort:restrictedPorts1", @"Localizable", @"cocoaControlEditPC"), [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"TCP-Ports-Host"], [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"UDP-Ports-Host"], [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"TCP-Ports-Guest"], [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"UDP-Ports-Guest"]];
            } else if (![[[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"TCP-Ports-Host"] isEqualToString:@""]) {
                // tcp only
                redirectedPorts = [NSString stringWithFormat: NSLocalizedStringFromTable(@"startShowEditPort:restrictedPorts2", @"Localizable", @"cocoaControlEditPC"), [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"TCP-Ports-Host"], [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"TCP-Ports-Guest"]];
            } else {
                // udp only
                redirectedPorts = [NSString stringWithFormat: NSLocalizedStringFromTable(@"startShowEditPort:restrictedPorts3", @"Localizable", @"cocoaControlEditPC"), [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"UDP-Ports-Host"], [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"UDP-Ports-Guest"]];
            }
            
            NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"startShowEditPort:AlertSheet:messageText", @"Localizable", @"cocoaControlEditPC")
				defaultButton: NSLocalizedStringFromTable(@"startShowEditPort:AlertSheet:defaultButton", @"Localizable", @"cocoaControlEditPC")
				alternateButton:nil
				otherButton:nil
				informativeTextWithFormat:[NSString stringWithFormat: NSLocalizedStringFromTable(@"startShowEditPort:AlertSheet:informativeText", @"Localizable", @"cocoaControlEditPC"), [[firewallPortList objectAtIndex:[firewallPortTable selectedRow]] valueForKey:@"Name"], redirectedPorts]];
				
            [alert runModal];
        } else {
        [self startEditPort:NO];
        }
    }
}

- (void) startEditPort:(BOOL)newPort
{  
    /*[firewallPortPanel setFrame:NSMakeRect(
        [firewallPortPanel frame].origin.x,
        [firewallPortPanel frame].origin.y - 263,
        [firewallPortPanel frame].size.width,
        [firewallPortPanel frame].size.height + 263
    ) display:YES animate:YES];
    */
    
    [NSApp beginSheet:firewallPortEditPanel
        modalForWindow:editPCPanel 
        modalDelegate:self
        didEndSelector:nil
        contextInfo:nil];
        
    if(newPort) {
        // called to create a new port
        [textFieldFirewallPortName setStringValue:@""];
        [popUpButtonFirewallServiceType selectItemAtIndex:0];
        [textFieldFirewallPortHostPorts setStringValue:@""];
        [textFieldFirewallPortGuestPorts setStringValue:@""];
        
        [popUpButtonFirewallAdditionalPorts selectItemAtIndex:0];
        [self setAdditionalPort:self];
        [buttonFirewallSavePort setTarget:self];
        [buttonFirewallSavePort setAction:@selector(saveNewPort:)];
    } else {
        // called to edit a port
        [buttonFirewallSavePort setTarget:self];
        [buttonFirewallSavePort setAction:@selector(saveEditPort:)];
        [popUpButtonFirewallAdditionalPorts selectItemWithTitle: NSLocalizedStringFromTable(@"startEditPort:popUpButtonFirewallAdittionalPortsCustom", @"Localizable", @"cocoaControlEditPC")];
        // load port info from list
        int selectedPort = [firewallPortTable selectedRow];
        
        [textFieldFirewallPortName setStringValue:[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"Name"]];
        if(![[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"TCP-Ports-Host"] isEqualToString:@""] && ![[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"UDP-Ports-Host"] isEqualToString:@""]) {
            [popUpButtonFirewallServiceType selectItemAtIndex:2];
            [textFieldFirewallPortHostPorts setStringValue:[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"TCP-Ports-Host"]];
        [textFieldFirewallPortGuestPorts setStringValue:[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"TCP-Ports-Guest"]];
        } else if(![[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"TCP-Ports-Host"] isEqualToString:@""]) {
            [popUpButtonFirewallServiceType selectItemAtIndex:0];
            [textFieldFirewallPortHostPorts setStringValue:[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"TCP-Ports-Host"]];
        [textFieldFirewallPortGuestPorts setStringValue:[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"TCP-Ports-Guest"]];
        } else if(![[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"UDP-Ports-Host"] isEqualToString:@""]) {
            [popUpButtonFirewallServiceType selectItemAtIndex:1];
            [textFieldFirewallPortHostPorts setStringValue:[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"UDP-Ports-Host"]];
        [textFieldFirewallPortGuestPorts setStringValue:[[firewallPortList objectAtIndex:selectedPort] valueForKey:@"UDP-Ports-Guest"]];
        }
    }
}

- (IBAction) deletePort:(id)sender
{
    // check if port is a default port
    if([firewallPortTable selectedRow] >= 0 && [firewallPortTable selectedRow] < [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-defaults" ofType:@"plist"]] count]) {
        NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"deletePort:AlertSheet:messageText", @"Localizable", @"cocoaControlEditPC")
				defaultButton: NSLocalizedStringFromTable(@"deletePort:AlertSheet:defaultButton", @"Localizable", @"cocoaControlEditPC")
				alternateButton:nil
				otherButton:nil
				informativeTextWithFormat: NSLocalizedStringFromTable(@"deletePort:AlertSheet:informativeText", @"Localizable", @"cocoaControlEditPC")];
				
        [alert runModal];
    } else {
        // delete
        [firewallPortList removeObjectAtIndex:[firewallPortTable selectedRow]];
        [firewallPortTable reloadData];
    }
}

- (IBAction) setAdditionalPort:(id)sender
{
    // load data from fw-additionals.plist
    if ([popUpButtonFirewallAdditionalPorts indexOfSelectedItem] <= ([popUpButtonFirewallAdditionalPorts numberOfItems] - 3)) {
        // only sets from fw-additionals are loaded here..
        NSArray * additionalPorts = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-additionals" ofType:@"plist"]];
        
        [textFieldFirewallPortName setStringValue:[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"Name"]];
        if(![[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"TCP-Ports-Host"] isEqualToString:@""] && ![[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"UDP-Ports-Host"] isEqualToString:@""]) {
            // tcp and udp
            // add both type's ports, if set is saved we load it directly from fw-additionals because of possible duplicates
            [popUpButtonFirewallServiceType selectItemAtIndex:2];
            [textFieldFirewallPortHostPorts setStringValue:[NSString stringWithFormat:@"%@,%@", [[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"TCP-Ports-Host"], [[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"UDP-Ports-Host"]]];
        [textFieldFirewallPortGuestPorts setStringValue:[NSString stringWithFormat:@"%@,%@", [[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"TCP-Ports-Guest"], [[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"UDP-Ports-Guest"]]];
        } else if(![[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"TCP-Ports-Host"] isEqualToString:@""]) {
            // tcp only
            [popUpButtonFirewallServiceType selectItemAtIndex:0];
            [textFieldFirewallPortHostPorts setStringValue:[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"TCP-Ports-Host"]];
        [textFieldFirewallPortGuestPorts setStringValue:[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"TCP-Ports-Guest"]];
        } else if(![[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"UDP-Ports-Host"] isEqualToString:@""]) {
            // udp only
            [popUpButtonFirewallServiceType selectItemAtIndex:1];
            [textFieldFirewallPortHostPorts setStringValue:[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"UDP-Ports-Host"]];
        [textFieldFirewallPortGuestPorts setStringValue:[[additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]] valueForKey:@"UDP-Ports-Guest"]];
        }
        // lock elements
        [textFieldFirewallPortName setEnabled:NO];
        [textFieldFirewallPortHostPorts setEnabled:NO];
        [textFieldFirewallPortGuestPorts setEnabled:NO];
        [popUpButtonFirewallServiceType setEnabled:NO];
    } else {
        // custom port chosen
        [textFieldFirewallPortName setStringValue:@""];
        [textFieldFirewallPortHostPorts setStringValue:@""];
        [textFieldFirewallPortGuestPorts setStringValue:@""];
        [popUpButtonFirewallServiceType selectItemAtIndex:0];
        
        [textFieldFirewallPortName setEnabled:YES];
        [textFieldFirewallPortHostPorts setEnabled:YES];
        [textFieldFirewallPortGuestPorts setEnabled:YES];
        [popUpButtonFirewallServiceType setEnabled:YES];
    }
}

- (IBAction) saveNewPort:(id)sender
{
    if([self checkPort:YES] == YES) {
        NSMutableDictionary * portDict;
        if ([popUpButtonFirewallAdditionalPorts indexOfSelectedItem] <= ([popUpButtonFirewallAdditionalPorts numberOfItems] - 3)) {
        // this is a set from fw-additionals, load it directly from the file        
        NSArray * additionalPorts = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-additionals" ofType:@"plist"]];
        portDict = [additionalPorts objectAtIndex:[popUpButtonFirewallAdditionalPorts indexOfSelectedItem]];
        } else {
        // this is a custom port, take entries from textFields
        portDict = [NSMutableDictionary dictionaryWithCapacity:5];
        [portDict setObject:[textFieldFirewallPortName stringValue] forKey:@"Name"];
        if([popUpButtonFirewallServiceType indexOfSelectedItem] == 0) {
            // tcp only
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"TCP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"TCP-Ports-Guest"];
        } else if([popUpButtonFirewallServiceType indexOfSelectedItem] == 1) {
            // udp only
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"UDP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"UDP-Ports-Guest"];
        } else if([popUpButtonFirewallServiceType indexOfSelectedItem] == 2) {
            // tcp and udp
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"TCP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"TCP-Ports-Guest"];
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"UDP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"UDP-Ports-Guest"];
        }
        } // end predefined/custom check
        // set enabled key
        [portDict setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
        // add to list
        [firewallPortList addObject:portDict];
        [self endEditPort:self];
    }
}

- (IBAction) saveEditPort:(id)sender
{
    if([self checkPort:NO] == YES) {
        // save to edited port
        int selectedPort = [firewallPortTable selectedRow];
        
        NSMutableDictionary * portDict = [NSMutableDictionary dictionaryWithCapacity:5];
        [portDict setObject:[textFieldFirewallPortName stringValue] forKey:@"Name"];
        if([popUpButtonFirewallServiceType indexOfSelectedItem] == 0) {
            // tcp only
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"TCP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"TCP-Ports-Guest"];
        } else if([popUpButtonFirewallServiceType indexOfSelectedItem] == 1) {
            // udp only
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"UDP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"UDP-Ports-Guest"];
        } else if([popUpButtonFirewallServiceType indexOfSelectedItem] == 2) {
            // tcp and udp
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"TCP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"TCP-Ports-Guest"];
            [portDict setObject:[textFieldFirewallPortHostPorts stringValue] forKey:@"UDP-Ports-Host"];
            [portDict setObject:[textFieldFirewallPortGuestPorts stringValue] forKey:@"UDP-Ports-Guest"];
        }
        // set enabled/disabled key
        [portDict setObject:[[firewallPortList objectAtIndex:selectedPort] objectForKey:@"Enabled"] forKey:@"Enabled"];
        // replace in list
        [firewallPortList replaceObjectAtIndex:selectedPort withObject:portDict];          
        [self endEditPort:self];
    }
}

- (BOOL) checkPort:(BOOL)newPort
{
    if([[textFieldFirewallPortName stringValue] isEqualToString:@""]) {
        // name empty
        [textFieldFirewallPortError setStringValue: NSLocalizedStringFromTable(@"checkPort:textFieldFirewallPortError:name", @"Localizable", @"cocoaControlEditPC")];
        [textFieldFirewallPortError setHidden:NO];
        return NO;
    } else if([[textFieldFirewallPortHostPorts stringValue] isEqualToString:@""]) {
        // host ports empty
        //NSLog(@"No empty host-port entry!");
        [textFieldFirewallPortError setStringValue: NSLocalizedStringFromTable(@"checkPort:textFieldFirewallPortError:hostport", @"Localizable", @"cocoaControlEditPC")];
        [textFieldFirewallPortError setHidden:NO];
        return NO;
    } else if([[textFieldFirewallPortGuestPorts stringValue] isEqualToString:@""]) {
        // guest ports empty
        //NSLog(@"No empty guest-port entry!");
        [textFieldFirewallPortError setStringValue: NSLocalizedStringFromTable(@"checkPort:textFieldFirewallPortError:guestport", @"Localizable", @"cocoaControlEditPC")];
        [textFieldFirewallPortError setHidden:NO];
        return NO;
    } else {
        // check for valid port ranges
	   int i,j,k;
	   int dcc = 0; // delimiter comma count
	   int dhc = 0; // delimiter haifin count
	   unichar tChar;
	   int invalid = 0;
	   NSString *tForbidden = [NSString stringWithString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!\"$%&/()=?+*#'_;:.<>"];
	   NSString *tDelimiters = [NSString stringWithString:@",-"];
	   NSArray *tPortRanges = [NSArray arrayWithObjects:[textFieldFirewallPortHostPorts stringValue], [textFieldFirewallPortGuestPorts stringValue], nil];
	   for (i = 0; i < [tPortRanges count]; i++) {
            for (j = 0; j < [[tPortRanges objectAtIndex:i] length]; j++) {
                tChar = [[tPortRanges objectAtIndex:i] characterAtIndex:j];
                for (k=0; k < [tForbidden length]; k++) {
                    //NSLog(@"%C, %C", tChar, [tForbidden characterAtIndex:k]);
                    if (tChar == [tForbidden characterAtIndex:k]) {
                        // invalid character
                        invalid = 1;
                    } else if(tChar == [tDelimiters characterAtIndex:0]) {
                        // raise comma count
                        dcc++;
                    } else if(tChar == [tDelimiters characterAtIndex:1]) {
                        // raise haifin count
                        dhc++;
                    }
                }
            }
	   }
	   if (invalid == 1) {
	       //NSLog(@"Illegal characters in ports!");
	       [textFieldFirewallPortError setStringValue: NSLocalizedStringFromTable(@"checkPort:textFieldFirewallPortError:illegalchars", @"Localizable", @"cocoaControlEditPC")];
	       [textFieldFirewallPortError setHidden:NO];
	       return NO;
	   } else if(dcc > 0 && dhc > 0) {
	       // both comma and haifin found, not supported/allowed atm
	       //NSLog(@"Combination of , and - not allowed.");
	       [textFieldFirewallPortError setStringValue: NSLocalizedStringFromTable(@"checkPort:textFieldFirewallPortError:combination", @"Localizable", @"cocoaControlEditPC")];
	       [textFieldFirewallPortError setHidden:NO];
	       return NO;
	   }
    }
    int i;
    int found = 0;
    if(newPort) {
        // check for same name in all entries of current list
        
        for(i=0; i<=[firewallPortList count]-1; i++) {
            if([[textFieldFirewallPortName stringValue] isEqualTo:[[firewallPortList objectAtIndex:i] objectForKey:@"Name"]]) {
                found = 1;
            }
        }
    } else {
        // check for same name in fw-default entries of current list
        for(i=0; i<=[[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-defaults" ofType:@"plist"]] count]-1; i++) {
            if([[textFieldFirewallPortName stringValue] isEqualTo:[[firewallPortList objectAtIndex:i] objectForKey:@"Name"]]) {
                found = 1;
            }
        }
    }
    if(found == 1) return NO;
    return YES;
}

- (IBAction) endEditPort:(id)sender
{
    // reset
    [textFieldFirewallPortName setStringValue:@""];
    [textFieldFirewallPortHostPorts setStringValue:@""];
    [textFieldFirewallPortGuestPorts setStringValue:@""];
    [popUpButtonFirewallServiceType selectItemAtIndex:0];
    [textFieldFirewallPortError setStringValue:@""];
    [textFieldFirewallPortError setHidden:YES];
        
    [textFieldFirewallPortName setEnabled:YES];
    [textFieldFirewallPortHostPorts setEnabled:YES];
    [textFieldFirewallPortGuestPorts setEnabled:YES];
    [popUpButtonFirewallServiceType setEnabled:YES];    
    
    [NSApp endSheet:firewallPortEditPanel];
    [firewallPortEditPanel orderOut:self];
    
    [firewallPortTable reloadData];
}

- (void) saveFirewallPortList
{
    // save the ports in configuration.plist
    // enumerate through entries and check for defaults, when enabled => save
    NSArray * firewallDefaults = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fw-defaults" ofType:@"plist"]];
    NSMutableArray * customPorts = [NSMutableArray arrayWithCapacity:10];
    int i;
    int ii;
    int found = 0;
    for(i=0; i<=[firewallPortList count]-1; i++) {
        for(ii=0; ii<=[firewallDefaults count]-1; ii++) {
            if([[[firewallPortList objectAtIndex:i] objectForKey:@"Name"] isEqualTo:[[firewallDefaults objectAtIndex:ii] objectForKey:@"Name"]]) {
                // found default port in customs, check for enabled status in firewallPortList
                found = 1;
                if([[[firewallPortList objectAtIndex:i] objectForKey:@"Enabled"] isEqualTo:[NSNumber numberWithBool:YES]]) {
                    // default port enabled => save to conf.plist
                    [customPorts addObject:[firewallPortList objectAtIndex:i]]; 
                }
            }   
        }
        if(found == 0) {
            // port is not default port, save to conf.plist regardless of Enabled
            [customPorts addObject:[firewallPortList objectAtIndex:i]];
        }
        found = 0;
    }
    [thisPC setObject:[NSDictionary dictionaryWithObject:customPorts forKey:@"Redirect"] forKey:@"Network"];
}

- (NSString *) constructFirewallArguments
{
    NSArray * portlist = [[thisPC objectForKey:@"Network"] objectForKey:@"Redirect"];
    NSMutableString * arguments = [NSMutableString stringWithCapacity:10];
    
    int i, ii, j, k;
    for(i=0; i<[portlist count]; i++) {
        // enumerate through portlist in conf.plist
        if([[[portlist objectAtIndex:i] objectForKey:@"Enabled"] isEqualTo:[NSNumber numberWithBool:YES]]) {
            NSArray * tcpHostComma = [[[portlist objectAtIndex:i] valueForKey:@"TCP-Ports-Host"] componentsSeparatedByString:@","];
            NSArray * tcpHostHaifin = [[[portlist objectAtIndex:i] valueForKey:@"TCP-Ports-Host"] componentsSeparatedByString:@"-"];
            NSArray * tcpGuestComma = [[[portlist objectAtIndex:i] valueForKey:@"TCP-Ports-Guest"] componentsSeparatedByString:@","];
            NSArray * tcpGuestHaifin = [[[portlist objectAtIndex:i] valueForKey:@"TCP-Ports-Guest"] componentsSeparatedByString:@"-"];
            
            NSArray * udpHostComma = [[[portlist objectAtIndex:i] valueForKey:@"UDP-Ports-Host"] componentsSeparatedByString:@","];
            NSArray * udpHostHaifin = [[[portlist objectAtIndex:i] valueForKey:@"UDP-Ports-Host"] componentsSeparatedByString:@"-"];
            NSArray * udpGuestComma = [[[portlist objectAtIndex:i] valueForKey:@"UDP-Ports-Guest"] componentsSeparatedByString:@","];
            NSArray * udpGuestHaifin = [[[portlist objectAtIndex:i] valueForKey:@"UDP-Ports-Guest"] componentsSeparatedByString:@"-"];
            
            NSArray * typeA = [NSArray arrayWithObjects:@"tcp",@"udp",nil];
            NSArray * seperatedA = [NSArray arrayWithObjects:[NSArray arrayWithObjects:tcpHostComma, tcpHostHaifin, tcpGuestComma, tcpGuestHaifin, nil], [NSArray arrayWithObjects:udpHostComma, udpHostHaifin, udpGuestComma, udpGuestHaifin, nil], nil];
            
            for(ii=0; ii<[seperatedA count]; ii++) {
            // tcp/udp
            id tp = [typeA objectAtIndex:ii];
            id hc = [[seperatedA objectAtIndex:ii] objectAtIndex:0];
            id hh = [[seperatedA objectAtIndex:ii] objectAtIndex:1];
            id gc = [[seperatedA objectAtIndex:ii] objectAtIndex:2];
            id gh = [[seperatedA objectAtIndex:ii] objectAtIndex:3];
            
            
            /* comma code */
            if([hc count] > 1 && [gc count] > 1) {
                // both seperated by comma
                if([hc count] == [gc count]) {
                    // both have the same amount of ports
                    // redirect same=>same
                    for(j=0; j < [hc count]; j++) {
                        [arguments appendString:[NSString stringWithFormat:@" -redir %@:%@::%@",tp, [hc objectAtIndex:j], [gc objectAtIndex:j]]];
                    }
                } else {
                    // both have a different amount of ports
                    // redirect every=>every
                    for(j=0; j < [hc count]; j++) {
                        for(k=0; k < [gc count]; k++) {
                            [arguments appendString:[NSString stringWithFormat:@" -redir %@:%@::%@",tp, [hc objectAtIndex:j], [gc objectAtIndex:k]]];
                        }
                    }
                }
            } else if([hc count] == 1 && [gc count] > 1) {
                // only guest seperated by comma
                // redirect one=>every
                 for(j=0; j < [gc count]; j++) {
                    [arguments appendString:[NSString stringWithFormat:@" -redir %@:%@::%@",tp, [hc objectAtIndex:0], [gc objectAtIndex:j]]];
                    }
            } else if([hc count] > 1 && [gc count] == 1) {
                // only host seperated by comma
                // redirect one=>every
                 for(j=0; j < [hc count]; j++) {
                    [arguments appendString:[NSString stringWithFormat:@" -redir %@:%@::%@",tp, [hc objectAtIndex:j], [gc objectAtIndex:0]]];
                    }
            }
            
            /* haifin code */
            if([hh count] > 1 && [gh count] > 1) {
                // both seperated by haifin
                // redirect same=>same
                j=[[hh objectAtIndex:0] intValue];
                k=[[gh objectAtIndex:0] intValue]; 
                while(j <= [[hh objectAtIndex:1] intValue]) {
                    [arguments appendString:[NSString stringWithFormat:@" -redir %@:%d::%d",tp, j,k]];
                    j++;
                    k++;
                }
            } else if([hh count] == 1 && [gh count] > 1) {
                // only guest seperated by haifin
                // redirect one=>every
                j=[[gh objectAtIndex:0] intValue];
                while(j < [[gh objectAtIndex:1] intValue]) {
                    [arguments appendString:[NSString stringWithFormat:@" -redir %@:%@::%d",tp, [hh objectAtIndex:0],j]];
                    j++;
                    }
            } else if([hh count] > 1 && [gh count] == 1) {
                // only host seperated by haifin
                // redirect one=>every
                j=[[hh objectAtIndex:0] intValue];
                while(j < [[hh objectAtIndex:1] intValue]) {
                    [arguments appendString:[NSString stringWithFormat:@" -redir %@:%d::%@", j,[gh objectAtIndex:0]]];
                    j++;
                    }
            }
            
            /* only one=>one port code */
            // check also for empty port ranges, because componentsSeperatedByString: returns count 1 even from an empty string
            if(([hh count] == 1 && [gh count] == 1) && ([hc count] == 1 && [gc count] == 1)) {
                if(!([[hh objectAtIndex:0] isEqualTo:@""] && [[gh objectAtIndex:0] isEqualTo:@""]) && !([[hc objectAtIndex:0] isEqualTo:@""] && [[gc objectAtIndex:0] isEqualTo:@""])) {
                    // only one port
                    // redirect one=>one
                    [arguments appendString:[NSString stringWithFormat:@" -redir %@:%@::%@",tp, [hc objectAtIndex:0] ,[gc objectAtIndex:0]]];
                }
            } // end if ([hh count == 1] ...
            } // end tcp/udp
        } // end if enabled
    } // end for portlist
    return arguments;
}

@end
