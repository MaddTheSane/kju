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
    self = [super init];
    return self;
}

- (id) initWithSender:(id)sender
{
    [sender retain];
    controller = sender;
    showsDetails = NO;
    tableEnabled = YES;
    
    return self;
}

- (void)awakeFromNib
{
    [self initDownloadInterface];
}

#pragma mark -
#pragma mark Interface Functions

- (void) initDownloadInterface
{
    [table setDoubleAction:@selector(startDownload:)];
    [self showWindow];
    
    [NSThread detachNewThreadSelector:@selector(showAllDownloads) toTarget:self withObject:nil];
    //[self showAllDownloads];
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // load downloadLists
    // save an original of the list so we dont have to load it again
    if(downloadOriginalList == nil || [downloadOriginalList count] == 0) {
        // first call in the class || call again when initially list not loaded
        if(downloadOriginalList == nil) {
            downloadOriginalList = [[[NSMutableArray alloc] init] retain];
            downloadList = [[[NSMutableArray alloc] init] retain];
        }
        
        [statusText setStringValue: NSLocalizedStringFromTable(@"showAllDownloads:statusText", @"Localizable", @"cocoaDownloadController")];
        [statusBar setDoubleValue:0.0];
        [statusText setHidden:NO];
        [statusBar setHidden:NO];
        [statusBar setIndeterminate:YES];
        [statusBar startAnimation:self];
    
        NSArray * dlList = [self getDownloadListFromServer];
        
        BOOL serverUp = [self checkFreeOSZooIsUp];
        
        [statusText setStringValue: NSLocalizedStringFromTable(@"showAllDownloads:statusText2", @"Localizable", @"cocoaDownloadController")];
        [statusBar setDoubleValue:0.0];
        //[statusText setHidden:YES];
        //[statusBar setHidden:YES];
        [statusBar setIndeterminate:NO];
        [statusBar stopAnimation:self];
    
        // copy downloadList
        if(dlList != nil) {
            // check if freeoszoo is up, else only add the kju-app guests
            if(serverUp) {
                [downloadList addObjectsFromArray:dlList];
            } else {
            int i;
                for (i=0; i < [dlList count]; i++) {
                    if([[dlList objectAtIndex:i] valueForKey:@"Kju"] == [NSNumber numberWithInt:1])
                        [downloadList addObject: [dlList objectAtIndex:i]];
                }
            }
            [self prepareOSTypeSelector];
            [self showWindow];
        } else {
            // download list is nil, spawn error message
            //NSLog(@"Could not load list.");
            NSBeginAlertSheet(NSLocalizedStringFromTable(@"showAllDownloads:AlertSheet:standardAlert", @"Localizable", @"cocoaDownloadController"),NSLocalizedStringFromTable(@"showAllDownloads:AlertSheet:defaultButton", @"Localizable", @"cocoaDownloadController"),nil,nil,mainDlWindow,self,@selector(listDownloadFailedAlertSheetDidEnd:returnCode:contextInfo:),nil,nil,NSLocalizedStringFromTable(@"showAllDownloads:AlertSheet:informativeText", @"Localizable", @"cocoaDownloadController"));
        }
        [downloadOriginalList addObjectsFromArray:downloadList];
    } else {
        // list is still there, we dont have to download it again
        // when we call it later we only need the original list
        [downloadList removeAllObjects];
        [downloadList addObjectsFromArray:downloadOriginalList];
        [self showWindow];
    }
    // force table reload
    [table reloadData];
    // force showDetails update
    if([self returnShowsDetails]) [self showDetails:[table selectedRow]];
    
    [pool release];	
}

- (BOOL) checkFreeOSZooIsUp
{
    BOOL isUp = NO;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:@"http://oszoo.org"]];
    [request setHTTPMethod:@"HEAD"];
    NSHTTPURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request
                              returningResponse:&response
                                          error:NULL];
    if ((response != nil) && ([response statusCode] == 200))
        isUp = YES;
    return isUp;
}

