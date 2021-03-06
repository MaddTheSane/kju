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

NS_ASSUME_NONNULL_BEGIN

@class QDocument;

#define SEMI_TRANSPARENT_COLOR [NSColor colorWithCalibratedWhite:0.0 alpha:0.6]

@interface FSToolbarController : NSObject <NSWindowDelegate>

- (instancetype) initWithSender:(QDocument*)sender;

- (void) show;
- (void) hide;
@property (readonly) BOOL showsToolbar;
- (void) setupToolbar;
- (void) addToolbarItem:(NSString *)icon withTitle:(NSString *)title rectangle:(NSRect)rectangle target:(id) target action:(SEL)action;
- (void) addCustomToolbarItem:(nullable id)item;

- (NSWindow *) createTransparentWindow NS_RETURNS_RETAINED;

// fading operations
- (void) fadeIn;
- (void) fadeOut;
@property (getter=isAnimating, setter=setAnimates:) BOOL animating;
- (IBAction) setFullscreen:(nullable id)sender;
- (IBAction) shutdownPC:(nullable id)sender;
@end

NS_ASSUME_NONNULL_END
