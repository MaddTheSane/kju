/*
 * QEMU Cocoa Control Controller
 * 
 * Copyright (c) 2005, 2006 Mike Kronenberg
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
 
#import "cocoaControlController.h"
#import "cocoaControlDiskImage.h"
#import "cocoaDownloadController.h"

@implementation cocoaControlController
-(id)init
{
//	NSLog(@"cocoaControlController: init");
	
	/* preferences */
	[[NSUserDefaults standardUserDefaults] registerDefaults:[[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:
		[NSString stringWithString:@"OpenGL"], /* enable OpenGL */
		[NSNumber numberWithBool:TRUE], /* enable search for updates */
		[@"~/Documents/QEMU" stringByExpandingTildeInPath], /* standart path */
		nil
	] forKeys:[NSArray arrayWithObjects:@"display", @"enableCheckForUpdates", @"dataPath", nil]]];
	userDefaults = [NSUserDefaults standardUserDefaults];
	
	/* compatibility with old prefferences */
	if ([userDefaults objectForKey:@"enableOpenGL"]) {
		if (![userDefaults boolForKey:@"enableOpenGL"]) {
			[userDefaults setObject:@"QuickDraw" forKey:@"display"];
		}
		[userDefaults removeObjectForKey:@"enableOpenGL"];
	}
	
	if ((self = [super init])) {
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(checkATaskStatus:) 
		name:NSTaskDidTerminateNotification 
		object:nil];
		
	/* check for update */
	if ([userDefaults boolForKey:@"enableCheckForUpdates"]) {
		[self getLatestVersion];
	}
	
	/* start qserver  for distributed object */
	qdoserver = [[cocoaControlDOServer alloc] init];
	
	return self;
	}
	
	return nil;
}

-(id)pcs
{
	return pcs;
}

/* NSApp Delegate */
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
//	NSLog(@"cocoaControlController: openFile");

	[ self startPC:filename];
	
	return true;
}

-(void)awakeFromNib
{
//	NSLog(@"cocoaControlController: awakeFromNib");
	
	[NSApp setDelegate:self];
	[mainWindow setDelegate:self];

	/* other Nibs */
	editPC = [[cocoaControlEditPC alloc] init];
	if (![NSBundle loadNibNamed:@"cocoaControlEditPC" owner:editPC]) {
		printf("cocoaControlEditPC.nib not loaded!\n");
	}
	[[editPC editPCPanel] center];
	
	preferences = [[cocoaControlPreferences alloc] init];
	if (![NSBundle loadNibNamed:@"cocoaControlPreferences" owner:preferences]) {
		printf("cocoaControlPreferences.nib not loaded!\n");
	}
	
	/* div vars */
	if (![userDefaults objectForKey:@"dataPath"]) { /* here we take care of older userDefaults without @"dataPath" */
		[userDefaults setObject:[NSString stringWithFormat:@"%@/Documents/QEMU", NSHomeDirectory()] forKey:@"dataPath"];
	}
	
	cpuTypes = [[[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"i386-softmmu",@"x86_64-softmmu",@"ppc-softmmu",@"sparc-softmmu",@"mips-softmmu",@"arm-softmmu",nil] forKeys:[NSArray arrayWithObjects:@"x86",@"x86-64",@"PowerPC",@"SPARC",@"MIPS",@"ARM",nil]] retain];
					
	/* create PC directory */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath: [NSString stringWithFormat:@"%@/", [userDefaults objectForKey:@"dataPath"]]] == NO)
		[fileManager createDirectoryAtPath: [NSString stringWithFormat:@"%@/", [userDefaults objectForKey:@"dataPath"]] attributes: nil];

	/* initialise pcs */
	[self loadConfigurations];
	
	/* change status to "shutdown" after corrupt termination of QEMU */
	int i;
	for (i=0; i < [pcs count]; i++)
	if ([[[[pcs objectAtIndex:i] objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"] ) {
			[[[pcs objectAtIndex:i] objectForKey:@"PC Data"] setObject:@"shutdown" forKey:@"state"];
			[self savePCConfiguration:[pcs objectAtIndex:i]];
	}

	/* Creating Toolbar */
	NSToolbar *controlWindowToolbar = [[[NSToolbar alloc] initWithIdentifier: @"controlWindowToolbarIdentifier"] autorelease];
	[controlWindowToolbar setAllowsUserCustomization: YES]; //allow customisation
	[controlWindowToolbar setAutosavesConfiguration: YES]; //autosave changes
	[controlWindowToolbar setDisplayMode: NSToolbarDisplayModeIconOnly]; //what is shown
	[controlWindowToolbar setSizeMode:NSToolbarSizeModeSmall]; //default Toolbar Size
	[controlWindowToolbar setDelegate: self]; // We are the delegate
	[mainWindow setToolbar: controlWindowToolbar]; // Attach the toolbar to the document window 
	
	/* format Cell to imageCell */
	id cell;
	NSTableColumn *theColumn;
	theColumn = [table tableColumnWithIdentifier:@"image"];
	cell = [NSImageCell new];
	[theColumn setDataCell:cell];
	
	/* handle Table DoubleClick */
	[table setTarget:self];
	[table setDoubleAction:@selector(tableDoubleClick:)];
	
	/* Timer for Updates */
	timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector( updateThumbnails ) userInfo:nil repeats:YES];

	/* Dictionary for Tasks */
	pcsTasks = [[NSMutableDictionary alloc] init];
	pcsPIDs = [[NSMutableDictionary alloc] init];
	
	/* Dictionary for Windows Numbers */
	pcsWindows = [[NSMutableArray alloc] init];
	
	/*loading initial Thumbnails */
	[self updateThumbnails];
}



- (void) applicationWillBecomeActive:(NSNotification *)aNotification
{
//	NSLog(@"applicationWillBecomeActive: applicationWillBecomeActive");

	NSEnumerator *enumerator = [pcsPIDs keyEnumerator];
	id key;
	NSMutableDictionary *pcsWindowsNumbers = [[NSMutableDictionary alloc] init];
	
	while ((key = [enumerator nextObject])) {
		[pcsWindowsNumbers setObject:
			[[[pcsPIDs objectForKey:key] objectForKey:@"PC Data"] objectForKey:@"name"]
		forKey:
			[NSString stringWithFormat:@"%d",[qdoserver guestWindowNumber:[[[pcsPIDs objectForKey:key] objectForKey:@"PC Data"] objectForKey:@"name"]]]
		];
	}

	int wcount;
	NSCountWindows(&wcount);
	int wlist[wcount];
	NSWindowList(wcount, wlist);
	[pcsWindows removeAllObjects];
	int i;
	
	for (i=0; i<wcount; i++) {
		if ([pcsWindowsNumbers objectForKey:[NSString stringWithFormat:@"%d",wlist[i]]]) {
			[pcsWindows addObject:[pcsWindowsNumbers objectForKey:[NSString stringWithFormat:@"%d",wlist[i]]]];
		} else if (wlist[i]==[mainWindow windowNumber]) {
			[pcsWindows addObject:@"Q Control"];
		}
		
	}
	
}

- (void) applicationDidBecomeActive:(NSNotification *)aNotification
{
//	NSLog(@"cocoaControlController: applicationDidBecomeActive");

	int i;
	int aboveWindowNumber = [mainWindow windowNumber];
	
	if ([mainWindow isKeyWindow]) {
		
		/* set Key Window */
		if (![[pcsWindows objectAtIndex:0] isEqual:@"Q Control"]) {
			ProcessSerialNumber psn;
			GetProcessForPID( [[pcsTasks objectForKey:[pcsWindows objectAtIndex:0]] processIdentifier], &psn );
			SetFrontProcess( &psn );
			aboveWindowNumber = [qdoserver guestWindowNumber:[pcsWindows objectAtIndex:0]];;
		}
		
		/* set other Windows */
		for (i=1; i<[pcsWindows count]; i++) {/* displaying windows with the lowest possible flicker */
			if ([[pcsWindows objectAtIndex:i] isEqual:@"Q Control"]) {
				aboveWindowNumber = [mainWindow windowNumber];
			} else {
				[qdoserver guestOrderWindow:NSWindowBelow relativeTo:aboveWindowNumber guest:[pcsWindows objectAtIndex:i]];
				aboveWindowNumber = [qdoserver guestWindowNumber:[pcsWindows objectAtIndex:i]];
			}
		}

		[pcsWindows removeAllObjects];
	}
}

- (void) applicationWillHide:(NSNotification *)aNotification
{
//	NSLog(@"cocoaControlController: applicationWillHide");

	NSEnumerator *enumerator = [pcsPIDs keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) {
		[qdoserver guestHide:[[[pcsPIDs objectForKey:key] objectForKey:@"PC Data"] objectForKey:@"name"]];
	}
}

- (void) applicationWillUnhide:(NSNotification *)aNotification
{
//	NSLog(@"cocoaControlController: applicationWillUnhide");

	NSEnumerator *enumerator = [pcsPIDs keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) {
		[qdoserver guestUnhide:[[[pcsPIDs objectForKey:key] objectForKey:@"PC Data"] objectForKey:@"name"]];
	}
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
//	NSLog(@"cocoaControlController: applicationShouldTerminate");
	
	if ([pcsPIDs count]) {
		[self standardAlert: NSLocalizedStringFromTable(@"applicationShouldTerminate:standardAlert", @"Localizable", @"cocoaControlController")
			 informativeText: NSLocalizedStringFromTable(@"applicationShouldTerminate:informativeText", @"Localizable", @"cocoaControlController")];
		return NSTerminateCancel;
	}

	return NSTerminateNow;
}

-(void) applicationWillTerminate:(NSNotification *)notification
{
//	NSLog(@"cocoaControlController: applicationWillTerminate");
	
	/* cleanup */
	[pcsPIDs release];
	[pcsTasks release];
	[pcs release];
	[pcsImages release];
	[pcsWindows release];
}

/* mainMenu */
- (IBAction) showPreferences:(id)sender
{
//	NSLog(@"cocoaControlController: showPreferences");

	/* enter current Values into preferencesPanel */
	[preferences preparePreferences];

	/* display preferencesPanel */
	[[preferences preferencesPanel] setDelegate:preferences];
	[[preferences preferencesPanel] center];
	[[preferences preferencesPanel] makeKeyAndOrderFront:self];
}

- (IBAction) qemuWindowMoveToFront:(id)sender
{
//	NSLog(@"cocoaControlController: qemuWindowMoveToFront");
	
	ProcessSerialNumber psn;
	
	/* move a QEMU to front */
	GetProcessForPID( [sender tag], &psn );
	SetFrontProcess( &psn );
}

/* NSWindow Delegate */
- (BOOL) windowShouldClose:(id)sender
{
//	NSLog(@"cocoaControlController: windowShouldClose");
	
	[NSApp terminate:nil];
	return NO;
}


- (void) checkATaskStatus:(NSNotification *)aNotification
{
//	NSLog(@"cocoaControlController: checkATaskStatus");
	
	id thisPC;
	
	thisPC = [pcsPIDs objectForKey:[NSString stringWithFormat:@"%d", [[aNotification object] processIdentifier]]];
	if (!thisPC)
		return;
	
	int status = [[aNotification object] terminationStatus];
	if (status == 0) {
		[[thisPC objectForKey:@"PC Data"] setObject:@"shutdown" forKey:@"state"];
	} else if (status == 2) {
		[[thisPC objectForKey:@"PC Data"] setObject:@"saved" forKey:@"state"];
	} else {
        // something is wrong here :-)
		[[thisPC objectForKey:@"PC Data"] setObject:@"shutdown" forKey:@"state"];
		
		// error management here //
        NSData * pipedata;
        //NSFileHandle * fileHandle = [pcsPipes objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"] fileHandleForReading];
        
        while ((pipedata = [[[[pcsTasks objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]] standardOutput] fileHandleForReading] availableData]) && [pipedata length])
		{
            NSString * console_out = [[[NSString alloc] initWithData:pipedata encoding:NSUTF8StringEncoding] autorelease];
            // trim string to only contain the error
            NSArray * comps = [console_out componentsSeparatedByString:@": "];
            NSLog(@"error: %@", console_out);
            NSString * errormsg = [@"Error: " stringByAppendingString:[comps objectAtIndex:1]];         
            [self standardAlert:@"Qemu unexpectedly quit" informativeText:errormsg];         
        }
    }

	/* Save Data */
	[self savePCConfiguration:thisPC];
	[table reloadData];

	/* update Table */
	[self loadConfigurations];
	
	/* remove entry from windowMenu */
	[windowMenu removeItemAtIndex:[windowMenu indexOfItemWithTitle:[NSString stringWithFormat:@"Q - %@", [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]]];

	/* cleanup */
	[thisPC release];
	[pcsTasks removeObjectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];
	[pcsPIDs removeObjectForKey:[NSString stringWithFormat:@"%d", [[aNotification object] processIdentifier]]];
	if([pcsPipes objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]])
        [pcsPipes removeObjectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];

}

