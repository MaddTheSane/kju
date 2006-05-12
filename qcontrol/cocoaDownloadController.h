/*
 * QEMU Cocoa Control Download Controller
 * 
 * Copyright (c) 2006 René Korthaus
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
#import "cocoaDownload.h"

@interface cocoaDownloadController : NSObject
{
    IBOutlet id table;
    IBOutlet id mainDlWindow;
    IBOutlet id welcomePanel;
    IBOutlet id detailsTextView;
    IBOutlet id downloadButton;
    IBOutlet id statusText;
    IBOutlet id statusBar;
    IBOutlet id osTypeSelect;
    
    IBOutlet id detailsNSView;    
    
    // download object
    cocoaDownload * download;
    NSTimer * statusTimer;
}

NSMutableArray * downloadList;
NSMutableArray * downloadOriginalList;


BOOL showsDetails;
BOOL tableEnabled;

// interface functions
- (void) setupTable; // table setup functions
- (NSWindow*) dLWindow;
- (void) showWindow;
- (BOOL) returnShowsDetails; // returns whether the window shows details
- (void) resizeSmall; // show detailsTextView
- (void) resizeBig; // show detailsTextView
- (void) showAllDownloads;
- (IBAction) showDownloadsByType:(id)sender;
- (void) showDetails:(int)row; // show details of selected free os
- (void) disableTableView:(BOOL)disable;

// Table Delegate Methods needed for the disableTableView method
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex;
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn;

// data functions
- (NSArray *) getHTTPList; // get list of HTTP Downloads
- (NSArray *) getBTList; // get list of Bittorrent Downloads

- (IBAction) startDownload:(id)sender;
- (IBAction) stopDownload:(id)sender;
- (void) cleanupDownload:(NSString *)path;

// file manipulation functions
- (void)uncompressPC:(NSString *)path;

@end
