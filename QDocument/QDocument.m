/*
 * Q Document
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

#import "QDocument.h"
#import "QDocumentOpenGLView.h"
#import "../QShared/QButtonCell.h"
#import "../QShared/QPopUpButtonCell.h"
#import "../QShared/QQvmManager.h"

//for CDROM
#import <paths.h>
#import <sys/param.h>
#import <IOKit/IOBSD.h>
#import <IOKit/storage/IOMediaBSDClient.h>
#import <IOKit/storage/IOMedia.h>
#import <IOKit/storage/IOCDMedia.h>


@implementation QDocument

- (id)init
{
	Q_DEBUG(@"init");

    self = [super init];
    if (self) {
    
        // Application
        qApplication = [NSApp delegate];
        uniqueDocumentID = [qApplication leaseAUniqueDocumentID:self];
    
        // initialize QEMU state
        cpuUsage = 0.0;
        ideActivity = FALSE;
        driveFileNames = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", nil];
        absolute_enabled = FALSE;
        VMSupportsSnapshots = FALSE;

		// other Nibs
		editVMController = [[QDocumentEditVMController alloc] init];
		if (![NSBundle loadNibNamed:@"QEditVM" owner:editVMController]) {
			NSLog(@"QEditVM.nib not loaded!");
		}
        
        // Todo, define some globals
        // set allowed filetypes
        fileTypes = [[NSArray alloc] initWithArrayOfAllowedFileTypes];

    }
    return self;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	Q_DEBUG(@"initWithContentsOfURL:%@", absoluteURL);

    self = [self init];
    
    if (self) {
		if ([[absoluteURL class] isEqual:[NSURL class]]) {
			[self setFileURL:absoluteURL];
		} else {
			[self setFileURL:[NSURL fileURLWithPath:(NSString *)absoluteURL]];
		}
        [self setFileType:typeName];
        [self setFileModificationDate:[NSDate date]];



        // initialize the guest (we want this to be done before the nib loads!)

        // read the .qvm file
        configuration = [[QQvmManager sharedQvmManager] loadVMConfiguration:[[self fileURL] path]];
		if (configuration) {
			[configuration retain];
			// is this VM saveable (only -hda qcow2 is)
			NSRange hdb;
			NSRange qcow2;
			hdb = [[configuration objectForKey:@"Arguments"] rangeOfString:@"-hdb"];
			qcow2 = [[configuration objectForKey:@"Arguments"] rangeOfString:@"qcow2"];
        
			if (qcow2.length > 0) {
				if (hdb.length > 0) {
					if (qcow2.location < hdb.location) {
						VMSupportsSnapshots = TRUE;
					}
				} else {
					VMSupportsSnapshots = TRUE;
				}
			}

			// set VMState
			if ([[[configuration objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]) {
				VMState = QDocumentSaved;
			} else {
				VMState = QDocumentShutdown;
			}
		} else {
			VMState = QDocumentInvalid;
		}
        
        
        // create shared videoram
        int videoRAMSize;
        int fd, ret;
        videoRAMSize = 1024 * 768 * 4;
        void *dummyFile;
        dummyFile = malloc(videoRAMSize);
        fd = open([[NSString stringWithFormat:@"/tmp/qDocument_%D.vga", uniqueDocumentID] cString], O_CREAT|O_RDWR, 0666); // open (trunkate/create) for read/write
        if (fd == -1) {
            [self defaultAlertMessage:[NSString stringWithFormat:@"QDocument: could not create '/tmp/qDocument_%D.vga' file", uniqueDocumentID] informativeText:nil];
            [self setVMState:QDocumentInvalid];
            return nil;
        }
        ret = write(fd, dummyFile, videoRAMSize);
		
        ret = close(fd);
        free(dummyFile);        
        
        
        
    }
    return self;
}

- (void)dealloc
{
	Q_DEBUG(@"dealloc");

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (distributedObject)
        [distributedObject release];
    if (qemuTask)
        [qemuTask release];
    if (windowController)
        [windowController release];
    if (fileTypes)
        [fileTypes release];
    if (driveFileNames)
		[driveFileNames release];
	if (configuration)
		[configuration release];
    if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/tmp/qDocument_%D.vga", uniqueDocumentID]])
        [[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithFormat:@"/tmp/qDocument_%D.vga", uniqueDocumentID] handler: nil];

    [super dealloc];
}

- (NSString *)windowNibName
{
	Q_DEBUG(@"windowNibName");

    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"QDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	Q_DEBUG(@"windowControllerDidLoadNib");

    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.

	// Tiger compatible custom butoonCell
	[buttonEdit setCell:[[[QButtonCell alloc] initImageCell:[[buttonEdit cell] image] buttonType:QButtonCellAlone target:[[buttonEdit cell] target] action:[[buttonEdit cell] action]] autorelease]];

	[buttonFloppy setCell:[[[QPopUpButtonCell alloc] initTextCell:@"" buttonType:QButtonCellLeft pullsDown:[[buttonFloppy cell] pullsDown] menu:[[buttonFloppy cell] menu] image:[NSImage imageNamed:@"q_d_disk_drop"]] autorelease]];
	[buttonCDROM setCell:[[[QPopUpButtonCell alloc] initTextCell:@"" buttonType:QButtonCellRight pullsDown:[[buttonCDROM cell] pullsDown] menu:[[buttonCDROM cell] menu] image:[NSImage imageNamed:@"q_d_cd_drop"]] autorelease]];

	[buttonToggleFullscreen setCell:[[[QButtonCell alloc] initImageCell:[[buttonToggleFullscreen cell] image] buttonType:QButtonCellLeft target:[[buttonToggleFullscreen cell] target] action:[[buttonToggleFullscreen cell] action]] autorelease]];
	[buttonTakeScreenshot setCell:[[[QButtonCell alloc] initImageCell:[[buttonTakeScreenshot cell] image] buttonType:QButtonCellRight target:[[buttonTakeScreenshot cell] target] action:[[buttonTakeScreenshot cell] action]] autorelease]];
	[buttonCtrlAltDel setCell:[[[QButtonCell alloc] initImageCell:[[buttonCtrlAltDel cell] image] buttonType:QButtonCellLeft target:[[buttonCtrlAltDel cell] target] action:[[buttonCtrlAltDel cell] action]] autorelease]];
	[buttonReset setCell:[[[QButtonCell alloc] initImageCell:[[buttonReset cell] image] buttonType:QButtonCellMiddle target:[[buttonReset cell] target] action:[[buttonReset cell] action]] autorelease]];
	[buttonTogglePause setCell:[[[QButtonCell alloc] initImageCell:[[buttonTogglePause cell] image] buttonType:QButtonCellMiddle target:[[buttonTogglePause cell] target] action:[[buttonTogglePause cell] action]] autorelease]];
	[buttonTogleStartShutdown setCell:[[[QButtonCell alloc] initImageCell:[[buttonTogleStartShutdown cell] image] buttonType:QButtonCellRight target:[[buttonTogleStartShutdown cell] target] action:[[buttonTogleStartShutdown cell] action]] autorelease]];
	
    // create a controller for the document window
    windowController = [[QDocumentWindowController alloc] initWithWindow:[[[self windowControllers] objectAtIndex:0] window] sender:self];
}
/*
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	Q_DEBUG(@"dataRepresentationOfType");

    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    
    // For applications targeted for Tiger or later systems, you should use the new Tiger API -dataOfType:error:.  In this case you can also choose to override -writeToURL:ofType:error:, -fileWrapperOfType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	Q_DEBUG(@"loadDataRepresentation");

    // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    
    // For applications targeted for Tiger or later systems, you should use the new Tiger API readFromData:ofType:error:.  In this case you can also choose to override -readFromURL:ofType:error: or -readFromFileWrapper:ofType:error: instead.
    
    return YES;
}
*/
//readFromURL:ofType:error:
//writeToURL:ofType:error:
//writeToURL:ofType:forSaveOperation:originalContentsURL:error:
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    NSLog(@"readFromURL");
	return TRUE;
}
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    NSLog(@"writeToURL");
	return TRUE;
}


