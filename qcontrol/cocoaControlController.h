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

#import <Cocoa/Cocoa.h>

#import "cocoaControlDOServer.h"
#import "cocoaControlEditPC.h"
#import "cocoaControlPreferences.h"
#import "cocoaDownloadController.h"
#import "QControlTableView.h"

#define FILE_TYPES [NSArray arrayWithObjects:@"qcow2", @"qcow", @"raw", @"cow", @"vmdk", @"cloop", @"img", @"iso", @"dsk", @"dmg", @"cdr", @"toast", @"flp", @"fs", nil]

@interface cocoaControlController : NSObject
{
	/* preferences */
	NSUserDefaults *userDefaults;
	
	/* distributed object server */
	cocoaControlDOServer *qdoserver;
	
	/* mainMenu */
	IBOutlet id windowMenu;
	
	/* controlWindow */
	NSMutableArray *pcs;
	NSMutableArray *pcsImages;
	NSMutableArray *pcsWindows;
	NSDictionary *cpuTypes;
	NSMutableDictionary *pcsTasks;
	NSMutableDictionary *pcsPIDs;
	NSString *dataPath;
	IBOutlet id mainWindow;
	IBOutlet QControlTableView *table;
	
	NSTimer *timer;	 //to update Table Thumbnails
	
	/* progressPanel */
	IBOutlet id progressPanel;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextField *progressTitle;
	IBOutlet NSTextField *progressText;
	IBOutlet NSTextField *progressStatusText;
	
	/* editPCPanel */
	cocoaControlEditPC *editPC;
	
	/* preferences */
	cocoaControlPreferences *preferences;
	
	/* FreeOSDownloader */
	cocoaDownloadController *downloader;
	
	/* newImage */
	
}
/* init & dealloc */
- (id) init;

/* mainMenu */
- (IBAction)showPreferences:(id)sender;

/* getter & setter */
- (id)pcs;
- (id)pcsTasks;

/* controlWindow */
- (id) mainWindow;
- (IBAction) cycleWindows:(id)sender;
- (IBAction) cycleWindowsBack:(id)sender;
- (IBAction) activateApp:(id)sender;
- (void) loadConfigurations;
- (void) savePCConfiguration:(id)thisPC;
- (void) updateThumbnails;
- (IBAction) addPC:(id)sender;
- (void) addPCFromDragDrop:(NSString *)path;
- (IBAction) addPCFromAssistant:(NSMutableDictionary *)thisPC;
- (void) deleteThisPC:(id)pc;
- (IBAction) deletePC:(id)sender;
- (void) editThisPC:(id)pc;
- (IBAction) editPC:(id)sender;
- (BOOL) importFreeOSZooPC:(NSString *)name withPath:(NSString *)path;
- (IBAction) importVPC7PC:(id)sender;
- (IBAction) importQemuXPCs:(id)sender;
- (void) exportPCToFlashDrive:(id)pc;
- (IBAction) exportThisPCToFlashDrive:(id)sender;
- (void) importPCFromFlashDrive:(NSString *)filename;
- (IBAction) importThisPCFromFlashDrive:(id)sender;
- (void) startThisPC:(id)pc;
- (void) startPC:(NSString *)filename;
- (void) tableDoubleClick:(id)sender;
- (void) pauseThisPC:(id)pc;
- (void) playThisPC:(id)pc;
- (void) stopThisPC:(id)pc;

/* editPCPanel */
-(BOOL) checkPC:(id)thisPC name:(NSString *)name create:(BOOL)create;

/* dIWindow */
- (IBAction) openDIWindow:(id)sender;

/* freeOSDownloader */
- (IBAction)openFreeOSDownloader:(id)sender;

/* standardAlert */
- (void)standardAlert:(NSString *)messageText informativeText:(NSString *)informativeText;

/* check for update */
- (void)getLatestVersion;
- (void)updateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end
