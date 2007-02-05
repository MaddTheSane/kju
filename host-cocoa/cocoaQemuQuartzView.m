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
 
#import "cocoaQemu.h"

#import "cocoaQemuQuartzView.h"

#define cgrect(nsrect) (*(CGRect *)&(nsrect))

@implementation cocoaQemuQuartzView
- (id)initWithFrame:(NSRect)frameRect sender:(id)sender
{
//	NSLog(@"quartzView: init");

	/* set pc */
	pc = sender;
	
	if ((self = [super initWithFrame:frameRect])) {
	
		/* drag'n'drop */
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
		
		return self;
	}
	return nil;
}

- (void) dealloc
{
//	NSLog(@"quartzView: dealloc");

	/* drag'n'drop */
	[self unregisterDraggedTypes];

	/* free memory */
	if (screen_pixels)
		free(screen_pixels);
	if (dataProviderRef)
		CGDataProviderRelease(dataProviderRef);

	[super dealloc];
}

- (void) drawRect:(NSRect) rect
{
//	NSLog(@"quartzView: drawRect: %D x %D", (int)rect.size.width, (int)rect.size.height);

	/* get CoreGraphic context */
	CGContextRef viewContextRef = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetInterpolationQuality (viewContextRef, kCGInterpolationNone);
	CGContextSetShouldAntialias (viewContextRef, NO);
	
	/* draw screen bitmap directly to Core Graphics context */
	if (dataProviderRef) {
		CGImageRef imageRef = CGImageCreate(
			current_ds.width, //width
			current_ds.height, //height
			8, //bitsPerComponent
			32, //bitsPerPixel
			(current_ds.width * 4), //bytesPerRow
#if __LITTLE_ENDIAN__
			CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), //colorspace for OX S >= 10.4
			kCGImageAlphaNoneSkipLast,
#else
			CGColorSpaceCreateDeviceRGB(), //colorspace for OS X < 10.4 (actually ppc)
			kCGImageAlphaNoneSkipFirst, //bitmapInfo
#endif
			dataProviderRef, //provider
			NULL, //decode
			0, //interpolate
			kCGRenderingIntentDefault //intent
		);
        
        /* new selective drawing code */
        if (CGImageCreateWithImageInRect != NULL) {
        
            /* new selective drawing code (draws only dirty rectangles) (Tiger) */
            const NSRect *rectList;
            int rectCount;
            int i;
            CGImageRef clipImageRef;
            CGRect clipRect;
            float dx;
            float dy;
            
            dx = [self frame].size.width / current_ds.width;
            dy = [self frame].size.height / current_ds.height;
        
            [self getRectsBeingDrawn:&rectList count:&rectCount];
            for (i = 0; i < rectCount; i++) {
                clipRect.origin.x = rectList[i].origin.x / dx;
                clipRect.origin.y = current_ds.height - (rectList[i].origin.y + rectList[i].size.height) / dy;
                clipRect.size.width = rectList[i].size.width / dx;
                clipRect.size.height = rectList[i].size.height / dy;
            
                clipImageRef = CGImageCreateWithImageInRect(
                    imageRef,
                    clipRect
                );
                CGContextDrawImage (viewContextRef, cgrect(rectList[i]), clipImageRef);
                CGImageRelease (clipImageRef);
            }
            
        } else {
        
            /* old drawing code (draws everything) (Panther) */
            CGContextDrawImage (viewContextRef, CGRectMake(0, 0, [self bounds].size.width, [self bounds].size.height), imageRef);

        }
		CGImageRelease (imageRef);
	}
	
	/* draw overlays directly to Core Cgraphics context */
	
	/* drag'n'drop overlay */
	if (drag) {
		NSColor	 *rgbColor = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];

		CGContextSetLineWidth (viewContextRef, 4);
		CGContextSetRGBStrokeColor (viewContextRef, [rgbColor redComponent], [rgbColor greenComponent], [rgbColor blueComponent], 1);
		CGContextStrokeRect (viewContextRef, CGRectMake (2, 2, rect.size.width - 4, rect.size.height - 4));
	}

	/* paused overlay */
	if (![pc wMPaused]) {

		float px = rect.size.width/2 - 106;
		float py = rect.size.height/2 - 106;
		
		CGContextSetRGBFillColor (viewContextRef, 1, 1, 1, 0.25);
		CGContextFillRect (viewContextRef, CGRectMake (0, 0, rect.size.width, rect.size.height));

		CGContextSetShouldAntialias (viewContextRef, YES);

		CGContextSetRGBFillColor (viewContextRef, 0, 0, 0, 0.25);
		CGContextBeginPath (viewContextRef);
		CGContextMoveToPoint (viewContextRef, px, py + 20);
		CGContextAddArcToPoint (viewContextRef, px, py, px + 20, py, 20);
		CGContextAddLineToPoint (viewContextRef, px + 192, py);
		CGContextAddArcToPoint (viewContextRef, px + 212, py, px + 212, py + 20, 20);
		CGContextAddLineToPoint (viewContextRef, px + 212, py + 192);
		CGContextAddArcToPoint (viewContextRef, px + 212, py + 212, px + 192, py + 212, 20);
		CGContextAddLineToPoint (viewContextRef, px + 20, py + 212);
		CGContextAddArcToPoint (viewContextRef, px, py + 212, px, py + 192, 20);
		CGContextAddLineToPoint (viewContextRef, px, py + 20);
		CGContextClosePath (viewContextRef);
		CGContextDrawPath (viewContextRef, kCGPathFill);

		CGContextSetShadow (viewContextRef, CGSizeMake (0, -2), 4);
		CGContextSetRGBFillColor (viewContextRef, 1, 1, 1, 1);
		CGContextFillRect (viewContextRef, CGRectMake (px + 41, py + 41 , 43, 129));
		CGContextFillRect (viewContextRef, CGRectMake (px + 127, py + 41 , 41, 129));
	}
}

