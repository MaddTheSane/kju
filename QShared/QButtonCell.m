/*
 * Q ButtonCell
 * 
 * Copyright (c) 2007 - 2008 Mike Kronenberg
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

#import "QButtonCell.h"


@implementation QButtonCell
- (instancetype)initImageCell:(NSImage *)anImage
{
	Q_DEBUG(@"initImageCell");

	self = [super initImageCell:anImage];
	if (self) {
		imageNormal = [NSImage imageNamed:@"q_button_n"];
		[imageNormal setFlipped:TRUE];
		imagePressed = [NSImage imageNamed:@"q_button_p"];
		[imagePressed setFlipped:TRUE];
		[self.image setFlipped:TRUE];
		self.bezelStyle = NSRegularSquareBezelStyle;
	}
	return self;
}

- (instancetype)initImageCell:(NSImage *)anImage buttonType:(QButtonCellType)aButtonType target:(id)aTarget action:(SEL)anAction
{
	Q_DEBUG(@"initImageCell");

	self = [self initImageCell:anImage];
	if (self) {
		buttonType = aButtonType;
		self.target = aTarget;
		self.action = anAction;
	}
	return self;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	Q_DEBUG(@"drawBezelWithFrame");

	NSImage *bgImage;
	
	if (self.state == NSOffState) {
		bgImage = imageNormal;
	} else {
		bgImage = imagePressed;
	}
	
	switch (buttonType) {
		case QButtonCellAlone:
			[bgImage drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[bgImage drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(36.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
		case QButtonCellLeft:
			[bgImage drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[bgImage drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(16.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
		case QButtonCellMiddle:
			[bgImage drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(23.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[bgImage drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(16.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
		case QButtonCellRight:
			[bgImage drawInRect:NSMakeRect(0.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(23.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			[bgImage drawInRect:NSMakeRect(frame.size.width - 5.0, 0.0, 5.0, 19.0) fromRect:NSMakeRect(36.0, 0.0, 5.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
			break;
	}
	[bgImage drawInRect:NSMakeRect(5.0, 0.0, frame.size.width-10.0, 19.0) fromRect:NSMakeRect(5.0, 0.0, 10.0, 19.0) operation:NSCompositeSourceOver fraction:1.0];
	[self.image drawInRect:NSMakeRect((frame.size.width - self.image.size.width) * 0.5 + 0.5, 1.0, self.image.size.width, self.image.size.height - 1) fromRect:NSMakeRect(0.0, 0.0, self.image.size.width, self.image.size.height) operation:NSCompositeSourceOver fraction:1.0];

}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
	Q_DEBUG(@"drawImage");

	//we draw the image directy with the border
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	Q_DEBUG(@"startTrackingAt");

	self.state = NSOnState;
	return YES;
}
@end
