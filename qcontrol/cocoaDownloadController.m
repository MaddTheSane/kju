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
 
#import "cocoaDownloadController.h"
#import "cocoaControlController.h"

#define preferences [NSUserDefaults standardUserDefaults]

@implementation cocoaDownloadController

- (id) init
{
    showsDetails = NO;
    tableEnabled = YES;
    return self;
}

- (void)awakeFromNib
{
    [self showAllDownloads];
    [table setDoubleAction:@selector(startDownload:)];
    [table setDelegate:self];
}

#pragma mark -
#pragma mark Interface Functions

- (void)setupTable
{

}

- (NSWindow*) dLWindow
{  
    return mainDlWindow;
}

- (void) showWindow
{
    [mainDlWindow makeKeyAndOrderFront:self];
    // if the download-manager is accessed for the 1st time
    // show the welcome panel
    /* CRASHES with: "modal session requires modal window" !
    if(![preferences objectForKey:@"freeOSZooWelcomeShowed"]) {
        [NSApp beginModalSessionForWindow:mainDlWindow];
        [NSApp beginSheet:welcomePanel modalForWindow:mainDlWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
        [preferences setObject:[NSNumber numberWithBool:YES] forKey:@"freeOSZooWelcomeShowed"];
    }
    */
}

- (BOOL) returnShowsDetails
{
    return showsDetails;
}

- (void) resizeSmall
{
    NSRect windowFrame;
	NSRect newWindowFrame;

	windowFrame = [mainDlWindow frame];
	newWindowFrame = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y + [detailsNSView bounds].size.height, windowFrame.size.width, windowFrame.size.height - [detailsNSView bounds].size.height);

    if ([detailsNSView superview]) {
        [detailsNSView retain];
        [detailsNSView removeFromSuperview];
    }
	[mainDlWindow setFrame:newWindowFrame display:YES animate:YES];
	showsDetails = NO;
}

- (void) resizeBig
{
    NSRect windowFrame;
	NSRect newWindowFrame;

	windowFrame = [mainDlWindow frame];
	newWindowFrame = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y - [detailsNSView bounds].size.height,	windowFrame.size.width, [detailsNSView bounds].size.height + windowFrame.size.height);
    
    [mainDlWindow setFrame:newWindowFrame display:YES animate:YES];
    [[mainDlWindow contentView] addSubview:detailsNSView];
	showsDetails = YES;
}

- (void) showAllDownloads
{
    // load downloadLists
    // save an original of the list so we dont have to load it again
    if(downloadOriginalList == nil) {
        // first call in the class
        downloadOriginalList = [[[NSMutableArray alloc] init] retain];
        downloadList = [[[NSMutableArray alloc] init] retain];
        
        NSArray * HTTPList = [self getHTTPList];
        NSArray * BTList = [self getBTList];
        int i;
    
        // merge HTTP&BTList
        if(HTTPList != nil) {
            for(i=0; i<=[HTTPList count]-1; i++) {
                // add HTTPList
                [downloadList addObject:[HTTPList objectAtIndex:i]];
            }
        }
    
        if(BTList != nil) {
            for(i=0; i<=[BTList count]-1; i++) {
                // add BTList
                [downloadList addObject:[BTList objectAtIndex:i]];
            }
        }
        [downloadOriginalList addObjectsFromArray:downloadList];
    } else {
        // when we call it later we only need the original list
        [downloadList removeAllObjects];
        [downloadList addObjectsFromArray:downloadOriginalList];
    }
    // force table reload
    [table reloadData];
    // force showDetails update
    if([self returnShowsDetails]) [self showDetails:[table selectedRow]];
}

