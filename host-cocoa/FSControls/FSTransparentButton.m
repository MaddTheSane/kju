#import "FSTransparentButton.h"

@implementation FSTransparentButton

- (BOOL) acceptsFirstResponder
{
	return YES;
}

- (void) drawRect:(NSRect)rect
{
	[SEMI_TRANSPARENT_COLOR set];
	NSRectFill(rect);
	[super drawRect:rect];
}

@end
