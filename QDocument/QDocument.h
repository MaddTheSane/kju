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

#import "QDocumentWindowController.h"
#import "QDocumentDistributedObject.h"
#import "QDocumentTaskController.h"
#import "QDocumentEditVMController.h"

NS_ASSUME_NONNULL_BEGIN

@class QDocumentOpenGLView;
@class QApplicationController;

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

@property (weak) IBOutlet NSButton *buttonEdit;
@property (weak) IBOutlet NSButton *buttonFloppy;
@property (weak) IBOutlet NSButton *buttonCDROM;
@property (weak) IBOutlet NSButton *buttonToggleFullscreen;
@property (weak) IBOutlet NSButton *buttonTakeScreenshot;
@property (weak) IBOutlet NSButton *buttonCtrlAltDel;
@property (weak) IBOutlet NSButton *buttonReset;
@property (weak) IBOutlet NSButton *buttonTogglePause;
@property (weak) IBOutlet NSButton *buttonTogleStartShutdown;

//Progress panel
@property (weak) IBOutlet NSPanel *progressPanel;
@property (weak) IBOutlet NSTextField *progressText;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

// "canCloseDocumentWithDelegate" callback
- (void)docShouldClose:(id)sender;

// save configuration.plist
- (void) errorSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(nullable id)contextInfo;
- (void) defaultAlertMessage:(NSString *)message informativeText:(nullable NSString *)text;

// edit
- (IBAction) VMEdit:(nullable id)sender;

// start/shutdown VM
- (IBAction) VMStart:(nullable id)sender;
- (void) shutdownVMSheetDidEnd: (NSAlert *)alert returnCode: (NSInteger)returnCode contextInfo: (nullable void *)contextInfo;
- (IBAction) VMShutDown:(nullable id)sender;
- (IBAction) toggleStartShutdown:(nullable id)sender;

// reset VM
- (IBAction) VMReset:(nullable id)sender;

// send ctrl-alt-del to VM
- (IBAction) VMCtrlAltDel: (nullable id)sender;

// pause VM
- (IBAction) VMPause:(nullable id)sender;
- (IBAction) VMUnpause:(nullable id)sender;
@property (nonatomic, setter=VMSetPauseWhileInactive:) BOOL VMPauseWhileInactive;
- (IBAction) togglePause:(nullable id)sender;

// change drives of VM
@property (readonly, copy, nullable) NSString *firstCDROMDrive;
- (IBAction) VMUseCdrom:(nullable id)sender;
- (IBAction) VMChangeFda:(nullable id)sender;
- (IBAction) VMChangeFdb:(nullable id)sender;
- (IBAction) VMChangeCdrom:(nullable id)sender;
- (IBAction) VMEjectFda:(nullable id)sender;
- (IBAction) VMEjectFdb:(nullable id)sender;
- (IBAction) VMEjectCdrom:(nullable id)sender;

// take screenshot of VM
- (IBAction) takeScreenShot: (nullable id)sender;

// toggle fullscreen of VM
- (IBAction) toggleFullscreen:(nullable id)sender;

// getters/setters
@property (readonly, weak) QApplicationController *qApplication;
@property (readonly) BOOL canCloseDocumentClose;
@property (readonly) int uniqueDocumentID;
@property (readonly, strong) QDocumentDistributedObject *distributedObject;
@property (readonly, strong) QDocumentTaskController *qemuTask;
@property (readonly, strong) QDocumentOpenGLView* screenView;
@property (nonatomic) QDocumentVMState VMState;
@property (readonly, copy, nullable) NSString *smbPath;
@property float cpuUsage;
@property BOOL ideActivity;
@property (readonly, copy) NSArray<NSString*> *driveFileNames;
@property BOOL absolute_enabled;
@property (readonly, copy) NSMutableDictionary *configuration;

@end

NS_ASSUME_NONNULL_END