#pragma mark delegates and overrides for NSDocument
- (IBAction) newDocument:(id)sender
{
	Q_DEBUG(@"saveDocument");

	// Todo:
	// either create a "new document" (immediately create the files) or show a assistent
	// the -name argument is created by the document name

    NSLog(@"We should create a now Document now");
}

- (void)savePanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	Q_DEBUG(@"savePanelDidEnd");

	NSFileManager *fileManager;
	NSMutableArray *knownVMs;

    if (returnCode == NSOKButton) {

		fileManager = [NSFileManager defaultManager];
		
		// move untitled Document to named document
		if ([fileManager movePath:[[[configuration objectForKey:@"Temporary"] objectForKey:@"URL"] path] toPath:[panel filename] handler:nil]) {
			[[configuration objectForKey:@"Temporary"] setObject:[panel URL] forKey:@"URL"];
			[self setFileURL:[panel URL]];
	
			// if outside default path, add to knownVNs
			if (![[[qApplication userDefaults] objectForKey:@"knownVMs"] containsObject:[panel filename]]) {
				knownVMs = [[[[qApplication userDefaults] objectForKey:@"knownVMs"] mutableCopy] autorelease];
				[knownVMs addObject:[panel filename]];
				[[qApplication userDefaults] setObject:knownVMs forKey:@"knownVMs"];
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"QVMStatusDidChange" object:nil]; //communicate new state
		} else {
			[self defaultAlertMessage:@"Could not save %@" informativeText:[NSString stringWithFormat:@"There was an error while saving %@", [self displayName],  [self displayName]]];
		}
    }
}

