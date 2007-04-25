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

#import <Cocoa/Cocoa.h>
#import "../../Transmission/libtransmission/transmission.h"

@interface cocoaDownload : NSObject
{
    NSString * name;
    NSString * url;
    NSString * savePath;
    NSMutableArray * lastReceivedContentLength;
    NSTimer * timer;
    
    BOOL isHTTP;
    BOOL isBT;
    BOOL isQVM;
    
    float receivedContentLength;
    float expectedContentLength;
    float downloadRate;
    
    // HTTP Download stuff
    NSURLDownload * theDownload;
    
    // BT Download stuff
    tr_handle_t                 * fHandle; // main handle for libtransmission instance
    tr_torrent_t                * tHandle; // handle for single torrent
    int                         tError; // error code returned by tr_torrentInit
    int                         fCount, fSeeding, fDownloading, fCompleted;
    tr_stat_t                   * tStat;
    tr_info_t                   * tInfo;
    NSTimer                     * fTimer;
}

- (id) initWithHTTP;
- (id) initWithBT;

// get and set methods
- (void) setURL:(NSString *)aURL;
- (void) setName:(NSString *)aName;
- (void) setQVM:(BOOL)val;
- (NSString *) getName;
- (NSString *) getSavePath;

- (float) getExpectedData;
- (float) getReceivedData;
- (int) getLastReceivedData;

// managing downloads
- (void) startDownload;
- (void) startHTTPDownload;
- (void) startBTDownload;
- (void) checkDownloadStarted;
- (void) stopDownload;

// HTTP Download Methods and Delegates
// no declaration needed, cause they are NSNotification methods

// BT Download Methods and Delegates

// Additional Functions
- (NSString *) createQVM;

@end