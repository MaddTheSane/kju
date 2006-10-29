/*
 * QEMU Cocoa openGL View
 * 
 * Copyright (c) 2005, 2006 Mike Kronenberg
 *							Peter Stewart
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

#import <ApplicationServices/ApplicationServices.h>

#import "cocoaQemu.h"

#import "cocoaQemuOpenGLView.h"

@interface cocoaQemuOpenGLView (privat)
- (void)initGL;
@end

@implementation cocoaQemuOpenGLView
- (id)initWithFrame:(NSRect)frameRect sender:(id)sender
{
//	NSLog(@OpenGLView: INIT\n");

	/* set pc */
	pc = sender;

	/* Init pixel format attribs */
	NSOpenGLPixelFormatAttribute openGLPixelFormatAttribute[] =
	{
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		0
	};

	/* Initialize the NSOpenGLPixelFormat */
	NSOpenGLPixelFormat *openGLPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:openGLPixelFormatAttribute];
	if (!openGLPixelFormat) {
		fprintf(stderr, "OpenGL: No pixel format -- exiting");
		exit(1);
	}

	/* create the the CocoaGL instance */
	self = [super initWithFrame:frameRect pixelFormat:openGLPixelFormat];
	[openGLPixelFormat release];
	if(!self) {
		fprintf(stderr, "OpenGL: Not Inititated -- exiting");
		exit(1);
	}

	[[self openGLContext] makeCurrentContext];
	
	[self initGL];

	/* drag'n'drop */
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];

	return self;
}

- (void) dealloc
{
//	NSLog(@OpenGLView: dealloc");

	/* drag'n'drop */
	[self unregisterDraggedTypes];

	[super dealloc];
}

- (void) initGL
{
//	NSLog(@OpenGLView: initGL");

	/* Set the background to black. */
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
}

- (BOOL) toggleFullScreen
{
//	NSLog(@OpenGLView: toggleFullScreen\n");

	/* fadeout */
	CGDisplayFadeReservationToken displayFadeReservation;
	CGAcquireDisplayFadeReservation (
		kCGMaxDisplayReservationInterval,
		&displayFadeReservation
	);
	CGDisplayFade (
		displayFadeReservation,
		0.5,						// 0.5 seconds
		kCGDisplayBlendNormal,		// starting state
		kCGDisplayBlendSolidColor,	// ending state
		0.0, 0.0, 0.0,				// black
		TRUE						// wait for completion
	);
	
	/* toggle Fullscreen */
	if(fullscreen) {
		
		[pc ungrabMouse];
		[FullScreenWindow close];
		[[pc pcWindow] setContentView: self];
		[[pc pcWindow] makeKeyAndOrderFront: self];
		fullscreen = false;
		
	} else {
		
		/* Create FullscreenWindow */
		FullScreenWindow = [[cocoaQemuWindow alloc] initWithContentRect:[[NSScreen mainScreen] frame]
			styleMask:NSBorderlessWindowMask
			backing:NSBackingStoreBuffered
			defer: NO];
		[FullScreenWindow setBackgroundColor:[NSColor blackColor]];
			
		if(FullScreenWindow != nil)
		{
			[FullScreenWindow setTitle: @"QEMU FullScreenWindow"];
			[FullScreenWindow setReleasedWhenClosed: YES];
			[FullScreenWindow setContentView: self];
			[FullScreenWindow makeKeyAndOrderFront:self];
		
			/* set the window to the uppermost level, ie, in front of the screensaver
				  Note that the user can no longer access windows beneath this one */
			[FullScreenWindow setLevel: NSScreenSaverWindowLevel - 1];
			[pc grabMouse];
			fullscreen = true;
		}
		
	}
	
	/* refresh openGLView */
	[self display];

	/* fadein. */
	CGDisplayFade (
		displayFadeReservation,
		0.5,						// 0.5seconds
		kCGDisplayBlendSolidColor,	// starting state
		kCGDisplayBlendNormal,		// ending state
		0.0, 0.0, 0.0,				// black
		FALSE						// don't wait for completion
	);
	CGReleaseDisplayFadeReservation (displayFadeReservation);
	
	return fullscreen;
}