- (IBAction)saveDocumentAs:(id)sender
{
	Q_DEBUG(@"saveDocumentAs");

	if (VMState == QDocumentShutdown || VMState == QDocumentSaved) {	
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"qvm"]];
		[savePanel setCanSelectHiddenExtension:YES];
		[savePanel beginSheetForDirectory:nil file:[self displayName] modalForWindow:[screenView window] modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	} else {
		[self defaultAlertMessage:@"VM is running" informativeText:@"Please shutdown the VM before saving the VM to a new Name"];
	}
}

- (IBAction) saveDocument:(id)sender
{
	Q_DEBUG(@"saveDocument");
	
	// Todo: Document was not yet saved with a proper name, we call a savepanel and move the VM
	if (VMState == QDocumentShutdown || VMState == QDocumentSaved) {
		[self saveDocumentAs:self];

	// if the VM is running, we make a snapshot
	} else if (VMState == QDocumentPaused || VMState == QDocumentRunning) {
		[self setVMState:QDocumentSaving];
		[distributedObject setCommand:'W' arg1:0 arg2:0 arg3:0 arg4:0];
	}
}

- (IBAction)revertDocumentToSaved:(id)sender
{
	Q_DEBUG(@"revertDocumentToSaved");
	
	if (VMState == QDocumentPaused || VMState == QDocumentRunning) {
		[self setVMState:QDocumentLoading];
		[distributedObject setCommand:'X' arg1:0 arg2:0 arg3:0 arg4:0];
	}
}

- (void)docShouldClose:(id)sender
{
	Q_DEBUG(@"docShouldClose: %D", canCloseDocumentClose);

	if (canCloseDocumentContext->shouldCloseSelector) {
		id objc_msgSend(id, SEL, ...);
		void (*callback)(id, SEL, NSDocument *, BOOL, void *) = (void (*)(id, SEL, NSDocument *, BOOL, void *))objc_msgSend;
		(*callback)(canCloseDocumentContext->delegate, canCloseDocumentContext->shouldCloseSelector, self, canCloseDocumentClose, canCloseDocumentContext->contextInfo);
	}
	free(canCloseDocumentContext);
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	Q_DEBUG(@"canCloseDocumentWithDelegate:");

	canCloseDocumentContext = malloc(sizeof(CanCloseDocumentContext));
	canCloseDocumentContext->delegate = delegate;
	canCloseDocumentContext->shouldCloseSelector = shouldCloseSelector;
	canCloseDocumentContext->contextInfo = contextInfo;

	canCloseDocumentClose = TRUE;

	if (VMState == QDocumentPaused || VMState == QDocumentRunning) {
		[self VMShutDown:self];
	} else {
		[self docShouldClose:self];
	}
}