- (void) listDownloadFailedAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
    // return code of no interest here, we just want to have the downloads window closed
    [mainDlWindow orderOut:self];
}
- (void) prepareOSTypeSelector
{
    // fill 'all' and space
    [osTypeSelect removeAllItems];
    [osTypeSelect addItemWithTitle:@"All"];
    [[osTypeSelect menu] addItem:[NSMenuItem separatorItem]];
    int i,j;
    BOOL found = NO;
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:1];
    for(i=0; i<[downloadList count]; i++) {
        // if the Category is not listed yet in array add it
        for(j=0; j<[array count]; j++) {
            // search array
            if([[array objectAtIndex:j] isEqualTo:[[downloadList objectAtIndex:i] objectForKey:@"Category"]]) {
                found = YES;
            }
        }
        if(!found) [array addObject:[[downloadList objectAtIndex:i] objectForKey:@"Category"]];
        found = NO;
    }
    
    // add to selector
    for(i=0; i<[array count]; i++) {
        [osTypeSelect addItemWithTitle:[array objectAtIndex:i]];
    }
}

- (IBAction) showDownloadsByType:(id)sender
{
    //NSLog(@"showDownloadsByType:");
    // method for the popupbutton to select os type
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:1];
    if([[osTypeSelect titleOfSelectedItem] isEqualToString:@"All"]) {
        //NSLog(@"dlO: %@", downloadOriginalList);
        [array addObjectsFromArray:downloadOriginalList];
    } else {
        // be sure that we have the original downloadList here
        [downloadList removeAllObjects];
        [downloadList addObjectsFromArray:downloadOriginalList];
        int i;
        for (i=0; i<=[downloadList count]-1; i++) {
            // search for ostype and add equalling entries
            if ([[[downloadList objectAtIndex:i] valueForKey:@"Category"] isEqualTo:[osTypeSelect titleOfSelectedItem]]) {
                [array addObject:[downloadList objectAtIndex:i]];
            }
        }
    }
    
    // write os by found criteria/original downloads into downloadList
    [downloadList removeAllObjects];
    [downloadList addObjectsFromArray:array];
        
    // force table reload
    [table reloadData];
    // force showDetails update
    if([self returnShowsDetails]) [self showDetails:[table selectedRow]];
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
	   NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@ %@\n", [thisDownload objectForKey:@"Name"], [thisDownload objectForKey:@"Version"]] attributes:[NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName]] autorelease];
	   [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@, %@. %@: %@ MB\n%@ %@.", [thisDownload objectForKey:@"Category"], [thisDownload objectForKey:@"InstallType"], NSLocalizedStringFromTable(@"tableView:objectValueForTableColumn:Size", @"Localizable", @"cocoaDownloadController"), [thisDownload objectForKey:@"DownloadSize"], NSLocalizedStringFromTable(@"tableView:objectValueForTableColumn:Author", @"Localizable", @"cocoaDownloadController"), [thisDownload objectForKey:@"Author"]] attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
	   
		return attrString;
	} else if([[tableColumn identifier] isEqualToString:@"kju"]) {
		if([thisDownload valueForKey:@"Kju"] == [NSNumber numberWithInt:1])
		  return [NSImage imageNamed:@"q_icon.icns"];
        return nil;
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

- (NSArray *)getDownloadListFromServer
{
    // show status panel
    /*[NSApp beginSheet:precheckPanel
        modalForWindow:mainDlWindow
        modalDelegate:nil
        didEndSelector:nil
        contextInfo:nil];
    [precheckPanel orderFront:self];
    //[NSApp runModalForWindow: precheckPanel];
    [precheckStatusTextView setStringValue:@"Getting list from server.."];
    [precheckStatusProgressView startAnimation:self];
    // arrayWithContentsOfURL: url
    NSURLResponse * response;
    NSError * error;
    NSData * data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://cordney.com/q/freeoszoo.plist"]] returningResponse:nil error:nil];
    NSArray * downloadList = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:nil errorDescription:nil];
    */
        
    NSArray * downloadList = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:@"http://kju-app.org/data/freeoszoo_v2.plist"]];
    return downloadList;
}

// NSURLHandleClient This informal protocol defines the interface for clients to NSURL. A client is an object loading a URL resource in the background.
/*
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{   
    NSLog(@"Data available..");
    //[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Download finished");
    [precheckStatusTextView setStringValue:@"Got list from server.."];
    // todo: connectivity check freeoszoo.org
    [NSApp endSheet:precheckPanel];
    //[NSApp stopModal];
    [precheckPanel orderOut:self];
    [precheckStatusTextView setStringValue:@"Loading.."];
    [precheckStatusProgressView stopAnimation:self];
    [table reloadData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Download failed: %@", error);
}
*/

