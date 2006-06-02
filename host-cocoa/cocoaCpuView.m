/*
 * QEMU Cocoa CpuView
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

#import "cocoaCpuView.h"

@implementation cocoaCpuView

- (void) encodeWithCoder:(NSCoder *) coder
{
//	NSLog(@"cocoaCpuView: encodeWithCoder");

	[super encodeWithCoder:coder];
	[coder encodeObject: [self image] forKey:@"regularImage"];
}

- (id) initWithCoder:(NSCoder *) coder
{
//	NSLog(@"cocoaCpuView: initWithCoder");

	if ((self = [super initWithCoder:coder])) {
		regularImage = [[coder decodeObjectForKey:@"regularImage"] retain];
		smallImage = nil;
		ctlSize = NSRegularControlSize;
		cpuUsage = 100;
		
		return self;
	}
	return nil;
}

- (id) initWithImage:(NSImage *) image
{
//	NSLog(@"cocoaPopUpView: initWithImage");

	if( ( self = [super initWithFrame:NSMakeRect(0.,0.,[image size].width,[image size].height)] ) ) {
		[self setImage:image];
		return self;
	}
	
	return nil;
}

- (void) dealloc
{
//	NSLog(@"cocoaCpuView: dealloc");

	[regularImage release];
	[smallImage release];

	regularImage = nil;
	smallImage = nil;

	[super dealloc];
}

- (void) drawRect:(NSRect) rect
{
//	NSLog(@"cocoaCpuView: drawRect");

	[[NSColor blackColor] set]; 
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];

	if( ctlSize == NSRegularControlSize ) {
		[regularImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
		[path moveToPoint:NSMakePoint(16, 0)];
		[path lineToPoint:NSMakePoint(16. - cos(pi / 180. * (40. + cpuUsage)) * 24., sin(pi / 180. * (40. + cpuUsage)) * 24.)];
	} else {
		[smallImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
		[path moveToPoint:NSMakePoint(12, 0)];
		[path lineToPoint:NSMakePoint(12. - cos(pi / 180. * (40. + cpuUsage)) * 16., sin(pi / 180. * (40. + cpuUsage)) * 16.)];
	}
	[path stroke];
	
}

- (void) mouseDown:(NSEvent *) theEvent
{
//	NSLog(@"cocoaCpuView: mouseDown");

}

- (NSControlSize) controlSize
{
//	NSLog(@"cocoaCpuView: controlSize");

	return ( ctlSize ? ctlSize : NSRegularControlSize );
}

- (void) setControlSize:(NSControlSize) controlSize {
	if( controlSize == NSRegularControlSize ) {
		[toolbarItem setMinSize:NSMakeSize( 32., 32. )];
		[toolbarItem setMaxSize:NSMakeSize( 32., 32. )];
	} else if( controlSize == NSSmallControlSize ) {
		[toolbarItem setMinSize:NSMakeSize( 24., 24. )];
		[toolbarItem setMaxSize:NSMakeSize( 24., 24. )];
	}
	ctlSize = controlSize;
}
- (NSImage *) image;
{
//	NSLog(@"cocoaPopUpView: image");

	return regularImage;
}

- (void) setImage:(NSImage *) image
{
//	NSLog(@"cocoaPopUpView: setImage");

	int i;
	BOOL g = false;
	BOOL s = false;

	NSArray *reps = [image representations];
	for (i=0; i<[reps count]; i++) {
		if ([[reps objectAtIndex:i] pixelsHigh] == 32) {
			[regularImage autorelease];
			regularImage = [[NSImage alloc] initWithSize:NSMakeSize( 32., 32. )];
			[regularImage addRepresentation:[reps objectAtIndex:i]];
			g = true;
		} else if ([[reps objectAtIndex:i] pixelsHigh] == 24) {
			[smallImage autorelease];
			smallImage = [[NSImage alloc] initWithSize:NSMakeSize( 24., 24. )];
			[smallImage addRepresentation:[reps objectAtIndex:i]];
			s = true;
		}
	}
	
	if (!g) {
		[regularImage autorelease];
		regularImage = [image copy];
	}
	
	if (!s) {
		NSImageRep *sourceImageRep = [image bestRepresentationForDevice:nil];
		[smallImage autorelease];
		smallImage = [[NSImage alloc] initWithSize:NSMakeSize( 24., 24. )];
		[smallImage lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[sourceImageRep drawInRect:NSMakeRect( 0., 0., 24., 24. )];
		[smallImage unlockFocus];
	}
}

- (NSToolbarItem *) toolbarItem
{
//	NSLog(@"cocoaCpuView: toolbarItem");

	return [[toolbarItem retain] autorelease];
}

- (void) setToolbarItem:(NSToolbarItem *) item {
	toolbarItem = item;
}

- (void) updateToolbarItem
{
//	NSLog(@"cocoaCpuView: updateToolbarItem");

	/* read cpu usage */ //ps o "pcpu" -p PID
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: @"/bin/ps"];
	NSArray *arguments = [NSArray arrayWithObjects: @"o", @"pcpu", @"-p", [NSString stringWithFormat:@"%D",[[NSProcessInfo processInfo]processIdentifier]], nil];
	[task setArguments: arguments];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	[task launch];
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	cpuUsage = [[string substringFromIndex:6] intValue];
	
	/* update Label */
	[toolbarItem setLabel:[NSString stringWithFormat:@"CPU %D%%", cpuUsage]];
	[toolbarItem setTitle:[NSString stringWithFormat:@"CPU %D%%", cpuUsage]];
	
	/* update Icon */
	[self setNeedsDisplay:YES];
	[self display];
}
@end
