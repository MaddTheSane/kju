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

//#import "../CGSPrivate.h"

#import "QControlController.h"

#import "../QDocument/QDocument.h"
#import "../QShared/QButtonCell.h"
#import "../QShared/QWindow.h"

#import "Q-Swift.h"

#define PREFS_HEIGHT 100.0

@implementation QControlController
{
	__weak QApplicationController *qApplication;
	
	// controlWindow
	NSMutableArray *VMs;
	
	NSTimer *timer;	 //to update Table Thumbnails
	
	// preferences
	BOOL isPrefAnimating;
	BOOL isPrefShown;
	
	// loading VMs
	
	// browsing for qvms
	NSMetadataQuery *query;
	/*
	 // progressPanel
	 IBOutlet id progressPanel;
	 IBOutlet NSProgressIndicator *progressIndicator;
	 IBOutlet NSTextField *progressTitle;
	 IBOutlet NSTextField *progressText;
	 IBOutlet NSTextField *progressStatusText;
	 
	 // preferences
	 cocoaControlPreferences *preferences;
	 
	 // FreeOSDownloader
	 cocoaDownloadController *downloader;
	 
	 // newImage
	 */	
}

@synthesize table;
@synthesize prefUpdates;
@synthesize prefLog;
@synthesize prefYellow;
@synthesize prefFSWarning;
@synthesize buttonEdit;
@synthesize buttonAdd;
@synthesize loadProgressIndicator;
@synthesize loadProgressText;
@synthesize mainWindow;

-(instancetype)init
{
	Q_DEBUG(@"init");

    self = [super init];
	if (self) {
	
        // Application
        qApplication = NSApp.delegate;
		
		// load known VMs, search for new VMs
		[self loadConfigurations];
		
		// Listen if new VMs are found
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryFinished:) name:NSMetadataQueryDidFinishGatheringNotification object:query];

		// Listen to VM updates
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadConfigurations) name:@"QVMStatusDidChange" object:nil];
	}
    return self;
}

- (void) dealloc
{
	Q_DEBUG(@"dealloc");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)awakeFromNib
{
	Q_DEBUG(@"awakeFromNib");

#pragma mark TODO: load other nibs

	NSPredicate *predicate;

	buttonEdit.cell = [[QButtonCell alloc] initImageCell:[buttonEdit.cell image] buttonType:QButtonCellLeft target:buttonEdit.cell.target action:[buttonEdit.cell action]];
	buttonAdd.cell = [[QButtonCell alloc] initImageCell:[buttonAdd.cell image] buttonType:QButtonCellRight target:buttonAdd.cell.target action:[buttonAdd.cell action]];
	
	// search for qvms
	query = [[NSMetadataQuery alloc] init];
	query.delegate = self;
	[loadProgressIndicator startAnimation:self];
	predicate = [NSPredicate predicateWithFormat:@"kMDItemDisplayName ENDSWITH 'qvm'", nil];
    query.predicate = predicate;
    query.searchScopes = @[NSMetadataQueryUserHomeScope];
	[query startQuery];

	// preferences
    if ([[qApplication userDefaults] boolForKey:@"SUCheckAtStartup"]) {
        prefUpdates.state = NSOnState;
    } else {
        prefUpdates.state = NSOffState;
    }
    if ([[qApplication userDefaults] boolForKey:@"enableLogToConsole"]) {
        prefLog.state = NSOnState;
    } else {
        prefLog.state = NSOffState;
    }
    if ([[qApplication userDefaults] boolForKey:@"showFullscreenWarning"]) {
        prefFSWarning.state = NSOnState;
    } else {
        prefFSWarning.state = NSOffState;
    }
    if ([[qApplication userDefaults] boolForKey:@"yellow"]) {
        prefYellow.state = NSOnState;
    } else {
        prefYellow.state = NSOffState;
    }
}

- (IBAction) showQControl:(id)sender
{
	Q_DEBUG(@"showQControl");

	[mainWindow makeKeyAndOrderFront:self];
}


#pragma mark configurations
static NSComparisonResult revCaseInsensitiveCompare(id string1, id string2, void *context)
{
    return [[string2 lastPathComponent] caseInsensitiveCompare:[string1 lastPathComponent] ];
}