#pragma mark QEMU related
- (void) setVMState:(QDocumentVMState)tVMState
{
	Q_DEBUG(@"setVMState: %D", tVMState);

	// set new state
	VMState = tVMState;

	// take action for this document
	switch (VMState) {
		case QDocumentShutdown:
			[[configuration objectForKey:@"PC Data"] setObject:@"shutdown" forKey:@"state"];
			[[QQvmManager sharedQvmManager] saveVMConfiguration:configuration];
			if ([progressPanel isVisible]) {
				[NSApp endSheet:progressPanel];
				[progressPanel orderOut:self];
				[progressIndicator stopAnimation:self];
			}
			[buttonTogglePause setImage:[NSImage imageNamed:@"q_d_start.png"]];
			[buttonEdit setEnabled:TRUE];
			break;
		case QDocumentSaving:
			if (![progressPanel isVisible]) {
				[progressText setStringValue:@"Saving"];
				[progressIndicator startAnimation:self];
				[NSApp beginSheet:progressPanel 
					modalForWindow:[screenView window]
					modalDelegate:nil
					didEndSelector:nil
					contextInfo:nil];
			}
			break;
		case QDocumentSaved:
			[[configuration objectForKey:@"PC Data"] setObject:@"saved" forKey:@"state"];
			[[QQvmManager sharedQvmManager] saveVMConfiguration:configuration];
			if ([progressPanel isVisible]) {
				[NSApp endSheet:progressPanel];
				[progressPanel orderOut:self];
				[progressIndicator stopAnimation:self];
			}
			[buttonTogglePause setImage:[NSImage imageNamed:@"q_d_start.png"]];
			[buttonEdit setEnabled:FALSE];
			break;
		case QDocumentLoading:
			if (![progressPanel isVisible]) {
				[progressText setStringValue:@"Loading"];
				[progressIndicator startAnimation:self];
				[NSApp beginSheet:progressPanel 
					modalForWindow:[screenView window]
					modalDelegate:nil
					didEndSelector:nil
					contextInfo:nil];
			}
			break;
		case QDocumentPaused:
			[buttonTogglePause setImage:[NSImage imageNamed:@"q_d_start.png"]];
			[buttonEdit setEnabled:FALSE];
			[screenView display];
			break;
		case QDocumentRunning:
			if ([progressPanel isVisible]) {
				[NSApp endSheet:progressPanel];
				[progressPanel orderOut:self];
				[progressIndicator stopAnimation:self];
			}
			[buttonTogglePause setImage:[NSImage imageNamed:@"q_d_pause.png"]];
			[buttonEdit setEnabled:FALSE];
			[screenView display];
			break;
		case QDocumentEditing:
			break;
		case QDocumentInvalid:
			[buttonEdit setEnabled:FALSE];
			[buttonFloppy setEnabled:FALSE];
			[buttonCDROM setEnabled:FALSE];
			[buttonToggleFullscreen setEnabled:FALSE];
			[buttonTakeScreenshot setEnabled:FALSE];
			[buttonCtrlAltDel setEnabled:FALSE];
			[buttonReset setEnabled:FALSE];
			[buttonTogglePause setEnabled:FALSE];
			[buttonTogleStartShutdown setEnabled:FALSE];
			break;
		default:
			break;
	}
	
	//communicate new state
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QVMStatusDidChange" object:nil];

}
- (QDocumentVMState) VMState {return VMState;}

- (void) errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
	Q_DEBUG(@"errorSheetDidEnd");

    [sheet orderOut:self];
}

- (void) defaultAlertMessage:(NSString *)message informativeText:(NSString *)text
{
	Q_DEBUG(@"defaultAlertMessage");

    if (!text)
        text = @"";
    NSLog(@"%@ %@", message, text);
	
	// remove progressPanel
	if ([progressPanel isVisible]) {
		[NSApp endSheet:progressPanel];
		[progressPanel orderOut:self];
		[progressIndicator stopAnimation:self];
	}
	
	// display Alert
    NSBeginAlertSheet(
		message, //errormsg
		nil, //default button
		nil,
		nil,
		[screenView window],
		self,
		@selector(errorSheetDidEnd:returnCode:contextInfo:),
		nil,
		nil,
		text); //informative text
}



