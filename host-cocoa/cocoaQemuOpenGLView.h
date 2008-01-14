/*
 * QEMU Cocoa openGL View
 * 
 * Copyright (c) 2005 - 2007    Mike Kronenberg
 *                              Peter Stewart
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
#import <OpenGL/CGLCurrent.h>
#import <OpenGL/CGLContext.h>

#import "console.h"
#import "cocoaQemuWindow.h"

#define SCREEN_BPP 32

@interface cocoaQemuOpenGLView : NSOpenGLView
{
    id pc;
    float cx,cy,cw,ch,cdx,cdy;
    cocoaQemuWindow *FullScreenWindow;
    DisplayState current_ds;
    BOOL fullscreen;
    BOOL drag;
    GLint screen_tex;
    GLuint display_list_tex;
    GLuint display_list_tmb;
}
- (id)initWithFrame:(NSRect)frameRect sender:(id)sender;
- (BOOL) toggleFullScreen;
- (void) drawContent:(DisplayState *)ds;
- (void) resizeContent:(DisplayState *)ds width:(int)w height:(int)h;
- (NSImage *) screenshot:(NSSize)size;
- (void) setContentDimensions;
@end