/* control Window */
- (void) loadConfigurations
{
//	NSLog(@"cocoaControlController: loadConfigurations");

	if (pcs)
		[pcs release];
	
	pcs = [[[NSMutableArray alloc] init] retain];
	NSString *configurationFile;
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[userDefaults objectForKey:@"dataPath"]];
	while ((configurationFile = [enumerator nextObject])) {
		if ([[configurationFile lastPathComponent] isEqualToString:@"configuration.plist"]) {
			NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [userDefaults objectForKey:@"dataPath"], configurationFile]];
			if (data) {
				NSMutableDictionary *tempPC = [NSPropertyListSerialization
					propertyListFromData: data
					mutabilityOption: NSPropertyListMutableContainersAndLeaves
					format: nil
					errorDescription: nil];
				
				/* upgrade Version 0.1.0.Q */
				if ([[tempPC objectForKey:@"Version"] isEqual:@"0.1.0.Q"]) {
					NSArray *singleArguments = [[NSArray init] arrayWithObjects:@"-snapshot", @"-nographic", @"-audio-help", @"-localtime", @"-full-screen", @"-win2k-hack", @"-usb", @"-s", @"-S", @"-d", @"-std-vga", nil];
					NSEnumerator *enumerator = [[tempPC objectForKey:@"Arguments"] keyEnumerator];
					id key;
					NSMutableString *newArguments = [[NSMutableString alloc] init];
					while ((key = [enumerator nextObject])) {
						if ([[tempPC objectForKey:@"Arguments"] objectForKey:key]) {
							if ([key isEqual:@"-net"] && [[[tempPC objectForKey:@"Arguments"] objectForKey:key] isEqual:@"user"]) {
								[newArguments appendFormat:[NSString stringWithFormat:@" -net nic"]];
							}
							if ([singleArguments containsObject:key]) {
								[newArguments appendFormat:[NSString stringWithFormat:@" %@", key]];
							} else {
								[newArguments appendFormat:[NSString stringWithFormat:@" %@ %@", key, [[tempPC objectForKey:@"Arguments"] objectForKey:key]]];
							}
						}
					}
					[tempPC setObject:newArguments forKey:@"Arguments"];
					[tempPC setObject:@"0.2.0.Q" forKey:@"Version"];
				}
				
				/* isolate Arguments, that we need for the table
					-m
					-soundhw
					-M
				*/
				NSArray *tableArguments = [[NSArray init] arrayWithObjects:@"-m", @"-soundhw", @"-M", nil];
				NSArray *array = [[tempPC objectForKey:@"Arguments"] componentsSeparatedByString:@" "];
				NSMutableString *option = [[NSMutableString alloc] initWithString:@""];
				NSMutableString *argument = [[NSMutableString alloc] init];
				int i;
				for (i = 1; i < [array count]; i++) {
					if ([[array objectAtIndex:i] cString][0] != '-') { //Teil eines Arguments
						[argument appendFormat:[NSString stringWithFormat:@" %@", [array objectAtIndex:i]]];
					} else {
						if ([option length] > 0) {
							if ([tableArguments containsObject:option]) {
								[[tempPC objectForKey:@"Temporary"] setObject:[argument substringFromIndex:1] forKey:option];
							}
						}
						[option setString:[array objectAtIndex:i]];
						[argument setString:@""];
					}
				}
				if ([tableArguments containsObject:option]) {
					[[tempPC objectForKey:@"Temporary"] setObject:[argument substringFromIndex:1] forKey:option];
				}
	
				[[tempPC objectForKey:@"Temporary"] setObject:[NSString stringWithFormat:@"%@/%@", [userDefaults objectForKey:@"dataPath"], [configurationFile stringByDeletingLastPathComponent]] forKey:@"-cocoapath"];
				[pcs addObject: tempPC];
			}
		}
	}
}

