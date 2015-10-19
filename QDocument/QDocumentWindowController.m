/*
 * Q Document Window Controller
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

#import "QDocumentWindowController.h"

#import "QDocument.h"
#import "QDocumentOpenGLView.h"



@implementation QDocumentWindowController
- (id) initWithWindow:(NSWindow *)tWindow sender:(QDocument *)sender
{
	Q_DEBUG(@"initWithWindow:");

    self = [super init];
    if (self) {
        
        // we are part of this document
        document = (QDocument *)sender;
		screenView = (QDocumentOpenGLView *)[document screenView];
        
        // we are delegate of this window
        window = tWindow;
        [window setDelegate:self];
        [window setAcceptsMouseMovedEvents:YES];

    }
    return self;
}



#pragma mark delegates
- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	Q_DEBUG(@"windowDidBecomeKey:");

    if ([document VMPauseWhileInactive])
        [(QDocument *)document VMPause:self];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	Q_DEBUG(@"windowDidResignKey:");

    if ([document VMPauseWhileInactive])
        [document VMUnpause:self];
}

- (NSSize)windowWillResize:(NSWindow *)tWindow toSize:(NSSize)proposedFrameSize
{
    Q_DEBUG(@"QemuCocoaView: windowWillResize: toSize: NSSize(%f, %f)", proposedFrameSize.width, proposedFrameSize.height);

    // update zoom
    [screenView displayPropertiesSetZoom:(proposedFrameSize.width / (float)[screenView screenProperties].width)];

    // Update the content to new size before window is resized, if the new size is bigger
    if (proposedFrameSize.width > [tWindow frame].size.width || proposedFrameSize.height > [tWindow frame].size.height) {
        [screenView setContentDimensionsForFrame:NSMakeRect(0, 0, proposedFrameSize.width, proposedFrameSize.height - TITLE_BAR_HEIGHT - ICON_BAR_HEIGHT)];
    }

    return proposedFrameSize;
}
/*
- (void)windowDidResize:(NSNotification *)notification
{
    Q_DEBUG(@"QemuCocoaView: windowDidResize");

	if (![screenView isFullscreen]) {
		// update zoom
		[screenView displayPropertiesSetZoom:([window frame].size.width / (float)[screenView screenProperties].width)];
	
		[screenView setContentDimensionsForFrame:NSMakeRect(0, 0, [window frame].size.width, [window frame].size.height - TITLE_BAR_HEIGHT - ICON_BAR_HEIGHT)];
		[screenView reshape];
	}
}
*/

@end