#pragma mark edit VM
- (IBAction) VMEdit:(id)sender
{
	Q_DEBUG(@"VMEdit");

	[editVMController showEditVMPanel:self];
}



#pragma mark start/shutdown VM
- (IBAction) VMStart:(id)sender
{
	Q_DEBUG(@"VMStart");

	//set dirty bit, once stated
	[self updateChangeCount:NSChangeDone];
	
    // generate a distributedObject
    if (!distributedObject) // wen don't want a second instance, if we restart a VM
		distributedObject = [[QDocumentDistributedObject alloc] initWithSender:self];
    if (!distributedObject) {
        [self defaultAlertMessage:@"QDocument: could not establisch DO server" informativeText:nil];
        return;
    }

    // start a qemu instance
    qemuTask = [[QDocumentTaskController alloc] initWithFile:[[self fileURL] path] sender:self];
    if (!qemuTask) {
        [self defaultAlertMessage:@"QDocument: could not create a QEMU instance" informativeText:nil];
        return;
    }
}



- (void) shutdownVMSheetDidEnd: (NSAlert *)alert returnCode: (int)returnCode contextInfo: (void *)contextInfo
{
	Q_DEBUG(@"shutdownVMSheetDidEnd %@", (NSDictionary *)contextInfo);

	NSData *data;
	NSBitmapImageRep *bitmapImageRep;
	NSFileManager * fileManager;
	
    [[alert window] orderOut:self];
    
    // saving enabled
    if (VMSupportsSnapshots) {
        if (returnCode == NSAlertDefaultReturn) { // save and shutdown
			[self setVMState:QDocumentSaving];
            [distributedObject setCommand:'Z' arg1:0 arg2:0 arg3:0 arg4:0];
			bitmapImageRep = [NSBitmapImageRep imageRepWithData:[[screenView screenshot:NSMakeSize(0.0, 0.0)] TIFFRepresentation]];
			data =[bitmapImageRep representationUsingType: NSPNGFileType properties: nil];
			fileManager = [NSFileManager defaultManager];
			if(![fileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/QuickLook", [[[configuration objectForKey:@"Temporary"] objectForKey:@"URL"] path]]])
				[fileManager createDirectoryAtPath: [NSString stringWithFormat: @"%@/QuickLook", [[[configuration objectForKey:@"Temporary"] objectForKey:@"URL"] path]] withIntermediateDirectories: NO attributes: nil error: NULL];
			[data writeToFile: [NSString stringWithFormat: @"%@/QuickLook/Thumbnail.png", [[[configuration objectForKey:@"Temporary"] objectForKey:@"URL"] path]] atomically: YES];
			[screenView updateSavedImage:self];
        } else if (returnCode == NSAlertOtherReturn) { // shutdown
			[distributedObject setCommand:'Q' arg1:0 arg2:0 arg3:0 arg4:0];
		} else { //cancel
			canCloseDocumentClose = NO;
			[self docShouldClose:self];
        }

    // saving disabled
    } else {
        if (returnCode == NSAlertDefaultReturn) { // cancel
			canCloseDocumentClose = NO;
			[self docShouldClose:self];
        } else { // shutdown
			[distributedObject setCommand:'Q' arg1:0 arg2:0 arg3:0 arg4:0];
        }
    }
}

- (IBAction) VMShutDown:(id)sender
{
	Q_DEBUG(@"VMShutDown");

    // exit fullscreen
    if ([(QDocumentOpenGLView *)screenView isFullscreen])
        [screenView toggleFullScreen];
	
    if ([(QDocumentOpenGLView *)screenView mouseGrabed])
		[screenView ungrabMouse];

    if (!VMSupportsSnapshots) {
        NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"shutdownPC:text:1", @"Localizable", @"cocoaQemu")
            defaultButton: NSLocalizedStringFromTable(@"shutdownPC:defaultButton:1", @"Localizable", @"cocoaQemu")
            alternateButton: NSLocalizedStringFromTable(@"shutdownPC:alternateButton:1", @"Localizable", @"cocoaQemu")
            otherButton:@""
            informativeTextWithFormat: NSLocalizedStringFromTable(@"shutdownPC:informativeTextWithFormat:1", @"Localizable", @"cocoaQemu")];
        [alert beginSheetModalForWindow:[screenView window]
            modalDelegate:self
            didEndSelector:@selector(shutdownVMSheetDidEnd:returnCode:contextInfo:)
            contextInfo:sender];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"shutdownPC:text:2", @"Localizable", @"cocoaQemu")
            defaultButton: NSLocalizedStringFromTable(@"shutdownPC:defaultButton:2", @"Localizable", @"cocoaQemu")
            alternateButton: NSLocalizedStringFromTable(@"shutdownPC:alternateButton:2", @"Localizable", @"cocoaQemu")
            otherButton: NSLocalizedStringFromTable(@"shutdownPC:otherButton:2", @"Localizable", @"cocoaQemu")
            informativeTextWithFormat: NSLocalizedStringFromTable(@"shutdownPC:informativeTextWithFormat:2", @"Localizable", @"cocoaQemu")];
        [alert beginSheetModalForWindow:[screenView window]
            modalDelegate:self
            didEndSelector:@selector(shutdownVMSheetDidEnd:returnCode:contextInfo:)
            contextInfo:sender];
    }
}