- (void) savePCConfiguration:(id)thisPC
{
//	NSLog(@"cocoaControlController: savePCConfiguration");

	NSData *data = [NSPropertyListSerialization
		dataFromPropertyList: thisPC
		format: NSPropertyListXMLFormat_v1_0
		errorDescription: nil];
	[data writeToFile:[NSString stringWithFormat:@"%@/configuration.plist", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]] atomically:YES];

}

- (void) updateThumbnails
{
//	NSLog(@"cocoaControlController: updateThumbnails");
	
	if (pcsImages)
		[pcsImages release];
	
	pcsImages = [[NSMutableArray alloc] init];
	
	int i;
	for (i = 0; i < [pcs count]; i++ ) {
		NSString *pathImage = [NSString stringWithFormat: @"%@/thumbnail.png", [[[pcs objectAtIndex:i] objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]];
		NSImage *image =	[[NSImage alloc] initWithContentsOfFile:pathImage];	
		if (image) {
			[pcsImages addObject:image];
		} else {
			[pcsImages addObject:[NSImage imageNamed: @"q_table_shutdown.png"]];
		}
		[image release];
	}
	
	[table reloadData];
}

/* Toolbar delegates */
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];  
	if ([itemIdent isEqual: @"newPCIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:newPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:newPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:newPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_newpc.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( addPC: )];
	} else if ([itemIdent isEqual: @"editPCIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:editPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:editPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:editPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_editpc.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( editPC: )];
	} else if([itemIdent isEqual: @"removePCIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:removePC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:removePC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:removePC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_removepc.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( deletePC: )];
	} else if([itemIdent isEqual: @"startPCIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:startPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:startPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:startPC", @"Localizable", @"cocoaControlController")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_startpc.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( tableDoubleClick: )];
	} else if([itemIdent isEqual: @"importVPC7Identifier"]) {
		[toolbarItem setLabel: @"Import VPC7"];
		[toolbarItem setPaletteLabel: @"Import VPC7"];
		[toolbarItem setToolTip: @"Import VPC7"];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_impvpc.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( importVPC7PC: )];
	} else if([itemIdent isEqual: @"importQemuXIdentifier"]) {
		[toolbarItem setLabel: @"Import QemuX"];
		[toolbarItem setPaletteLabel: @"Import QemuX"];
		[toolbarItem setToolTip: @"Import QemuX"];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_impqemux.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( importQemuXPCs: )];
	} else {
		toolbarItem = nil;
	}
	
	return toolbarItem;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:
		@"newPCIdentifier",
		@"editPCIdentifier",
		@"removePCIdentifier",
		@"startPCIdentifier",
		@"importVPC7Identifier",
		@"importQemuXIdentifier",
		NSToolbarCustomizeToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		@"newPCIdentifier",
		@"editPCIdentifier",
		@"startPCIdentifier",
		NSToolbarFlexibleSpaceItemIdentifier,
		//		NSToolbarCustomizeToolbarItemIdentifier,
		@"removePCIdentifier",
		nil];
}

- (BOOL) validateToolbarItem:(NSToolbarItem *)theItem
{
	return YES;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
//	NSLog(@"windowDidBecomeKey");
}

-(int)numberOfRowsInTableView:(NSTableView *)table
{
	return [pcs count];
}

-(IBAction) addPC:(id)sender
{
//	NSLog(@"cocoaControlController: addPC");

	/* standard values */
	NSMutableDictionary *thisPC = [[[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Q", @"none", [NSDate date], @"Q guest PC", nil] forKeys:[NSArray arrayWithObjects: @"Author", @"Copyright", @"Date", @"Description", nil]],
		[[NSMutableString alloc] initWithString:@"-m 128 -net nic -net user -cdrom /dev/cdrom -boot c -localtime -smb ~/Desktop/Q Shared Files/"],
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"My new PC", @"shutdown", @"x86", nil] forKeys:[NSArray arrayWithObjects: @"name", @"state", @"architecture", nil]],
//		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:true], nil] forKeys:[NSArray arrayWithObjects: @"QWinDrivers", nil]],
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects: nil] forKeys:[NSArray arrayWithObjects: nil]],
		@"0.2.0.Q",
		nil
	] forKeys:[NSArray arrayWithObjects:@"About", @"Arguments", @"PC Data", @"Temporary", @"Version", nil]] retain];
				
	/* enter current Values into editPCPanel */
	[editPC prepareEditPCPanel:thisPC newPC:YES sender:self];
 
	/* display editPCPanel */		  
	[[editPC editPCPanel] makeKeyAndOrderFront:self];
	[NSApp runModalForWindow:[editPC editPCPanel]];
}

