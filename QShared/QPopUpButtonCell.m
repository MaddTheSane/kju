/*
 * Q QPopUpButtonCell
 * 
 * Copyright (c) 2008 Mike Kronenberg
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

#import "QPopUpButtonCell.h"



@implementation QPopUpButtonCell
- (id)initTextCell:(NSString *)stringValue buttonType:(QButtonCellType)aButtonType pullsDown:(BOOL)pullDown menu:(NSMenu *)menu image:(NSImage *)anImage
{
	Q_DEBUG(@"initImageCell");

	self = [self initTextCell:stringValue];
	if (self) {

		[self setMenu:menu];
		[self setPullsDown:pullDown];
		[self setBezelStyle:NSRegularSquareBezelStyle];
		[self setArrowPosition:NSPopUpNoArrow];

		image = anImage;
		[image setFlipped:TRUE];
		imageNormal = [[NSImage imageNamed:@"q_button_n"] retain];
		[imageNormal setFlipped:TRUE];

		buttonType = aButtonType;
	}
	return self;
}

- (void) dealloc
{
	[imageNormal release];
	[super dealloc];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	Q_DEBUG(@"drawBezelWithFrame");
	
	switch (buttonType) {
		case QButtonCellAlone:
			[imageNormal drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[imageNormal drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(36.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
		case QButtonCellLeft:
			[imageNormal drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[imageNormal drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(16.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
		case QButtonCellMiddle:
			[imageNormal drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(23.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[imageNormal drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(16.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
		case QButtonCellRight:
			[imageNormal drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(23.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[imageNormal drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(36.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
	}
	[imageNormal drawInRect:NSMakeRect(5.0, 0.0, frame.size.width-10.0, 19.0) fromRect:NSMakeRect(5.0, 0.0, 10.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
	[image drawInRect:NSMakeRect((frame.size.width - [image size].width) * 0.5 + 0.5, 1.0, [image size].width, [image size].height - 1) fromRect:NSMakeRect(0.0, 0.0, [image size].width, [image size].height) operation:NSCompositeSourceOver fraction:1.0];

}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	Q_DEBUG(@"drawTitle");

	//we draw no text
	return frame;
}
@end