- (IBAction) toggleStartShutdown:(id)sender
{
	Q_DEBUG(@"toggleStartShutdown");

	switch (VMState) {
		case QDocumentShutdown:
		case QDocumentSaved:
			[self VMStart:self];
			break;
		case QDocumentPaused:
		case QDocumentRunning:
			[self VMShutDown:self];
			break;
		default:
			break;
	}
}



#pragma mark reset VM
- (IBAction) VMReset:(id)sender
{
	Q_DEBUG(@"VMReset");

    [distributedObject setCommand:'R' arg1:0 arg2:0 arg3:0 arg4:0];
}



#pragma mark send ctrl-alt-del to VM
- (IBAction) VMCtrlAltDel: (id)sender
{
	Q_DEBUG(@"VMCtrlAltDel");

    // press keys
    [distributedObject setCommand:'K' arg1: 56 & 0x7f arg2:0 arg3:0 arg4:0];
    [distributedObject setCommand:'K' arg1: 29 & 0x7f arg2:0 arg3:0 arg4:0];
    [distributedObject setCommand:'K' arg1:211 & 0x7f arg2:0 arg3:0 arg4:0];

    // release keys
    [distributedObject setCommand:'K' arg1: 56 | 0x80 arg2:0 arg3:0 arg4:0];
    [distributedObject setCommand:'K' arg1: 29 | 0x80 arg2:0 arg3:0 arg4:0];
    [distributedObject setCommand:'K' arg1:211 | 0x80 arg2:0 arg3:0 arg4:0];
}


#pragma mark pause VM
- (void) VMSetPauseWhileInactive:(BOOL)value;
{
	Q_DEBUG(@"setPauseWhileInactive %D", (int)value);

    VMPauseWhileInactive = value;
}

- (IBAction) VMPause:(id)sender
{
	Q_DEBUG(@"pause");
	
	if (VMState == QDocumentRunning) { // only allow a running PC to be paused
		[distributedObject setCommand:'P' arg1:1 arg2:0 arg3:0 arg4:0];
	}
}

- (IBAction) VMUnpause:(id)sender
{
	Q_DEBUG(@"unPause");

	if (VMState == QDocumentPaused) { // only allow a pased PC to be unpaused
		[distributedObject setCommand:'P' arg1:0 arg2:0 arg3:0 arg4:0];
	}
}

- (IBAction) togglePause:(id)sender
{
	Q_DEBUG(@"togglePause");

	switch (VMState) {
		case QDocumentShutdown:
		case QDocumentSaved:
			[self VMStart:self];
			break;
		case QDocumentPaused:
			[self VMUnpause:self];
			break;
		case QDocumentRunning:
			[self VMPause:self];
			break;
		default:
			break;
	}
}
- (BOOL) VMPauseWhileInactive {return VMPauseWhileInactive;}



