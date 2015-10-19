/*
 * QEMU Cocoa Fullscreen Controller
 * 
 * Copyright (c) 2006 - 2008 René Korthaus
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

#import "FSController.h"
#import "../QDocument/QDocument.h"
#import "../QDocument/QDocumentOpenGLView.h"

@implementation FSController

- (id) initWithSender:(QDocument*)sender
{
	Q_DEBUG(@"initWithSender");
	
    pc = sender;
    // init connections to fullscreen controls
    toolbar = [[FSToolbarController alloc] initWithSender: pc];
    
    // return
    return self;
}

#pragma mark Toolbar

- (BOOL) showsToolbar
{
	Q_DEBUG(@"showsToolbar");

    return [toolbar showsToolbar];
}

- (void) toggleToolbar
{
	Q_DEBUG(@" toggleToolbar");

    if(![toolbar isAnimating]) {
    // avoid animation loop
        if([toolbar showsToolbar]) {
            [toolbar hide];
            [[pc screenView] grabMouse];
        } else {
            [toolbar show];
            [[pc screenView] ungrabMouse];
        }
    }
}

#pragma mark -

- (void) dealloc
{
	Q_DEBUG(@"dealloc");

}

@end
