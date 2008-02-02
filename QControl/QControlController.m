/*
 * Q Control Controller
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

#import "../CGSPrivate.h"

#import "QControlController.h"

#import "../QDocument/QDocument.h"
#import "../QShared/QButtonCell.h"
#import "../QShared/QQvmManager.h"


#define PREFS_HEIGHT 190.0

@implementation QControlController
-(id)init
{
	Q_DEBUG(@"init");

    self = [super init];
	if (self) {
	
        // Application
        qApplication = [NSApp delegate];
		
		// load known VMs
		[self loadConfigurations];

		// change status to "shutdown" after corrupt termination of QEMU
		int i;
		for (i = 0; i < [VMs count]; i++) {
			if ([[[[VMs objectAtIndex:i] objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"] ) {
				[[[VMs objectAtIndex:i] objectForKey:@"PC Data"] setObject:@"shutdown" forKey:@"state"];
				[[QQvmManager sharedQvmManager] saveVMConfiguration:[VMs objectAtIndex:i]];
			}
		}

		// Listen to VM updates
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadConfigurations) name:@"QVMStatusDidChange" object:nil];
	}
    return self;
}

- (void) dealloc
{
	Q_DEBUG(@"dealloc");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void)awakeFromNib
{
	Q_DEBUG(@"awakeFromNib");

#pragma mark TODO: load other nibs

	[buttonEdit setCell:[[[QButtonCell alloc] initImageCell:[[buttonEdit cell] image] buttonType:QButtonCellLeft target:[[buttonEdit cell] target] action:[[buttonEdit cell] action]] autorelease]];
	[buttonAdd setCell:[[[QButtonCell alloc] initImageCell:[[buttonAdd cell] image] buttonType:QButtonCellRight target:[[buttonAdd cell] target] action:[[buttonAdd cell] action]] autorelease]];
	

	// preferences
	[prefPath setStringValue:[[qApplication userDefaults] objectForKey:@"dataPath"]];
    if ([[qApplication userDefaults] boolForKey:@"SUCheckAtStartup"]) {
        [prefUpdates setState:NSOnState];
    } else {
        [prefUpdates setState:NSOffState];
    }
    if ([[qApplication userDefaults] boolForKey:@"enableLogToConsole"]) {
        [prefLog setState:NSOnState];
    } else {
        [prefLog setState:NSOffState];
    }
    if ([[qApplication userDefaults] boolForKey:@"showFullscreenWarning"]) {
        [prefFSWarning setState:NSOnState];
    } else {
        [prefFSWarning setState:NSOffState];
    }
    if ([[qApplication userDefaults] boolForKey:@"yellow"]) {
        [prefYellow setState:NSOnState];
    } else {
        [prefYellow setState:NSOffState];
    }
}

- (IBAction) showQControl:(id)sender
{
	Q_DEBUG(@"showQControl");

	[mainWindow makeKeyAndOrderFront:self];
}


#pragma mark configurations


- (void) loadConfigurations
{
	Q_DEBUG(@"loadConfigurations");

    if (VMs)
        [VMs release];

    VMs = [[[NSMutableArray alloc] init] retain];
    NSString *qvmFile;
	NSMutableDictionary *tempVM;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[qApplication userDefaults] objectForKey:@"dataPath"]];
    while ((qvmFile = [enumerator nextObject])) {
		if ([[qvmFile pathExtension] isEqual:@"qvm"]) {
			tempVM = [[QQvmManager sharedQvmManager] loadVMConfiguration:[NSString stringWithFormat:@"%@/%@", [[qApplication userDefaults] objectForKey:@"dataPath"], qvmFile]];
			if (tempVM)
				[VMs addObject:tempVM];
		}
    }
	// add knownVMs
	int i;
	NSMutableArray *knownVMs = [[[qApplication userDefaults] objectForKey:@"knownVMs"] mutableCopy];
	for (i = [knownVMs count] - 1; i > -1; i--) {
		// does it still exist?
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:[knownVMs objectAtIndex:i]]) {
			tempVM = [[QQvmManager sharedQvmManager] loadVMConfiguration:[knownVMs objectAtIndex:i]];
			if (tempVM) {
				[VMs addObject:tempVM];
			} else {
				[knownVMs removeObjectAtIndex:i];
			}
		} else {
			[knownVMs removeObjectAtIndex:i];
		}
	}
	[[qApplication userDefaults] setObject:knownVMs forKey:@"knownVMs"];
}


/*
#pragma mark PC methods
-(IBAction) addPC:(id)sender
{
	Q_DEBUG(@"addPC");

    cocoaControlNewPCAssistant *npa = [[cocoaControlNewPCAssistant alloc] init];
    [NSBundle loadNibNamed:@"cocoaControlNewPCAssistant" owner:npa];
    [npa setQSender:self];
    
    [NSApp beginSheet:[npa npaPanel]
        modalForWindow:mainWindow 
        modalDelegate:npa
        didEndSelector:@selector(npaPanelDidEnd:returnCode:contextInfo:)
        contextInfo:nil];
}
*/
- (void) addVMToKnownVMs:(NSString *)path
{
	Q_DEBUG(@"addVMToKnownVMs: %@", path);

	// add knownVMs
	NSMutableArray *knownVMs = [[[qApplication userDefaults] objectForKey:@"knownVMs"] mutableCopy];
	NSMutableDictionary *tempVM = [[QQvmManager sharedQvmManager] loadVMConfiguration:path];
	if (tempVM) {
		[knownVMs addObject:path];
		[VMs addObject:tempVM];
		[table reloadData];
		[[qApplication userDefaults] setObject:knownVMs forKey:@"knownVMs"];
	}
}

