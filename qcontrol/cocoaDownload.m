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
#import <IOKit/IOMessage.h>

#define preferences [NSUserDefaults standardUserDefaults]

@implementation cocoaDownload

- (id) initWithHTTP
{
    isHTTP = YES;
    isBT = NO;
    
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
    NSURL * URLObject = [NSURL URLWithString:url];
    theDownload = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:URLObject] delegate:self];
    [theDownload setDeletesFileUponFailure:YES];
}

- (void) startBTDownload
{
    // download the torrent file
    NSString * torrentPath = [[self createQVM] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.torrent", name]];
    // we need to temporarily save the qvm path here, cause we may need it later

    NSData * torrentFile = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    [torrentFile writeToFile:torrentPath atomically:YES];
    // init some values
    fCount = 0;
    fDownloading = 0;
    fSeeding = 0;
    fCompleted = 0;
    fStat  = nil;
    // get the download data every 10ms &
    // start the torrent download
    if(tr_torrentInit( fHandle, [torrentPath UTF8String] ) == 0 ) {
        tr_torrentSetFolder( fHandle, 0, [[torrentPath stringByDeletingLastPathComponent] UTF8String] );
        tr_torrentStart( fHandle, 0 );
        fTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector( BTDownloadDidReceiveData: ) userInfo: nil repeats: YES];
        
        // set the save path
        if (fStat)
            free(fStat);
        
        fCount = tr_torrentStat( fHandle, &fStat );
        savePath = [[torrentPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithUTF8String:fStat[0].info.name]];
        [savePath retain];
        
        // tell the controller that the download started
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidReceiveResponse" object:self];
    } else {
        NSLog(@"Initiating Torrent %@ Failed!", torrentPath);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFail" object:self];
    }
}

- (void) stopDownload
{
    if(isHTTP) {
        [theDownload cancel];
        [theDownload release];
    } else if(isBT) {
        tr_torrentStop(fHandle, 0);
        tr_torrentClose(fHandle, 0);
        tr_close(fHandle);
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
        //NSLog(@"Download did receive Response.");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidReceiveResponse" object:self];
    }
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{    
    NSString * destinationFilename=[[self createQVM] stringByAppendingPathComponent:filename];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFail" object:download userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:@"ERROR_DESCRIPTION"]];
    //NSLog(@"Download did fail with error: %@", errorDescription);
}

#pragma mark -
#pragma mark BT Download Methods and Delegates

- (void) BTDownloadDidReceiveData:(NSTimer *)theTimer
{
    int i;

    //Update download values
    if (fStat)
        free(fStat);
        
    fCount = tr_torrentStat( fHandle, &fStat );
    fDownloading = 0;
    fSeeding = 0;

    /*
    //Update the global DL/UL rates
    tr_torrentRates( fHandle, &dl, &ul );
    NSString * downloadRate = [NSString stringForSpeed: dl];
    NSString * uploadRate = [NSString stringForSpeed: ul];
    [fTotalDLField setStringValue: downloadRate];
    [fTotalULField setStringValue: uploadRate];
    */

    // Update DL/(UL) and size values
    /* available values:
        fStat[row].downloaded already downloaded [size]
        fStat[row].uploaded already uploaded [size]
        ... (see transmission.h->tr_torrentStat)
    */
    
    receivedContentLength = fStat[0].downloaded;
    expectedContentLength = fStat[0].info.totalSize;
    downloadRate = fStat[0].rateDownload;
        
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidReceiveData" object:self];
    
    //check if torrent(s) have recently ended.
    for (i = 0; i < fCount; i++)
    {
        if (fStat[i].status & (TR_STATUS_CHECK | TR_STATUS_DOWNLOAD))
            fDownloading++;
        else if (fStat[i].status & TR_STATUS_SEED)
            fSeeding++;
            //NSLog(@"Seeding download.");

        if( !tr_getFinished( fHandle, i ) )
            continue;

        fCompleted++;
        tr_setFinished( fHandle, i, 0 );
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadDidFinish" object:self];
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
}

@end