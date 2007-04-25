/*
 * QEMU Cocoa Control Download Class
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
 
#import "cocoaDownload.h"

#define preferences [NSUserDefaults standardUserDefaults]

@implementation cocoaDownload

- (id) initWithHTTP
{
    isHTTP = YES;
    isBT = NO;
    isQVM = NO;
    
    // do initialization here...
    theDownload = nil;
    lastReceivedContentLength = [[[NSMutableArray alloc] initWithCapacity:10] retain];
    
    return self;
}

- (id) initWithBT
{
    isHTTP = NO;
    isBT = YES;
    
    // do initialization here...
    fHandle = tr_init();
    
    return self;
}

#pragma mark -
#pragma mark Get and Set Methods

- (void) setURL:(NSString *)aURL
{
    [aURL retain];
    [url release];
    url = aURL;
}

- (void) setName:(NSString *)aName;
{
    [aName retain];
    [name release];
    name = aName;
}

- (void) setQVM:(BOOL)val
{
    isQVM = val;
}

- (float) getExpectedData
{
    return expectedContentLength;
}

- (float) getReceivedData
{
    return receivedContentLength;
}

- (int) getLastReceivedData
{
    if(isHTTP) {
        int i;
        int v_all=0;
        for(i=0; i<[lastReceivedContentLength count]; i++) {
            v_all += [[lastReceivedContentLength objectAtIndex:i] intValue];
        }
        [lastReceivedContentLength removeAllObjects];
        return v_all;
    } else if(isBT) {
        // return downloadRate*1024 because we get the value from transmission in kB already
        return downloadRate*1024;
    }
    
    return 0;
}

- (NSString *) getName
{
    return name;
}

- (NSString *) getSavePath
{
    NSLog(@"saveP: %@", savePath);
    return savePath;
}

#pragma mark -
#pragma mark Managing Downloads

- (void) startDownload
{
    if(isHTTP) {
        [self startHTTPDownload];
    } else if(isBT) {
        [self startBTDownload];
    }
}

// custom HTTP&BT startDownload methods
- (void) startHTTPDownload
{
    // timeout does not work here, instead we fire a 1min timer and check if receivedContentLength > 0
    NSURLRequest * theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]]; //cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
    if (theDownload) timer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkDownloadStarted) userInfo:nil repeats:NO] retain];
}

- (void) startBTDownload
{
    NSString * torrentPath;
    // download the torrent file
    if(isQVM)
        torrentPath = [[preferences objectForKey:@"dataPath"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.torrent", name]];
    else
        torrentPath = [[self createQVM] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.torrent", name]];

    // we need to temporarily save the qvm path here, cause we need it later
    savePath = torrentPath;
    [savePath retain];
    
    NSData * torrentFile = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if([torrentFile length] == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFail" object:self userInfo:[NSDictionary dictionaryWithObject:NSLocalizedStringFromTable(@"startBTDownload:torrentFile:length", @"Localizable", @"cocoaDownload") forKey:@"ERROR_DESCRIPTION"]];
        return;
    }
    [torrentFile writeToFile:torrentPath atomically:YES];
    tStat = nil;
    tInfo = nil;
    // get the download data every 10ms &
    // start the torrent download
    tHandle = tr_torrentInit( fHandle, [torrentPath UTF8String], 0, &tError );
    if(tHandle != NULL) {
        tr_torrentSetFolder( tHandle, [[torrentPath stringByDeletingLastPathComponent] UTF8String] );
        tr_torrentStart( tHandle );
        fTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector( BTDownloadDidReceiveData: ) userInfo: nil repeats: YES];
        // prepare the torrent stats
        tStat = tr_torrentStat( tHandle );
        tInfo = tr_torrentInfo ( tHandle );
        tr_torrentRemoveSaved( tHandle );
        // set the save path
        [savePath release];
        savePath = [[torrentPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithUTF8String:tInfo[0].name]];
        [savePath retain];
        
        // tell the controller that the download started
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidReceiveResponse" object:self];
        // start timer for checking download started
        timer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkDownloadStarted) userInfo:nil repeats:NO] retain];
    } else {
        //NSLog(@"Initiating Torrent %@ Failed!", torrentPath);
        NSString * errorDescription;
        switch (tError) {
            case 1:
                errorDescription = NSLocalizedStringFromTable(@"startBTDownload:torrentFile:tError:invalid", @"Localizable", @"cocoaDownload");
                break;
            case 2:
                errorDescription = NSLocalizedStringFromTable(@"startBTDownload:torrentFile:tError:unsupported", @"Localizable", @"cocoaDownload");
                break;
            case 3:
                errorDescription = NSLocalizedStringFromTable(@"startBTDownload:torrentFile:tError:exists", @"Localizable", @"cocoaDownload");
                break;
            case 666:
                errorDescription = NSLocalizedStringFromTable(@"startBTDownload:torrentFile:tError:miscellanious", @"Localizable", @"cocoaDownload");
                break;
            default:
                errorDescription = NSLocalizedStringFromTable(@"startBTDownload:torrentFile:tError:miscellanious", @"Localizable", @"cocoaDownload");
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFail" object:self userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:@"ERROR_DESCRIPTION"]];
    }
}

- (void) checkDownloadStarted
{
#if kju_debug
    NSLog(@"check: receivedBytes %f", receivedContentLength);
#endif
    if(receivedContentLength > 0.0) {
        // download started
    } else {
#if kju_debug
        NSLog(@"download cancelled.");
#endif
        // download did not start for 60 seconds, cancel and inform the user
        NSString * errorDescription = NSLocalizedStringFromTable(@"checkDownloadStarted:errorDescription", @"Localizable", @"cocoaDownload");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFail" object:self userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:@"ERROR_DESCRIPTION"]];
        [self stopDownload];
    }
    // called only once, so invalidate timer
    [timer invalidate];
}

- (void) stopDownload
{
    if(isHTTP) {
        //[theDownload cancel];
        //[theDownload release];
    } else if(isBT) {
        tr_torrentStop( tHandle );
        tr_torrentClose( fHandle, tHandle );
        tr_close( fHandle );
        fHandle = nil;
        tHandle = nil;
        [fTimer invalidate];
    }
}

#pragma mark -
#pragma mark HTTP Download Methods and Delegates

- (void)downloadDidBegin:(NSURLDownload *)download
{
    // do we need to implement it here?
    //NSLog(@"Download did begin.");
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    expectedContentLength = [response expectedContentLength];
	
    if (expectedContentLength > 0) {
        // the download got a response, hence the download starts
        // we can inform the DownloadController about it
        // NSLog(@"Download did receive Response.");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidReceiveResponse" object:self];
    }
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSString * destinationFilename;
    if(isQVM)
        destinationFilename = [[preferences objectForKey:@"dataPath"] stringByAppendingPathComponent:filename];
    else
        destinationFilename=[[self createQVM] stringByAppendingPathComponent:filename];

    savePath = destinationFilename;
    [savePath retain];
    [download setDestination:destinationFilename allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
    if (expectedContentLength > 0.0) {
        receivedContentLength += length;
        [lastReceivedContentLength addObject:[NSNumber numberWithInt:length]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidReceiveData" object:self];
    }
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    [download release];
    // we should inform the controller about this
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFinish" object:self];
    //NSLog(@"Download did finish.");
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	// we should inform the controller about this
	[download release];
	NSString *errorDescription = [error localizedDescription];
    if (!errorDescription) {
        errorDescription = @"Please check your internet connection.";
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFail" object:self userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:@"ERROR_DESCRIPTION"]];
    //NSLog(@"Download did fail with error: %@", errorDescription);
}

#pragma mark -
#pragma mark BT Download Methods and Delegates

- (void) BTDownloadDidReceiveData:(NSTimer *)theTimer
{
    //Update download values
    tStat = tr_torrentStat( tHandle );
    tInfo = tr_torrentInfo( tHandle );
    
    //NSLog(@"rcvCL: %f", receivedContentLength);
    receivedContentLength = tInfo[0].totalSize * tStat[0].progress;
    expectedContentLength = tInfo[0].totalSize;
    downloadRate = tStat[0].rateDownload;
        
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidReceiveData" object:self];
    
    // check if torrent has recently ended.

    if (tStat[0].status & (TR_STATUS_CHECK | TR_STATUS_DOWNLOAD)) {
        // do nothing
    } else if (tStat[0].status & TR_STATUS_SEED) {
        // do nothing
        //NSLog(@"Seeding download.");
        if( tr_getFinished( tHandle ) == 1 ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFinish" object:self];
        }
    }
        
    // DEBUG output
    //NSLog(@"peers: %d | dlRate: %d", fStat[0].peersTotal, fStat[0].rateDownload);
}

#pragma mark -
#pragma mark Additional Functions

- (NSString *) createQVM
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *homeDirectory=[preferences objectForKey:@"dataPath"];
    NSString * path;
    // we need to check if qvm already exists
    int i=1;
    if([fileManager fileExistsAtPath:[homeDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.qvm", name]]]) {
        while([fileManager fileExistsAtPath:[homeDirectory stringByAppendingPathComponent:[name stringByAppendingString:[NSString stringWithFormat:@"-%d.qvm", i]]]]) {
            i++;
        }
        [fileManager createDirectoryAtPath:[homeDirectory stringByAppendingPathComponent:[name stringByAppendingString:[NSString stringWithFormat:@"-%d.qvm", i]]] attributes:nil];
        path = [homeDirectory stringByAppendingPathComponent:[name stringByAppendingString:[NSString stringWithFormat:@"-%d.qvm", i]]];
    } else {
        [fileManager createDirectoryAtPath:[homeDirectory stringByAppendingPathComponent:[name stringByAppendingString:@".qvm"]] attributes:nil];
        path = [homeDirectory stringByAppendingPathComponent:[name stringByAppendingString:@".qvm"]];
    }
    return path;
}

#pragma mark -
#pragma mark Cleanup

- (void) dealloc
{
    [super dealloc];
    [lastReceivedContentLength removeAllObjects];
    [lastReceivedContentLength release];
    [url release];
    [name release];
    [savePath release];
}

@end