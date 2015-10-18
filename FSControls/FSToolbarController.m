/*
 * Q Fullscreen Toolbar Controller
 * 
 * Copyright (c) 2006-2008 René Korthaus
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

#import "FSToolbarController.h"
#import "FSTransparentButton.h"
#import "../QDocument/QDocument.h"
#import "../QDocument/QDocumentOpenGLView.h"

@implementation FSToolbarController

- (id) initWithSender:(id)sender
{
	Q_DEBUG(@"initWithSender");

	pc = sender;
	showsToolbar = NO;
	isAnimating = NO;
	
	// create a transparent window
	window = [self createTransparentWindow];
	// we want to become the window's delegate to receive notifications
	[window setDelegate: self];
	
	// create a rounded view and make it the window's contentView
	view = [[FSRoundedView alloc] init];
	[window setContentView:view];
	
    [self setupToolbar];
	
	// return
	return self;
}

- (void) show
{
	Q_DEBUG(@"show");

    // orderFront
    showsToolbar = YES;
    [self setAnimates: YES];
    [window makeKeyAndOrderFront:nil];
	// start the NSTimer to fade in
	fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fadeIn) userInfo:nil repeats:YES] retain];    
}

- (void) hide
{
	Q_DEBUG(@"hide");

	// start the NSTimer to fade out
	[self setAnimates: YES];
	fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fadeOut) userInfo:nil repeats:YES] retain];
	showsToolbar = NO;
}

- (BOOL) showsToolbar
{
	Q_DEBUG(@"showsToolbar");

    return showsToolbar;
}

- (void) setupToolbar
{
	Q_DEBUG(@"setupToolbar");

    // set up toolbar items
	float margin_h = 30; // left and right margin of the toolbar on the window
	//float margin_space = 40;
	float itemWidth = 64 + 5;
	float itemHeight = 64 + 5;
	[self addToolbarItem:@"q_tbfs_screenshot.png" withTitle: NSLocalizedStringFromTable(@"toolbar:label:screenshot", @"Localizable", @"FSToolbarController") rectangle:NSMakeRect(margin_h,20,itemWidth,itemHeight) target:pc action:@selector(screenShot:)];
	[self addToolbarItem:@"q_tbfs_ctrlaltdel.png" withTitle: NSLocalizedStringFromTable(@"toolbar:label:ctrlaltdel", @"Localizable", @"FSToolbarController") rectangle:NSMakeRect(120,20,itemWidth,itemHeight) target:pc action:@selector(ctrlAltDel:)];
	[self addToolbarItem:@"q_tbfs_shutdown.png" withTitle: NSLocalizedStringFromTable(@"toolbar:label:shutdown", @"Localizable", @"FSToolbarController") rectangle:NSMakeRect(220,20,itemWidth,itemHeight) target:self action:@selector(shutdownPC:)];
	
	// add seperator item and last item at the end of the window
	NSRect viewFrame = [[[window contentView] superview] frame];
	float lastItemOriginX = viewFrame.size.width - margin_h - itemWidth;
	[self addToolbarItem:@"q_tbfs_fullscreen.png" withTitle: NSLocalizedStringFromTable(@"toolbar:label:fullscreen", @"Localizable", @"FSToolbarController") rectangle:NSMakeRect(lastItemOriginX,20,itemWidth,itemHeight) target:self action:@selector(setFullscreen:)];
	
	NSRect seperatorRect;
	seperatorRect.size.height = viewFrame.size.height - 20; //itemHeight + 20;
	seperatorRect.size.width = 2;
	seperatorRect.origin.x = lastItemOriginX - margin_h;
	seperatorRect.origin.y = viewFrame.origin.y + ((viewFrame.size.height - seperatorRect.size.height) / 2);

	NSBox * seperator = [[NSBox alloc] initWithFrame:seperatorRect];
	[seperator setBoxType: NSBoxSeparator];
	[self addCustomToolbarItem: seperator];    
}

- (void) addToolbarItem:(NSString *)icon withTitle:(NSString *)title rectangle:(NSRect)rectangle target:(id) target action:(SEL)action
{
	Q_DEBUG(@"addToolbarItem");

	id cView = [[window contentView] superview];	

	// add button
	FSTransparentButton * button = [[FSTransparentButton alloc] initWithFrame: rectangle];
	[button setButtonType: NSMomentaryChangeButton];
	[button setBezelStyle: NSRegularSquareBezelStyle];
	[button setBordered: NO];
	[button setImage: [NSImage imageNamed: icon]];
	[button setTarget: target];
	[button setAction: action];
	[cView addSubview: button];
	[button release];
	
	// add title label
	// we have to position it centered underneath the button
	NSRect textFieldRect;
	textFieldRect.size.width = rectangle.size.width + 30;
	textFieldRect.size.height = 15;
	textFieldRect.origin.x = rectangle.origin.x - ((textFieldRect.size.width - rectangle.size.width) / 2);
	textFieldRect.origin.y = rectangle.origin.y - textFieldRect.size.height - 2;
	
	NSTextField * textField = [[NSTextField alloc] initWithFrame: textFieldRect];
	[textField setEditable: NO];
	[textField setBackgroundColor: SEMI_TRANSPARENT_COLOR];
	[textField setTextColor: [NSColor whiteColor]];
	[textField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[textField setBordered: NO];
	[textField setAlignment: NSCenterTextAlignment];
	[textField setStringValue: title];
	[cView addSubview: textField];
	[textField release];
	
	[cView setNeedsDisplay: YES];
}

- (void) addCustomToolbarItem:(id)item
{
	Q_DEBUG(@"addCustomToolbarItem");

	id cView = [[window contentView] superview];	
	[cView addSubview: item];
	[item release];

	[cView setNeedsDisplay: YES];
}

- (NSWindow *) createTransparentWindow
{
	Q_DEBUG(@"createTransparentWindow");

    NSRect frameRect = [[NSScreen mainScreen] frame];
    NSRect contentRect;
    contentRect.size.width = 800.0;
    contentRect.size.height = 100.0;
    // position from bottom left
	contentRect.origin.x = (frameRect.size.width - contentRect.size.width) / 2; // place in the horizontal center of screen
    contentRect.origin.y = frameRect.size.height * 0.1; // place 10% of screen size away from bottom
    
    // create a borderless window
    NSWindow * aWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    // actually make it transparent
    [aWindow setBackgroundColor: [NSColor clearColor]];
    [aWindow setOpaque: NO];
	[aWindow setHasShadow: NO];
	[aWindow setLevel: NSScreenSaverWindowLevel - 1];
	[aWindow setAlphaValue: 0.0]; // fade to 1.0
	
	return aWindow;
}

- (void) fadeIn
{
	Q_DEBUG(@"fadeIn");

	if([window alphaValue] < 1.0) {
		// fade in..
		float nextAlphaValue = [window alphaValue] + 0.2;
		[window setAlphaValue: nextAlphaValue];
	} else {
		// fadeIn complete
		[fadeTimer invalidate];
		[fadeTimer release];
		[self setAnimates: NO];
	}
}

- (void) fadeOut
{
	Q_DEBUG(@"fadeOut");

	if([window alphaValue] > 0.0) {
		// fade out..
		float nextAlphaValue = [window alphaValue] - 0.2;
		[window setAlphaValue: nextAlphaValue];
	} else {
		// fadeOut complete
		[fadeTimer invalidate];
		[fadeTimer release];
		[window orderOut:nil];
		[self setAnimates: NO];
	}
}

- (void) setAnimates:(BOOL)lock
{
	Q_DEBUG(@"setAnimates");

    isAnimating = lock;
}

- (BOOL) isAnimating
{
	Q_DEBUG(@"isAnimating");

    return isAnimating;
}

// custom toolbar actions
- (void) setFullscreen:(id)sender
{
	Q_DEBUG(@"setFullscreen");

    [[pc screenView] toggleFullScreen];
    // release ourselves with the FSController
    [[[pc screenView] fullscreenController] release];
}

- (void) shutdownPC:(id)sender
{
	Q_DEBUG(@"shutdownPC");

    [pc VMShutDown:self];
    // release ourselves with the FSController
    [[[pc screenView] fullscreenController] release];
}

- (void) dealloc
{
	Q_DEBUG(@"dealloc");

    [window close];
    [super dealloc];
}

@end
