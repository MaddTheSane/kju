/*
 * QEMU Cocoa Quarz View
 * 
 * Copyright (c) 2006 Mike Kronenberg
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

#import "vl.h"
#import "cocoaQemuWindow.h"

@interface cocoaQemuQuartzView : NSView
{
	id pc;
	cocoaQemuWindow *FullScreenWindow;
	CGDataProviderRef dataProviderRef;
	void *screen_pixels;
	DisplayState current_ds;
	BOOL fullscreen;
	BOOL drag;
}
- (id)initWithFrame:(NSRect)frameRect sender:(id)sender;
- (BOOL) toggleFullScreen;
- (void) resizeContent:(DisplayState *)ds width:(int)w height:(int)h;
- (NSImage *) screenshot:(NSSize)size;
@end