- (BOOL) toggleFullScreen
{
//	NSLog(@"quartzView: toggleFullScreen");

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

- (void) resizeContent:(DisplayState *)ds width:(int)w height:(int)h
{
//	NSLog(@"quartzView: resizeContent width:%d height:%d", w, h);
		
	[[pc pcWindow] setContentSize:NSMakeSize(w,h)];
	[[pc pcWindow] update];
	
	if(fullscreen)
		[FullScreenWindow setContentView: self];

	/* cleanup */
	if (dataProviderRef)
		CGDataProviderRelease(dataProviderRef);
	if (screen_pixels)
		free(screen_pixels);
		
	screen_pixels = malloc( w * 4 * h );
	dataProviderRef = CGDataProviderCreateWithData(NULL, screen_pixels, w * 4 * h, NULL);

	ds->data = screen_pixels;
	ds->linesize = (w * 4);
	ds->depth = 32;
	ds->width = w;
	ds->height = h;

	current_ds = *ds;
}

- (NSImage *) screenshot:(NSSize)size
{
//	NSLog(@"quartzView: Thumbnail width:%d height:%d\n", (int)size.width, (int)size.height);

	/* if no size is set, make fullsize shot */
	if (!size.width || !size.height)
		size = [self bounds].size;

	NSBitmapImageRep* sBitmapImageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
		pixelsWide:size.width
		pixelsHigh:size.height
		bitsPerSample:8
		samplesPerPixel:3
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSDeviceRGBColorSpace
		bytesPerRow:(size.width*4)
		bitsPerPixel:32] autorelease];
	
	NSImage* image = [[[NSImage alloc] initWithSize:NSMakeSize(size.width, size.height)] autorelease];
	[image addRepresentation:sBitmapImageRep];
		
	[image lockFocusOnRepresentation:sBitmapImageRep];

	/* setup CG */
	CGContextRef viewContextRef = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetInterpolationQuality (viewContextRef, kCGInterpolationNone);
	CGContextSetShouldAntialias (viewContextRef, NO);

	/*draw screen bitmap directly to Core Graphics context */
	if (dataProviderRef) {
		CGImageRef imageRef = CGImageCreate(
			current_ds.width, //width
			current_ds.height, //height
			8, //bitsPerComponent
			32, //bitsPerPixel
			(current_ds.width * 4), //bytesPerRow
#if __LITTLE_ENDIAN__
			CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), //colorspace for OX S >= 10.4
			kCGImageAlphaNoneSkipLast,
#else
			CGColorSpaceCreateDeviceRGB(), //colorspace for OS X < 10.4 (actually ppc)
			kCGImageAlphaNoneSkipFirst, //bitmapInfo
#endif
			dataProviderRef, //provider
			NULL, //decode
			0, //interpolate
			kCGRenderingIntentDefault //intent
		);
		CGContextDrawImage (viewContextRef, CGRectMake(0, 0, size.width, size.height), imageRef);
		CGImageRelease (imageRef);
	}
	
	[image unlockFocus];

	return image;
}

- (void) mouseDown:(NSEvent *)theEvent
{
//	NSLog(@"quartzView: mouseDown");

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
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
//	NSLog(@"quartzView: draggingEntered");

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
//	NSLog(@"quartzView: draggingExited");

	/* hide border */
	drag = false;
	[self display];
}

- (void) draggingEnded:(id <NSDraggingInfo>)sender
{
//	NSLog(@"quartzView: draggingEnded");

	/* hide border */
	drag = false;
	[self display];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
//	NSLog(@"prepareForDragOperation");

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