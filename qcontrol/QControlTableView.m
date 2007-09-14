/*
 * Q Control Controller
 * 
 * Copyright (c) 2006 - 2007 Mike Kronenberg, inspired by transmission
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

#import "QControlTableView.h"

#import "cocoaControlController.h"

#define ICON_WIDTH 12.0
#define ICON_HEIGHT 12.0

@implementation QControlTableView
- (id) initWithCoder: (NSCoder *) decoder
{
    if ((self = [super initWithCoder: decoder]))
    {
        qPlayIcon = [NSImage imageNamed: @"q_tv_play.png"];
        qPauseIcon = [NSImage imageNamed: @"q_tv_pause.png"];
        qStopIcon = [NSImage imageNamed: @"q_tv_stop.png"];
        qEditIcon = [NSImage imageNamed: @"q_tv_edit.png"];
        qDeleteIcon = [NSImage imageNamed: @"q_tv_delete.png"];
        
//        fClickPoint = NSZeroPoint;
        
//        fDefaults = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}

-(void) setQControl:(id)sender
{
    qControl = sender;
}

- (void) mouseDown: (NSEvent *) event
{
    int i;
    id thisPC;
    BOOL clicked = false;
    pointClicked = [self convertPoint:[event locationInWindow] fromView:nil];
    int row = [self rowAtPoint: pointClicked];
    NSRect cellRect = [self frameOfCellAtColumn:1 row:row];
    
    for (i = 1; i < 5; i++) {
        if (NSPointInRect(pointClicked, NSMakeRect(
            cellRect.origin.x + cellRect.size.width - i * (ICON_WIDTH + 4),
            cellRect.origin.y + cellRect.size.height - ICON_HEIGHT - 4,
            ICON_WIDTH,
            ICON_HEIGHT
        ))) {
            thisPC = [[qControl pcs] objectAtIndex:row];
            switch (i) {
                case 1: /* delete */
                    if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"])
                        clicked = TRUE;
                break;
                case 2: /* stop */
                    if (![[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"])
                        clicked = TRUE;
                break;
                case 3: /* play/pause */
                    clicked = TRUE;
                break;
                case 4: /* edit */
                    clicked = TRUE;
                break;
            }
        }
    }
    
    if (clicked)
        [self display];
    else {
        pointClicked = NSZeroPoint;
        [super mouseDown: event];
    }
}

- (void) mouseUp: (NSEvent *) event
{
    int i;
    id thisPC;
    BOOL clicked = false;
    pointClicked = [self convertPoint:[event locationInWindow] fromView:nil];
    int row = [self rowAtPoint: pointClicked];
    NSRect cellRect = [self frameOfCellAtColumn:1 row:row];
    
    for (i = 1; i < 5; i++) {
        if (NSPointInRect(pointClicked, NSMakeRect(
            cellRect.origin.x + cellRect.size.width - i * (ICON_WIDTH + 4),
            cellRect.origin.y + cellRect.size.height - ICON_HEIGHT - 4,
            ICON_WIDTH,
            ICON_HEIGHT
        ))) {
            thisPC = [[qControl pcs] objectAtIndex:row];
            switch (i) {
                case 1: /* delete */
                    if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"])
                        [qControl deleteThisPC:thisPC];
                break;
                case 2: /* stop */
                    if (![[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"])
                        [qControl stopThisPC:thisPC];
                break;
                case 3: /* play/pause */
                    if (![[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"])
                        [qControl startThisPC:thisPC];
                    else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"])
                        [qControl pauseThisPC:thisPC];
                break;
                case 4: /* edit */
                    [qControl editThisPC:thisPC];
                break;
            }
        }
    }

    pointClicked = NSZeroPoint;
    [self display];
    
    if (!clicked)
        [super mouseUp: event];
}

- (void) drawRect: (NSRect) rect
{
//	NSLog(@"QControlTableView: drawRect");

    NSRect cellRect;
    NSPoint point;
    id thisPC;
    NSImage *image;
    float qFraction;
    int i;


    [super drawRect: rect];

    for (i = 0; i < [[qControl pcs] count]; i++) {
        thisPC = [[qControl pcs] objectAtIndex:i];
        cellRect = [self frameOfCellAtColumn:1 row:i];
        
        /* edit icon */
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - 4 * (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)))
            qFraction = 1.0;
        else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]||[[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"])
            qFraction = 0.25;
        else
            qFraction = 0.5;
        [qEditIcon
            drawAtPoint: point
            fromRect: NSMakeRect(0, 0, ICON_WIDTH, ICON_HEIGHT)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];

        /* play/pause icon */
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - 3 * (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)))
            qFraction = 1.0;
        else
            qFraction = 0.5;
        if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"])
            image = qPauseIcon;
        else
            image = qPlayIcon;
        [image
            drawAtPoint: point
            fromRect: NSMakeRect(0, 0, ICON_WIDTH, ICON_HEIGHT)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];

        /* stop icon */
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - 2 * (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)))
            qFraction = 1.0;
        else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"]||[[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"])
            qFraction = 0.5;
        else
            qFraction = 0.25;
        [qStopIcon
            drawAtPoint: point
            fromRect: NSMakeRect(0, 0, ICON_WIDTH, ICON_HEIGHT)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];
        
        /* delete icon */
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)))
            qFraction = 1.0;
        else if ([[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]||[[[thisPC objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"])
            qFraction = 0.25;
        else
            qFraction = 0.5;
        [qDeleteIcon
            drawAtPoint: point
            fromRect: NSMakeRect(0, 0, ICON_WIDTH, ICON_HEIGHT)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];
    }
}
@end