- (void) addVMFromDragDrop:(NSString *)path
{
	Q_DEBUG(@"addVMFromDragDrop");

/*
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
*/
}

-(IBAction) addVMFromAssistant:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"addVMAssistant");

/*
    // enter current Values into editPCPanel
    [editPC prepareEditPCPanel:thisPC newPC:YES sender:self];
 
    // display editPCPanel  
    [[editPC editPCPanel] makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:[editPC editPCPanel]];
*/
}

-(void) editVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"editThisPC");

/*
    // enter current Values into editPCPanel
    [editPC prepareEditPCPanel:pc newPC:NO sender:self];
 
    // display editPCPanel
    [[editPC editPCPanel] makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:[editPC editPCPanel]];
*/
}
/*
-(IBAction) editPC:(id)sender
{
	Q_DEBUG(@"editPC");


    // no empty line selection
    if ( [table numberOfSelectedRows] == 0 )
        return;

    [self editThisPC:[VMs objectAtIndex:[table selectedRow]]];
}

-(BOOL) checkPC:(id)thisPC name:(NSString *)name create:(BOOL)create
{
	Q_DEBUG(@"checkPC");


    NSEnumerator *enumerator = [VMs objectEnumerator];
    id object;
    
    if (create) {
        while ( (object = [enumerator nextObject]) ) {
            if ([[[object objectForKey:@"PC Data"] objectForKey:@"name"] isEqual: name] )
                return 0;
        }
    } else {
        while ( (object = [enumerator nextObject]) ) {
            if ([[[object objectForKey:@"PC Data"] objectForKey:@"name"] isEqual: name]) {
                if ( ![[[thisPC objectForKey:@"PC Data"] objectForKey:@"name"] isEqual:name])
                    return 0;
            }
        }
    }
    
    return 1;
}
*/
- (void) deleteVMAlertDidEnd:alert returnCode:(int)returnCode contextInfo:(id)contextInfo
{
	Q_DEBUG(@"deleteVMAlertDidEnd");

    if (returnCode == 1) {
        
        // delete .qvm
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:[[[contextInfo objectForKey:@"Temporary"] objectForKey:@"URL"] path]])
            [fileManager removeFileAtPath:[[[contextInfo objectForKey:@"Temporary"] objectForKey:@"URL"] path] handler:nil];
    
        // cleanup
        [self loadConfigurations];
    }
}

