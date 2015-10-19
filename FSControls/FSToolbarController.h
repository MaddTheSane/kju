/*
 * Q Fullscreen Toolbar Controller
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

#import <Cocoa/Cocoa.h>
#import "FSRoundedView.h"

@class QDocument;

#define SEMI_TRANSPARENT_COLOR [NSColor colorWithCalibratedWhite:0.0 alpha:0.6]

@interface FSToolbarController : NSObject <NSWindowDelegate>
{
	NSWindow * window;
	FSRoundedView * view;
	NSTimer * fadeTimer;
	
	BOOL showsToolbar;
	BOOL isAnimating;
	QDocument *pc;
}
- (instancetype) initWithSender:(QDocument*)sender;

- (void) show;
- (void) hide;
@property (readonly) BOOL showsToolbar;
- (void) setupToolbar;
- (void) addToolbarItem:(NSString *)icon withTitle:(NSString *)title rectangle:(NSRect)rectangle target:(id) target action:(SEL)action;
- (void) addCustomToolbarItem:(id)item;

@property (readonly, strong) NSWindow *createTransparentWindow;

// fading operations
- (void) fadeIn;
- (void) fadeOut;
- (void) setAnimates:(BOOL)lock;
@property (getter=isAnimating, setter=setAnimates:) BOOL animating;
- (IBAction) setFullscreen:(id)sender;
- (IBAction) shutdownPC:(id)sender;
@end
