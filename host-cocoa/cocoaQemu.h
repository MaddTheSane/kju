/*
 * QEMU Cocoa display driver
 * 
 * Copyright (c) 2005 - 2007 Pierre d'Herbemont
 *							 Mike Kronenberg
 *							 many code/inspiration from SDL 1.2 code (LGPL)
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

#import <paths.h>
#import <sys/param.h>
#import <IOKit/IOBSD.h>
#import <IOKit/storage/IOMediaBSDClient.h>
#import <IOKit/storage/IOMedia.h>
#import <IOKit/storage/IOCDMedia.h>

#import <OpenGL/CGLCurrent.h>
#import <OpenGL/CGLContext.h>

#import "../qemu-common.h"
#import "../../../q/qcontrol/cocoaControlDOServer.h"
#import "cocoaQemuProgressWindow.h"
#import "cocoaQemuOpenGLView.h"
#import "FSControls/FSController.h"

/*
 ------------------------------------------------------
 	QemuCocoaPcWindowView
 ------------------------------------------------------
*/
@interface cocoaQemu : NSObject <cocoaControlDOGuestProto>
{
	/* Q distributed Object Server */
	id <cocoaControlDOServerProto> qdoserver;

	/* pc */
	NSString *pcName;
	NSString *pcWindowName;
	NSString *pcStatus;
	NSString *pcPath;
	NSString *smbPath;
	NSTimer *pcTimer;
	NSTimer *progressWindowTimer;
	id thisPC;
	BOOL WMSupportsSnapshots;
	BOOL WMStopWhenInactive;
	BOOL wMPausedByUser;
	BOOL wMPaused;
	BOOL pcDialogs;
	BOOL fullscreen;
	BOOL grab;
	BOOL absolute_enabled;
	BOOL tablet_enabled;
	int modifiers_state[256];
	
	NSArray	*fileTypes; //allowed filetypes
	
	/* pcWindow */
	cocoaQemuWindow *pcWindow;
	BOOL pcOpenGLView;
	id contentView;
	
	/* progressWindow */
	cocoaQemuProgressWindow *progressWindow;
	
	/* FullscreenController */
    FSController * fullscreenController;
}
/* init & dealloc */
- (id) init;
- (void) dealloc;

/* getters & setters */
- (NSString *) pcName;
- (NSString *) pcWindowName;
- (NSString *) smbPath;
- (id) qdoserver;
- (int) modifierAtIndex:(int)index;
- (BOOL) fullscreen;
- (void) setFullscreen:(BOOL)val;
- (id) fullscreenController;
- (void) setFullscreenController:(id)controller;
- (BOOL) grab;
- (BOOL) absolute_enabled;
- (BOOL) tablet_enabled;
- (BOOL) wMStopWhenInactive;
- (BOOL) wMPaused;
- (BOOL) wMPausedByUser;
- (void) setGrab:(BOOL)val;
- (void) setAbsolute_enabled:(BOOL)val;
- (void) setTablet_enabled:(BOOL)val;
- (void) setModifierAtIndex:(int)index to:(int)value;
- (void) resetModifiers;
- (id) pcWindow;
- (id) contentView;
- (void) liveThumbnail;
- (void) closeProgressWindow;

/* pc */
- (void) grabMouse;
- (void) ungrabMouse;
- (void) stopVM;
- (void) startVM;
- (void) saveVM;
- (void) startPCWithArgs:(id)arguments;

/* pcWindow toolbar selectors */
- (void) changeFda:(id)sender;
- (void) changeFdb:(id)sender;
- (void) changeCdrom:(id)sender;
- (void) changeDeviceSheetDidEnd: (NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(NSString *)contextInfo;

- (void) useCdrom: (id)sender;
- (void) ejectFda: (id)sender;
- (void) ejectFdb: (id)sender;
- (void) ejectCdrom: (id)sender;
- (void) pausePlay: (id)sender;
- (void) ctrlAltDel: (id)sender;

- (int) ejectDevice: (BlockDriverState *) bs withForce: (int) force;
- (void) ejectImage:(const char *) filename withForce: (int) force;
- (void) changeDeviceImage: (const char *) device filename: (const char *) filename withForce: (int) force;

- (void) shutdownPC;
- (void) shutdownPCSheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void) shutdownPC2SheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (void *)contextInfo;
- (void) resetPC;

- (void) screenshot;
@end