- (IBAction) showDownloadsByType:(id)sender
{
    // method for the popupbutton to select os type
    if([[osTypeSelect titleOfSelectedItem] isEqualToString:@"All"]) {
        [self showAllDownloads];
    } else {
        // be sure that we have the original downloadList here
        [downloadList removeAllObjects];
        [downloadList addObjectsFromArray:downloadOriginalList];
        int i;
        NSMutableArray * array = [NSMutableArray arrayWithCapacity:1];
        for (i=0; i<=[downloadList count]-1; i++) {
            // search for ostype and add equalling entries
            if ([[[downloadList objectAtIndex:i] valueForKey:@"ostype"] isEqualTo:[osTypeSelect titleOfSelectedItem]]) {
                [array addObject:[downloadList objectAtIndex:i]];
            }
        }
        
        // write os by found criteria into downloadList
        [downloadList removeAllObjects];
        [downloadList addObjectsFromArray:array];
        
        // force table reload
        [table reloadData];
        // force showDetails update
        if([self returnShowsDetails]) [self showDetails:[table selectedRow]];
    }
}

- (void) disableTableView:(BOOL)disable
{
    NSEnumerator * ec = [[table tableColumns] objectEnumerator];
    NSTableColumn * curColumn;
    NSColor * textColor = nil; 
    NSColor * backgroundColor = nil;
    
    if(disable) {
        textColor = [NSColor colorWithCalibratedWhite:0.50 alpha:1.0];
        backgroundColor = [NSColor colorWithCalibratedWhite:0.94 alpha:1.0];
        tableEnabled = NO;
    } else {
        textColor = [NSColor blackColor];
        backgroundColor = [NSColor colorWithCalibratedWhite:0.94 alpha:1.0];
        tableEnabled = YES;
    }
    
    while ((curColumn = [ec nextObject])) {
        if([[curColumn dataCell] isKindOfClass:[NSTextFieldCell class]]) {
                [[curColumn dataCell] setTextColor:textColor];
                [[curColumn dataCell] setBackgroundColor:backgroundColor];
        }
    }
    
    if([[table enclosingScrollView] hasVerticalScroller])
        [[[table enclosingScrollView] verticalScroller] setEnabled:!disable];

    //if([[table enclosingScrollView] hasHorizontalScroller])
        //[[[table enclosingScrollView] horizontalScroller] setEnabled:(bEnable && saveHorizontalScrollerEnabled)];
}

#pragma mark Table Delegate Methods needed for the disableTableView method

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
    return tableEnabled;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return tableEnabled;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
    return tableEnabled;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn
{
    return tableEnabled;
}

#pragma mark main table Delegate Methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [downloadList count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{	
	id thisDownload;
	thisDownload = [downloadList objectAtIndex:row];
	
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
	   // return name and version 
	   NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@ %@\n", [thisDownload objectForKey:@"name"], [thisDownload objectForKey:@"version"]] attributes:[NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName]] autorelease];
	   [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@, %@. Download Size: %@ MB\nprovided by %@.", [thisDownload objectForKey:@"ostype"], [thisDownload objectForKey:@"installtype"], [thisDownload objectForKey:@"size"], [thisDownload objectForKey:@"author"]] attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
	   
		return attrString;
	} else {
		return @"";
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	// TODO: implement window size change for the first selection
	if([table selectedRow] != -1) {
        if(![self returnShowsDetails]) {
            [self resizeBig];
        }
        [self showDetails:[table selectedRow]];
    } else {
        // reset OS details and make window small
        [detailsTextView setString:@""];
        if([self returnShowsDetails]) [self resizeSmall];
    }
}

#pragma mark -
#pragma mark Data Functions

- (NSArray *)getHTTPList
{
    // TODO: change to arrayWithContentsOfURL: url
    NSArray * HTTPList = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:@"http://cordney.com/q/freeoszoo.plist"]];
    return HTTPList;
}

- (NSArray *)getBTList
{
    // TODO: change to arrayWithContentsOfURL: url
    return nil;
}