- (void) openGLDrawRect:(NSRect) rect inRect:(NSRect) vPortRect
{
	float onePixel[2];
	onePixel[0] = 2.0/vPortRect.size.width;
	onePixel[1] = 2.0/vPortRect.size.height;
		
	glBegin(GL_QUADS);
	glVertex2f(rect.origin.x * onePixel[0] - 1, rect.origin.y * onePixel[1] - 1);
	glVertex2f(rect.origin.x * onePixel[0] - 1, (rect.origin.y + rect.size.height) * onePixel[1] - 1);
	glVertex2f((rect.origin.x + rect.size.width) * onePixel[0] - 1, (rect.origin.y + rect.size.height) * onePixel[1] - 1);
	glVertex2f((rect.origin.x + rect.size.width) * onePixel[0] - 1, rect.origin.y * onePixel[1] - 1);
	glEnd();
}

- (void) drawRect:(NSRect) rect
{
//	NSLog(@"OpenGLView: drawRect: %D x %D", (int)rect.size.width, (int)rect.size.height);

	/* Make this the current OpenGL context */
	[[self openGLContext] makeCurrentContext];

	/* Bind, update and draw new image */
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, screen_tex);

	/* glTexSubImage2D is faster when not using a texture range */
#if __LITTLE_ENDIAN__
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA,	(GLint)current_ds.width, (GLint)current_ds.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, current_ds.data);
#else
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA,	(GLint)current_ds.width, (GLint)current_ds.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, current_ds.data);
#endif

	/* Use the compiled display list */
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glCallList(display_list_tex);
	glDisable(GL_TEXTURE_RECTANGLE_EXT);


	/* drag'n'drop overlay */
	if (drag) {
		float onePixel[2];
		onePixel[0] = 2.0/rect.size.width;
		onePixel[1] = 2.0/rect.size.height;
		
		NSColor	 *rgbColor = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		glColor3f([rgbColor redComponent], [rgbColor greenComponent], [rgbColor blueComponent]);

		glBegin(GL_QUAD_STRIP);

		glVertex2f(-1.0, -1.0);
		glVertex2f(3 * onePixel[0] - 1, 3 * onePixel[1] - 1);

		glVertex2f(1.0, -1.0);
		glVertex2f((rect.size.width - 3) * onePixel[0] - 1, 3 * onePixel[1] - 1);

		glVertex2f(1.0, 1.0);
		glVertex2f((rect.size.width - 3) * onePixel[0] - 1, (rect.size.height - 3) * onePixel[1] - 1);

		glVertex2f(-1.0, 1.0);
		glVertex2f(3 * onePixel[0] - 1, (rect.size.height - 3) * onePixel[1] - 1);

		glVertex2f(-1.0, -1.0);
		glVertex2f(3 * onePixel[0] - 1, 3 * onePixel[1] - 1);

		glEnd();
	}
	
	/* paused overlay */
	if (![pc wMPaused]) {
		float px = rect.size.width/2 - 106;
		float py = rect.size.height/2 - 106;
		
		glEnable(GL_BLEND);
		
		glBlendFunc(GL_SRC_ALPHA,GL_ONE); 
		glBegin(GL_QUADS);
		glColor4f(1.0f, 1.0f, 1.0f, 0.25f);
		glVertex2f(-1.0, -1.0);
		glVertex2f(1.0, -1.0);
		glVertex2f(1.0, 1.0);
		glVertex2f(-1.0, 1.0);
		glEnd();

		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		glColor4f(0.0f, 0.0f, 0.0f, 0.25f);
		[self openGLDrawRect:NSMakeRect(px, py, 212, 212) inRect: rect];

		glDisable(GL_BLEND);
		
		glColor3f(1.0f, 1.0f, 1.0f);
		[self openGLDrawRect:NSMakeRect(px + 41, py + 41, 43, 129) inRect: rect];
		[self openGLDrawRect:NSMakeRect(px + 127, py + 41, 41, 129) inRect: rect];
	}

	/* Swap buffer to screen */
	[[self openGLContext] flushBuffer];
}