-(IBAction) editPC:(id)sender
{
//	NSLog(@"cocoaControlController: editPC");

	/* no empty line selection */
	if ( [table numberOfSelectedRows] == 0 )
		return;
	
	/* don't allow to edit a running/saved pc */
	id thisPC;
	thisPC = [pcs objectAtIndex:[table selectedRow]];
	
	if (![[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"]) {
		[self standardAlert: [NSString stringWithFormat: NSLocalizedStringFromTable(@"editPC:standardAlert", @"Localizable", @"cocoaControlController"),[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]
			 informativeText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"editPC:informativeText", @"Localizable", @"cocoaControlController"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
		return;
	}

	/* enter current Values into editPCPanel */
	[editPC prepareEditPCPanel:thisPC newPC:NO sender:self];

	/* display editPCPanel */
	[[editPC editPCPanel] makeKeyAndOrderFront:self];
	[NSApp runModalForWindow:[editPC editPCPanel]];
}

-(BOOL) checkPC:(NSString *)name create:(BOOL)create
{
//	NSLog(@"cocoaControlController: checkPC");

	NSEnumerator *enumerator = [pcs objectEnumerator];
	id object;
	
	if (create) {
		while ( (object = [enumerator nextObject]) ) {
			if ([[[object objectForKey:@"PC Data"] objectForKey:@"name"] isEqual: name] )
				return 0;
		}
	} else {
		id thisPC = [pcs objectAtIndex:[table selectedRow]];
		while ( (object = [enumerator nextObject]) ) {
			if ([[[object objectForKey:@"PC Data"] objectForKey:@"name"] isEqual: name]) {
				if ( ![[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"] isEqual:name])
					return 0;
			}
		}
	}
	
	return 1;
}

-(IBAction) deletePC:(id)sender
{
//	NSLog(@"cocoaControlController: deletePC");

	/* no empty line selection */
	if ( [table numberOfSelectedRows] == 0 )
		return;
	
	/* don't allow to delete a running pc */
	id thisPC;
	thisPC = [pcs objectAtIndex:[table selectedRow]];
	if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"]) {
		[self standardAlert: [NSString stringWithFormat: NSLocalizedStringFromTable(@"deletePC:standardAlert", @"Localizable", @"cocoaControlController"),[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]
			 informativeText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"deletePC:informativeText", @"Localizable", @"cocoaControlController"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
		return;
	}
	
	/* prepare alert */
	NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"deletePC:alertWithMessageText", @"Localizable", @"cocoaControlController")
					  defaultButton: NSLocalizedStringFromTable(@"deletePC:defaultButton", @"Localizable", @"cocoaControlController")
					alternateButton: NSLocalizedStringFromTable(@"deletePC:alternateButton", @"Localizable", @"cocoaControlController")
						otherButton:nil
				  informativeTextWithFormat:[NSString stringWithFormat: NSLocalizedStringFromTable(@"deletePC:informativeTextWithFormat", @"Localizable", @"cocoaControlController"),[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
	
	/* display alert */
	[alert beginSheetModalForWindow:mainWindow
				  modalDelegate:self
				 didEndSelector:@selector(deletePCAlertDidEnd:returnCode:contextInfo:)
				 contextInfo:nil];
}

- (BOOL) importFreeOSZooPC:(NSString *)name withPath:(NSString *)path
{
	NSMutableDictionary * thisPC = [[[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Q", @"none", [NSDate date], @"Q guest PC from FreeOSZoo", nil] forKeys:[NSArray arrayWithObjects: @"Author", @"Copyright", @"Date", @"Description", nil]],
		[[NSMutableString alloc] initWithString:@" -m 128 -net user -boot c -localtime -smb ~/Desktop/Q Shared Files/"],
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"My new PC", @"shutdown", @"x86", nil] forKeys:[NSArray arrayWithObjects: @"name", @"state", @"architecture", nil]],
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:true], nil] forKeys:[NSArray arrayWithObjects: @"QWinDrivers", nil]],
		@"0.2.0.Q",
		nil
	] forKeys:[NSArray arrayWithObjects:@"About", @"Arguments", @"PC Data", @"Temporary", @"Version", nil]] retain];
	
	[[thisPC objectForKey:@"Temporary"] setObject:path forKey:@"-cocoapath"];
	NSLog(@"-cocoapath: %@", path);
	[[thisPC objectForKey:@"PC Data"] setObject:name forKey:@"name"];
	
	// TODO: use README file to get HD and other arguments 
	// for now we search for a .img/.qcow file and use it as HD
	BOOL foundHD = NO;
	BOOL foundDir = NO;
	NSFileManager * manager = [NSFileManager defaultManager];
	NSArray * dirContents = [manager directoryContentsAtPath:path];
	NSArray * subDir;
	int i,ii;
	for (i=0; i<=[dirContents count]-1; i++) {
		if ([[[dirContents objectAtIndex:i] pathExtension] isEqualToString:@"img"] || [[[dirContents objectAtIndex:i] pathExtension] isEqualToString:@"qcow"]) {
			foundHD = YES;
			break;
		} else if([[[manager fileAttributesAtPath:[path stringByAppendingPathComponent:[dirContents objectAtIndex:i]] traverseLink:NO] objectForKey:NSFileType] isEqualTo:NSFileTypeDirectory]) {
			foundDir = YES;
			NSLog(@"Found Dir: %@", [dirContents objectAtIndex:i]);
			break;
		} else {
			NSLog(@"Found no image or folder.");
		}
	}

	if(foundHD) {
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [dirContents objectAtIndex:i]]];
	} else if(foundDir) {
		subDir = [manager directoryContentsAtPath:[path stringByAppendingPathComponent:[dirContents objectAtIndex:i]]];
		for(ii=0; i<=[subDir count]-1; ii++) {
			// search for .img or .qcow
			if([[[subDir objectAtIndex:ii] pathExtension] isEqualToString:@"img"] || [[[subDir objectAtIndex:i] pathExtension] isEqualToString:@"qcow"]) {
				NSLog(@"found HD in subdir!");
				// move hd to root dir and delete the folder
				[manager movePath:[path stringByAppendingPathComponent:[[dirContents objectAtIndex:i] stringByAppendingPathComponent:[subDir objectAtIndex:ii]]] toPath:[path stringByAppendingPathComponent:[subDir objectAtIndex:ii]] handler:nil];
				[manager removeFileAtPath:[path stringByAppendingPathComponent:[dirContents objectAtIndex:i]] handler:nil];
				[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [subDir objectAtIndex:ii]]];
				foundHD = YES;
				break;
			}
		}
	}
	/* save Configuration */
	[self savePCConfiguration:thisPC];
	
	/* update Table */
	[self loadConfigurations];
	[table reloadData];
	return foundHD;
}

- (NSString *) convertDI:(NSString *)oldImagePath to:(NSString *)newPCname
{
//	NSLog(@"cocoaControlController: convertDI");

	/* search a free Name */
	int i = 1;
	NSString *name;
	NSString *path = [NSString stringWithString:[[NSString stringWithFormat:@"%@/%@.qvm",[userDefaults objectForKey:@"dataPath"], newPCname] stringByExpandingTildeInPath]];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", path, [NSString stringWithFormat:@"Harddisk_%d.qcow", i]]])
		i++;
	name = [NSString stringWithFormat:@"Harddisk_%d.qcow", i];
	
	/* convert diskImage */
	NSArray *arguments = [NSArray arrayWithObjects:@"convert", @"-c", @"-O", @"qcow", oldImagePath, [NSString stringWithFormat:@"%@/%@", path, name], nil];
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: [NSString stringWithFormat:@"%@/MacOS/qemu-img", [[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent]]];
	[task setArguments: arguments];
	[task launch];
	[task waitUntilExit];
	int status = [task terminationStatus];
	[task release];
	
	if (status == 0) {
		return name;
	}
	
	return [NSString stringWithString:@""];
}

- (void) importVPC7PCDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//	NSLog(@"cocoaControlController: importVPC7PCDidEnd");

	/* hide Save Sheet */
	[ sheet orderOut:self ];
	
	if ( returnCode == NSOKButton ) {
		NSString *tempString;
		NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/Configuration.plist", [sheet filename]]];
		if (!data) {
			[self standardAlert: NSLocalizedStringFromTable(@"importVPC7PC:standardAlert:plist", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importVPC7PC:informativeText:plist", @"Localizable", @"cocoaControlController")];
			return;
		}
		
		/* setup & show Progress panel */
		[progressTitle setStringValue: NSLocalizedStringFromTable(@"importVPC7PC:progress:title", @"Localizable", @"cocoaControlController")];
		[progressText setStringValue:[[[sheet filename] lastPathComponent] stringByDeletingPathExtension]];
		[progressStatusText setStringValue: NSLocalizedStringFromTable(@"importVPC7PC:progress:config", @"Localizable", @"cocoaControlController")];
		[progressIndicator setUsesThreadedAnimation:TRUE];
		[progressIndicator setIndeterminate:FALSE];
		[progressIndicator setMaxValue:100];
		[progressIndicator setDoubleValue:10];
		
		[NSApp beginSheet:progressPanel
		modalForWindow:mainWindow 
		modalDelegate:nil
		didEndSelector:nil
		contextInfo:nil];
		
		NSDictionary *vpc7 = [NSPropertyListSerialization
			propertyListFromData: data
			mutabilityOption: nil
			format: nil
			errorDescription: nil];

		/* check if guest is Shutdown */
		if (![vpc7 objectForKey:@"Running At Quit"]) {
			[NSApp endSheet:progressPanel];
			[progressPanel orderOut:self];
			[self standardAlert: NSLocalizedStringFromTable(@"importVPC7PC:standardAlert:running", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importVPC7PC:informativeText:running", @"Localizable", @"cocoaControlController")];
			return;
		}
		
		/* search a free Name */
		int i = 2;
		NSString *name;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@.qvm",[userDefaults objectForKey:@"dataPath"], [[[sheet filename] lastPathComponent] stringByDeletingPathExtension]]]) {
			while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@_%d.qvm",[userDefaults objectForKey:@"dataPath"], [[[sheet filename] lastPathComponent] stringByDeletingPathExtension], i]])
				i++;		
			name = [NSString stringWithFormat:@"%@_%d",[[[sheet filename] lastPathComponent] stringByDeletingPathExtension], i];
		} else {
			name = [[[sheet filename] lastPathComponent] stringByDeletingPathExtension];
		}

		/* standard values */
		NSMutableDictionary *thisPC = [[[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Q", @"none", [NSDate date], @"Q guest PC converted from vpc7.", nil] forKeys:[NSArray arrayWithObjects: @"Author", @"Copyright", @"Date", @"Description", nil]],
		[[NSMutableString alloc] initWithString:@"-net nic -net user -boot c -localtime"],
		[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:name, @"shutdown", @"x86", nil] forKeys:[NSArray arrayWithObjects: @"name", @"state", @"architecture", nil]],
		[[NSMutableDictionary alloc] init],
		@"0.2.0.Q",
		nil
		] forKeys:[NSArray arrayWithObjects:@"About", @"Arguments", @"PC Data", @"Temporary", @"Version", nil]] retain];
							
		[[thisPC objectForKey:@"Temporary"] setObject:[NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], name] forKey:@"-cocoapath"];
		
		/* vpc7 values */
		/* RAM */
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -m %@", [vpc7 objectForKey:@"Memory/RAM Size"]]];

		/* CD-ROM */
		if ([vpc7 objectForKey:@"CDROM/Captured Image Location"]) {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -cdrom %@", [[vpc7 objectForKey:@"CDROM/Captured Image Location"] objectForKey:@"_CFURLString"]]];
		} else {
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -cdrom /dev/cdrom"]];
		}
		
		[progressIndicator setDoubleValue:20];

		/* Harddisks */
		NSArray *ideChannels = [NSArray arrayWithObjects:@"-hda",@"-hdb",@"-hdd",nil];
		if ([fileManager fileExistsAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]] == NO)
			[fileManager createDirectoryAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"] attributes: nil];	
		i = 0;
		while (([vpc7 objectForKey:[NSString stringWithFormat:@"IDE/Drive/%D/Location",i]]) && (i < 3)) {
			[progressStatusText setStringValue:[NSString stringWithFormat: NSLocalizedStringFromTable(@"importVPC7PC:progress:hdx", @"Localizable", @"cocoaControlController"), i]];
			/* Try relative Path */
			if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@/BaseDrive.vhd", [sheet filename], [[[vpc7 objectForKey:[NSString stringWithFormat:@"IDE/Drive/%D/Location",i]] objectForKey:@"_CFURLString"] lastPathComponent]]]) {
				tempString = [self convertDI:[NSString stringWithFormat:@"%@/%@/BaseDrive.vhd", [sheet filename], [[[vpc7 objectForKey:[NSString stringWithFormat:@"IDE/Drive/%D/Location",i]] objectForKey:@"_CFURLString"] lastPathComponent]] to:name];
				if ([tempString isEqual:@""]) {
					[NSApp endSheet:progressPanel];
					[progressPanel orderOut:self];
					[self standardAlert: NSLocalizedStringFromTable(@"importVPC7PC:standardAlert:imageConvert", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importVPC7PC:informativeText:imageConvert", @"Localizable", @"cocoaControlController")];
					return;		
				}
				[[thisPC objectForKey:@"Arguments"] appendFormat: [NSString stringWithFormat:@" %@ %@", [ideChannels objectAtIndex:i], tempString]];
			/* Try absolute Path */
			} else if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/BaseDrive.vhd", [[vpc7 objectForKey:[NSString stringWithFormat:@"IDE/Drive/%D/Location",i]] objectForKey:@"_CFURLString"]]]) {
				tempString = [self convertDI:[NSString stringWithFormat:@"%@/BaseDrive.vhd", [[vpc7 objectForKey:[NSString stringWithFormat:@"IDE/Drive/%D/Location",i]] objectForKey:@"_CFURLString"]] to:name];
				if ([tempString isEqual:@""]) {
					[NSApp endSheet:progressPanel];
					[progressPanel orderOut:self];
					[self standardAlert: NSLocalizedStringFromTable(@"importVPC7PC:standardAlert:imageConvert", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importVPC7PC:informativeText:imageConvert", @"Localizable", @"cocoaControlController")];
					return;		
				}
				[[thisPC objectForKey:@"Arguments"] appendFormat: [NSString stringWithFormat:@" %@ %@", [ideChannels objectAtIndex:i], tempString]];
			}
			i++;
			[progressIndicator setDoubleValue:(20 + i * 20)];
		}
		
		/* save Configuration */
		[self savePCConfiguration:thisPC];
		[progressIndicator setDoubleValue:100];

		/* update Table */
		[self loadConfigurations];

		/* hide panel */
		[NSApp endSheet:progressPanel];
		[progressPanel orderOut:self];
		
		/* show warining */
		[self standardAlert: NSLocalizedStringFromTable(@"importVPC7PC:standardAlert:finish", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importVPC7PC:informativeText:finish", @"Localizable", @"cocoaControlController")];
	}
}

- (IBAction) importVPC7PC:(id)sender
{
//	NSLog(@"cocoaControlController: importVPC7PC");

	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel beginSheetForDirectory:[NSString stringWithFormat:@"%@/Documents/Virtual PC List", NSHomeDirectory()]
		file:nil
		types:[NSArray arrayWithObjects:@"vpc7", nil]
		modalForWindow:mainWindow
		modalDelegate:self
		didEndSelector:@selector(importVPC7PCDidEnd:returnCode:contextInfo:)
		contextInfo:sender];
}

- (IBAction) importQemuXPCs:(id)sender
{
//	NSLog(@"cocoaControlController: importQemuXPCs");

	/* setup & show Progress panel */
	[progressTitle setStringValue: NSLocalizedStringFromTable(@"importQemuXPCs:progress:title", @"Localizable", @"cocoaControlController")];
	[progressText setStringValue:@""];
	[progressStatusText setStringValue: NSLocalizedStringFromTable(@"importQemuXPCs:progress:config", @"Localizable", @"cocoaControlController")];
	[progressIndicator setUsesThreadedAnimation:TRUE];
	[progressIndicator setIndeterminate:FALSE];
	[progressIndicator setMaxValue:100];
	[progressIndicator setDoubleValue:0];
		
	[NSApp beginSheet:progressPanel
		modalForWindow:mainWindow 
		modalDelegate:nil
		didEndSelector:nil
		contextInfo:nil];

//	NSMutableString *message = [NSMutableString stringWithFormat: NSLocalizedStringFromTable(@"importQemuXPCs:message", @"Localizable", @"cocoaControlController")];
	NSArray * qemux = [NSArray arrayWithContentsOfFile:[@"~/Library/Application Support/QemuX/oslist.plist" stringByExpandingTildeInPath]];

	if (!qemux) {
		[NSApp endSheet:progressPanel];
		[progressPanel orderOut:self];
		[self standardAlert: NSLocalizedStringFromTable(@"importQemuXPCs:standardAlert:plist", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importQemuXPCs:informativeText:plist", @"Localizable", @"cocoaControlController")];
		return;
	}

	/* check if guest is Shutdown, seems difficult for QemuX
	should we instead check for QemuX running?
	if (![vpc7 objectForKey:@"Running At Quit"]) {
		[self standardAlert:@"Import of VPC7 Guest" informativeText:@"PC is running! It must be shut down before it can be converted."];
		return;
	}
	*/
	
	/* standard values, no -boot c here, we look for the boot param later */
	NSMutableDictionary *thisPC = [[[NSMutableDictionary alloc] init] retain];
	NSDictionary *standardValues = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:
	[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Q", @"none", [NSDate date], @"Q guest PC converted from QemuX.", nil] forKeys:[NSArray arrayWithObjects: @"Author", @"Copyright", @"Date", @"Description", nil]],
	[[NSMutableString alloc] initWithString:@"-net nic -net user -localtime"],
	[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"name_placeholder", @"shutdown", @"x86", nil] forKeys:[NSArray arrayWithObjects: @"name", @"state", @"architecture", nil]],
	[[NSMutableDictionary alloc] init],
	@"0.2.0.Q",
	nil
	] forKeys:[NSArray arrayWithObjects:@"About", @"Arguments", @"PC Data", @"Temporary", @"Version", nil]];
	
	int i;
	for(i = 0; i<=[qemux count]-1; i++) {
		/* go through the array and import the pc's */
		
		NSFileManager * fileManager = [NSFileManager defaultManager];
		/* set Standard Values & Name */
		NSString *name = [[qemux objectAtIndex:i] objectForKey:@"name"];
		/* just to be sure... */
		[thisPC removeAllObjects];
		[thisPC setDictionary:standardValues];
		[[thisPC objectForKey:@"PC Data"] setObject:name forKey:@"name"];
//		[message appendFormat:@"%@\n", name];

		/* update Progresspanel text */
		[progressText setStringValue:[NSString stringWithFormat: NSLocalizedStringFromTable(@"importQemuXPCs:progress:pc", @"Localizable", @"cocoaControlController"), name]];

		
		/* set the -cocoapath */
		[[thisPC objectForKey:@"Temporary"] setObject:[NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], name] forKey:@"-cocoapath"];
		NSLog(@"cocoapath: %@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]);
		
		/* Create .qvm */
		[fileManager createDirectoryAtPath:[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"] attributes: nil];
		
		/* QemuX values */
		/* RAM */
		[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -m %@", [[qemux objectAtIndex:i] objectForKey:@"ram"]]];
		
		/* CD-Rom */
		if([[[qemux objectAtIndex:i] objectForKey:@"cdrom"] isEqualToString:@""]) {
			/* when cd-rom is not given, add /dev/cdrom */
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -cdrom /dev/cdrom"]];
		} else {
			/* path to cd-image given, save it and copy image */
			[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -cdrom %@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"] ,[[[qemux objectAtIndex:i] objectForKey:@"cdrom"]	lastPathComponent]]];
			[fileManager copyPath:[[qemux objectAtIndex:i] objectForKey:@"cdrom"] toPath:[NSString stringWithFormat:@"%@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:@"cdrom"] lastPathComponent]] handler: nil];
		}
		
		/* Harddisks */
		NSArray * hds = [NSArray arrayWithObjects:@"fda",@"hda",@"hdb",@"hdc",@"hdd", nil];
		
		int ii;
		for(ii = 0; ii<=[hds count]-1; ii++) {
			[progressStatusText setStringValue:[NSString stringWithFormat: NSLocalizedStringFromTable(@"importQemuXPCs:progress:hdx", @"Localizable", @"cocoaControlController"), [[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] lastPathComponent]]];
			if([[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] && ![[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] isEqualToString:@""]) {
				// add to arguments
				[[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -%@ %@",[hds objectAtIndex:ii], [[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] lastPathComponent]]];
				// copy over into .qvm
				[fileManager copyPath:[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] toPath:[NSString stringWithFormat:@"%@/%@",	 [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] lastPathComponent]] handler:nil];
				NSLog(@"copy allowed, done.");
			}
			NSLog(@"hd: %@", [[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]]);
			NSLog(@"copy from %@ to %@", [[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]], [NSString stringWithFormat:@"%@/%@",	[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] lastPathComponent]]);
		}
		
		// Boot param
		switch ([[[qemux objectAtIndex:i] objectForKey:@"boot"] intValue]) {
			case 0: 
				[[thisPC objectForKey:@"Arguments"] appendString:@" -boot a"];
				break;
			case 1:
				[[thisPC objectForKey:@"Arguments"] appendString:@" -boot c"];
				break;
			case 2:
				[[thisPC objectForKey:@"Arguments"] appendString:@" -boot d"];
				break;
			default:
				[[thisPC objectForKey:@"Arguments"] appendString:@" -boot c"];
		}
		
		/* additional options */
		// Linux boot specific:
		
		// Linux Kernel
		if(([[qemux objectAtIndex:i] objectForKey:@"linuxKernel"]) && !([[[qemux objectAtIndex:i] objectForKey:@"linuxKernel"] isEqualToString:@""])) {
			// copy into .qvm, set the parameter
			[fileManager copyPath:[[qemux objectAtIndex:i] objectForKey:@"linuxKernel"] toPath:[NSString stringWithFormat:@"%@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:@"linuxKernel"] lastPathComponent]] handler:nil];	  
			[[thisPC objectForKey:@"Arguments"] appendFormat:@" -kernel %@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:@"linuxKernel"] lastPathComponent]];					  
		}
		
		// Linux Ramdisk
		if(([[qemux objectAtIndex:i] objectForKey:@"linuxRamdisk"]) && !([[[qemux objectAtIndex:i] objectForKey:@"linuxRamdisk"] isEqualToString: @""])) {
			// copy into .qvm, set the parameter
			[fileManager copyPath:[[qemux objectAtIndex:i] objectForKey:@"linuxRamdisk"] toPath:[NSString stringWithFormat:@"%@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:@"linuxRamdisk"] lastPathComponent]] handler:nil];	
			[[thisPC objectForKey:@"Arguments"] appendFormat:@" -initrd %@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:@"linuxRamdisk"] lastPathComponent]];
		}
		
		// Linux Kernel Command Line
		if(([[qemux objectAtIndex:i] objectForKey:@"linuxCmdline"]) && !([[[qemux objectAtIndex:i] objectForKey:@"linuxCmdline"] isEqualToString: @""])) {
			// set the parameter	 
			[[thisPC objectForKey:@"Arguments"] appendFormat:@" -append %@", [[qemux objectAtIndex:i] objectForKey:@"linuxCmdline"]];
		}
		
		// additional options, summarized
		// options with integer values 0,1 (NO,YES)
		NSArray * additionalIntSynonym = [NSArray arrayWithObjects:@"freeze",@"gdb",@"nographic",@"snapshot",@"stdvga",nil];
		// array for the QEMU command line paramters from above, because QemuX used to store them with slightly different names
		NSArray * additionalIntQemu = [NSArray arrayWithObjects:@"-S",@"-s",@"-nographic",@"-snapshot",@"-std-vga",nil];
		
		for(ii=0; ii<=[additionalIntSynonym count]-1; ii++) {
			// if they are TRUE, append to arguments
			if([[[qemux objectAtIndex:i] objectForKey:[additionalIntSynonym objectAtIndex:ii]] intValue] == 1) {
				[[thisPC objectForKey:@"Arguments"] appendFormat:@" %@", [additionalIntQemu objectAtIndex:ii]];
			}
		}
		
		// options with string values
		NSArray * additionalStringSynonym = [NSArray arrayWithObjects:@"gdbport",@"monitor",@"redir",@"serial",nil];
		NSArray * additionalStringQemu = [NSArray arrayWithObjects:@"-p",@"-monitor",@"-redir",@"serial",nil];

		for(ii=0; ii<=[additionalStringSynonym count]-1; ii++) {
			// if they are not empty, append to arguments
			if(![[[qemux objectAtIndex:i] objectForKey:[additionalStringSynonym objectAtIndex:ii]] isEqualToString:@""]) {
				[[thisPC objectForKey:@"Arguments"] appendFormat:@" %@ %@", [additionalStringQemu objectAtIndex:ii], [[qemux objectAtIndex:i] objectForKey:[additionalStringSynonym objectAtIndex:ii]]];
			}
		}
			
		/* save Configuration */
		[self savePCConfiguration:thisPC];
		
		/* update Progressbar */
		[progressIndicator setDoubleValue:(100 / [qemux count] * (i + 1))];
	}
	
//	[message appendString: NSLocalizedStringFromTable(@"importQemuXPCs:message:appendString", @"Localizable", @"cocoaControlController")];

	/* update Table */
	[self loadConfigurations];

	/* hide panel */
	[NSApp endSheet:progressPanel];
	[progressPanel orderOut:self];
	
	/* show warining */
	[self standardAlert: NSLocalizedStringFromTable(@"importQemuXPCs:standardAlert:finish", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importQemuXPCs:informativeText:finish", @"Localizable", @"cocoaControlController")];
}

- (BOOL) addArgumentTo:(id)arguments option:(id)option argument:(id)argument filename:filename
{
//	NSLog(@"addArgumentTo:option:argument:filename:");
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	/* List of incompatible pre 0.8.0 Arguments */
	NSArray *obsoleteArguments = [[NSArray init] arrayWithObjects:@"-user-net", @"-tun-fd", @"-dummy-net", @"-prep", nil];				
	
	/* sort out old configurations */
	if ([obsoleteArguments containsObject:option]) {
		[self standardAlert: NSLocalizedStringFromTable(@"addArgumentTo:standardAlert", @"Localizable", @"cocoaControlController") informativeText:[NSString stringWithFormat: NSLocalizedStringFromTable(@"addArgumentTo:informativeText", @"Localizable", @"cocoaControlController"), option]];
		return FALSE;
	}
	
	/* do some error checking to avoid QEMU shuting down for incorrect Arguments */
	
	/* if files have relative Paths, we guess they are stored in .qvm */
	if ([option isEqual:@"-hda"] || [option isEqual:@"-hdb"] || [option isEqual:@"-hdc"] || [option isEqual:@"-hdd"] || [option isEqual:@"-cdrom"]) {
		[arguments addObject:[NSString stringWithString:option]];
		if ([argument isAbsolutePath]) {
			[arguments addObject:[NSString stringWithString:argument]]; //remove for bools!!!
		} else {
			[arguments addObject:[NSString stringWithFormat:@"%@/%@", filename, argument]]; //remove for bools!!!
		}

	/* "-smb", prepare Folder for Q Filesharing */
	} else if ([option isEqual:@"-smb"]) {
		/* Q Filesharing */
		if ([argument isEqual:@"~/Desktop/Q Shared Files/"]) {
			[fileManager createDirectoryAtPath:[@"~/Desktop/Q Shared Files/" stringByExpandingTildeInPath] attributes: nil];
			[arguments addObject:@"-smb"];
			[arguments addObject:[@"~/Desktop/Q Shared Files/" stringByExpandingTildeInPath]];
		/* normal SMB */
		} else if ([fileManager fileExistsAtPath:argument]) {
			[arguments addObject:@"-smb"];
			[arguments addObject:[NSString stringWithString:argument]];
		}
		
	/* standart */		  
	} else {	
		[arguments addObject:[NSString stringWithString:option]];
		if (![argument isEqual:@""]) {
			[arguments addObject:[NSString stringWithString:argument]];
		}
	}
	return TRUE;
}



- (void) startPC:(NSString *)filename
{
	NSLog(@"cocoaControlController: startPC:%@", filename);
	
	NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/configuration.plist", filename]];
	NSMutableDictionary *thisPC;
	
	if (data) {
		thisPC = [[NSPropertyListSerialization
			propertyListFromData: data
			mutabilityOption: NSPropertyListMutableContainersAndLeaves
			format: nil
			errorDescription: nil] retain];
	} else {
		return;
	}
	
	/* upgrade Version 0.1.0.Q */
	if ([[thisPC objectForKey:@"Version"] isEqual:@"0.1.0.Q"]) {
		NSArray *singleArguments = [[NSArray init] arrayWithObjects:@"-snapshot", @"-nographic", @"-audio-help", @"-localtime", @"-full-screen", @"-win2k-hack", @"-usb", @"-s", @"-S", @"-d", @"-std-vga", nil];
		NSEnumerator *enumerator = [[thisPC objectForKey:@"Arguments"] keyEnumerator];
		id key;
		NSMutableString *newArguments = [[NSMutableString alloc] init];
		while ((key = [enumerator nextObject])) {
			if ([[thisPC objectForKey:@"Arguments"] objectForKey:key]) {
				if ([key isEqual:@"-net"] && [[[thisPC objectForKey:@"Arguments"] objectForKey:key] isEqual:@"user"]) {
					[newArguments appendFormat:[NSString stringWithFormat:@" -net nic"]];
				}
				if ([singleArguments containsObject:key]) {
					[newArguments appendFormat:[NSString stringWithFormat:@" %@", key]];
				} else {
					[newArguments appendFormat:[NSString stringWithFormat:@" %@ %@", key, [[thisPC objectForKey:@"Arguments"] objectForKey:key]]];
				}
			}
		}
		[thisPC setObject:newArguments forKey:@"Arguments"];
		[thisPC setObject:@"0.2.0.Q" forKey:@"Version"];
	}
	
	/* if this PC is already running, abort */
	if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"])
		return;
	
	/* save filename in temp */
	[[thisPC objectForKey:@"Temporary"] setObject:filename forKey:@"-cocoapath"];
	
	NSMutableArray *arguments = [[NSMutableArray alloc] init];
	
	/* Arguments for Q */
		
	/* which display ? */
	if ([[userDefaults objectForKey:@"display"] isEqual:@"OpenGL"]) {
	} else if ([[userDefaults objectForKey:@"display"] isEqual:@"Quartz"]) {
		[arguments addObject: @"-cocoaquartz"];
	} else {
		[arguments addObject: @"-cocoaquickdraw"];
	}
	
	/* where to store PC files */
	[arguments addObject: @"-cocoapath"];
	[arguments addObject: filename];
	
	/* name of the PC */
	[arguments addObject: @"-cocoaname"];
	[arguments addObject: [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];
	
	/* thumbnails */
	[arguments addObject: @"-cocoalivethumbnail"];
	
	/* WMStopWhenInactive */
	if ([[thisPC objectForKey:@"Temporary"] objectForKey:@"WMStopWhenInactive"])
		[arguments addObject: @"-wmstopwheninactive"];
	
	/* Q Windows Drivers */
	if ([[thisPC objectForKey:@"Temporary"] objectForKey:@"QWinDrivers"]) {
		[arguments addObject: @"-hdb"];
		[arguments addObject:[NSString stringWithFormat:@"%@/Contents/Resources/qdrivers.qcow", [[NSBundle mainBundle] bundlePath]]];
	}
	
	/* Arguments of thisPC */
	NSArray *array = [[thisPC objectForKey:@"Arguments"] componentsSeparatedByString:@" "];
	NSMutableString *option = [[NSMutableString alloc] initWithString:@""];
	NSMutableString *argument = [[NSMutableString alloc] init];
	int i;
	for (i = 1; i < [array count]; i++) {
		if ([[array objectAtIndex:i] cString][0] != '-') { //Teil eines Arguments
			[argument appendFormat:[NSString stringWithFormat:@" %@", [array objectAtIndex:i]]];
		} else {
			if ([option length] > 0) {
				if ([argument isEqual:@""]) {
					if (![self addArgumentTo:arguments option:option argument:@"" filename:filename])
						return;
				} else {
					if (![self addArgumentTo:arguments option:option argument:[argument substringFromIndex:1] filename:filename])
						return;
				}
			}
			[option setString:[array objectAtIndex:i]];
			[argument setString:@""];
		}
	}
	if ([argument isEqual:@""]) {
		if (![self addArgumentTo:arguments option:option argument:@"" filename:filename])
			return;
	} else {
		if (![self addArgumentTo:arguments option:option argument:[argument substringFromIndex:1] filename:filename])
			return;
	}
				
	/* start a saved vm */
	if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]) {
		[arguments addObject: @"-loadvm"];
		[arguments addObject:[NSString stringWithFormat: @"%@/saved.vm", filename]]; 
	}

	for (i = 0; i < [arguments count]; i++)
		NSLog(@"Argument: %@", [arguments objectAtIndex:i]);
	
	/* save Status */
	[[thisPC objectForKey:@"PC Data"] setObject:@"running" forKey:@"state"];
	[self savePCConfiguration:thisPC];
	
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: [NSString stringWithFormat:@"%@/Contents/MacOS/%@.app/Contents/MacOS/%@", [[NSBundle mainBundle] bundlePath], [cpuTypes objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"]], [cpuTypes objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"]]]];
	[task setArguments: arguments];
	[arguments release];
	
	// prepare nstask output to grab exit codes
    NSPipe * pipe = [[NSPipe alloc] init];

	[task setStandardOutput: pipe];
    [task setStandardError: pipe];
    
	[task launch];
	
	/* add entry to windowMenu */
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Q - %@", [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]] action:@selector(qemuWindowMoveToFront:) keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItem setTag:[task processIdentifier]];
	[windowMenu addItem:menuItem];
	[menuItem release];
	
	/* save PID */
	[pcsPIDs setObject:thisPC forKey:[NSString stringWithFormat:@"%d", [task processIdentifier]]];
	[pcsTasks setObject:task forKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];
	[pcsPipes setObject:pipe forKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];
	[task release];
	[pipe release];
	
	/* update Table */
	[self loadConfigurations];
	[table reloadData];
}

- (void) deletePCAlertDidEnd:alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//	NSLog(@"cocoaControlController: deletePCAlertDidEnd");

	if (returnCode == 1) {
		
		/* delete .qvm */
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"name"]]])
			[fileManager removeFileAtPath: [NSString stringWithFormat: @"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"name"]] handler:nil];
	
		/* cleanup */
		[pcs removeObjectAtIndex:[table selectedRow]];
		[pcsImages removeObjectAtIndex:[table selectedRow]];
		[table reloadData];
	}
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
//	NSLog(@"cocoaControlController: tableView");

	id thisPC;
	NSString *platform = [NSString stringWithString:@""];
	
	thisPC = [pcs objectAtIndex:rowIndex];
	
	if ([[aTableColumn identifier] isEqualTo: @"image"]) {
		if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqualTo:@"shutdown"]) {
			return [NSImage imageNamed: @"q_table_shutdown.png"];
		} else {
			return [pcsImages objectAtIndex:rowIndex];
		}
	}
	else if ([[aTableColumn identifier] isEqualTo: @"description"]) {
		
		if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"x86"]) {
			platform = [NSString stringWithString:@"x86 PC"];
		} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"x86-64"]) {
			platform = [NSString stringWithString:@"x86-64 PC"];
		} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"PowerPC"] && [[[thisPC objectForKey:@"Temporary"] objectForKey:@"-M"] isEqual:@"prep"]) {
			platform = [NSString stringWithString:@"PPC PREP"];
		} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"PowerPC"]) {
			platform = [NSString stringWithString:@"PPC PowerMac"];
		} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"SPARC"]) {
			platform = [NSString stringWithString:@"SPARC"];
		} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"MIPS"]) {
			platform = [NSString stringWithString:@"MIPS"];
		} else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"ARM"]) {
			platform = [NSString stringWithString:@"ARM"];
		}
		
		NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@\n", [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]] attributes:[NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName]] autorelease];
		[attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: NSLocalizedStringFromTable(@"tableView:mb", @"Localizable", @"cocoaControlController"), platform, [[thisPC objectForKey:@"Temporary"] objectForKey:@"-m"]] attributes:[NSDictionary dictionaryWithObject: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
		if ([[thisPC objectForKey:@"Temporary"] objectForKey:@"-soundhw"])
			[attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: NSLocalizedStringFromTable(@"tableView:audio", @"Localizable", @"cocoaControlController"),[[thisPC objectForKey:@"Temporary"] objectForKey:@"-soundhw"]] attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
		[attrString appendAttributedString: [[[NSAttributedString alloc] initWithString: NSLocalizedStringFromTable([[thisPC objectForKey:@"PC Data"] objectForKey:@"state"], @"Localizable", @"vmstate") attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
		
		return attrString;
	}
	
	return nil;
}

- (void) tableDoubleClick:(id)sender
{
//	NSLog(@"cocoaControlController: tableDoubleClick");

	/* no empty line selection */
	if ([table selectedRow] < 0)
		return;
	
	if ([[[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"state"] isEqualTo:@"running"]) {
		/* move QEMU to front */
		ProcessSerialNumber psn;
		GetProcessForPID( [[pcsTasks objectForKey:[[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"name"]] processIdentifier], &psn );
		SetFrontProcess( &psn );
	} else {
		/* start PC */
		[self startPC:[NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"name"]]];
	}
}

/* dIWindow */
- (IBAction) openDIWindow:(id)sender
{
//	NSLog(@"cocoaControlController: openDIWindow");

	cocoaControlDiskImage *dI = [[cocoaControlDiskImage alloc] init];
	if (![NSBundle loadNibNamed:@"cocoaControlDiskImage" owner:dI]) {
		NSLog(@"Error loading cocoaControlDiskImage.nib for document!");
	} else {
		[dI setQSender:nil];
	}
	[[dI dIWindow] makeKeyAndOrderFront:self];
}

/* downloadWindow */
- (IBAction) openDownloadWindow:(id)sender
{
//	printf("cocoaControlController: openDownloadWindow\n");
	cocoaDownloadController * dl = [[cocoaDownloadController alloc] init];
	if (![NSBundle loadNibNamed:@"cocoaDownload" owner:dl]) {
		printf("cocoaDownload.nib not loaded!\n");
	}
	NSLog(@"returns %@", [dl dLWindow]);
	[dl showWindow];
}

/* Standard Alert */
- (void) standardAlert:(NSString *)messageText informativeText:(NSString *)informativeText
{
//	NSLog(@"cocoaControlController: standardAlert\n");

	NSAlert *alert = [NSAlert alertWithMessageText:messageText
		defaultButton:@"OK"
		alternateButton:nil
		otherButton:nil
		informativeTextWithFormat:informativeText];

	[alert beginSheetModalForWindow:mainWindow
		modalDelegate:self
		didEndSelector:nil
		contextInfo:nil];
}

/* check for Update */
- (void) getLatestVersion
{
//	NSLog(@"cocoaControlController: getLatestVersion");

	unichar dev = 'd';
	
	if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] characterAtIndex:5] == dev) {
		[[NSURL URLWithString:@"http://www.kberg.ch/q/latestVersion.php?d=builds/nightly"] loadResourceDataNotifyingClient:self usingCache:NO];
	} else {
		[[NSURL URLWithString:@"http://www.kberg.ch/q/latestVersion.php?d=builds"] loadResourceDataNotifyingClient:self usingCache:NO];
	}
}

