/*
 * QEMU Cocoa Quickdraw View
 * 
 * Copyright (c) 2005, 2006 Pierre d'Herbemont
 *							Mike Kronenberg
 *							many code/inspiration from SDL 1.2 code (LGPL)
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

#import "cocoaQemuQuickDrawView.h"

@implementation cocoaQemuQuickDrawView
- (id)initWithFrame:(NSRect)frameRect sender:(id)sender
{
//	NSLog(@"QuickDrawView: init");

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
//	NSLog(@"QuickDrawView: dealloc");

	/* drag'n'drop */
	[self unregisterDraggedTypes];
	
	[super dealloc];
}

- (BOOL) toggleFullScreen
{
//	NSLog(@"QuickDrawView: toggleFullScreen");

	return false;
}

- (void) refreshView
{
//	NSLog(@"QuickDrawView: refreshView");

	/* Assume 32 bit if( bpp == 32 )*/
	if ( 1 ) {
	
		uint32_t	*pixels = (uint32_t*) current_ds.data;
		uint32_t	rowPixels = current_ds.linesize / 4;
		uint32_t	i, j;
		
		for (i = 0; i < current_ds.height; i++)
			for (j = 0; j < current_ds.width; j++) {
		
				pixels[(i * rowPixels) + j] |= 0xFF000000;
			}
	}
}

- (void) drawContent:(DisplayState *)ds
{
//	NSLog(@"QuickDrawView: drawcontent");

	NSRect contentRect = [self frame];
	/* Use QDFlushPortBuffer() to flush content to display */
	RgnHandle dirty = NewRgn ();
	RgnHandle temp	= NewRgn ();

	SetEmptyRgn (dirty);

	/* Build the region of dirty rectangles */
	MacSetRectRgn (temp, contentRect.origin.x, contentRect.origin.y, contentRect.size.width, contentRect.size.height);
	MacUnionRgn (dirty, temp, dirty);
				
	/* Flush the dirty region */
	QDFlushPortBuffer ( [self  qdPort], dirty );
	DisposeRgn (dirty);
	DisposeRgn (temp);
}

- (void) resizeContent:(DisplayState *)ds width:(int)w height:(int)h
{
//	NSLog(@"QuickDrawView: resizeContent");
	
	const int device_bpp = 32;
	static void *screen_pixels;
	static int	screen_pitch;
	
	[[pc pcWindow] setContentSize:NSMakeSize(w,h)];
	[[pc pcWindow] update];

	/* Careful here, the window seems to have to be onscreen to do that */
	LockPortBits ( [self qdPort] );
	screen_pixels = GetPixBaseAddr ( GetPortPixMap ( [self qdPort] ) );
	screen_pitch  = GetPixRowBytes ( GetPortPixMap ( [self qdPort] ) );
	UnlockPortBits ( [self qdPort] );
	{ 
			int vOffset = [[pc pcWindow] frame].size.height - [self frame].size.height - [self frame].origin.y;
			int hOffset = [self frame].origin.x;
			
		   screen_pixels += (vOffset * screen_pitch) + hOffset * (device_bpp/8);
	}
	ds->data = screen_pixels;
	ds->linesize = screen_pitch;
	ds->depth = device_bpp;
	ds->width = w;
	ds->height = h;
	
	current_ds = *ds;
}

- (NSImage *) screenshot:(NSSize)size
{
//	NSLog(@"QuickDrawView: Thumbnail width:%d height:%d\n", (int)size.width, (int)size.height);

	/* if no size is set, make fullsize shot */
	if (!size.width || !size.height)
		size = [self bounds].size;
	
//	NSSize originalSize = [self bounds].size;

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
//	glViewport(0,0,size.width,size.height);
//	glCallList(display_list_tmb);
	
	/* read pixels */
//	glReadPixels(0, 0, size.width, size.height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, [bitmapImageRep bitmapData]);

	/* reset glViewport to original Size */
//	glViewport(0,0,originalSize.width,originalSize.height);
	
	NSImage* image = [[[NSImage alloc] initWithSize:NSMakeSize(size.width, size.height)] autorelease];
	[image addRepresentation:bitmapImageRep];

	return image;
}

- (void) mouseDown:(NSEvent *)theEvent
{
//	NSLog(@"QuickDrawView: mouseDown");
	
	/* Mouse-grab is activatet by clicks in Windowed View only,
		so we can handle clicks on other GUI Items */
	if(!fullscreen && ![pc absolute_enabled])
		[pc grabMouse];
}

/* drag'n'drop */
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
//	NSLog(@"QuickDrawView: draggingEntered");

	if ((NSDragOperationCopy & [sender draggingSourceOperationMask]) == NSDragOperationCopy)
	{
		/* show border */
		
		return NSDragOperationCopy;
	} else {
		return NSDragOperationNone;
	}
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
//	NSLog(@"QuickDrawView: draggingExited");

	/* hide border */
	
}

- (void) draggingEnded:(id <NSDraggingInfo>)sender
{
//	NSLog(@"QuickDrawView: draggingEnded");

	/* hide border */
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

}
@end