- (void) drawContent:(DisplayState *)ds
{
//	NSLog(@OpenGLView: drawcontent\n");

	[self display];
}

- (void) resizeContent:(DisplayState *)ds width:(int)w height:(int)h
{
//	NSLog(@OpenGLView: resizeContent\n");

	NSRect contentRect;
	contentRect = NSMakeRect (0, 0, w, h);
	
	[[pc pcWindow] setContentSize:contentRect.size];
	[[pc pcWindow] update];
		
	if (fullscreen) {
		[FullScreenWindow	 setContentView: self];	
		contentRect = [[NSScreen mainScreen] frame];
	}
	
	[[self openGLContext] makeCurrentContext];
	[[self openGLContext] update];
	
	glViewport(0, 0, (int) contentRect.size.width, (int)  contentRect.size.height);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	/* This is used as a init'd flag as well... */
	if( screen_tex != 0) {
		glDeleteTextures(1, &screen_tex);
		glDeleteLists( display_list_tex, 1);
	}
	
	screen_tex = 1;
	
	if(ds->data != NULL) free(ds->data);
	ds->data = (GLubyte *) malloc(w * h * (SCREEN_BPP >> 3));
	assert(ds->data != NULL);
	ds->linesize = w * (SCREEN_BPP >> 3);
	ds->depth = SCREEN_BPP;
	ds->width = w;
	ds->height = h;
	
	current_ds = *ds;

	/* Setup some basic OpenGL stuff as from Apple */
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, screen_tex);

	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT,	w * h *	(SCREEN_BPP >> 3), ds->data);

	/* Use CACHED for VRAM+reused tex Use SHARED for AGP+used once tex
		Note the texture is always changing so use SHARED */
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);

#if __LITTLE_ENDIAN__
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, ds->data);
#else
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, w, h, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, ds->data);
#endif

	glFlush();

	/* Setup a display list to save all the operations below */
	display_list_tex = glGenLists(1);
	glNewList(display_list_tex, GL_COMPILE);

	glBegin(GL_QUADS);

	glTexCoord2f(0.0f, 0.0f);
	glVertex2f(-1.0f, 1.0f);

	glTexCoord2f(0.0f, (GLfloat)h);
	glVertex2f(-1.0f, -1.0f);

	glTexCoord2f((GLfloat)w, (GLfloat)h);
	glVertex2f(1.0f, -1.0f);

	glTexCoord2f((GLfloat)w, 0.0f);
	glVertex2f(1.0f, 1.0f);

	glEnd();

	glEndList();
	
	/* Setup a display list to save the Screenshot (This is just a vertical Inverted Copy) */
	display_list_tmb = glGenLists(1);
	glNewList(display_list_tmb, GL_COMPILE);

	glBegin(GL_QUADS);

	glTexCoord2f(0.0f, (GLfloat)h);
	glVertex2f(-1.0f, 1.0f);

	glTexCoord2f(0.0f, 0.0f);
	glVertex2f(-1.0f, -1.0f);

	glTexCoord2f((GLfloat)w, 0.0f);
	glVertex2f(1.0f, -1.0f);

	glTexCoord2f((GLfloat)w, (GLfloat)h);
	glVertex2f(1.0f, 1.0f);

	glEnd();
	
	glEndList();
}

