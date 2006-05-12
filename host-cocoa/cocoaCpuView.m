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
}

- (id) initWithCoder:(NSCoder *) coder
{
//	NSLog(@"cocoaCpuView: initWithCoder");

	if ((self = [super initWithCoder:coder])) {
		ctlSize = NSRegularControlSize;
		cpuUsage = 100;
		return self;
	}
	return nil;
}

- (id) initWithFrame:(NSRect) frame
{
//	NSLog(@"cocoaCpuView: initWithFrame");

	if( ( self = [super initWithFrame:frame] ) ) {
		return self;
	}
	return nil;
}

- (void) drawRect:(NSRect) rect
{
//	NSLog(@"cocoaCpuView: drawRect");

	int lines;
	int width;
	int i = 0;
	
	if( ctlSize == NSRegularControlSize ) {
		lines = (int)(cpuUsage/100. * 32 / 3.);
		width = 32;;
	} else {
		lines = (int)(cpuUsage/100. * 24 / 3.);
		width = 24;
	}
	
	[[NSColor greenColor] set]; 
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];
	while (i < lines) {
		i++;
		[path moveToPoint:NSMakePoint(0, i*3)];
		[path relativeLineToPoint:NSMakePoint( width, 0)];
		[path stroke];
	}
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
//	NSLog(@"cocoaCpuView: awakeFromNib");

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
	
	/* update Icon */
	[self setNeedsDisplay:YES];
}
@end