- (void) loadConfigurations
{
	Q_DEBUG(@"loadConfigurations");
	
	NSMutableDictionary *tempVM;
	NSMutableArray *knownVMs;

	VMs =[[NSMutableArray alloc] init];
	
	// check knownVMs
	knownVMs = [[[qApplication userDefaults] objectForKey:@"knownVMs"] mutableCopy];
	[knownVMs sortUsingFunction:revCaseInsensitiveCompare context:nil];
	for (NSInteger i = knownVMs.count - 1; i > -1; i--) {
		tempVM = [[QQvmManager sharedQvmManager] loadVMConfiguration:knownVMs[i]];
		if (tempVM) {
			[VMs addObject:tempVM];
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
		if (![knownVMs containsObject:path]) {
			[knownVMs addObject:path];
			[VMs addObject:tempVM];
			[table reloadData];
			[[qApplication userDefaults] setObject:knownVMs forKey:@"knownVMs"];
		}
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
            if ([[[object objectForKey:@"Temporary"] objectForKey:@"name"] isEqual: name] )
                return 0;
        }
    } else {
        while ( (object = [enumerator nextObject]) ) {
            if ([[[object objectForKey:@"Temporary"] objectForKey:@"name"] isEqual: name]) {
                if ( ![[[thisPC objectForKey:@"Temporary"] objectForKey:@"name"] isEqual:name])
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
        if ([fileManager fileExistsAtPath:[contextInfo[@"Temporary"][@"URL"] path]])
            [fileManager removeItemAtURL:contextInfo[@"Temporary"][@"URL"] error:nil];
    
        // cleanup
        [self loadConfigurations];
    }
}

- (void) deleteVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"deleteThisVM: %@", VM);

	// do not allow deleting a running VM
    if ([VM[@"PC Data"][@"state"] isEqual:@"running"]) {
        [self standardAlert: [NSString stringWithFormat: NSLocalizedStringFromTable(@"deleteVM:standardAlert", @"Localizable", @"QControlController"),VM[@"Temporary"][@"name"]]
             informativeText: [NSString stringWithFormat: NSLocalizedStringFromTable(@"deleteVM:informativeText", @"Localizable", @"QControlController"), VM[@"Temporary"][@"name"]]];
        return;
    }
    
    // prepare alert
    NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"deleteVM:alertWithMessageText", @"Localizable", @"QControlController")
                      defaultButton: NSLocalizedStringFromTable(@"deleteVM:defaultButton", @"Localizable", @"QControlController")
                    alternateButton: NSLocalizedStringFromTable(@"deleteVM:alternateButton", @"Localizable", @"QControlController")
                        otherButton:nil
                  informativeTextWithFormat:@"%@", [NSString stringWithFormat: NSLocalizedStringFromTable(@"deleteVM:informativeTextWithFormat", @"Localizable", @"QControlController"),VM[@"Temporary"][@"name"]]];
    
    // display alert
    [alert beginSheetModalForWindow:mainWindow
                  modalDelegate:self
                 didEndSelector:@selector(deleteVMAlertDidEnd:returnCode:contextInfo:)
                 contextInfo:(__bridge void * _Nullable)(VM)];
}

- (void) startVMWithURL:(NSURL *)URL
{
	Q_DEBUG(@"startVMWithURL:%@", URL);

	// start VM
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {}];
}

- (void) startVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"startVM: %@", VM);

    [self startVMWithURL:VM[@"Temporary"][@"URL"]];
}

- (void) pauseVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"pauseVM: %@", VM);

	QDocument *qDocument;
	qDocument = [[NSDocumentController sharedDocumentController] documentForURL:VM[@"Temporary"][@"URL"]];
	[qDocument VMPause:self];
}

- (void) unpauseVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"unpauseVM: %@", VM);

	QDocument *qDocument;
	qDocument = [[NSDocumentController sharedDocumentController] documentForURL:VM[@"Temporary"][@"URL"]];
	[qDocument VMUnpause:self];
}

- (void) stopVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"stopVM: %@", VM);

	QDocument *qDocument;
	qDocument = [[NSDocumentController sharedDocumentController] documentForURL:VM[@"Temporary"][@"URL"]];
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
        
        tFrame = table.superview.superview.frame;
        viewDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
        viewDictionary[NSViewAnimationTargetKey] = table.superview.superview;      
        viewDictionary[NSViewAnimationStartFrameKey] = [NSValue valueWithRect:tFrame];
            
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
        
        viewDictionary[NSViewAnimationEndFrameKey] = [NSValue valueWithRect:tFrame];  
        viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[viewDictionary]];
        viewAnimation.duration = 0.25;
        viewAnimation.animationCurve = NSAnimationLinear;
        viewAnimation.delegate = self;
        [viewAnimation startAnimation];
        
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


#pragma mark query handlers
  - (void)queryFinished:(NSNotification*)note
{
	Q_DEBUG(@"queryFinished");

	int i;
	NSArray *searchResults;
	NSString *VMPath;
	NSMutableArray *knownVMs;
	
	knownVMs = [[[qApplication userDefaults] objectForKey:@"knownVMs"] mutableCopy];
	searchResults = ((NSMetadataQuery*)note.object).results;
	
	for (i = 0; i < searchResults.count; i++) {
		VMPath = [[searchResults[i] valueForAttribute: (NSString *)kMDItemPath] stringByResolvingSymlinksInPath];
		if (![knownVMs containsObject:VMPath]) {
			[knownVMs addObject:VMPath];
		}
	}
	[[qApplication userDefaults] setObject:knownVMs forKey:@"knownVMs"];

	// change status to "shutdown" after corrupt termination of QEMU
	for (i = 0; i < VMs.count; i++) {
		if ([VMs[i][@"PC Data"][@"state"] isEqual:@"running"] ) {
			VMs[i][@"PC Data"][@"state"] = @"shutdown";
			[[QQvmManager sharedQvmManager] saveVMConfiguration:VMs[i]];
		}
	}

	[loadProgressText setHidden:TRUE];
	[loadProgressIndicator stopAnimation:self];
	[table reloadData];
}



#pragma mark Standard Alert
- (void) standardAlert:(NSString *)messageText informativeText:(NSString *)informativeText
{
	Q_DEBUG(@"standardAlert");

    NSAlert *alert = [NSAlert alertWithMessageText:messageText
        defaultButton:@"OK"
        alternateButton:nil
        otherButton:nil
        informativeTextWithFormat:@"%@", informativeText];

    [alert beginSheetModalForWindow:mainWindow
        modalDelegate:self
        didEndSelector:nil
        contextInfo:nil];
}



#pragma mark getters and setter
- (NSMutableArray *) VMs {return VMs;}
@end