- (void) showDetails:(int)row
{
    showsDetails = YES;
    // clear textView
    [detailsTextView setString:@""];
    NSDictionary * details = [[NSDictionary alloc] initWithDictionary:[downloadList objectAtIndex:row]];
    // load logo
    /*NSImage * logo = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[details valueForKey:@"logo"]]];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    if ([(NSCell *)[attachment attachmentCell] respondsToSelector:@selector(setImage:)]) {
        [(NSCell *)[attachment attachmentCell] setImage:logo];
    }*/
        
    // create logo
    //NSAttributedString * detailsLogo = [NSAttributedString attributedStringWithAttachment:attachment];
    
    // create name and version
    NSDictionary * nameAttr = [NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName];
    NSAttributedString * detailsName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [details objectForKey:@"name"], [details objectForKey:@"version"]] attributes:nameAttr];
    NSAttributedString * detailsDesc = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", [details objectForKey:@"description"]]];
    NSAttributedString * detailsURLpre = [[NSAttributedString alloc] initWithString:@"\nWeb: "];
    NSAttributedString * detailsURL = [[NSAttributedString alloc] initWithString:[details objectForKey:@"weburl"] attributes:[NSDictionary dictionaryWithObject:[details objectForKey:@"weburl"] forKey:NSLinkAttributeName]];
    // create spacer
    NSAttributedString * spacer = [[NSAttributedString alloc] initWithString:@"\n"];
    
    // append strings to textView
    [[detailsTextView textStorage] appendAttributedString:spacer];
    //[[detailsTextView textStorage] appendAttributedString:detailsLogo];
    [[detailsTextView textStorage] appendAttributedString:detailsName];
    [[detailsTextView textStorage] appendAttributedString:spacer];
    [[detailsTextView textStorage] appendAttributedString:detailsDesc];
    [[detailsTextView textStorage] appendAttributedString:spacer];
    [[detailsTextView textStorage] appendAttributedString:detailsURLpre];
    [[detailsTextView textStorage] appendAttributedString:detailsURL];

    
    // release objects
    //[logo release];
    //[attachment release];
    [detailsName release];
    [detailsDesc release];
    [detailsURLpre release];
    [detailsURL release];
    [spacer release];
    [details release];
}

- (IBAction)startDownload:(id)sender
{
    if ([table selectedRow] != -1) {
        id thisDownload = [downloadList objectAtIndex:[table selectedRow]];
        
        // 1. init download object, set values
        // TODO: distinguish between HTTP&BT, url pathExtension?
        if([thisDownload valueForKey:@"torrent"] == [NSNumber numberWithInt:1]) {
            download = [[[cocoaDownload alloc] initWithBT] retain];
        } else {
            download = [[[cocoaDownload alloc] initWithHTTP] retain];
        }
        if([[thisDownload objectForKey:@"version"] isEqualToString:@""]) {
            [download setName:[thisDownload objectForKey:@"name"]];
        } else {
            [download setName:[NSString stringWithFormat:@"%@ %@", [thisDownload objectForKey:@"name"], [thisDownload objectForKey:@"version"]]];
        }
        [download setURL:[thisDownload objectForKey:@"url"]];
        // - monitor the download object with NSNotifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidReceiveResponse:) name:@"DownloadDidReceiveResponse" object:download];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startStatusTimer:) name:@"DownloadDidReceiveData" object:download];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidFinish:) name:@"DownloadDidFinish" object:download];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidFail:) name:@"DownloadDidFail" object:download];
						
        [download startDownload];
        
        // 2. set to downloading mode
        [self disableTableView:YES];
        [table setDoubleAction:nil];
        [downloadButton setTitle:@"Stop"];
        [downloadButton setAction:@selector(stopDownload:)];
        [self resizeSmall];
        
        [statusText setStringValue:@"Starting download..."];
        [statusBar setDoubleValue:0.0];
        [statusText setHidden:NO];
        [statusBar setHidden:NO];
        [statusBar setIndeterminate:YES];
        [statusBar startAnimation:self];
    }
}

- (IBAction)stopDownload:(id)sender
{
    NSBeginAlertSheet(@"You have active downloads running.",@"Stop",@"Cancel",nil,mainDlWindow,self,@selector(stopDownloadSheetDidEnd:returnCode:contextInfo:),nil,nil,@"Are you sure you want to stop downloading?");
}