- (void) showDetails:(int)row
{
    showsDetails = YES;
    // clear textView
    [detailsTextView setString:@""];
    NSDictionary * details = [[NSDictionary alloc] initWithDictionary:[downloadList objectAtIndex:row]];
    
    // create name and version
    NSDictionary * nameAttr = [NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName];
    NSAttributedString * detailsName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [details objectForKey:@"Name"], [details objectForKey:@"Version"]] attributes:nameAttr];
    NSAttributedString * detailsDesc = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", [details objectForKey:@"Description"]]];
    NSAttributedString * detailsURLpre = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@: ", NSLocalizedStringFromTable(@"showDetails:MoreInfo", @"Localizable", @"cocoaDownloadController")]];
    NSAttributedString * detailsURL = [[NSAttributedString alloc] initWithString:[details objectForKey:@"InfopageURL"] attributes:[NSDictionary dictionaryWithObject:[details objectForKey:@"InfopageURL"] forKey:NSLinkAttributeName]];
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
        if([thisDownload valueForKey:@"Torrent"] == [NSNumber numberWithInt:1])
            download = [[[cocoaDownload alloc] initWithBT] retain];
        else
            download = [[[cocoaDownload alloc] initWithHTTP] retain];
            
        if([[thisDownload objectForKey:@"Version"] isEqualToString:@""])
            [download setName:[thisDownload objectForKey:@"Name"]];
        else
            [download setName:[NSString stringWithFormat:@"%@ %@", [thisDownload objectForKey:@"Name"], [thisDownload objectForKey:@"Version"]]];
        
        if([thisDownload valueForKey:@"Kju"] == [NSNumber numberWithInt:1])
            [download setQVM: YES];
            
        [download setURL:[thisDownload objectForKey:@"DownloadURL"]];
        // - monitor the download object with NSNotifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidReceiveResponse:) name:@"DownloadDidReceiveResponse" object:download];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startStatusTimer:) name:@"DownloadDidReceiveData" object:download];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidFinish:) name:@"DownloadDidFinish" object:download];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidFail:) name:@"DownloadDidFail" object:download];
						        
        // 2. set to downloading mode
        [self disableTableView:YES];
        [osTypeSelect setEnabled:NO];
        [table setDoubleAction:nil];
        [downloadButton setTitle:NSLocalizedStringFromTable(@"startDownload:downloadButton:Title", @"Localizable", @"cocoaDownloadController")];
        [downloadButton setAction:@selector(stopDownload:)];
        if([self returnShowsDetails]) [self resizeSmall];
        
        [statusText setStringValue:NSLocalizedStringFromTable(@"startDownload:statusText:Text", @"Localizable", @"cocoaDownloadController")];
        [statusBar setDoubleValue:0.0];
        [statusText setHidden:NO];
        [statusBar setHidden:NO];
        [statusBar setIndeterminate:YES];
        [statusBar startAnimation:self];
        
        [download startDownload];
    }
}

