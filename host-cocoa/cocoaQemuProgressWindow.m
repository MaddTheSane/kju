/*
 * QEMU Cocoa QEMU Progress Window
 * 
 * Copyright (c) 2005, 2006 Mike Kronenberg
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

#import "cocoaQemuProgressWindow.h"

@implementation cocoaQemuProgressWindow
- (id) init
{
//	NSLog(@cocoaQemuProgressWindow: init");

	if ((self = [super initWithContentRect:NSMakeRect (0, 0, 400, 116)
		styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask|NSClosableWindowMask
		backing:NSBackingStoreBuffered
		defer:YES])) {
		[self setDelegate: self];
		[self setReleasedWhenClosed:NO];

		/* creating NSTextField */
		progressTitle = [[NSTextField alloc] initWithFrame: NSMakeRect(17, 82, 275, 14)];
		[progressTitle setDrawsBackground:NO];
		[progressTitle setBordered:NO];
		[progressTitle setStringValue: [[[NSAttributedString alloc] initWithString:@"Saving PC" attributes:[NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
		[progressTitle setSelectable:NO];
		[progressTitle setEditable:NO];
		[[self contentView] addSubview: progressTitle];
		
		/* creating NSprogressbarIndicator */
		progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(19, 62, 275, NSProgressIndicatorPreferredAquaThickness)];
		[progressIndicator setIndeterminate:YES];
		[progressIndicator setUsesThreadedAnimation:YES];
		[[self contentView] addSubview:progressIndicator];

		/* creating NSTextField */
		progressText = [[NSTextField alloc] initWithFrame: NSMakeRect(17, 42, 275, 14)];
		[progressText setDrawsBackground: NO];
		[progressText setBordered: NO];
		[progressText setStringValue:@"TEST"];
		[progressText setSelectable:NO];
		[progressText setEditable:NO];
		[[self contentView] addSubview: progressText];

		/* creating NSButton */
		progressButton = [[NSButton alloc] initWithFrame: NSMakeRect(305, 54, 80, 28)];
//		[progressButton setButtonType:NSMomentaryPushButton];
		[[progressButton cell] setControlSize:NSSmallControlSize];
		[progressButton setBezelStyle:NSRoundedBezelStyle];
		[progressButton setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		[progressButton setTitle: NSLocalizedStringFromTable(@"init:title", @"Localizable", @"cocoaQemuProgressWindow")];
		[progressButton setKeyEquivalent:@"\E"];
		[progressButton setTarget:self];
		[progressButton setAction:@selector(stop:)];
		[[self contentView] addSubview: progressButton];
	
		return self;
	}
	return nil;
}

- (void) showProgressWindow:(id)sender text:(NSString *)text name:(NSString *)name
{
//	NSLog(@cocoaQemuProgressWindow: showProgressWindow");
	
	[progressTitle setStringValue: [[[NSAttributedString alloc] initWithString:text attributes:[NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
	[progressText setStringValue: [NSString stringWithFormat: NSLocalizedStringFromTable(@"showProgressWindow:text", @"Localizable", @"cocoaQemuProgressWindow"), name]];
	[progressIndicator startAnimation:self];

	[NSApp beginSheet:self 
		modalForWindow:sender
		modalDelegate:nil
		didEndSelector:nil
		contextInfo:nil];
}

- (void) hideProgressWindow
{
//	NSLog(@cocoaQemuProgressWindow: hideProgressWindow");

	[NSApp endSheet:self];
	[self orderOut:self];
	[progressIndicator stopAnimation:self];
}

- (void) stop:(id)sender
{
//	NSLog("cocoaQemuProgressWindow: stop");

	[self hideProgressWindow];
	[NSApp terminate:self];
}
@end
