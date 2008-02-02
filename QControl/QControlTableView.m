/*
 * Q Control TableView
 * 
 * Copyright (c) 2007 - 2008 Mike Kronenberg, inspired by transmission
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

#import "QControlController.h"
#import "../QDocument/QDocument.h"


#define ICON_WIDTH 12.0
#define ICON_HEIGHT 12.0

@implementation QControlTableView
- (id) initWithCoder: (NSCoder *) decoder
{
	Q_DEBUG(@"init");

    if ((self = [super initWithCoder: decoder]))
    {
        qPlayIcon = [NSImage imageNamed: @"q_tv_play.png"];
        qPauseIcon = [NSImage imageNamed: @"q_tv_pause.png"];
        qStopIcon = [NSImage imageNamed: @"q_tv_stop.png"];
        qEditIcon = [NSImage imageNamed: @"q_tv_edit.png"];
        qDeleteIcon = [NSImage imageNamed: @"q_tv_delete.png"];

		// register table for drag'n drop
		[self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
    }
    
    return self;
}

- (void) mouseDown: (NSEvent *) event
{
	Q_DEBUG(@"mouseDown");

    int i;
    id VM;
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
            VM = [[qControl VMs] objectAtIndex:row];
            switch (i) {
                case 1: // delete
                    if ([[[VM objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"])
                        clicked = TRUE;
                break;
                case 2: // stop
                    if (![[[VM objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"])
                        clicked = TRUE;
                break;
                case 3: // play/pause
                    clicked = TRUE;
                break;
                case 4: // edit
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
	Q_DEBUG(@"mouseUp");

    int i;
	int row;
    id VM;
	NSRect cellRect;
    BOOL clicked;
	QDocument *document;
	
	clicked = false;
    pointClicked = [self convertPoint:[event locationInWindow] fromView:nil];
    row = [self rowAtPoint: pointClicked];
    cellRect = [self frameOfCellAtColumn:1 row:row];
	VM = [[qControl VMs] objectAtIndex:row];
	document = [[NSDocumentController sharedDocumentController] documentForURL:[[VM objectForKey:@"Temporary"] objectForKey:@"URL"]];
	
    for (i = 1; i < 5; i++) {
        if (NSPointInRect(pointClicked, NSMakeRect(
            cellRect.origin.x + cellRect.size.width - i * (ICON_WIDTH + 4),
            cellRect.origin.y + cellRect.size.height - ICON_HEIGHT - 4,
            ICON_WIDTH,
            ICON_HEIGHT
        ))) {
            switch (i) {
                case 1: // delete
                    if (!document) // only allow if VM is not open
                        [qControl deleteVM:VM];
					break;
                case 2: // stop
                    if (document) {
						if (([document VMState]==QDocumentRunning)||([document VMState]==QDocumentPaused)) {
							[document VMShutDown:self];
						}
					}
					break;
                case 3: // play/pause
					if (document) {
						switch ([document VMState]) {
							case QDocumentShutdown:
							case QDocumentSaved:
								[document VMStart:self];
								break;
							case QDocumentPaused:
								[document VMUnpause:self];
								break;
							case QDocumentRunning:
								[document VMPause:self];
								break;
						}
					} else {
						[qControl startVM:VM];
					}
					break;
                case 4: // edit
                    [qControl editVM:VM];
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
	Q_DEBUG(@"drawRect");

    NSRect cellRect;
    NSPoint point;
    id VM;
    NSImage *image;
    float qFraction;
    int i;
	QDocument *document;

	if (qControl) {
    [super drawRect: rect];


    for (i = 0; i < [[qControl VMs] count]; i++) {
        VM = [[qControl VMs] objectAtIndex:i];
		document = [[NSDocumentController sharedDocumentController] documentForURL:[[VM objectForKey:@"Temporary"] objectForKey:@"URL"]];
        cellRect = [self frameOfCellAtColumn:1 row:i];
        
        // edit icon
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - 4 * (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT))) {
            qFraction = 1.0;
        } else if (document) {
			switch ([document VMState]) {
				case QDocumentShutdown:
					qFraction = 0.5;
				default:
					qFraction = 0.25;
					break;
			}
		} else if ([[[VM objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]) {
            qFraction = 0.25;
        } else {
            qFraction = 0.5;
		}
        [qEditIcon
            drawAtPoint: point
            fromRect: NSMakeRect(0, 0, ICON_WIDTH, ICON_HEIGHT)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];

        // play/pause icon
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - 3 * (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT))) {
            qFraction = 1.0;
        } else if (document) {
			switch ([document VMState]) {
				case QDocumentShutdown:
				case QDocumentSaved:
				case QDocumentPaused:
					qFraction = 0.5;
					image = qPlayIcon;
					break;
				case QDocumentRunning:
					qFraction = 0.5;
					image = qPauseIcon;
					break;
				default:
					qFraction = 0.25;
					image = qPlayIcon;
					break;
			}
		} else if (
			[[[VM objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"shutdown"] ||
			[[[VM objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]) {
            image = qPlayIcon;
			qFraction = 0.5;
        } else {
            image = qPlayIcon;
			qFraction = 0.25;
		}
        [image
            drawAtPoint: point
            fromRect: NSMakeRect(0, 0, ICON_WIDTH, ICON_HEIGHT)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];

        // stop icon
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - 2 * (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT))) {
            qFraction = 1.0;
        } else if (document) {
			switch ([document VMState]) {
				case QDocumentPaused:
				case QDocumentRunning:
					qFraction = 0.5;
					break;
				default:
					qFraction = 0.25;
					break;
			}
		} else {
			qFraction = 0.25;
		}
        [qStopIcon
            drawAtPoint: point
            fromRect: NSMakeRect(0, 0, ICON_WIDTH, ICON_HEIGHT)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];
        
        // delete icon
        point = NSMakePoint(cellRect.origin.x + cellRect.size.width - (ICON_WIDTH + 4), cellRect.origin.y + cellRect.size.height - (ICON_HEIGHT + 4));
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)))
            qFraction = 1.0;
        else if (document)
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

}



#pragma mark getters and setters
-(void) setQControl:(id)sender {qControl = sender;}
@end