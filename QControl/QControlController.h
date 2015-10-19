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

#import <Cocoa/Cocoa.h>
/*
#import "cocoaControlDOServer.h"
#import "cocoaControlEditPC.h"
#import "cocoaControlPreferences.h"
#import "cocoaDownloadController.h"
*/
#import "QApplicationController.h"
#import "QControlTableView.h"

@class QWindow;

@interface QControlController : NSObject <NSAnimationDelegate, NSMetadataQueryDelegate>
@property (weak) IBOutlet QControlTableView *table;
@property (weak) IBOutlet NSButton *prefUpdates;
@property (weak) IBOutlet NSButton *prefLog;
@property (weak) IBOutlet NSButton *prefYellow;
@property (weak) IBOutlet NSButton *prefFSWarning;

@property (weak) IBOutlet NSButton *buttonEdit;
@property (weak) IBOutlet NSButton *buttonAdd;

@property (weak) IBOutlet NSProgressIndicator *loadProgressIndicator;
@property (weak) IBOutlet NSTextField *loadProgressText;

/* init & dealloc */
- (instancetype) init;

// IBActions
//- (IBAction) addPC:(id)sender;
- (IBAction) showQControl:(id)sender;
//- (IBAction) addVMFromAssistant:(NSMutableDictionary *)VM;
//- (IBAction) editPC:(id)sender;

- (void) loadConfigurations;
- (void) addVMToKnownVMs:(NSString *)path;
- (void) addVMFromDragDrop:(NSString *)path;

- (void) editVM:(NSMutableDictionary *)VM;
- (void) startVMWithURL:(NSURL *)filename;
- (void) startVM:(NSMutableDictionary *)VM;
- (void) pauseVM:(NSMutableDictionary *)VM;
- (void) unpauseVM:(NSMutableDictionary *)VM;
- (void) stopVM:(NSMutableDictionary *)VM;
- (void) deleteVM:(NSMutableDictionary *)VM;

- (IBAction) togglePreferences:(id)sender;
- (IBAction) prefUpdates:(id)sender;
- (IBAction) prefLog:(id)sender;
- (IBAction) prefYellow:(id)sender;
- (IBAction) prefFSWarning:(id)sender;

/*
- (BOOL) importFreeOSZooPC:(NSString *)name withPath:(NSString *)path;
- (IBAction) importVPC7PC:(id)sender;
- (IBAction) importQemuXPCs:(id)sender;
- (void) updatePC:(id)thisPC;
- (void) updatePCAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)contextInfo;
- (IBAction) updateThisPC:(id)sender;
- (void) exportPCToFlashDrive:(id)pc;
- (IBAction) exportThisPCToFlashDrive:(id)sender;
- (void) importPCFromFlashDrive:(NSString *)filename;
- (IBAction) importThisPCFromFlashDrive:(id)sender;
*/

/*
// editPCPanel
-(BOOL) checkPC:(id)thisPC name:(NSString *)name create:(BOOL)create;

// dIWindow
- (IBAction) openDIWindow:(id)sender;

// freeOSDownloader
- (IBAction)openFreeOSDownloader:(id)sender;
*/
// standardAlert
- (void)standardAlert:(NSString *)messageText informativeText:(NSString *)informativeText;

// getters & setters
@property (readonly, copy) NSMutableArray *VMs;
@property (readonly, unsafe_unretained) IBOutlet QWindow *mainWindow;
@end
