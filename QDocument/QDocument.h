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


#import <Cocoa/Cocoa.h>

#import "../QApplication/QApplicationController.h"
#import "QDocumentWindowController.h"
#import "QDocumentDistributedObject.h"
#import "QDocumentTaskController.h"
#import "QDocumentEditVMController.h"

@class QDocumentOpenGLView;

typedef NS_ENUM(NSInteger, QDocumentVMState) {
   QDocumentShutdown = 0,
   QDocumentSaving = 1,
   QDocumentSaved = 2,
   QDocumentLoading = 3,
   QDocumentPaused = 4,
   QDocumentRunning = 5,
   QDocumentEditing = 6,
   QDocumentInvalid = 7
};

typedef struct {
	id delegate __unsafe_unretained;
	SEL shouldCloseSelector;
	void *contextInfo;
} CanCloseDocumentContext;

@interface QDocument : NSDocument
{
    QApplicationController *__unsafe_unretained qApplication;
    QDocumentWindowController *windowController;
    QDocumentDistributedObject *distributedObject;
    QDocumentTaskController *qemuTask;
    QDocumentOpenGLView *screenView;
    int uniqueDocumentID;
    
    // QEMU state
    NSMutableDictionary *configuration;
	QDocumentVMState VMState;
    BOOL VMPauseWhileInactive;
    BOOL VMPausedByUser;
    NSString *smbPath;
    float cpuUsage;
    BOOL ideActivity;
    NSMutableArray *driveFileNames;
    BOOL absolute_enabled;
    BOOL VMSupportsSnapshots;
	
	IBOutlet NSButton *buttonEdit;
	IBOutlet NSButton *buttonFloppy;
	IBOutlet NSButton *buttonCDROM;
	IBOutlet NSButton *buttonToggleFullscreen;
	IBOutlet NSButton *buttonTakeScreenshot;
	IBOutlet NSButton *buttonCtrlAltDel;
	IBOutlet NSButton *buttonReset;
	IBOutlet NSButton *buttonTogglePause;
	IBOutlet NSButton *buttonTogleStartShutdown;
	
	//Progress panel
	IBOutlet NSPanel *progressPanel;
	IBOutlet NSTextField *progressText;
	IBOutlet NSProgressIndicator *progressIndicator;
	
	//Edit VM panel
	QDocumentEditVMController *editVMController;

    NSArray<NSString*> *fileTypes;
	
	// overriding "canCloseDocumentWithDelegate"
	// http://lists.apple.com/archives/cocoa-dev/2001/Nov/msg00940.html
	BOOL canCloseDocumentClose;
	CanCloseDocumentContext *canCloseDocumentContext;
}
// "canCloseDocumentWithDelegate" callback
- (void)docShouldClose:(id)sender;

// save configuration.plist
- (void) errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo;
- (void) defaultAlertMessage:(NSString *)message informativeText:(NSString *)text;

// edit
- (IBAction) VMEdit:(id)sender;

// start/shutdown VM
- (IBAction) VMStart:(id)sender;
- (void) shutdownVMSheetDidEnd: (NSAlert *)alert returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (IBAction) VMShutDown:(id)sender;
- (IBAction) toggleStartShutdown:(id)sender;

// reset VM
- (IBAction) VMReset:(id)sender;

// send ctrl-alt-del to VM
- (IBAction) VMCtrlAltDel: (id)sender;

// pause VM
- (void) VMSetPauseWhileInactive:(BOOL)value;
- (IBAction) VMPause:(id)sender;
- (IBAction) VMUnpause:(id)sender;
@property (readonly) BOOL VMPauseWhileInactive;
- (IBAction) togglePause:(id)sender;

// change drives of VM
@property (readonly, copy) NSString *firstCDROMDrive;
- (IBAction) VMUseCdrom:(id)sender;
- (void)changeDeviceSheetDidEnd: (NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(NSString *)contextInfo;
- (IBAction) VMChangeFda:(id)sender;
- (IBAction) VMChangeFdb:(id)sender;
- (IBAction) VMChangeCdrom:(id)sender;
- (IBAction) VMEjectFda:(id)sender;
- (IBAction) VMEjectFdb:(id)sender;
- (IBAction) VMEjectCdrom:(id)sender;

// take screenshot of VM
- (IBAction) takeScreenShot: (id)sender;

// toggle fullscreen of VM
- (IBAction) toggleFullscreen:(id)sender;

// getters/setters
@property (readonly, unsafe_unretained) QApplicationController *qApplication;
@property (readonly) BOOL canCloseDocumentClose;
@property (readonly) int uniqueDocumentID;
@property (readonly, strong) QDocumentDistributedObject *distributedObject;
@property (readonly, strong) QDocumentTaskController *qemuTask;
@property (readonly, strong) QDocumentOpenGLView* screenView;
@property (nonatomic) QDocumentVMState VMState;
@property (readonly, copy) NSString *smbPath;
@property float cpuUsage;
@property BOOL ideActivity;
@property (readonly, copy) NSArray<NSString*> *driveFileNames;
@property BOOL absolute_enabled;
@property (readonly, copy) NSMutableDictionary *configuration;

@end