- (void) deleteVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"deleteThisVM: %@", VM);

	// do not allow deleting a running VM
    if ([[[VM objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"]) {
        [self standardAlert: [NSString stringWithFormat: NSLocalizedStringFromTable(@"deleteVM:standardAlert", @"Localizable", @"QControlController"),[[VM objectForKey:@"PC Data"] objectForKey:@"name"]]
             informativeText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"deleteVM:informativeText", @"Localizable", @"QControlController"), [[VM objectForKey:@"PC Data"] objectForKey:@"name"]]];
        return;
    }
    
    // prepare alert
    NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"deleteVM:alertWithMessageText", @"Localizable", @"QControlController")
                      defaultButton: NSLocalizedStringFromTable(@"deleteVM:defaultButton", @"Localizable", @"QControlController")
                    alternateButton: NSLocalizedStringFromTable(@"deleteVM:alternateButton", @"Localizable", @"QControlController")
                        otherButton:nil
                  informativeTextWithFormat:[NSString stringWithFormat: NSLocalizedStringFromTable(@"deleteVM:informativeTextWithFormat", @"Localizable", @"QControlController"),[[VM objectForKey:@"PC Data"] objectForKey:@"name"]]];
    
    // display alert
    [alert beginSheetModalForWindow:mainWindow
                  modalDelegate:self
                 didEndSelector:@selector(deleteVMAlertDidEnd:returnCode:contextInfo:)
                 contextInfo:VM];
}

- (void) startVMWithURL:(NSURL *)URL
{
	Q_DEBUG(@"startVMWithURL:%@", URL);

	// start VM
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES error:nil];
}

- (void) startVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"startVM: %@", VM);

    [self startVMWithURL:[[VM objectForKey:@"Temporary"] objectForKey:@"URL"]];
}

- (void) pauseVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"pauseVM: %@", VM);

	QDocument *qDocument;
	qDocument = [[NSDocumentController sharedDocumentController] documentForURL:[[VM objectForKey:@"Temporary"] objectForKey:@"URL"]];
	[qDocument VMPause:self];
}

- (void) unpauseVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"unpauseVM: %@", VM);

	QDocument *qDocument;
	qDocument = [[NSDocumentController sharedDocumentController] documentForURL:[[VM objectForKey:@"Temporary"] objectForKey:@"URL"]];
	[qDocument VMUnpause:self];
}

- (void) stopVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"stopVM: %@", VM);

	QDocument *qDocument;
	qDocument = [[NSDocumentController sharedDocumentController] documentForURL:[[VM objectForKey:@"Temporary"] objectForKey:@"URL"]];
	[qDocument VMShutDown:self];
}



#pragma mark open other windows
/*
- (IBAction) openDIWindow:(id)sender
{
	Q_DEBUG(@"openDIWindow");


    cocoaControlDiskImage *dI = [[cocoaControlDiskImage alloc] init];
    if (![NSBundle loadNibNamed:@"cocoaControlDiskImage" owner:dI]) {
        NSLog(@"Error loading cocoaControlDiskImage.nib for document!");
    } else {
        [dI setQSender:nil];
    }
    [[dI dIWindow] makeKeyAndOrderFront:self];
}
*/
#pragma mark openFreeOSDownloader
/*
- (IBAction) openFreeOSDownloader:(id)sender
{
	Q_DEBUG(@"openFreeOSDownloader");

    if(!downloader) {
        downloader = [[cocoaDownloadController alloc] initWithSender:self];
        if (![NSBundle loadNibNamed:@"cocoaDownload" owner:downloader]) {
            printf("cocoaDownload.nib not loaded!\n");
        }
    } else {
        [downloader initDownloadInterface];
    }
}
*/



#pragma mark preferences
- (void)animationDidEnd:(NSAnimation*)animation
{
	Q_DEBUG(@"animationDidEnd");

    isPrefAnimating = FALSE;
}