- (IBAction)stopDownload:(id)sender
{
    NSBeginAlertSheet(NSLocalizedStringFromTable(@"stopDownload:AlertSheet:standardAlert", @"Localizable", @"cocoaDownloadController"),NSLocalizedStringFromTable(@"stopDownload:AlertSheet:defaultButton", @"Localizable", @"cocoaDownloadController"),NSLocalizedStringFromTable(@"stopDownload:AlertSheet:alternativeButton", @"Localizable", @"cocoaDownloadController"),nil,mainDlWindow,self,@selector(stopDownloadSheetDidEnd:returnCode:contextInfo:),nil,nil,NSLocalizedStringFromTable(@"stopDownload:AlertSheet:informativeText", @"Localizable", @"cocoaDownloadController"));
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
    
    // change receiveData notification to downloadDidReceiveData notification
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
        remainingString = [NSString stringWithFormat:NSLocalizedStringFromTable(@"downloadDidReceiveData:remainingString1", @"Localizable", @"cocoaDownloadController"), time_rhour, time_rlmin, time_rlsec];
    } else if(time_rmin >= 1 && time_rmin < 10) {
        remainingString = [NSString stringWithFormat:NSLocalizedStringFromTable(@"downloadDidReceiveData:remainingString2", @"Localizable", @"cocoaDownloadController"), time_rmin, time_rlsec];
    } else if(time_rmin >=1) {
        remainingString = [NSString stringWithFormat:NSLocalizedStringFromTable(@"downloadDidReceiveData:remainingString3", @"Localizable", @"cocoaDownloadController"), time_rmin];
    } else {
        remainingString = [NSString stringWithFormat:NSLocalizedStringFromTable(@"downloadDidReceiveData:remainingString4", @"Localizable", @"cocoaDownloadController"), time_rsec];
    }
    
    if(receivedKB < 10.0) {
        [statusText setStringValue:NSLocalizedStringFromTable(@"downloadDidReceiveData:connecting", @"Localizable", @"cocoaDownloadController")];
    } else {
        if([statusBar isIndeterminate])
            [statusBar setIndeterminate:NO];
        if(receivedKB <= 1024) {
            [statusText setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"downloadDidReceiveData:statusText1", @"Localizable", @"cocoaDownloadController"), receivedD, dSize, expectedD, tDSize, lastRCVData/1024, remainingString]];
        } else {
            [statusText setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"downloadDidReceiveData:statusText2", @"Localizable", @"cocoaDownloadController"), receivedD, dSize, expectedD, tDSize, lastRCVData/1024, remainingString]];
        }
    }
}

- (void) downloadDidFinish:(NSNotification *)aNotification
{
    /* XXX FEHLERQUELLE !!! XXX */
    
    [statusText setStringValue: NSLocalizedStringFromTable(@"downloadDidFinish:statusText", @"Localizable", @"cocoaDownloadController")];
    [downloadButton setAction:nil];
    
    // call some File Manipulation Functions here
    // e.g. uncompress, move, ...
    [download stopDownload];
    [self cleanupDownload:[[download getSavePath] stringByDeletingLastPathComponent]];
    [self uncompressPC:[download getSavePath]];
}

- (void) downloadDidFail:(NSNotification *)aNotification
{
    //NSLog(@"Download did fail: %@", [[aNotification userInfo] objectForKey:@"ERROR_DESCRIPTION"]);
    
    // delete qvm
    //NSLog(@"savepath: %@", [download getSavePath]);
    if(![[[download getSavePath] stringByDeletingLastPathComponent] isEqualTo:@""] || [[download getSavePath] stringByDeletingLastPathComponent] != nil) {
        NSFileManager * manager = [NSFileManager defaultManager];
        [manager removeFileAtPath:[[download getSavePath] stringByDeletingLastPathComponent] handler:nil];
    }
    
    // reset UI
    [self cleanupDownload:[[download getSavePath] stringByDeletingLastPathComponent]];
    [statusText setStringValue: NSLocalizedStringFromTable(@"downloadDidFail:statusText", @"Localizable", @"cocoaDownloadController")];
    
    [download release];
    
    // alert sheet
    NSBeginAlertSheet(NSLocalizedStringFromTable(@"downloadDidFail:AlertSheet:standardAlert", @"Localizable", @"cocoaDownloadController"),NSLocalizedStringFromTable(@"downloadDidFail:AlertSheet:defaultButton", @"Localizable", @"cocoaDownloadController"),nil,nil,mainDlWindow,self,nil,nil,nil,[[aNotification userInfo] objectForKey:@"ERROR_DESCRIPTION"]);
}

- (void) cleanupDownload:(NSString *)path
{
    //NSLog(@"Cleaning up after download..");
    if(statusTimer) {
        [statusTimer invalidate];
    }      
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidReceiveResponse" object:download];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidReceiveData" object:download];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidFinish" object:download];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadDidFail" object:download];
    
    [statusBar stopAnimation:self];
    [statusBar setIndeterminate:NO];
    [statusBar setDoubleValue:0.0];
    [statusBar setMaxValue:100.0];
    
    [table setDoubleAction:@selector(startDownload:)];
    [downloadButton setTitle:@"Download"];
    [downloadButton setAction:@selector(startDownload:)];
    // enable tableview
    [osTypeSelect setEnabled:YES];
    [self disableTableView:NO];
}