- (void) URLResourceDidFinishLoading:(NSURL *)sender
{
//	NSLog(@"cocoaControlController: URLResourceDidFinishLoading");

	NSData *data = [sender resourceDataUsingCache:YES];

	if(data){
		NSString *ver = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSISOLatin1StringEncoding];
		
		if (![ver isEqual:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
			NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"URLResourceDidFinishLoading:alertWithMessageText", @"Localizable", @"cocoaControlController")
				defaultButton: NSLocalizedStringFromTable(@"URLResourceDidFinishLoading:defaultButton", @"Localizable", @"cocoaControlController")
				alternateButton: NSLocalizedStringFromTable(@"URLResourceDidFinishLoading:alternateButton", @"Localizable", @"cocoaControlController")
				otherButton:nil
				informativeTextWithFormat:@""];

			 [alert beginSheetModalForWindow:mainWindow
				modalDelegate:self
				didEndSelector:@selector(updateAlertDidEnd:returnCode:contextInfo:)
				contextInfo:nil];
		}
	}
}

- (void) URLResourceDidCancelLoading:(NSURL *)sender
{
//	NSLog(@"cocoaControlController: URLResourceDidCancelLoading");
}

- (void)updateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//	NSLog(@"cocoaControlController: updateAlertDidEnd Button=%d", returnCode );
	
	if (returnCode == 1) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.kberg.ch/q"]];
	}
}
@end