#pragma mark change drives of VM
- (NSString *) firstCDROMDrive
{
	Q_DEBUG(@"firstCDROMDrive");

    NSString *path = nil;
    io_iterator_t mediaIterator;
    kern_return_t kernResult = KERN_FAILURE; 
    mach_port_t masterPort;
    CFMutableDictionaryRef  classesToMatch;
    io_object_t nextMedia;
    char *bsdPath = '\0';
    CFIndex maxPathSize = 1024;

    // find ejectable media
    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult) {
        NSLog(@"QDocument: firstCDROMDrive: IOMasterPort returned %d", kernResult);
        return nil;
    }
    classesToMatch = IOServiceMatching(kIOCDMediaClass); 
    if (classesToMatch == NULL) {
        NSLog(@"QDocument: firstCDROMDrive: IOServiceMatching returned a NULL dictionary.");
        return nil;
    } else {
        CFDictionarySetValue(classesToMatch, CFSTR(kIOMediaEjectableKey), kCFBooleanTrue);
    }
    kernResult = IOServiceGetMatchingServices( masterPort, classesToMatch, &mediaIterator);
    if (KERN_SUCCESS != kernResult) {
        NSLog(@"QDocument: firstCDROMDrive: IOServiceGetMatchingServices returned %d", kernResult);
        return nil;
    }

    // find path
    nextMedia = IOIteratorNext(mediaIterator);
    if (nextMedia) {
        CFTypeRef   bsdPathAsCFString;
        bsdPathAsCFString = IORegistryEntryCreateCFProperty(nextMedia, CFSTR(kIOBSDNameKey), kCFAllocatorDefault, 0);
        if (bsdPathAsCFString) {
            size_t devPathLength;
            strcpy(bsdPath, _PATH_DEV);
            strcat(bsdPath, "r");
            devPathLength = strlen(bsdPath);
            if (CFStringGetCString(bsdPathAsCFString, bsdPath + devPathLength, maxPathSize - devPathLength, kCFStringEncodingASCII)) {
                if (bsdPath[0] != '\0')
                    path = [NSString stringWithCString:bsdPath];
            }
            CFRelease(bsdPathAsCFString);
        }
        IOObjectRelease(nextMedia);
    }
    IOObjectRelease(mediaIterator);

    return path;
}

- (IBAction) VMUseCdrom: (id)sender
{
	Q_DEBUG(@"VMUseCdrom");

//    [self changeDeviceImage:[@"cdrom" cString] filename:[@"/dev/cdrom" cString] withForce:1];
    [driveFileNames insertObject:[self firstCDROMDrive] atIndex:2];
    [distributedObject setCommand:'D' arg1:2 arg2:0 arg3:0 arg4:0];
}

