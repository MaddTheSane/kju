/*
 * QEMU Cocoa QEMU Window
 * 
 * Copyright (c) 2005, 2006 Mike Kronenberg
 *							Pierre d'Herbemont
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

#import "cocoaQemuWindow.h"
#import "cocoaQemu.h"
#import "cocoaQemuOpenGLView.h"
#import "cocoaQemuQuickDrawView.h"
#import "cocoaPopUpView.h"
#import "cocoaCpuView.h"
#import "vl.h"
#import "CGSPrivate.h"



@implementation cocoaQemuWindow
- (id) initWithSender:(id)sender
{
//	NSLog(@"cocoaQemuWindow: initWithSender");

	if ((self = [super initWithContentRect:NSMakeRect (0, 0, 640, 400)
		//styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask|NSClosableWindowMask|NSUnifiedTitleAndToolbarWindowMask|NSResizableWindowMask //Scrollview
		styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask|NSClosableWindowMask|NSUnifiedTitleAndToolbarWindowMask
		backing:NSBackingStoreBuffered
		defer:YES])) {
	
		pc = sender;
			
		[self setAcceptsMouseMovedEvents:YES];
		[self setReleasedWhenClosed:YES];
		[self setBackgroundColor:[NSColor blackColor]];
		[self center];
		[self setupToolbar];
		[self setDelegate:self];
		[self makeKeyAndOrderFront:nil];
			
		return self;
	}
	return nil;
}

- (void)windowDidResize:(NSNotification *)aNotification
{
//	NSLog(@"cocoaQemuWindow: windowDidResize");

	if ([contentView isKindOfClass:[cocoaQemuQuickDrawView class]]) {
		 /* make the alpha channel opaque so anim won't have holes in it */
		[contentView refreshView];
	}
}

- (void) setupToolbar
{
//	NSLog(@"cocoaQemuWindow: setupToolbar");

	pcWindowToolbar = [[[NSToolbar alloc] initWithIdentifier: @"pcWindowToolbarIdentifier"] autorelease];
	[pcWindowToolbar setAllowsUserCustomization: YES]; //allow customisation
	[pcWindowToolbar setAutosavesConfiguration: YES]; //autosave changes
	[pcWindowToolbar setDisplayMode: NSToolbarDisplayModeIconOnly]; //what is shown
	[pcWindowToolbar setSizeMode:NSToolbarSizeModeSmall]; //default Toolbar Size
	[pcWindowToolbar setDelegate: self]; // We are the delegate
	[self setToolbar: pcWindowToolbar]; // Attach the toolbar to the document window
}

