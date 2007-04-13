/*
 * QEMU Cocoa Control Controller
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
 
#import "cocoaControlController.h"
#import "cocoaControlDiskImage.h"
#import "cocoaControlNewPCAssistant.h"

@implementation cocoaControlController
-(id)init
{
//  NSLog(@"cocoaControlController: init");

    /* preferences */
    [[NSUserDefaults standardUserDefaults] registerDefaults:[[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:
        [NSString stringWithString:@"Quartz"], /* enable Quartz by default */
        [NSNumber numberWithBool:TRUE], /* enable search for updates */
        [NSNumber numberWithBool:FALSE], /* disable log to console */
        [@"~/Documents/QEMU" stringByExpandingTildeInPath], /* standart path */
        nil
    ] forKeys:[NSArray arrayWithObjects:@"display", @"enableCheckForUpdates", @"enableLogToConsole", @"dataPath", nil]]];
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

    /* start qserver for distributed object */
    qdoserver = [[cocoaControlDOServer alloc] init];
    [qdoserver setSender:self];

    return self;
    }

    return nil;
}

-(id)pcs
{
    return pcs;
}

- (id)pcsTasks
{
    return pcsTasks;
}

/* NSApp Delegate */
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
//  NSLog(@"cocoaControlController: openFile");

    [ self startPC:filename];
    
    return true;
}