- (void)changeDeviceSheetDidEnd: (NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(NSString *)contextInfo
{
	Q_DEBUG(@"changeDeviceSheetDidEnd");

    if(returnCode == NSOKButton) {
        [driveFileNames insertObject:[sheet filename] atIndex:[contextInfo intValue]];
        [distributedObject setCommand:'D' arg1:[contextInfo intValue] arg2:0 arg3:0 arg4:0];
    }
}

- (IBAction) VMChangeFda:(id)sender
{
	Q_DEBUG(@"VMChangeFda");

        NSOpenPanel *op = [[NSOpenPanel alloc] init];
        [op setPrompt: NSLocalizedStringFromTable(@"changeFda:prompt", @"Localizable", @"cocoaQemu")];
        [op setMessage: NSLocalizedStringFromTable(@"changeFda:message", @"Localizable", @"cocoaQemu")];
        [op beginSheetForDirectory:nil
        file:nil
        types:fileTypes
        modalForWindow:[screenView window]
        modalDelegate:self
        didEndSelector:@selector(changeDeviceSheetDidEnd:returnCode:contextInfo:)
        contextInfo:[NSNumber numberWithInt:0]];
}

- (IBAction) VMChangeFdb:(id)sender
{
	Q_DEBUG(@"VMChangeFdb");

    NSOpenPanel *op = [[NSOpenPanel alloc] init];
        [op setPrompt: NSLocalizedStringFromTable(@"changeFdb:prompt", @"Localizable", @"cocoaQemu")];
        [op setMessage: NSLocalizedStringFromTable(@"changeFdb:message", @"Localizable", @"cocoaQemu")];
        [op beginSheetForDirectory:nil
        file:nil
        types:fileTypes
        modalForWindow:[screenView window]
        modalDelegate:self
        didEndSelector:@selector(changeDeviceSheetDidEnd:returnCode:contextInfo:)
        contextInfo:[NSNumber numberWithInt:1]];
}

- (IBAction) VMChangeCdrom:(id)sender
{
	Q_DEBUG(@"VMChangeCdrom");

    NSOpenPanel *op = [[NSOpenPanel alloc] init];
        [op setPrompt: NSLocalizedStringFromTable(@"changeCdrom:prompt", @"Localizable", @"cocoaQemu")];
        [op setMessage: NSLocalizedStringFromTable(@"changeCdrom:message", @"Localizable", @"cocoaQemu")];
        [op beginSheetForDirectory:nil
        file:nil
        types:fileTypes
        modalForWindow:[screenView window]
        modalDelegate:self
        didEndSelector:@selector(changeDeviceSheetDidEnd:returnCode:contextInfo:)
        contextInfo:[NSNumber numberWithInt:2]];
}

- (IBAction) VMEjectFda:(id)sender
{
	Q_DEBUG(@"VMEjectFda");

    [distributedObject setCommand:'E' arg1:0 arg2:0 arg3:0 arg4:0];
}

- (IBAction) VMEjectFdb:(id)sender
{
	Q_DEBUG(@"VMEjectFdb");

    [distributedObject setCommand:'E' arg1:1 arg2:0 arg3:0 arg4:0];
}

- (IBAction) VMEjectCdrom:(id)sender
{
	Q_DEBUG(@"VMEjectCdrom");

    [distributedObject setCommand:'E' arg1:2 arg2:0 arg3:0 arg4:0];
}



#pragma mark take screenshot of VM
- (IBAction) takeScreenShot:(id)sender
{
	Q_DEBUG(@"screenshot");

	int i;
    NSBitmapImageRep *bitmapImageRep;
	NSData *data;
	NSFileManager *fileManager;
	
	bitmapImageRep = [NSBitmapImageRep imageRepWithData:[[screenView screenshot:NSMakeSize(0.0, 0.0)] TIFFRepresentation]];
	data =[bitmapImageRep representationUsingType: NSPNGFileType properties: nil];

    // find next free number for name and save it to the desktop
    fileManager = [NSFileManager defaultManager];
    i = 1;
    while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/Q Screenshot %D.png", [@"~/Desktop" stringByExpandingTildeInPath], i]])
        i++;
    [data writeToFile: [NSString stringWithFormat:@"%@/Q Screenshot %D.png", [@"~/Desktop" stringByExpandingTildeInPath], i] atomically: YES];
}



#pragma mark toggle fullscreen of VM
- (IBAction) toggleFullscreen:(id)sender
{
	Q_DEBUG(@"toggleFullscreen");

    [screenView toggleFullScreen];
}



#pragma mark getters
- (QApplicationController *) qApplication { return qApplication;}
- (BOOL) canCloseDocumentClose {return canCloseDocumentClose;}
- (int) uniqueDocumentID {return uniqueDocumentID;}
- (QDocumentDistributedObject *) distributedObject {return distributedObject;}
- (QDocumentTaskController *) qemuTask {return qemuTask;}
- (id) screenView {return screenView;}
- (NSString *) smbPath { return smbPath;}
- (float) cpuUsage {return cpuUsage;}
- (BOOL) ideActivity {return ideActivity;}
- (NSMutableArray *) driveFileNames { return driveFileNames;}
- (BOOL) absolute_enabled {return absolute_enabled;}
- (NSMutableDictionary *) configuration {return configuration;}



#pragma mark setters
- (void) setCpuUsage:(float)tCpuUsage { cpuUsage = tCpuUsage;}
- (void) setIdeActivity:(BOOL)tIdeActivity{ ideActivity = tIdeActivity;}
- (void) setAbsolute_enabled:(BOOL)tAbsloute_enabled {absolute_enabled = tAbsloute_enabled;}
@end