/* Toolbar Delegates*/
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSMenu *menu;
	NSMenuItem *menuItem;
	cocoaPopUpView *popUpView;
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
	if ([itemIdent isEqual: @"fdaChangeIdentifier"]) {
		[toolbarItem setMinSize: NSMakeSize(32,32)];
		[toolbarItem setMaxSize: NSMakeSize(32,32)];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:fda", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:fda", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:fda", @"Localizable", @"cocoaQemuWindow")];

		menu = [[NSMenu alloc] initWithTitle:@"fda"];
		menuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(@"toolbar:menuItem:fda:1", @"Localizable", @"cocoaQemuWindow") action:@selector(changeFda:) keyEquivalent:@""];
		[menuItem setTarget:pc];
		[menu addItem:menuItem];
		[menuItem release];		
		[menu addItem:[NSMenuItem separatorItem]];
		menuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(@"toolbar:menuItem:fda:2", @"Localizable", @"cocoaQemuWindow") action:@selector(ejectFda:) keyEquivalent:@""];
		[menuItem setTarget:pc];
		[menu addItem:menuItem];
		[menuItem release];

		popUpView = [[cocoaPopUpView alloc] initWithImage:[NSImage imageNamed: @"q_tb_fd.tiff"]];
		[popUpView setMenu:menu];
		[popUpView setToolbarItem:toolbarItem];
		[toolbarItem setView: popUpView];
		[popUpView release];
	} else if([itemIdent isEqual: @"fdbChangeIdentifier"]) {
		[toolbarItem setMinSize: NSMakeSize(32,32)];
		[toolbarItem setMaxSize: NSMakeSize(32,32)];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:fdb", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:fdb", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:fdb", @"Localizable", @"cocoaQemuWindow")];

		menu = [[NSMenu alloc] initWithTitle:@"fdb"];
		menuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(@"toolbar:menuItem:fdb:1", @"Localizable", @"cocoaQemuWindow") action:@selector(changeFdb:) keyEquivalent:@""];
		[menuItem setTarget:pc];
		[menu addItem:menuItem];
		[menuItem release];		
		[menu addItem:[NSMenuItem separatorItem]];
		menuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(@"toolbar:menuItem:fdb:2", @"Localizable", @"cocoaQemuWindow") action:@selector(ejectFdb:) keyEquivalent:@""];
		[menuItem setTarget:pc];
		[menu addItem:menuItem];
		[menuItem release];

		popUpView = [[cocoaPopUpView alloc] initWithImage:[NSImage imageNamed: @"q_tb_fd.tiff"]];
		[popUpView setMenu:menu];
		[popUpView setToolbarItem:toolbarItem];
		[toolbarItem setView: popUpView];
		[popUpView release];
	} else if([itemIdent isEqual: @"cdromChangeIdentifier"]) {
		[toolbarItem setMinSize: NSMakeSize(32,32)];
		[toolbarItem setMaxSize: NSMakeSize(32,32)];
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:cdrom", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:cdrom", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:cdrom", @"Localizable", @"cocoaQemuWindow")];
		
		menu = [[NSMenu alloc] initWithTitle:@"cdrom"];
		menuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(@"toolbar:menuItem:cdrom:1", @"Localizable", @"cocoaQemuWindow") action:@selector(useCdrom:) keyEquivalent:@""];
		[menuItem setTarget:pc];
		[menu addItem:menuItem];
		[menuItem release];
		menuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(@"toolbar:menuItem:cdrom:2", @"Localizable", @"cocoaQemuWindow") action:@selector(changeCdrom:) keyEquivalent:@""];
		[menuItem setTarget:pc];
		[menu addItem:menuItem];
		[menuItem release];
		[menu addItem:[NSMenuItem separatorItem]];
		menuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(@"toolbar:menuItem:cdrom:3", @"Localizable", @"cocoaQemuWindow") action:@selector(ejectCdrom:) keyEquivalent:@""];
		[menuItem setTarget:pc];
		[menu addItem:menuItem];
		[menuItem release];

		popUpView = [[cocoaPopUpView alloc] initWithImage:[NSImage imageNamed: @"q_tb_cdrom.tiff"]];
		[popUpView setMenu:menu];
		[popUpView setToolbarItem:toolbarItem];
		[toolbarItem setView: popUpView];
		[popUpView release];
	} else if([itemIdent isEqual: @"screenshotIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:screenshot", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:screenshot", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:screenshot", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_foto.tiff"]];
		[toolbarItem setTarget: pc];
		[toolbarItem setAction: @selector( screenshot )];
	} else if([itemIdent isEqual: @"cpuIdentifier"]) {
		[toolbarItem setMinSize: NSMakeSize(32,32)];
		[toolbarItem setMaxSize: NSMakeSize(32,32)];
		
//		cocoaCpuView *cpuView = [[cocoaCpuView alloc] initWithFrame:NSMakeRect(0.,0.,32.,32.)];
		cocoaCpuView *cpuView = [[cocoaCpuView alloc] initWithImage:[NSImage imageNamed: @"q_tb_cpu.tiff"]];
		
		[cpuView setToolbarItem:toolbarItem];
		[toolbarItem setView: cpuView];
		[cpuView release];
		
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:cpu", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:cpu", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:cpu", @"Localizable", @"cocoaQemuWindow")];
	} else if([itemIdent isEqual: @"pausePlayIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:pausePlay", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:pausePlay", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:pausePlay", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_pause.tiff"]];
		[toolbarItem setTarget: pc];
		[toolbarItem setAction: @selector( pausePlay: )];
	} else if([itemIdent isEqual: @"systemResetIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:resetPC", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:resetPC", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:resetPC", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_reset.tiff"]];
		[toolbarItem setTarget: pc];
		[toolbarItem setAction: @selector( resetPC )];
	} else if ([itemIdent isEqual: @"shutdownPCIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:shutdownPC", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:shutdownPC", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:shutdownPC", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_shutdown.tiff"]];
		[toolbarItem setTarget: pc];
		[toolbarItem setAction: @selector( shutdownPC )];
	} else if ([itemIdent isEqual: @"ctrlAltDelIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:ctrlAltDel", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:ctrlAltDel", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:ctrlAltDel", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_ctrlaltdel.tiff"]];
		[toolbarItem setTarget: pc];
		[toolbarItem setAction: @selector( ctrlAltDel: )];
	} else if ([itemIdent isEqual: @"fullscreenIdentifier"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:fullscreen", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:fullscreen", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:fullscreen", @"Localizable", @"cocoaQemuWindow")];
		[toolbarItem setImage: [NSImage imageNamed: @"q_tb_fullscreen.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( setFullscreen: )];
	} else {
		toolbarItem = nil;
	}
	
	return toolbarItem;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:
		@"fdaChangeIdentifier",
		@"fdbChangeIdentifier",
		@"cdromChangeIdentifier",
		@"systemResetIdentifier",
		@"shutdownPCIdentifier",
		@"screenshotIdentifier",
		@"cpuIdentifier",
		@"pausePlayIdentifier",
		@"ctrlAltDelIdentifier",
		@"fullscreenIdentifier",
		NSToolbarCustomizeToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		@"cdromChangeIdentifier",
		@"fullscreenIdentifier",
		@"screenshotIdentifier",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"cpuIdentifier",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"ctrlAltDelIdentifier",
		@"systemResetIdentifier",
		@"shutdownPCIdentifier",
		nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	return YES;
}

- (void)toolbarWillAddItem:(NSNotification *)notification
{
//	NSLog(@"will add item: %@", [[[notification userInfo] objectForKey:@"item"] itemIdentifier]);

    id tempView = [[[notification userInfo] objectForKey:@"item"] view];
	
	if ([[[[notification userInfo] objectForKey:@"item"] itemIdentifier] isEqual:@"cpuIdentifier"]) {
		cpuTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:tempView selector:@selector(updateToolbarItem:) userInfo:nil repeats:YES];
	}
}

- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
//	NSLog(@"did remove item: %@", [[[notification userInfo] objectForKey:@"item"] itemIdentifier]);
	
	if ([[[[notification userInfo] objectForKey:@"item"] itemIdentifier] isEqual:@"cpuIdentifier"]) {
		[cpuTimer invalidate];
	}
}

- (void) setMyContentView:(id)aContentView
{
	contentView = aContentView;
}

- (void) windowWillMiniaturize:(NSNotification *)aNotification
{
//	NSLog(@"cocoaQemuWindow: windowWillMiniaturize");

	/* OS X cant display openGL canvas during miniturize, so we draw it to a NSImageView */
	if ([contentView isKindOfClass:[cocoaQemuOpenGLView class]]) {
		imageView = [[NSImageView alloc] initWithFrame: [[self contentView] frame]];
		[imageView setImage: [contentView screenshot:NSMakeSize(0,0)]];
		[[self contentView] addSubview:imageView];
		[imageView display];	
	
		/* now we hide the contentView */
		[contentView setHidden:YES];
	}
}

- (void)miniaturize:(id)sender
{
//	NSLog(@"cocoaQemuWindow: miniaturize");

	if ([contentView isKindOfClass:[cocoaQemuQuickDrawView class]]) {
		 /* make the alpha channel opaque so anim won't have holes in it */
		[contentView refreshView];
	}
	
	[super miniaturize:sender];
}

- (void)display
{
//	NSLog(@"cocoaQemuWindow: display");

	if ([contentView isKindOfClass:[cocoaQemuQuickDrawView class]]) {
		/* make sure pixels are fully opaque */
		[contentView refreshView];
		
		/* save current visible SDL surface */
		[self cacheImageInRect:[contentView frame]];
		
		/* let the window manager redraw controls, border, etc */
		[super display];
		
		/* restore visible SDL surface */
		[self restoreCachedImage];
	} else {
		[super display];
	}
}

- (void) windowDidDeminiaturize:(NSNotification *)aNotification
{
//	NSLog(@"cocoaQemuWindow: windowDidDeminiaturize");

	if ([contentView isKindOfClass:[cocoaQemuOpenGLView class]]) {
		/* refresh openGLView */
		[contentView display];
		
		/* show contentView */
		[contentView setHidden:NO];
		
		/* get rid of NSImageView */
		[imageView removeFromSuperview];
	}
}

- (void) windowDidBecomeKey:(NSNotification *)aNotification
{
//	NSLog(@"cocoaQemuWindow: windowDidBecomeKey");

	/* start WM if required */
	if ([pc wMStopWhenInactive] && ![pc wMPausedByUser])
		[pc startVM];
		
    /* if we are fullscreen, reactivate tablet/grab (fix for virtueDesktop) */
    if ([pc fullscreen]) {
        if ([pc absolute_enabled]) {
            /* enable Tablet */
            if (![pc tablet_enabled]) {
                [NSCursor hide];
                [pc setTablet_enabled:1];
            }
        } else {
            /* grab Mouse */
            [pc grabMouse];
        }
    }
        
}

- (BOOL) windowIsVisible
{
    OSStatus oResult;
    int iActiveWorkspace;
    int iWindowWorkspace;
    CGSConnection oConnection = _CGSDefaultConnection();
    
    /* get active Workspace */
    oResult = CGSGetWorkspace(oConnection, &iActiveWorkspace);
    if (oResult) {
#ifdef QDEBUG
        NSLog(@"Failed getting active workspace [Error: %i]", oResult);
#endif
        return YES;
    }
    
    /* get window Workspace */
    oResult = CGSGetWindowWorkspace(oConnection, [self windowNumber], &iWindowWorkspace);
    if (oResult) {
#ifdef QDEBUG
        NSLog(@"Failed getting window workspace [Error: %i]", iActiveWorkspace, oResult);
#endif
        return YES;
    }
    
    /* is the window on the same workspace? */
    return (iActiveWorkspace == iWindowWorkspace);
}

- (void) windowDidResignKey:(NSNotification *)aNotification
{
//	NSLog(@"cocoaQemuWindow: windowDidResignKey");


    if ([pc fullscreen] && [self windowIsVisible]) {
//        [pc setFullscreen:[[pc contentView] toggleFullScreen]];
        
         /* setup transition */        CGSConnection cid = _CGSDefaultConnection();        int transitionHandle = -1;        CGSTransitionSpec transitionSpecifications;
                transitionSpecifications.type = 7;          //transition;
        transitionSpecifications.option = 0;        //option;        transitionSpecifications.wid = 0;           //wid        transitionSpecifications.backColour = 0;    //background color        /* freeze desktop: OSStatus CGSNewTransition(const CGSConnection cid, const CGSTransitionSpec* transitionSpecifications, int *transitionHandle) */        CGSNewTransition(cid, &transitionSpecifications, &transitionHandle);

        /* change monitor */
        [NSApp hide:self];
        
        /* wait */        usleep(10000);
        
        /* run transition: OSStatus CGSInvokeTransition(const CGSConnection cid, int transitionHandle, float duration) */        CGSInvokeTransition(cid, transitionHandle, 1.0);       
    }

    if ([pc absolute_enabled]) {
        /* disable Tablet */
        if ([pc tablet_enabled]) {
            [NSCursor unhide];
            [pc setTablet_enabled:0];
        }
    } else {
	   /* ungrab Mouse */
        [pc ungrabMouse];
    }
	
	/* reset Key Modifiers */
	[pc resetModifiers];

	/* stop WM if required */
	if ([pc wMStopWhenInactive])
		[pc stopVM];
}

- (BOOL) windowShouldClose:(id)sender
{
//	NSLog(@"cocoaQemuWindow: windowShouldClose");

	[pc shutdownPC];
	return NO;
}

- (void) setFullscreen:(id)sender;
{
//	NSLog(@"cocoaQemuWindow: setFullscreen");
    [pc setFullscreen:[[pc contentView] toggleFullScreen]];
}

@end