#pragma mark -
#pragma mark File Manipulation Functions

- (void)uncompressPC:(NSString *)path
{
    [statusText setStringValue: NSLocalizedStringFromTable(@"uncompressPC:statusText", @"Localizable", @"cocoaDownloadController")];
    [statusBar setIndeterminate:YES];
    [statusBar startAnimation:self];
    NSTask * task = [[[NSTask alloc] init] retain];
    BOOL isArchive = NO;
    if([[path pathExtension] isEqualTo:@"tar"] || [[path pathExtension] isEqualTo:@"bz"] || [[path pathExtension] isEqualTo:@"bz2"] || [[path pathExtension] isEqualTo:@"gz"]) {
        [task setLaunchPath:@"/usr/bin/tar"];
        NSString * fmtArgs;
        if([[path pathExtension] isEqualTo:@"bz"] || [[path pathExtension] isEqualTo:@"bz2"]) {
            fmtArgs = @"-xjf";
        } else if ([[path pathExtension] isEqualTo:@"gz"]) {
            fmtArgs = @"-xzf";
        } else {
            fmtArgs = @"-xf";
        }
        [task setArguments:[NSArray arrayWithObjects:fmtArgs, path, nil]];
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
        [self finishDownload:1 withStatus:0];
    }
    [task release];
}

- (void)uncompressPCFinished:(NSNotification *)aNotification
{
    [self finishDownload:0 withStatus:[[aNotification object] terminationStatus]];
    //NSLog(@"extract finished Notify");
}

- (void) finishDownload:(int)sender withStatus:(int)status
{
//  NSLog(@"cocoaDownloadController: finishDownload");
    NSString * message;        
    NSString * path = [download getSavePath];
    NSString * name = [download getName];
    
    // start import into Q
    [statusText setStringValue: NSLocalizedStringFromTable(@"finishDownload:statusText1", @"Localizable", @"cocoaDownloadController")];
    if([controller importFreeOSZooPC:name withPath: [path stringByDeletingLastPathComponent]]) {
        message = NSLocalizedStringFromTable(@"finishDownload:message1", @"Localizable", @"cocoaDownloadController");
    } else {
        message = NSLocalizedStringFromTable(@"finishDownload:message2", @"Localizable", @"cocoaDownloadController");
    }
    
    // sender: 0: task, 1: file check
    if(sender == 0) {
        if(status == 0) {
            //NSLog(@"Task succeeded.");
            // delete downloaded file, leave message unchanged
            NSFileManager * manager = [NSFileManager defaultManager];
            [manager removeFileAtPath:path handler:nil];
        } else {
            //NSLog(@"Task failed.");
            // do not delete file, set message to failed
            message = [NSString stringWithFormat: NSLocalizedStringFromTable(@"finishDownload:message2", @"Localizable", @"cocoaDownloadController"), path];
        }
    } else if(sender == 1) {
        message = [NSString stringWithFormat: NSLocalizedStringFromTable(@"finishDownload:message2", @"Localizable", @"cocoaDownloadController"), path];
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:  NSLocalizedStringFromTable(@"finishDownload:AlertSheet:messageText", @"Localizable", @"cocoaDownloadController")
		defaultButton:  NSLocalizedStringFromTable(@"finishDownload:AlertSheet:defaultButton", @"Localizable", @"cocoaDownloadController")
		alternateButton:nil
		otherButton:nil
		informativeTextWithFormat:message];

    [alert beginSheetModalForWindow:mainDlWindow
		modalDelegate:self
		didEndSelector:nil
		contextInfo:nil];
    
    [statusText setStringValue:  NSLocalizedStringFromTable(@"finishDownload:statusText2", @"Localizable", @"cocoaDownloadController")];
    [statusBar setMaxValue:100.0];
    [statusBar setDoubleValue:0.0];
    [statusBar setIndeterminate:NO];
    [downloadButton setAction:@selector(startDownload:)];
    [download release];
}

- (void) dealloc
{
    // cleanup here..
    [downloadList release];
    [downloadOriginalList release];
    [controller release];
    [super dealloc];
}

@end