- (IBAction) togglePreferences:(id)sender
{
	Q_DEBUG(@"togglePreferences");

    if (!isPrefAnimating) {
        NSViewAnimation *viewAnimation;
        NSMutableDictionary* viewDictionary;
        NSRect tFrame;
        
        tFrame = [[[table superview] superview] frame];
        viewDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        [viewDictionary setObject:[[table superview] superview] forKey:NSViewAnimationTargetKey];      
        [viewDictionary setObject:[NSValue valueWithRect:tFrame] forKey:NSViewAnimationStartFrameKey];
            
        if (isPrefShown) {
            tFrame.origin.y = 30.0;
            tFrame.size.height += PREFS_HEIGHT;
            isPrefShown = FALSE;
        } else {
			[mainWindow makeKeyAndOrderFront:self];
            tFrame.origin.y = PREFS_HEIGHT + 30.0;
            tFrame.size.height -= PREFS_HEIGHT;  
            isPrefShown = TRUE;
        }
        
        [viewDictionary setObject:[NSValue valueWithRect:tFrame] forKey:NSViewAnimationEndFrameKey];  
        viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:viewDictionary, nil]];
        [viewAnimation setDuration:0.25];
        [viewAnimation setAnimationCurve:NSAnimationLinear];
        [viewAnimation setDelegate:self];
        [viewAnimation startAnimation];
        [viewAnimation release];
        
        isPrefAnimating = TRUE;
    }
}

- (IBAction) prefUpdates:(id)sender
{
	Q_DEBUG(@"prefUpdates");

	if ([sender state] == NSOnState) {
		[[qApplication userDefaults] setBool:TRUE forKey:@"SUCheckAtStartup"];
	} else {
		[[qApplication userDefaults] setBool:FALSE forKey:@"SUCheckAtStartup"];
	}
}

- (IBAction) prefLog:(id)sender
{
	Q_DEBUG(@"prefLog");

	if ([sender state] == NSOnState) {
		[[qApplication userDefaults] setBool:TRUE forKey:@"enableLogToConsole"];
	} else {
		[[qApplication userDefaults] setBool:FALSE forKey:@"enableLogToConsole"];
	}
}

- (IBAction) prefYellow:(id)sender
{
	Q_DEBUG(@"prefYellow");

	if ([sender state] == NSOnState) {
		[[qApplication userDefaults] setBool:TRUE forKey:@"yellow"];
	} else {
		[[qApplication userDefaults] setBool:FALSE forKey:@"yellow"];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"yellow" object:nil];
}


- (IBAction) prefFSWarning:(id)sender
{
	Q_DEBUG(@"prefYellow");

	if ([sender state] == NSOnState) {
		[[qApplication userDefaults] setBool:TRUE forKey:@"showFullscreenWarning"];
	} else {
		[[qApplication userDefaults] setBool:FALSE forKey:@"showFullscreenWarning"];
	}
}

- (IBAction) prefPathReset:(id)sender
{
	Q_DEBUG(@"prefPathReset");

	[[qApplication userDefaults] setObject:[@"~/Documents/QEMU" stringByExpandingTildeInPath] forKey:@"dataPath"];
	[prefPath setStringValue:[[qApplication userDefaults] objectForKey:@"dataPath"]];
}

- (void) genericFolderSelectPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
	Q_DEBUG(@"genericFolderSelectPanelDidEnd");

	[ sheet orderOut:self ]; // hide Sheet
	if ( returnCode == NSOKButton ) {
		[[qApplication userDefaults] setObject:[sheet filename] forKey:@"dataPath"];
		[prefPath setStringValue:[sheet filename]];
	}
}

- (IBAction) prefPathChoose:(id)sender
{
	Q_DEBUG(@"prefPathChoose");

	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel beginSheetForDirectory:[@"~/Documents" stringByExpandingTildeInPath]
		file:nil
		types:nil
		modalForWindow:mainWindow
		modalDelegate:self
		didEndSelector:@selector(genericFolderSelectPanelDidEnd:returnCode:contextInfo:)
		contextInfo:sender];
}



#pragma mark Standard Alert
- (void) standardAlert:(NSString *)messageText informativeText:(NSString *)informativeText
{
	Q_DEBUG(@"standardAlert");

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



#pragma mark getters and setter
- (id) mainWindow {return mainWindow;}
- (NSMutableArray *) VMs {return VMs;}
@end