- (void)stopDownloadSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	if ( returnCode == NSAlertDefaultReturn ) {
		// Stop download and delete files
		[download stopDownload];
        [statusText setStringValue:@"Download cancelled."];
        [self cleanupDownload:[[download getSavePath] stringByDeletingLastPathComponent]];
        [[NSFileManager defaultManager] removeFileAtPath:[[download getSavePath] stringByDeletingLastPathComponent] handler:nil];
        [download release];
	}
}

#pragma mark -
#pragma mark Download Notification Functions

- (void) downloadDidReceiveResponse:(NSNotification *)aNotification
{
    [statusText setStringValue:@"Download started..."];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidReceiveResponse" object:download];
    // do we need to do more here ?
}

- (void) startStatusTimer:(NSNotification *)aNotification
{
    // start the timer to update the text progress every 1sec
    statusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressText:) userInfo:nil repeats:YES];
    
    // change receivedData notification to downloadDidReceiveData
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidReceiveData" object:download];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidReceiveData:) name:@"DownloadDidReceiveData" object:download];
}

// Update the progressBar whenever data was received to have
// a smooth progress view
- (void) downloadDidReceiveData:(NSNotification *)aNotification
{
    float expectedData = [download getExpectedData];
    float receivedData = [download getReceivedData];
    
    if([statusBar maxValue] == 100.0)
        [statusBar setMaxValue:(double)expectedData];
    [statusBar setDoubleValue:(double)receivedData];
}

// Update the progress text only every 1sec
- (void) updateProgressText:(NSTimer *)theTimer
{
    int lastRCVData = [download getLastReceivedData];
    float expectedData = [download getExpectedData];
    float receivedData = [download getReceivedData];
    
    float expectedKB = expectedData/1024;
    float expectedMB = expectedKB/1024;
    float receivedKB = receivedData/1024;
    float receivedMB = receivedKB/1024;
    
    float expectedD = expectedKB;
    float receivedD = receivedKB;
    NSString * dSize = @"kB";
    NSString * tDSize = @"kB";
    
    if(expectedKB >= 1024) {
        expectedD = expectedMB;
        tDSize = @"MB";
    }
    if(receivedKB >= 1024) {
        receivedD = receivedMB;
        dSize = @"MB";
    }
    
    int time_rsec = (expectedData-receivedData)/lastRCVData;
    int time_rmin = time_rsec / 60;
    int time_rhour = time_rsec / 60 / 60;
    int time_rlmin = time_rmin - time_rhour*60;
    int time_rlsec = time_rsec - time_rlmin*60 - time_rhour*60*60;
    
    NSString * remainingString;
    
    if(time_rhour >= 1) {
        remainingString = [NSString stringWithFormat:@"%d hours %d minutes remaining", time_rhour, time_rlmin, time_rlsec];
    } else if(time_rmin >= 1 && time_rmin < 10) {
        remainingString = [NSString stringWithFormat:@"%d minutes %d seconds remaining", time_rmin, time_rlsec];
    } else if(time_rmin >=1) {
        remainingString = [NSString stringWithFormat:@"about %d minutes remaining", time_rmin];
    } else {
        remainingString = [NSString stringWithFormat:@"about %d seconds remaining", time_rsec];
    }
    
    if(receivedKB < 10.0) {
        [statusText setStringValue:@"Connecting.."];
    } else {
        if([statusBar isIndeterminate])
            [statusBar setIndeterminate:NO];
        if(receivedKB <= 1024) {
            [statusText setStringValue:[NSString stringWithFormat:@"%.0f %@ of %.1f %@ (%d kB/s), %@", receivedD, dSize, expectedD, tDSize, lastRCVData/1024, remainingString]];
        } else {
            [statusText setStringValue:[NSString stringWithFormat:@"%.1f %@ of %.1f %@ (%d kB/s), %@", receivedD, dSize, expectedD, tDSize, lastRCVData/1024, remainingString]];
        }
    }
}

