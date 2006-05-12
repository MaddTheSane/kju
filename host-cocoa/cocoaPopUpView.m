/*
 * QEMU Cocoa PopUpView
 * 
 * Copyright (c) 2005, 2006 Mike Kronenberg
 *                    inspired by cocoadev.com, Colloqui, Adium
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

#import "cocoaPopUpView.h"

@implementation cocoaPopUpView

- (void) encodeWithCoder:(NSCoder *) coder
{
//	NSLog(@"cocoaPopUpView: encodeWithCoder");

	[super encodeWithCoder:coder];
	[coder encodeObject: [self image] forKey:@"regularImage"];
}

- (id) initWithCoder:(NSCoder *) coder
{
//	NSLog(@"cocoaPopUpView: initWithCoder");

	if ((self = [super initWithCoder:coder])) {
		
		menu = nil;
		regularImage = [[coder decodeObjectForKey:@"regularImage"] retain];
		smallImage = nil;
		toolbarItem = nil;
		ctlSize = NSRegularControlSize;
		
		return self;
	}
	return nil;
}

- (id) initWithImage:(NSImage *) image
{
//	NSLog(@"cocoaPopUpView: initWithImage");

	if( ( self = [super initWithFrame:NSMakeRect(0.,0.,[image size].width+6,[image size].height)] ) ) {
		[self setImage:image];
		return self;
	}
	return nil;
}

- (void) dealloc
{
//	NSLog(@"cocoaPopUpView: dealloc");

	[regularImage release];
	[smallImage release];

	regularImage = nil;
	smallImage = nil;
	toolbarItem = nil;

	[super dealloc];
}

- (void) drawRect:(NSRect) rect
{
//	NSLog(@"cocoaPopUpView: drawRect: %D x %D", (int)rect.size.width, (int)rect.size.height);

	NSBezierPath *path = [NSBezierPath bezierPath];

	if( ctlSize == NSRegularControlSize ) {
		[regularImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
		[path moveToPoint:NSMakePoint(32, 5)]; 
		[path relativeLineToPoint:NSMakePoint( 6, 0 )];
		[path relativeLineToPoint:NSMakePoint( -3, -5 )];
	} else if( ctlSize == NSSmallControlSize ) {
		[smallImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
		[path moveToPoint:NSMakePoint(24, 3)];  
		[path relativeLineToPoint:NSMakePoint( 4, 0 )];
		[path relativeLineToPoint:NSMakePoint( -2, -3 )];
	}

	[path closePath];
	[[[NSColor blackColor] colorWithAlphaComponent:0.75] set];
	[path fill];
}

- (void) mouseDown:(NSEvent *) theEvent
{
//	NSLog(@"cocoaPopUpView: mouseDown");
	
	NSEvent *newEvent = [NSEvent mouseEventWithType: [theEvent type]
		location: [self convertPoint:[self bounds].origin toView:nil]
		modifierFlags: [theEvent modifierFlags]
		timestamp: [theEvent timestamp]
		windowNumber: [theEvent windowNumber]
		context: [theEvent context]
		eventNumber: [theEvent eventNumber]
		clickCount: [theEvent clickCount]
		pressure: [theEvent pressure]];
	    
	[NSMenu popUpContextMenu: menu  withEvent: newEvent  forView: self];
}

- (NSControlSize) controlSize
{
//	NSLog(@"cocoaPopUpView: controlSize");

	return ( ctlSize ? ctlSize : NSRegularControlSize );
}

- (void) setControlSize:(NSControlSize) controlSize
{
//	NSLog(@"cocoaPopUpView: setControlSize");

	if( controlSize == NSRegularControlSize ) {
		[toolbarItem setMinSize:NSMakeSize( 38., 32. )];
		[toolbarItem setMaxSize:NSMakeSize( 38., 32. )];
	} else if( controlSize == NSSmallControlSize ) {
		[toolbarItem setMinSize:NSMakeSize( 28., 24. )];
		[toolbarItem setMaxSize:NSMakeSize( 28., 24. )];
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
//	NSLog(@"cocoaPopUpView: toolbarItem");

	return [[toolbarItem retain] autorelease];
}

- (void) setToolbarItem:(NSToolbarItem *) item {
	toolbarItem = item;
}

-(NSMenu *)menu
{
//	NSLog(@"cocoaPopUpView: menu");

	return menu;
}

-(void)setMenu:(NSMenu *)aMenu
{
//	NSLog(@"cocoaPopUpView: setMenu");

	menu = aMenu;
}
@end
