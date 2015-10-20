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

#define ICON_WIDTH 9.0
#define ICON_HEIGHT 9.0
#define ICON_X 3.0
#define ICON_Y 31.0
#define ICON_SPACE 2.0

@implementation QControlTableView
{
	NSPoint pointClicked;
	NSImage *qPlayIcon;
	NSImage *qPauseIcon;
	NSImage *qStopIcon;
	NSImage *qEditIcon;
	NSImage *qDeleteIcon;
}
@synthesize qControl;

- (instancetype) initWithCoder: (NSCoder *) decoder
{
	Q_DEBUG(@"init");

    if ((self = [super initWithCoder: decoder]))
    {
        qPlayIcon = [NSImage imageNamed: @"q_tv_play"];
        qPauseIcon = [NSImage imageNamed: @"q_tv_pause"];
        qStopIcon = [NSImage imageNamed: @"q_tv_stop"];
        qEditIcon = [NSImage imageNamed: NSImageNameActionTemplate];
        qDeleteIcon = [NSImage imageNamed: @"q_tv_delete"];

		// register table for drag'n drop
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    
    return self;
}

- (void) mouseDown: (NSEvent *) event
{
	Q_DEBUG(@"mouseDown");

    int i;
    id VM;
    BOOL clicked = false;
    pointClicked = [self convertPoint:event.locationInWindow fromView:nil];
    NSInteger row = [self rowAtPoint: pointClicked];
    NSRect cellRect = [self frameOfCellAtColumn:1 row:row];
    
    for (i = 0; i < 4; i++) {
        if (NSPointInRect(pointClicked, NSMakeRect(
            cellRect.origin.x + ICON_X + i * (ICON_WIDTH),
            cellRect.origin.y + ICON_Y,
            ICON_WIDTH,
            ICON_HEIGHT
        ))) {
            VM = [qControl VMs][row];
            switch (i) {
                case 0: // edit
                    clicked = TRUE;
                break;
                case 1: // play/pause
                    clicked = TRUE;
                break;
                case 2: // stop
                    if (![VM[@"PC Data"][@"state"] isEqual:@"shutdown"])
                        clicked = TRUE;
                break;
                case 3: // delete
                    if ([VM[@"PC Data"][@"state"] isEqual:@"shutdown"])
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
	NSInteger row;
    id VM;
	NSRect cellRect;
    BOOL clicked;
	QDocument *document;
	
	clicked = false;
    pointClicked = [self convertPoint:event.locationInWindow fromView:nil];
    row = [self rowAtPoint: pointClicked];
    cellRect = [self frameOfCellAtColumn:1 row:row];
	VM = [qControl VMs][row];
	document = [[NSDocumentController sharedDocumentController] documentForURL:VM[@"Temporary"][@"URL"]];
	
    for (i = 0; i < 4; i++) {
        if (NSPointInRect(pointClicked, NSMakeRect(
            cellRect.origin.x + ICON_X + i * (ICON_WIDTH + ICON_SPACE),
            cellRect.origin.y + ICON_Y,
            ICON_WIDTH,
            ICON_HEIGHT
        ))) {
            switch (i) {
                case 0: // edit
                    [qControl editVM:VM];
                break;
                case 1: // play/pause
					if (document) {
						switch (document.VMState) {
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
								
							default:
								break;
						}
					} else {
						[qControl startVM:VM];
					}
					break;
                case 2: // stop
                    if (document) {
						if ((document.VMState==QDocumentRunning)||(document.VMState==QDocumentPaused)) {
							[document VMShutDown:self];
						}
					}
					break;
                case 3: // delete
                    if (!document) // only allow if VM is not open
                        [qControl deleteVM:VM];
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
	QDocument *document;

	if (qControl) {
    [super drawRect: rect];


    for (NSInteger i = 0; i < [qControl VMs].count; i++) {
		CGFloat qFraction;
        VM = [qControl VMs][i];
		document = [[NSDocumentController sharedDocumentController] documentForURL:VM[@"Temporary"][@"URL"]];
        cellRect = [self frameOfCellAtColumn:1 row:i];
        
        // edit icon
        point = NSMakePoint(cellRect.origin.x + ICON_X, cellRect.origin.y + ICON_Y);
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT))) {
            qFraction = 1.0;
        } else if (document) {
			switch (document.VMState) {
				case QDocumentShutdown:
					qFraction = 0.5;
					break;
				default:
					qFraction = 0.25;
					break;
			}
		} else if ([VM[@"PC Data"][@"state"] isEqual:@"saved"]) {
            qFraction = 0.25;
        } else {
            qFraction = 0.5;
		}
        [qEditIcon
            drawInRect: NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)
            fromRect: NSMakeRect(0, 0, qEditIcon.size.width, qEditIcon.size.height)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];

        // play/pause icon
        point = NSMakePoint(cellRect.origin.x + ICON_X + (ICON_WIDTH + ICON_SPACE), cellRect.origin.y + ICON_Y);
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT))) {
            qFraction = 1.0;
        } else if (document) {
			switch (document.VMState) {
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
			[VM[@"PC Data"][@"state"] isEqual:@"shutdown"] ||
			[VM[@"PC Data"][@"state"] isEqual:@"saved"]) {
            image = qPlayIcon;
			qFraction = 0.5;
        } else {
            image = qPlayIcon;
			qFraction = 0.25;
		}
        [image
            drawInRect: NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)
            fromRect: NSMakeRect(0, 0, image.size.width, image.size.height)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];

        // stop icon
        point = NSMakePoint(cellRect.origin.x + ICON_X + 2 * (ICON_WIDTH + ICON_SPACE), cellRect.origin.y + ICON_Y);
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT))) {
            qFraction = 1.0;
        } else if (document) {
			switch (document.VMState) {
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
            drawInRect: NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)
            fromRect: NSMakeRect(0, 0, qStopIcon.size.width, qStopIcon.size.height)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];
        
        // delete icon
        point = NSMakePoint(cellRect.origin.x + ICON_X + 3 * (ICON_WIDTH + ICON_SPACE), cellRect.origin.y + ICON_Y);
        if (NSPointInRect(pointClicked, NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)))
            qFraction = 1.0;
        else if (document)
            qFraction = 0.25;
        else
            qFraction = 0.5;
        [qDeleteIcon
            drawInRect: NSMakeRect(point.x, point.y, ICON_WIDTH, ICON_HEIGHT)
            fromRect: NSMakeRect(0, 0, qDeleteIcon.size.width, qDeleteIcon.size.height)
            operation: NSCompositeSourceOver
            fraction: qFraction
        ];
    }
	}
}

@end