- (void) downloadDidFinish:(NSNotification *)aNotification
{
    [statusText setStringValue:@"Download finished."];
    [downloadButton setAction:nil];
    
    // call some File Manipulation Functions here
    // e.g. uncompress, move, ...
    [download stopDownload];
    [self cleanupDownload:[[download getSavePath] stringByDeletingLastPathComponent]];
    [self uncompressPC:[download getSavePath]];
}

- (void) downloadDidFail:(NSNotification *)aNotification
{

    // TODO: alert sheet
    NSLog(@"Download did fail: %@", [[aNotification userInfo] objectForKey:@"ERROR_DESCRIPTION"]);
    
    // reset UI
    [statusText setStringValue:@"Download failed."];
    [self cleanupDownload:[[download getSavePath] stringByDeletingLastPathComponent]];
    [download release];
}

- (void) cleanupDownload:(NSString *)path
{    
    if(statusTimer) {
        [statusTimer invalidate];
    }
    
    [statusBar stopAnimation:self];
    [statusBar setIndeterminate:NO];
    [statusBar setDoubleValue:0.0];
    [statusBar setMaxValue:100.0];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidReceiveResponse" object:download];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidReceiveData" object:download];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidFinish" object:download];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidFail" object:download];
    
    [table setDoubleAction:@selector(startDownload:)];
    [downloadButton setTitle:@"Download"];
    [downloadButton setAction:@selector(startDownload:)];
    // enable tableview
    [self disableTableView:NO];
}

#pragma mark -
#pragma mark File Manipulation Functions

- (void)uncompressPC:(NSString *)path
{
    [statusText setStringValue:@"Extracting files.."];
    [statusBar setIndeterminate:YES];
    [statusBar startAnimation:self];
    NSTask * task = [[NSTask alloc] init];
    BOOL isArchive = NO;
    if([[path pathExtension] isEqualTo:@"tar"] || [[path pathExtension] isEqualTo:@"bz"] || [[path pathExtension] isEqualTo:@"bz2"] || [[path pathExtension] isEqualTo:@"gz"]) {
        [task setLaunchPath:@"/usr/bin/tar"];
        [task setArguments:[NSArray arrayWithObjects:@"-xf", path, nil]];
        isArchive = YES;
    } else if([[path pathExtension] isEqualTo:@"zip"]) {
        [task setLaunchPath:@"/usr/bin/unzip"];
        [task setArguments:[NSArray arrayWithObjects:path, nil]];
        isArchive = YES;
    }

    if(isArchive) {
	   [task setCurrentDirectoryPath:[path stringByDeletingLastPathComponent]];
	
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uncompressPCFinished:) name:NSTaskDidTerminateNotification object:task];
        [task launch];
    } else {
        NSLog(@"Could not detect file format. No archive?");
    }
}

- (void)uncompressPCFinished:(NSNotification *)aNotification
{
    cocoaControlController * controller = [[cocoaControlController alloc] init];
    NSString * path = [download getSavePath];
    NSString * name = [download getName];
    NSFileManager * manager = [NSFileManager defaultManager];
    [statusText setStringValue:@"Extracting files complete."];
    [manager removeFileAtPath:path handler:nil];
    
    NSString * message;
    // start import into Q
    [statusText setStringValue:@"Importing Free OS.."];
    if([controller importFreeOSZooPC:name withPath:[path stringByDeletingLastPathComponent]]) {
        message = @"You can now start using your Free OS.";
    } else {
        message = @"The harddisk could not be found. Please check the settings before using your Free OS.";
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Import finished"
		defaultButton:@"OK"
		alternateButton:nil
		otherButton:nil
		informativeTextWithFormat:message];

	   [alert beginSheetModalForWindow:mainDlWindow
		modalDelegate:self
		didEndSelector:nil
		contextInfo:nil];
    
    [statusText setStringValue:@"Finished."];
    [statusBar setMaxValue:100.0];
    [statusBar setDoubleValue:0.0];
    [statusBar setIndeterminate:NO];
    [downloadButton setAction:@selector(startDownload:)];
    [download release];
}

@end