-(void)awakeFromNib
{
//  NSLog(@"cocoaControlController: awakeFromNib");
    
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

    /* set infos for microIcons */
    [table setQControl:self];

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

    /* loading initial Thumbnails */
    [self updateThumbnails];

    /* register table for drag'n drop */
    [table registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
}



- (void) applicationWillBecomeActive:(NSNotification *)aNotification
{
//  NSLog(@"applicationWillBecomeActive: applicationWillBecomeActive");

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
//  NSLog(@"cocoaControlController: applicationDidBecomeActive");

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

- (IBAction) activateApp:(id)sender
{
//  NSLog(@"cocoaControlController: activateApp");
    if (![NSApp isActive])
        [NSApp activateIgnoringOtherApps:YES];
}

- (void) applicationWillHide:(NSNotification *)aNotification
{
//  NSLog(@"cocoaControlController: applicationWillHide");

    NSEnumerator *enumerator = [pcsPIDs keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        [qdoserver guestHide:[[[pcsPIDs objectForKey:key] objectForKey:@"PC Data"] objectForKey:@"name"]];
    }
}

- (void) applicationWillUnhide:(NSNotification *)aNotification
{
//  NSLog(@"cocoaControlController: applicationWillUnhide");

    NSEnumerator *enumerator = [pcsPIDs keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        [qdoserver guestUnhide:[[[pcsPIDs objectForKey:key] objectForKey:@"PC Data"] objectForKey:@"name"]];
    }
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
//  NSLog(@"cocoaControlController: applicationShouldTerminate");

    if ([pcsPIDs count]) {
        [self standardAlert: NSLocalizedStringFromTable(@"applicationShouldTerminate:standardAlert", @"Localizable", @"cocoaControlController")
             informativeText: NSLocalizedStringFromTable(@"applicationShouldTerminate:informativeText", @"Localizable", @"cocoaControlController")];
        return NSTerminateCancel;
    }

    return NSTerminateNow;
}

-(void) applicationWillTerminate:(NSNotification *)notification
{
//  NSLog(@"cocoaControlController: applicationWillTerminate");

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
//  NSLog(@"cocoaControlController: showPreferences");

    /* enter current Values into preferencesPanel */
    [preferences preparePreferences:self];

    /* display preferencesPanel */
    [[preferences preferencesPanel] setDelegate:preferences];
    [[preferences preferencesPanel] center];
    [[preferences preferencesPanel] makeKeyAndOrderFront:self];
}

- (IBAction) qemuWindowMoveToFront:(id)sender
{
//  NSLog(@"cocoaControlController: qemuWindowMoveToFront");
    
    ProcessSerialNumber psn;
    
    /* move a QEMU to front */
    GetProcessForPID( [sender tag], &psn );
    SetFrontProcess( &psn );
}

/* NSWindow Delegate */
- (IBAction) cycleWindows:(id)sender
{
//    NSLog(@"cocoaControlController: cycleWindows");
    [qdoserver guestSwitch: @"Q Control" fullscreen:NO nextGuestName:nil];
}

- (IBAction) cycleWindowsBack:(id)sender
{
//    NSLog(@"cocoaControlController: cycleWindows");
    
    [qdoserver guestSwitch: @"Q Control" fullscreen:NO previousGuestName:nil];
}

- (BOOL) windowShouldClose:(id)sender
{
//  NSLog(@"cocoaControlController: windowShouldClose");
    
    [NSApp terminate:nil];
    return NO;
}


- (void) checkATaskStatus:(NSNotification *)aNotification
{
//  NSLog(@"cocoaControlController: checkATaskStatus");

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
        
        /* error management here - display the crash output of qemu */
        if(![userDefaults boolForKey:@"enableLogToConsole"]) {

            NSData * pipedata;

            while ((pipedata = [[[[pcsTasks objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]] standardOutput] fileHandleForReading] availableData]) && [pipedata length])
            {
                NSString * console_out = [[[NSString alloc] initWithData:pipedata encoding:NSUTF8StringEncoding] autorelease];
                // trim string to only contain the error
                NSArray * comps = [console_out componentsSeparatedByString:@": "];
                NSString * errormsg = [@"Error: " stringByAppendingString:[comps objectAtIndex:1]];
                [self standardAlert:@"Qemu unexpectedly quit" informativeText:errormsg];
            }
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
    [pcsTasks removeObjectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];
    [thisPC release];
    [pcsPIDs removeObjectForKey:[NSString stringWithFormat:@"%d", [[aNotification object] processIdentifier]]];
}

/* control Window */
- (id) mainWindow {
//  NSLog(@"cocoaControlController: mainWindow");
    return mainWindow;
}

- (void) loadConfigurations
{
//  NSLog(@"cocoaControlController: loadConfigurations");

    /* update defaults */
    userDefaults = [NSUserDefaults standardUserDefaults];

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

                /* isolate Arguments, that we need at hand
                    -m
                    -soundhw
                    -M
                    -hda
                    -hdb
                    -hdd
                */
                NSArray *tableArguments = [[NSArray init] arrayWithObjects:@"-m", @"-soundhw", @"-M", @"-hda", @"-hdb", @"-hdd", nil];
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
//  NSLog(@"cocoaControlController: savePCConfiguration");

    NSData *data = [NSPropertyListSerialization
        dataFromPropertyList: thisPC
        format: NSPropertyListXMLFormat_v1_0
        errorDescription: nil];
    [data writeToFile:[NSString stringWithFormat:@"%@/configuration.plist", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]] atomically:YES];

}

- (void) updateThumbnails
{
//  NSLog(@"cocoaControlController: updateThumbnails");
    
    if (pcsImages)
        [pcsImages release];
    
    pcsImages = [[NSMutableArray alloc] init];
    
    int i;
    for (i = 0; i < [pcs count]; i++ ) {
        NSString *pathImage = [NSString stringWithFormat: @"%@/thumbnail.png", [[[pcs objectAtIndex:i] objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]];
        NSImage *image =    [[NSImage alloc] initWithContentsOfFile:pathImage]; 
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
        //      NSToolbarCustomizeToolbarItemIdentifier,
        @"removePCIdentifier",
        nil];
}

- (BOOL) validateToolbarItem:(NSToolbarItem *)theItem
{
    return YES;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
//  NSLog(@"windowDidBecomeKey");
}

-(int)numberOfRowsInTableView:(NSTableView *)table
{
    return [pcs count];
}

-(IBAction) addPC:(id)sender
{
//  NSLog(@"cocoaControlController: addPC");

    cocoaControlNewPCAssistant *npa = [[cocoaControlNewPCAssistant alloc] init];
    [NSBundle loadNibNamed:@"cocoaControlNewPCAssistant" owner:npa];
    [npa setQSender:self];
    
    [NSApp beginSheet:[npa npaPanel]
        modalForWindow:mainWindow 
        modalDelegate:npa
        didEndSelector:@selector(npaPanelDidEnd:returnCode:contextInfo:)
        contextInfo:nil];
}

- (void) addPCFromDragDrop:(NSString *)path
{
//  NSLog(@"cocoaControlController: addPCFromDragDrop");

    cocoaControlNewPCAssistant *npa = [[cocoaControlNewPCAssistant alloc] init];
    [NSBundle loadNibNamed:@"cocoaControlNewPCAssistant" owner:npa];
    [npa setQSender:self];
    [npa setOS:5];
    [npa setAdditionalHardwarePath: path];
    
    [NSApp beginSheet:[npa npaPanel]
        modalForWindow:mainWindow 
        modalDelegate:npa
        didEndSelector:@selector(npaPanelDidEnd:returnCode:contextInfo:)
        contextInfo:nil];
}

-(IBAction) addPCFromAssistant:(NSMutableDictionary *)thisPC
{
//  NSLog(@"cocoaControlController: addPCAssistant");

    /* enter current Values into editPCPanel */
    [editPC prepareEditPCPanel:thisPC newPC:YES sender:self];
 
    /* display editPCPanel */         
    [[editPC editPCPanel] makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:[editPC editPCPanel]];
}

-(void) editThisPC:(id)pc
{
//  NSLog(@"cocoaControlController: editThisPC");

    /* enter current Values into editPCPanel */
    [editPC prepareEditPCPanel:pc newPC:NO sender:self];
 
    /* display editPCPanel */
    [[editPC editPCPanel] makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:[editPC editPCPanel]];
}

-(IBAction) editPC:(id)sender
{
//  NSLog(@"cocoaControlController: editPC");

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

    [self editThisPC:thisPC];
}

-(BOOL) checkPC:(id)thisPC name:(NSString *)name create:(BOOL)create
{
//  NSLog(@"cocoaControlController: checkPC");

    NSEnumerator *enumerator = [pcs objectEnumerator];
    id object;
    
    if (create) {
        while ( (object = [enumerator nextObject]) ) {
            if ([[[object objectForKey:@"PC Data"] objectForKey:@"name"] isEqual: name] )
                return 0;
        }
    } else {
//      id thisPC = [pcs objectAtIndex:[table selectedRow]];
        while ( (object = [enumerator nextObject]) ) {
            if ([[[object objectForKey:@"PC Data"] objectForKey:@"name"] isEqual: name]) {
                if ( ![[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"] isEqual:name])
                    return 0;
            }
        }
    }
    
    return 1;
}

- (void) deletePCAlertDidEnd:alert returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//  NSLog(@"cocoaControlController: deletePCAlertDidEnd");

    if (returnCode == 1) {
        
        /* delete .qvm */
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [[contextInfo objectForKey:@"PC Data"] objectForKey:@"name"]]])
            [fileManager removeFileAtPath: [NSString stringWithFormat: @"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [[contextInfo objectForKey:@"PC Data"] objectForKey:@"name"]] handler:nil];
    
        /* cleanup */
        [self loadConfigurations];
    }
}

- (void) deleteThisPC:(id)pc
{
//  NSLog(@"cocoaControlController: deleteThisPC");

    /* prepare alert */
    NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"deletePC:alertWithMessageText", @"Localizable", @"cocoaControlController")
                      defaultButton: NSLocalizedStringFromTable(@"deletePC:defaultButton", @"Localizable", @"cocoaControlController")
                    alternateButton: NSLocalizedStringFromTable(@"deletePC:alternateButton", @"Localizable", @"cocoaControlController")
                        otherButton:nil
                  informativeTextWithFormat:[NSString stringWithFormat: NSLocalizedStringFromTable(@"deletePC:informativeTextWithFormat", @"Localizable", @"cocoaControlController"),[[pc objectForKey:@"PC Data"] objectForKey:@"name"]]];
    
    /* display alert */
    [alert beginSheetModalForWindow:mainWindow
                  modalDelegate:self
                 didEndSelector:@selector(deletePCAlertDidEnd:returnCode:contextInfo:)
                 contextInfo:pc];
}

-(IBAction) deletePC:(id)sender
{
//  NSLog(@"cocoaControlController: deletePC");

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
    
    [self deleteThisPC:thisPC];
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
#if kju_debug
    NSLog(@"-cocoapath: %@", path);
#endif
    [[thisPC objectForKey:@"PC Data"] setObject:name forKey:@"name"];
    
    // TODO: use README file to get HD and other arguments 
    // for now we search for a .img/.qcow file and use it as HD
    BOOL foundHD = NO;
    BOOL foundDir = NO;
    BOOL foundReadme = NO;
    NSFileManager * manager = [NSFileManager defaultManager];
    NSArray * dirContents = [manager directoryContentsAtPath:path];
    NSArray * subDir;
    int i,ii,j,k;
    for (i=0; i<=[dirContents count]-1; i++) {
        if (([[[dirContents objectAtIndex:i] pathExtension] isEqualToString:@"img"] || [[[dirContents objectAtIndex:i] pathExtension] isEqualToString:@"qcow"] || [[[dirContents objectAtIndex:i] pathExtension] isEqualToString:@"dsk"]) && (![[[manager fileAttributesAtPath:[path stringByAppendingPathComponent:[dirContents objectAtIndex:i]] traverseLink:NO] objectForKey:NSFileType] isEqualTo:NSFileTypeDirectory])) {
            foundHD = YES;
            break;
        } else if([[[manager fileAttributesAtPath:[path stringByAppendingPathComponent:[dirContents objectAtIndex:i]] traverseLink:NO] objectForKey:NSFileType] isEqualTo:NSFileTypeDirectory]) {
            foundDir = YES;
            //NSLog(@"Found Dir: %@", [dirContents objectAtIndex:i]);
            break;
        } else {
            //NSLog(@"Found no image or folder.");
        }
    }

    if(foundHD) {
       //if we found the hd image in the root folder, we only need to append -hda file to arguments
       [[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [dirContents objectAtIndex:i]]];
    } else if(foundDir) {
       // if we found a folder, the hd should be in it
       // if hd is found, move all files in the folder to root directory and delete folder
       subDir = [manager directoryContentsAtPath:[path stringByAppendingPathComponent:[dirContents objectAtIndex:i]]];
       for(ii=0; i<=[subDir count]-1; ii++) {
            // search for .img or .qcow
            if([[[subDir objectAtIndex:ii] pathExtension] isEqualToString:@"img"] || [[[subDir objectAtIndex:i] pathExtension] isEqualToString:@"qcow"]) {
                //NSLog(@"found HD in subdir!");
                // move all files to root dir and delete the folder
                for(j=0; j<[subDir count]; j++) {
                    [manager movePath:[path stringByAppendingPathComponent:[[dirContents objectAtIndex:i] stringByAppendingPathComponent:[subDir objectAtIndex:j]]] toPath:[path stringByAppendingPathComponent:[subDir objectAtIndex:j]] handler:nil];
                }
                [manager removeFileAtPath:[path stringByAppendingPathComponent:[dirContents objectAtIndex:i]] handler:nil];
                // append hd name to arguments
                [[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -hda %@", [subDir objectAtIndex:ii]]];
                foundHD = YES;
                break;
            }
        }
    }
    
    // search for a readme file, if found, open it with TextEdit
    dirContents = [manager directoryContentsAtPath:path];
    for(k=0; k<[dirContents count]; k++) {
       if([[dirContents objectAtIndex:k] isEqualToString:@"README"]) {
           foundReadme = YES;
           break;
       }
    }
    
    /* save Configuration */
    [self savePCConfiguration:thisPC];
    
    /* update Table */
    [self loadConfigurations];
    
    /* open Readme */
    if(foundReadme) [[NSWorkspace sharedWorkspace] openFile:[path stringByAppendingPathComponent:@"README"] withApplication:@"TextEdit.app"];
    
    return foundHD;
}

- (NSString *) convertDI:(NSString *)oldImagePath to:(NSString *)newPCname
{
//  NSLog(@"cocoaControlController: convertDI");

    /* search a free Name */
    int i = 1;
    NSString *name;
    NSString *path = [NSString stringWithString:[[NSString stringWithFormat:@"%@/%@.qvm",[userDefaults objectForKey:@"dataPath"], newPCname] stringByExpandingTildeInPath]];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", path, [NSString stringWithFormat:@"Harddisk_%d.qcow2", i]]])
        i++;
    name = [NSString stringWithFormat:@"Harddisk_%d.qcow2", i];
    
    /* convert diskImage */
    NSArray *arguments = [NSArray arrayWithObjects:@"convert", @"-c", @"-O", @"qcow2", oldImagePath, [NSString stringWithFormat:@"%@/%@", path, name], nil];
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
//  NSLog(@"cocoaControlController: importVPC7PCDidEnd");

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
        
        /* show warning */
        [self standardAlert: NSLocalizedStringFromTable(@"importVPC7PC:standardAlert:finish", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importVPC7PC:informativeText:finish", @"Localizable", @"cocoaControlController")];
    }
}

- (IBAction) importVPC7PC:(id)sender
{
//  NSLog(@"cocoaControlController: importVPC7PC");

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
//  NSLog(@"cocoaControlController: importQemuXPCs");

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

//  NSMutableString *message = [NSMutableString stringWithFormat: NSLocalizedStringFromTable(@"importQemuXPCs:message", @"Localizable", @"cocoaControlController")];
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
//      [message appendFormat:@"%@\n", name];

        /* update Progresspanel text */
        [progressText setStringValue:[NSString stringWithFormat: NSLocalizedStringFromTable(@"importQemuXPCs:progress:pc", @"Localizable", @"cocoaControlController"), name]];

        
        /* set the -cocoapath */
        [[thisPC objectForKey:@"Temporary"] setObject:[NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], name] forKey:@"-cocoapath"];
#if kju_debug
        NSLog(@"cocoapath: %@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]);
#endif
        
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
            [[thisPC objectForKey:@"Arguments"] appendFormat:[NSString stringWithFormat:@" -cdrom %@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"] ,[[[qemux objectAtIndex:i] objectForKey:@"cdrom"] lastPathComponent]]];
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
                [fileManager copyPath:[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] toPath:[NSString stringWithFormat:@"%@/%@",  [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] lastPathComponent]] handler:nil];
#if kju_debug
                NSLog(@"copy allowed, done.");
#endif
            }
#if kju_debug
            NSLog(@"hd: %@", [[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]]);
            NSLog(@"copy from %@ to %@", [[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]], [NSString stringWithFormat:@"%@/%@",    [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], [[[qemux objectAtIndex:i] objectForKey:[hds objectAtIndex:ii]] lastPathComponent]]);
#endif
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
    
//  [message appendString: NSLocalizedStringFromTable(@"importQemuXPCs:message:appendString", @"Localizable", @"cocoaControlController")];

    /* update Table */
    [self loadConfigurations];

    /* hide panel */
    [NSApp endSheet:progressPanel];
    [progressPanel orderOut:self];
    
    /* show warning */
    [self standardAlert: NSLocalizedStringFromTable(@"importQemuXPCs:standardAlert:finish", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importQemuXPCs:informativeText:finish", @"Localizable", @"cocoaControlController")];
}

- (void) updatePC:(id)thisPC
{
//  NSLog(@"cocoaControlController: updatePC");

    int i;
    NSString *tempString;
    NSString *harddisk;
    NSString *path;
    NSString *vmPath;

    NSArray *harddisks = [NSArray arrayWithObjects:@"-hda",@"-hdb",@"-hdd",nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    /* setup & show Progress panel */
    [progressTitle setStringValue: NSLocalizedStringFromTable(@"updatePC:progress:title", @"Localizable", @"cocoaControlController")];
    [progressText setStringValue: NSLocalizedStringFromTable(@"updatePC:progress:text", @"Localizable", @"cocoaControlController")];
    [progressStatusText setStringValue: NSLocalizedStringFromTable(@"updatePC:progress:config", @"Localizable", @"cocoaControlController")];
    [progressIndicator setUsesThreadedAnimation:TRUE];
    [progressIndicator setIndeterminate:TRUE];
    [progressIndicator startAnimation:self];

    [NSApp beginSheet:progressPanel
        modalForWindow:mainWindow 
        modalDelegate:nil
        didEndSelector:nil
        contextInfo:nil];

    for (i = 0; i < [harddisks count]; i++) {
        if ((harddisk = [[thisPC objectForKey:@"Temporary"] objectForKey:[harddisks objectAtIndex:i]])) {

            //path
            if (![harddisk isAbsolutePath]) { //we only convert files inside the .qvm package
                path = [NSString stringWithFormat:@"%@/%@",[[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], harddisk];

                //convert
                tempString = [self convertDI:path to:[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]];
                if ([tempString isEqual:@""]) {
                    [NSApp endSheet:progressPanel];
                    [progressPanel orderOut:self];
                    [self standardAlert: NSLocalizedStringFromTable(@"updatePC:standardAlert:imageConvert", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"updatePC:informativeText:imageConvert", @"Localizable", @"cocoaControlController")];
                    return;
                }

                //delete old Harddisk files
                [fileManager removeFileAtPath:path handler:nil];

                //delete old VM states
                vmPath = [NSString stringWithFormat:@"%@/saved.vm", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"]];
                if ([fileManager fileExistsAtPath:vmPath])
                    [fileManager removeFileAtPath:vmPath handler:nil];

                //rename or move new File (we only want .qcow2)
                if ([[harddisk pathExtension] isEqual:@"qcow2"]) {
                    [fileManager movePath:[NSString stringWithFormat:@"%@/%@", [[thisPC objectForKey:@"Temporary"] objectForKey:@"-cocoapath"], tempString] toPath:path handler:nil];
                } else {
                    NSRange range =[[thisPC objectForKey:@"Arguments"] rangeOfString:harddisk];
                    [thisPC setObject:[NSString stringWithFormat:@"%@%@%@",[[thisPC objectForKey:@"Arguments"] substringToIndex:range.location], tempString, [[thisPC objectForKey:@"Arguments"] substringFromIndex:(range.location + range.length)]] forKey:@"Arguments"];
                }

            }

        }
    }

    /* save Configuration */
    [self savePCConfiguration:thisPC];
    [progressIndicator stopAnimation:self];

    /* update Table */
    [self loadConfigurations];

    /* hide panel */
    [NSApp endSheet:progressPanel];
    [progressPanel orderOut:self];

//    /* show warning */
//    [self standardAlert: NSLocalizedStringFromTable(@"updatePC:standardAlert:finish", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"updatePC:informativeText:finish", @"Localizable", @"cocoaControlController")];
}

- (void) updatePCAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//  NSLog(@"cocoaControlController: updatePCAlertDidEnd");
    
    [[alert window] orderOut:self];

    if(returnCode == NSOKButton)
       [self updatePC:contextInfo];
}

- (IBAction) updateThisPC:(id)sender
{
//  NSLog(@"cocoaControlController: updateThisPC");

    /* no empty line selection */
    if ( [table numberOfSelectedRows] == 0 )
        return;
    
    /* don't allow to export a running/saved pc */
    id thisPC;
    thisPC = [pcs objectAtIndex:[table selectedRow]];
    
    if (![[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"]) {
        [self standardAlert: [NSString stringWithFormat: NSLocalizedStringFromTable(@"updateThisPC:standardAlert", @"Localizable", @"cocoaControlController"),[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]
             informativeText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"updateThisPC:informativeText", @"Localizable", @"cocoaControlController"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
        return;
    }
    
    /* prepare informative alert */
    NSAlert *alert = [NSAlert alertWithMessageText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"updateThisPC:alertWithMessageText", @"Localizable", @"cocoaControlController"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]
                      defaultButton: NSLocalizedStringFromTable(@"updateThisPC:defaultButton", @"Localizable", @"cocoaControlController")
                    alternateButton:NSLocalizedStringFromTable(@"updateThisPC:alternateButton", @"Localizable", @"cocoaControlController")
                        otherButton:nil
                  informativeTextWithFormat: NSLocalizedStringFromTable(@"updateThisPC:informativeTextWithFormat", @"Localizable", @"cocoaControlController")];
    
    // display alert
    [alert beginSheetModalForWindow:mainWindow
                  modalDelegate:self
                 didEndSelector:@selector(updatePCAlertDidEnd:returnCode:contextInfo:)
                 contextInfo:thisPC];
}

-(void) exportPCToFlashDrive:(id)pc
{
//  NSLog(@"cocoaControlController: exportThisPCToFlashDrive");
    // get the export path
    int result;
    NSSavePanel *savePanel = [[NSSavePanel alloc] init];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setTitle: NSLocalizedStringFromTable(@"exportPCToFlashDrive:savePanel:title", @"Localizable", @"cocoaControlController")];
    [savePanel setPrompt: NSLocalizedStringFromTable(@"exportPCToFlashDrive:savePanel:prompt", @"Localizable", @"cocoaControlController")];
    result = [savePanel runModalForDirectory: NSOpenStepRootDirectory()
        file:[[pc objectForKey:@"PC Data"] objectForKey:@"name"]];
    
    if(result != NSOKButton)
        return;
    
    NSString * exportPath = [savePanel filename];
    NSString * pkgSrcPath = [NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [[pc objectForKey:@"PC Data"] objectForKey:@"name"]];
    
    /* 0. setup & show Progress panel */
    [progressTitle setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:title", @"Localizable", @"cocoaControlController")];
    [progressText setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:text", @"Localizable", @"cocoaControlController")];
    [progressStatusText setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:statusText1", @"Localizable", @"cocoaControlController")];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setMaxValue:100];
    [progressIndicator setDoubleValue:10];
    [progressIndicator startAnimation:self];
        
    [NSApp beginSheet:progressPanel
        modalForWindow:mainWindow 
        modalDelegate:nil
        didEndSelector:nil
        contextInfo:nil];

    NSFileManager * fileManager = [NSFileManager defaultManager];
    /* 1. get architecture and copy binary.app */
    [progressStatusText setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:statusText2", @"Localizable", @"cocoaControlController")];
    NSString * srcPath = [NSString stringWithFormat:@"%@/Contents/MacOS/%@.app", [[NSBundle mainBundle] bundlePath], [cpuTypes objectForKey:[[pc objectForKey:@"PC Data"] objectForKey:@"architecture"]]];
    NSString * destPath = [NSString stringWithFormat:@"%@.app", exportPath];

    [fileManager copyPath: srcPath toPath: destPath handler: nil];
    /* 1.2 copy q_icon_portable.icns to binary package */
    [fileManager removeFileAtPath: [destPath stringByAppendingPathComponent:@"Contents/Resources/q_icon.icns"] handler: nil];
    [fileManager copyPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"q_icon_portable.icns"] toPath: [destPath stringByAppendingPathComponent:@"Contents/Resources/q_icon.icns"] handler: nil];
    
    /* 1.3 set NSUIElement to 0 to have a Dock Icon for the Exported Guest PC */
    NSMutableDictionary * appDict = [NSMutableDictionary dictionaryWithContentsOfFile: [destPath stringByAppendingPathComponent: @"Contents/Info.plist"]];
    [appDict setObject:[NSNumber numberWithInt:0] forKey:@"NSUIElement"];
    [appDict writeToFile:[destPath stringByAppendingPathComponent: @"Contents/Info.plist"] atomically: YES];
    
    [progressIndicator setDoubleValue:20];

    /* 2. create Guest folder in binary package & copy qvm package */
    [progressStatusText setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:statusText3", @"Localizable", @"cocoaControlController")];
    [fileManager createDirectoryAtPath: [destPath stringByAppendingPathComponent: @"Contents/Resources/Guest"] attributes: nil];
    
    /* TODO: threaded copy routine as on http://www.cocoadev.com/index.pl?FileCopyProgress */
    [fileManager copyPath: pkgSrcPath toPath: [[destPath stringByAppendingPathComponent: @"Contents/Resources/Guest"] stringByAppendingPathComponent: [pkgSrcPath lastPathComponent]] handler: nil];
    [progressIndicator setDoubleValue:90];
        
    /* 2.5 remove absolute pathnames from hda|hdb|hdc|hdd|fda|fdb|cdrom
                copy disks outside of .qvm into .app package
    */
    [progressStatusText setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:statusText4", @"Localizable", @"cocoaControlController")];
    
    /* reformat arguments to array containing spaces */
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    /* Arguments of thisPC */
    NSArray *array = [[pc objectForKey:@"Arguments"] componentsSeparatedByString:@" "];
    NSMutableString *option = [[NSMutableString alloc] initWithString:@""];
    NSMutableString *argument = [[NSMutableString alloc] init];
    int i;
    for (i = 1; i < [array count]; i++) {
        if ([[array objectAtIndex:i] cString][0] != '-') { // part of an argument
            [argument appendFormat:[NSString stringWithFormat:@" %@", [array objectAtIndex:i]]];
        } else {
            if ([option length] > 0) {
                if ([argument isEqual:@""]) {
                    [arguments addObject:[NSString stringWithString:option]];
                } else {
                    [arguments addObject:[NSString stringWithString:option]];
                    [arguments addObject:[NSString stringWithString:[argument substringFromIndex:1]]];
                }
            }
            [option setString:[array objectAtIndex:i]];
            [argument setString:@""];
        }
    }
    /* last Object */
    if ([argument isEqual:@""]) {
        [arguments addObject:[NSString stringWithString:option]];
    } else {
        [arguments addObject:[NSString stringWithString:option]];
        [arguments addObject:[NSString stringWithString:[argument substringFromIndex:1]]];
    }
    /* end reformatting */
    
    /* which display ? */
    if ([[userDefaults objectForKey:@"display"] isEqual:@"OpenGL"]) {
    } else if ([[userDefaults objectForKey:@"display"] isEqual:@"Quartz"]) {
        [arguments addObject: @"-cocoaquartz"];
    } else {
        [arguments addObject: @"-cocoaquickdraw"];
    }
    
    /* name of the PC */
    [arguments addObject: @"-cocoaname"];
    [arguments addObject: [[[pc objectForKey:@"PC Data"] objectForKey:@"name"] stringByAppendingString:@" (Standalone Mode)"]]; 
        
    for(i=0; i < [arguments count]; i++) {
        if([[arguments objectAtIndex:i] isEqualTo:@"-hda"] || [[arguments objectAtIndex:i] isEqualTo:@"-hdb"] || [[arguments objectAtIndex:i] isEqualTo:@"-hdc"] || [[arguments objectAtIndex:i] isEqualTo:@"-hdd"] || [[arguments objectAtIndex:i] isEqualTo:@"-fda"] || [[arguments objectAtIndex:i] isEqualTo:@"-fdb"] || [[arguments objectAtIndex:i] isEqualTo:@"-cdrom"]) {
            if([[arguments objectAtIndex:i+1] isAbsolutePath]) {
                // image resides outside of qvm, we have to copy it into app package->qvm and remove the absolute pathname
                [progressStatusText setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:statusText5", @"Localizable", @"cocoaControlController")];
                [fileManager copyPath: [arguments objectAtIndex:i+1] toPath:[destPath stringByAppendingPathComponent: [[NSString stringWithFormat:@"Contents/Resources/Guest/%@", [pkgSrcPath lastPathComponent]] stringByAppendingPathComponent: [[arguments objectAtIndex:i+1] lastPathComponent]]] handler:nil];
                [arguments replaceObjectAtIndex:i+1 withObject:[[arguments objectAtIndex:i+1] lastPathComponent]];
            }
        }
    }
    
    /* 3. save NSMutableArray back to NSString, save arguments in a qemu-binary readable format */
    [progressStatusText setStringValue: NSLocalizedStringFromTable(@"exportPCToFlashDrive:progressPanel:statusText6", @"Localizable", @"cocoaControlController")];
    NSMutableString * stringArguments = [NSMutableString stringWithCapacity:10];
    for(i=0; i< [arguments count]; i++) {
        [stringArguments appendFormat:@" %@", [arguments objectAtIndex:i]];
    }
    // write arguments to file
    if(![stringArguments writeToFile:[destPath stringByAppendingPathComponent: @"Contents/Resources/Guest/arguments"] atomically:YES encoding:NSUTF8StringEncoding error:NULL]) {
        [self standardAlert: NSLocalizedStringFromTable(@"exportPCToFlashDrive:alert:writeToFile:messageText", @"Localizable", @"cocoaControlController") informativeText:[NSString stringWithFormat: NSLocalizedStringFromTable(@"exportPCToFlashDrive:alert:writeToFile:informativeText", @"Localizable", @"cocoaControlController"), [[pc objectForKey:@"PC Data"] objectForKey:@"name"]]];
        // delete exported Guest PC app
        [fileManager removeFileAtPath: destPath handler: nil];
        /* hide panel */
        [NSApp endSheet:progressPanel];
        [progressPanel orderOut:self];
        return;
    }
        
    /* 4. finish */
    [progressIndicator setDoubleValue:100];
    [progressIndicator stopAnimation:self];

    /* hide panel */
    [NSApp endSheet:progressPanel];
    [progressPanel orderOut:self];
    
    /* show finished dialog */
    [self standardAlert: NSLocalizedStringFromTable(@"exportPCToFlashDrive:alert:exportFinished:messageText", @"Localizable", @"cocoaControlController") informativeText:[NSString stringWithFormat: NSLocalizedStringFromTable(@"exportPCToFlashDrive:alert:exportFinished:informativeText", @"Localizable", @"cocoaControlController"), [[pc objectForKey:@"PC Data"] objectForKey:@"name"]]];

}

- (IBAction) exportThisPCToFlashDrive:(id)sender
{
//  NSLog(@"cocoaControlController: exportThisPCToFlashDrive");

    /* no empty line selection */
    if ( [table numberOfSelectedRows] == 0 )
        return;
    
    /* don't allow to export a running/saved pc */
    id thisPC;
    thisPC = [pcs objectAtIndex:[table selectedRow]];
    
    if (![[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"]) {
        [self standardAlert: [NSString stringWithFormat: NSLocalizedStringFromTable(@"exportThisPCToFlashDrive:standardAlert", @"Localizable", @"cocoaControlController"),[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]
             informativeText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"exportThisPCToFlashDrive:informativeText", @"Localizable", @"cocoaControlController"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]];
        return;
    }
    
    /* prepare informative alert */
    NSAlert *alert = [NSAlert alertWithMessageText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"exportThisPCToFlashDrive:alertWithMessageText", @"Localizable", @"cocoaControlController"), [[thisPC objectForKey:@"PC Data"] objectForKey:@"name"]]
                      defaultButton: NSLocalizedStringFromTable(@"exportThisPCToFlashDrive:defaultButton", @"Localizable", @"cocoaControlController")
                    alternateButton:NSLocalizedStringFromTable(@"exportThisPCToFlashDrive:alternateButton", @"Localizable", @"cocoaControlController")
                        otherButton:nil
                  informativeTextWithFormat: NSLocalizedStringFromTable(@"exportThisPCToFlashDrive:informativeTextWithFormat", @"Localizable", @"cocoaControlController")];
    
    // display alert
    [alert beginSheetModalForWindow:mainWindow
                  modalDelegate:self
                 didEndSelector:@selector(exportPCAlertDidEnd:returnCode:contextInfo:)
                 contextInfo:thisPC];
}

- (void) exportPCAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//  NSLog(@"cocoaControlController: exportPCAlertDidEnd");
    
    [[alert window] orderOut:self];
    
    if(returnCode == NSOKButton)
       [self exportPCToFlashDrive:contextInfo];
}

- (void) importPCFromFlashDrive:(NSString *)filename
{
//  NSLog(@"cocoaControlController: importPCFromFlashDrive");
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    /* check for "Guest" folder inside app package */
    if(![fileManager fileExistsAtPath: [filename stringByAppendingPathComponent:@"Contents/Resources/Guest"] isDirectory:&isDir] && isDir) {
        [self standardAlert: NSLocalizedStringFromTable(@"importPCFromFlashDrive:alert:notFound:messageText", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importPCFromFlashDrive:alert:notFound:informativeText", @"Localizable", @"cocoaControlController")];
        return;
    }
    
    /* search for qvm package */
    NSString * file;
    NSString * guestDir = [filename stringByAppendingPathComponent:@"Contents/Resources/Guest"];
    NSDirectoryEnumerator * dirEnum = [fileManager enumeratorAtPath: guestDir];
 
    BOOL foundQVM = NO;
    while ((file = [dirEnum nextObject])) {
        if ([[file pathExtension] isEqualToString: @"qvm"]) {
            foundQVM = YES;
            break;
        }
    }
    
    if(!foundQVM) {
        [self standardAlert: NSLocalizedStringFromTable(@"importPCFromFlashDrive:alert:notFound:messageText", @"Localizable", @"cocoaControlController") informativeText: NSLocalizedStringFromTable(@"importPCFromFlashDrive:alert:notFound:informativeText", @"Localizable", @"cocoaControlController")];
        return;
    }
    
    file = [filename stringByAppendingPathComponent:[@"Contents/Resources/Guest" stringByAppendingPathComponent:file]];
#if kju_debug
    NSLog(@"file: %@", file);
#endif
    
    /* ready now, show progressPanel */
    [progressTitle setStringValue: NSLocalizedStringFromTable(@"importPCFromFlashDrive:progressPanel:title", @"Localizable", @"cocoaControlController")];
    [progressText setStringValue: NSLocalizedStringFromTable(@"importPCFromFlashDrive:progressPanel:text", @"Localizable", @"cocoaControlController")];
    [progressStatusText setStringValue: NSLocalizedStringFromTable(@"importPCFromFlashDrive:progressPanel:statusText1", @"Localizable", @"cocoaControlController")];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setMaxValue:100];
    [progressIndicator setDoubleValue:10];
    [progressIndicator startAnimation:self];
        
    [NSApp beginSheet:progressPanel
        modalForWindow:mainWindow 
        modalDelegate:nil
        didEndSelector:nil
        contextInfo:nil];
        
    /* now simply copy over .qvm package */
    isDir = NO;
    if(!([fileManager fileExistsAtPath:[[userDefaults objectForKey:@"dataPath"] stringByAppendingPathComponent:[file lastPathComponent]] isDirectory:&isDir] && isDir)) {
        [fileManager copyPath: file toPath:[[userDefaults objectForKey:@"dataPath"] stringByAppendingPathComponent:[file lastPathComponent]] handler: nil];
    } else {
        // append "(imported)" to filename and name in configuration.plist
        NSMutableDictionary * conf = [NSDictionary dictionaryWithContentsOfFile:[file stringByAppendingPathComponent:@"configuration.plist"]];
        NSMutableDictionary * pcdata = [conf objectForKey:@"PC Data"];
        [pcdata setObject:[NSString stringWithFormat:@"%@(imported)", [pcdata objectForKey:@"name"]] forKey:@"name"];
        [conf setObject:pcdata forKey:@"PC Data"];
        NSData *data = [NSPropertyListSerialization
        dataFromPropertyList: conf
        format: NSPropertyListXMLFormat_v1_0
        errorDescription: nil];
        [fileManager copyPath: file toPath:[[userDefaults objectForKey:@"dataPath"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@(imported).qvm", [[file lastPathComponent] substringToIndex:[[file lastPathComponent] length]-4 ]]] handler: nil];
        [data writeToFile:[[userDefaults objectForKey:@"dataPath"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@(imported).qvm/configuration.plist", [[file lastPathComponent] substringToIndex:[[file lastPathComponent] length]-4 ]]] atomically:YES];
    }
    
    /* finish */
    [progressIndicator setDoubleValue:100];
    [progressIndicator stopAnimation:self];
    
    /* update Table */
    [self loadConfigurations];

    /* hide panel */
    [NSApp endSheet:progressPanel];
    [progressPanel orderOut:self];
    
    /* show finished dialog */
    [self standardAlert: NSLocalizedStringFromTable(@"importPCFromFlashDrive:alert:importFinished:messageText", @"Localizable", @"cocoaControlController") informativeText:[NSString stringWithFormat: NSLocalizedStringFromTable(@"importPCFromFlashDrive:alert:importFinished:informativeText", @"Localizable", @"cocoaControlController"), [[file lastPathComponent] substringToIndex:[[file lastPathComponent] length]-4 ]]];
    
}

- (void) importThisPCFromFlashDriveDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//  NSLog(@"cocoaControlController: importPCFromFlashDriveDidEnd");

    /* hide Open Sheet */
    [ sheet orderOut:self ];
    
    if ( returnCode == NSOKButton )
        [self importPCFromFlashDrive:[sheet filename]];
}

- (IBAction)importThisPCFromFlashDrive:(id)sender
{
//  NSLog(@"cocoaControlController: importThisPCFromFlashDrive");
    // open panel
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel beginSheetForDirectory: NSOpenStepRootDirectory()
        file:nil
        types:[NSArray arrayWithObjects:@"app", nil]
        modalForWindow:mainWindow
        modalDelegate:self
        didEndSelector:@selector(importThisPCFromFlashDriveDidEnd:returnCode:contextInfo:)
        contextInfo:sender];

}

- (BOOL) addArgumentTo:(id)arguments option:(id)option argument:(id)argument filename:filename
{
//  NSLog(@"addArgumentTo:option:argument:filename:");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    /* List of incompatible pre 0.8.0 Arguments */
    NSArray *obsoleteArguments = [[NSArray init] arrayWithObjects:@"-user-net", @"-tun-fd", @"-dummy-net", @"-prep", nil];              
    
    /* sort out old configurations */
    if ([obsoleteArguments containsObject:option]) {
        [self standardAlert: NSLocalizedStringFromTable(@"addArgumentTo:standardAlert", @"Localizable", @"cocoaControlController") informativeText:[NSString stringWithFormat: NSLocalizedStringFromTable(@"addArgumentTo:informativeText", @"Localizable", @"cocoaControlController"), option]];
        return FALSE;
    }
    
    /* do some error checking to avoid QEMU shutting down for incorrect Arguments */
    
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
        
    /* standard */        
    } else {    
        [arguments addObject:[NSString stringWithString:option]];
        if (![argument isEqual:@""]) {
            [arguments addObject:[NSString stringWithString:argument]];
        }
    }
    return TRUE;
}


- (void) startThisPC:(id)pc
{
//  NSLog(@"cocoaControlController: startThisPC");
    [self startPC:[NSString stringWithFormat:@"%@/%@.qvm", [userDefaults objectForKey:@"dataPath"], [[pc objectForKey:@"PC Data"] objectForKey:@"name"]]];
}


- (void) startPC:(NSString *)filename
{
//  NSLog(@"cocoaControlController: startPC:%@", filename);
    
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
        [arguments addObject: @"kju"];
    }

#if kju_debug
    for (i = 0; i < [arguments count]; i++)
        NSLog(@"Argument: %@", [arguments objectAtIndex:i]);
#endif

    /* save Status */
    [[thisPC objectForKey:@"PC Data"] setObject:@"running" forKey:@"state"];
    [self savePCConfiguration:thisPC];
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: [NSString stringWithFormat:@"%@/Contents/MacOS/%@.app/Contents/MacOS/%@", [[NSBundle mainBundle] bundlePath], [cpuTypes objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"]], [cpuTypes objectForKey:[[thisPC objectForKey:@"PC Data"] objectForKey:@"architecture"]]]];
    [task setArguments: arguments];
    [arguments release];
    
    // check the user defaults
    if(![userDefaults boolForKey:@"enableLogToConsole"]) {
        // prepare nstask output to grab exit codes and display a standardAlert when the qemu instance crashed
        NSPipe * pipe = [[NSPipe alloc] init];
        [task setStandardOutput: pipe];
        [task setStandardError: pipe];
        
        [pipe release];
    }
    
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
    [task release];
    
    /* update Table */
    [self loadConfigurations];
    [table reloadData];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
//  NSLog(@"cocoaControlController: tableView");

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
//      [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: NSLocalizedStringFromTable(@"tableView:mb", @"Localizable", @"cocoaControlController"), platform, [[thisPC objectForKey:@"Temporary"] objectForKey:@"-m"]] attributes:[NSDictionary dictionaryWithObject: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
//      if ([[thisPC objectForKey:@"Temporary"] objectForKey:@"-soundhw"])
//          [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: NSLocalizedStringFromTable(@"tableView:audio", @"Localizable", @"cocoaControlController"),[[thisPC objectForKey:@"Temporary"] objectForKey:@"-soundhw"]] attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
        [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString: NSLocalizedStringFromTable([[thisPC objectForKey:@"PC Data"] objectForKey:@"state"], @"Localizable", @"vmstate") attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
        
        return attrString;
    }
    
    return nil;
}

/* drag'n drop */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op 
{
    // Add code here to validate the drop
    // For now we 'redirect' the drop to an empty row assuming the user wants to create a new Guest PC with a CD-ROM image
    NSPasteboard * paste = [info draggingPasteboard];
    [table setDropRow:[table numberOfRows] dropOperation: NSTableViewDropAbove];

    if([FILE_TYPES containsObject: [[[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0] pathExtension]]) {
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info 
            row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *paste = [info draggingPasteboard];
    NSArray *types = [NSArray arrayWithObjects: NSFilenamesPboardType, nil];
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];

    if (nil == carriedData)
    {
        NSRunAlertPanel(@"Paste Error", @"Sorry, but the paste operation failed", 
            nil, nil, nil);
        return NO;
    }
    else
    {
        if ([desiredType isEqualToString:NSFilenamesPboardType])
        {
            /* Live CD handling here: currently we handle the first file to be set as CD-Rom for all Operating Systems of the 'New PC Assistant' showing "Live CD" first */
            [self addPCFromDragDrop: [[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0]];
        }
        else
        {
            NSAssert(NO, @"This can't happen");
            return NO;
        }
    }
    return YES;
}

- (void) tableDoubleClick:(id)sender
{
//  NSLog(@"cocoaControlController: tableDoubleClick");

    /* no empty line selection */
    if ([table selectedRow] < 0)
        [self addPC:self];
    else if ([[[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"state"] isEqualTo:@"running"]) {
        /* move QEMU to front */
        [qdoserver guestSwitch: @"Q Control" fullscreen:NO nextGuestName:[[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"name"]];
//      ProcessSerialNumber psn;
//      GetProcessForPID( [[pcsTasks objectForKey:[[[pcs objectAtIndex:[table selectedRow]] objectForKey:@"PC Data"] objectForKey:@"name"]] processIdentifier], &psn );
//      SetFrontProcess( &psn );
    } else {
        /* start PC */
        [self startThisPC:[pcs objectAtIndex:[table selectedRow]]];
    }
}

- (void) pauseThisPC:(id)pc
{
//  NSLog(@"cocoaControlController: pauseThisPC");
    [qdoserver guestPause:[[pc objectForKey:@"PC Data"] objectForKey:@"name"]];
}

- (void) playThisPC:(id)pc
{
//  NSLog(@"cocoaControlController: playThisPC");
    [qdoserver guestPause:[[pc objectForKey:@"PC Data"] objectForKey:@"name"]];
}

- (void) stopThisPC:(id)pc
{
//  NSLog(@"cocoaControlController: stopThisPC");

    if (![qdoserver guestStop:[[pc objectForKey:@"PC Data"] objectForKey:@"name"]]) { //if we can't shutdown the guest in normal manner, use force
        [[pcsTasks objectForKey:[[pc objectForKey:@"PC Data"] objectForKey:@"name"]] terminate]; //this sends sigterm, maybe we need something stronger here: "bin kill -9"
    }
}

/* dIWindow */
- (IBAction) openDIWindow:(id)sender
{
//  NSLog(@"cocoaControlController: openDIWindow");

    cocoaControlDiskImage *dI = [[cocoaControlDiskImage alloc] init];
    if (![NSBundle loadNibNamed:@"cocoaControlDiskImage" owner:dI]) {
        NSLog(@"Error loading cocoaControlDiskImage.nib for document!");
    } else {
        [dI setQSender:nil];
    }
    [[dI dIWindow] makeKeyAndOrderFront:self];
}

/* openFreeOSDownloader */
- (IBAction) openFreeOSDownloader:(id)sender
{
//  printf("cocoaControlController: openFreeOSDownloader\n");
    if(!downloader) {
        downloader = [[cocoaDownloadController alloc] initWithSender:self];
        if (![NSBundle loadNibNamed:@"cocoaDownload" owner:downloader]) {
            printf("cocoaDownload.nib not loaded!\n");
        }
    } else {
        [downloader initDownloadInterface];
    }
    
    /*
    if(!cocoaDownloadController) {
        cocoaDownloadController * dl = [[cocoaDownloadController alloc] initWithSender:self];
        if (![NSBundle loadNibNamed:@"cocoaDownload" owner:dl]) {
            printf("cocoaDownload.nib not loaded!\n");
       }
    }*/
}

/* Standard Alert */
- (void) standardAlert:(NSString *)messageText informativeText:(NSString *)informativeText
{
//  NSLog(@"cocoaControlController: standardAlert\n");

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
// NSLog(@"cocoaControlController: getLatestVersion");

    unichar dev = 'd';
    
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] characterAtIndex:5] == dev) {
        [[NSURL URLWithString:@"http://www.kberg.ch/q/latestVersion.php?d=builds/nightly"] loadResourceDataNotifyingClient:self usingCache:NO];
    } else {
        [[NSURL URLWithString:@"http://www.kberg.ch/q/latestVersion.php?d=builds"] loadResourceDataNotifyingClient:self usingCache:NO];
    }
}

- (void) URLResourceDidFinishLoading:(NSURL *)sender
{
// NSLog(@"cocoaControlController: URLResourceDidFinishLoading");

    NSData *data = [sender resourceDataUsingCache:YES];

    if(data){
        NSString *ver = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSISOLatin1StringEncoding];
        
        if ([ver compare:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] == NSOrderedDescending) {
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
//  NSLog(@"cocoaControlController: URLResourceDidCancelLoading");
}

- (void)updateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//  NSLog(@"cocoaControlController: updateAlertDidEnd Button=%d", returnCode );
    
    if (returnCode == 1) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.kberg.ch/q"]];
    }
}
@end