- (NSImage *) screenshot:(NSSize)size
{
//	NSLog(@OpenGL: Thumbnail width:%d height:%d\n", (int)size.width, (int)size.height);

	/* if no size is set, make fullsize shot */
	if (!size.width || !size.height)
		size = [self bounds].size;
	
	NSSize originalSize = [self bounds].size;

	NSBitmapImageRep* bitmapImageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
		pixelsWide:size.width
		pixelsHigh:size.height
		bitsPerSample:8
		samplesPerPixel:3
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSDeviceRGBColorSpace
		bytesPerRow:(size.width*4)
		bitsPerPixel:32] autorelease];

	/* resize and flip TO BE DONE OFFSCREEN */
	glViewport(0,0,size.width,size.height);
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glCallList(display_list_tmb);
	glDisable(GL_TEXTURE_RECTANGLE_EXT);

	/* read pixels */
#if __LITTLE_ENDIAN__
	glReadPixels(0, 0, size.width, size.height, GL_RGBA, GL_UNSIGNED_BYTE, [bitmapImageRep bitmapData]);
#else
	glReadPixels(0, 0, size.width, size.height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, [bitmapImageRep bitmapData]);
#endif

	/* reset glViewport to original Size */
	glViewport(0,0,originalSize.width,originalSize.height);
	[self display];
	
	NSImage* image = [[[NSImage alloc] initWithSize:NSMakeSize(size.width, size.height)] autorelease];
	[image addRepresentation:bitmapImageRep];

	return image;
}

- (void) mouseDown:(NSEvent *)theEvent
{
//	NSLog(@cocoaOpenGLView: mouseDown\n");

	/* Mouse-grab is activatet by clicks in Windowed View only,
		so we can handle clicks on other GUI Items */
	if(fullscreen) {
	   /* exception: if the user activated the toolbar, mouse grab is released; so when he clicks on fullscreen view we have to grab again */
	   if([pc fullscreenController] && [[pc fullscreenController] showsToolbar]) {
	       [[pc fullscreenController] toggleToolbar];
	       [pc grabMouse];
	   }
	} else if([pc absolute_enabled]) {
        if (![pc tablet_enabled])
            [NSCursor hide];
        [pc setTablet_enabled:1];
    } else {
		[pc grabMouse];
    }
}

/* drag'n'drop */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
//	NSLog(@"cocoaOpenGLView: draggingEntered");

	if ((NSDragOperationCopy & [sender draggingSourceOperationMask]) == NSDragOperationCopy)
	{
		/* show border */
		drag = true;
		[self display];
		
		return NSDragOperationCopy;
	} else {
		return NSDragOperationNone;
	}
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
//	NSLog(@"cocoaOpenGLView: draggingExited");

	/* hide border */
	drag = false;
	[self display];
}

- (void) draggingEnded:(id <NSDraggingInfo>)sender
{
//	NSLog(@"cocoaOpenGLView: draggingEnded");

	/* hide border */
	drag = false;
	[self display];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"prepareForDragOperation");
	return true;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
//	NSLog(@"performDragOperation");
	
	NSPasteboard *paste = [sender draggingPasteboard];
	NSArray *types = [NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil];
	NSString *desiredType = [paste availableTypeFromArray:types];
	NSData *carriedData = [paste dataForType:desiredType];

	if (nil == carriedData)
	{
		NSRunAlertPanel(@"Paste Error", @"Sorry, but the past operation failed", 
			nil, nil, nil);
		return NO;
	}
	else
	{
		if ([desiredType isEqualToString:NSFilenamesPboardType])
		{
			NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
//			  [[pc pcWindow] makeKeyAndOrderFront: self];
			/* copy all dragged Files into smb folder */
			if ([pc smbPath]) {
				int i;
				NSFileManager *fileManager = [NSFileManager defaultManager];
				for (i=0; i<[fileArray count]; i++) {
					[fileManager copyPath:[fileArray objectAtIndex:i] toPath:[NSString stringWithFormat:@"%@/%@", [pc smbPath], [[fileArray objectAtIndex:i] lastPathComponent]] handler:nil]; 
				}
			}
		}
		else
		{
			NSAssert(NO, @"This can't happen");
			return NO;
		}
	}
	return YES;
}

- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
//	NSLog(@"concludeDragOperation");

	/* hide border */
	drag = false;
	[self display];
}
@end

