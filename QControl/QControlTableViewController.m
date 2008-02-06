/*
 * Q Control TableView Controller
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

#import "QControlTableViewController.h"

#import "QDocument.h"
#import "QDocumentOpenGLView.h"


@implementation QControlTableViewController
- (id) init
{
	Q_DEBUG(@"init");

	self = [super init];
	if (super) {
	
		// cache shutdown image
		shutdownImage = [NSImage imageNamed: @"q_table_shutdown.png"];
		[shutdownImage retain];
	
		// Listen to VM updates
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateThumbnails:) name:@"QVMStatusDidChange" object:nil];
	}
	return self;
}

- (void) dealloc
{
	Q_DEBUG(@"dealloc");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[VMsImages release];
	[shutdownImage release];
	[super dealloc];
}

-(void)awakeFromNib
{
	Q_DEBUG(@"awakeFromNib");

	// set infos for microIcons
	[table setQControl:qControl];

	// loading initial Thumbnails
	[self updateThumbnails:self];
	timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateThumbnails:) userInfo:nil repeats:YES];
}

#pragma mark fill the table
-(int)numberOfRowsInTableView:(NSTableView *)table
{
	Q_DEBUG(@"numberOfRowsInTableView");

    return [[qControl VMs] count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	Q_DEBUG(@"tableView: objectValueForTableColumn: row:%D", rowIndex);

    id VM;
    NSString *platform;
	NSString *state;
	QDocument *qDocument;

	platform = @"";
	VM = [[qControl VMs] objectAtIndex:rowIndex];
	qDocument = [[NSDocumentController sharedDocumentController] documentForURL:[[VM objectForKey:@"Temporary"] objectForKey:@"URL"]];
	if (qDocument) {
		switch ([qDocument VMState]) {
			case(QDocumentSaving):
				state = NSLocalizedStringFromTable(@"saving", @"Localizable", @"vmstate");
				break;
			case(QDocumentSaved):
				state = NSLocalizedStringFromTable(@"saved", @"Localizable", @"vmstate");
				break;
			case(QDocumentLoading):
				state = NSLocalizedStringFromTable(@"loading", @"Localizable", @"vmstate");
				break;
			case(QDocumentPaused):
				state = NSLocalizedStringFromTable(@"paused", @"Localizable", @"vmstate");
				break;
			case(QDocumentRunning):
				state = NSLocalizedStringFromTable(@"running", @"Localizable", @"vmstate");
				break;
			case(QDocumentEditing):
				state = NSLocalizedStringFromTable(@"editing", @"Localizable", @"vmstate");
				break;
			case(QDocumentInvalid):
				state = NSLocalizedStringFromTable(@"invalid", @"Localizable", @"vmstate");
				break;
			default:
				state = NSLocalizedStringFromTable(@"shutdown", @"Localizable", @"vmstate");
				break;
		}
	} else {
		state = NSLocalizedStringFromTable([[VM objectForKey:@"PC Data"] objectForKey:@"state"], @"Localizable", @"vmstate");
	}
    
    if ([[aTableColumn identifier] isEqualTo: @"image"]) {
        if ([VMsImages count] < rowIndex) { // return default image if no image available
            return [NSImage imageNamed: @"q_table_shutdown.png"];
		} else {
            return [VMsImages objectAtIndex:rowIndex];
        }
    }
    else if ([[aTableColumn identifier] isEqualTo: @"description"]) {
        
        if ([[[VM objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"x86"]) {
            platform = [NSString stringWithString:@"x86 PC"];
        } else if ([[[VM objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"x86-64"]) {
            platform = [NSString stringWithString:@"x86-64 PC"];
        } else if ([[[VM objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"PowerPC"] && [[[VM objectForKey:@"Temporary"] objectForKey:@"-M"] isEqual:@"prep"]) {
            platform = [NSString stringWithString:@"PPC PREP"];
        } else if ([[[VM objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"PowerPC"]) {
            platform = [NSString stringWithString:@"PPC PowerMac"];
        } else if ([[[VM objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"SPARC"]) {
            platform = [NSString stringWithString:@"SPARC"];
        } else if ([[[VM objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"MIPS"]) {
            platform = [NSString stringWithString:@"MIPS"];
        } else if ([[[VM objectForKey:@"PC Data"] objectForKey:@"architecture"] isEqual:@"ARM"]) {
            platform = [NSString stringWithString:@"ARM"];
        }
        
        NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"%@\n", [[VM objectForKey:@"Temporary"] objectForKey:@"name"]] attributes:[NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName]] autorelease];
        [attrString appendAttributedString: [[[NSAttributedString alloc] initWithString:state attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease]];
        
        return attrString;
    }
    
    return nil;
}



#pragma mark tooltips
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex mouseLocation:(NSPoint)mouseLocation
{
	Q_DEBUG(@"toolTipForCell");

    return [[[qControl VMs] objectAtIndex:rowIndex] objectForKey:@"Arguments"];
}



#pragma mark drag'n'drop
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op 
{
	Q_DEBUG(@"validateDrop");

	NSPasteboard *paste = [info draggingPasteboard];
    NSArray *types = [NSArray arrayWithObjects: NSFilenamesPboardType, nil];
    NSString *desiredType = [paste availableTypeFromArray:types];
    [table setDropRow:[table numberOfRows] dropOperation: NSTableViewDropAbove];

	if ([desiredType isEqualToString:NSFilenamesPboardType]) { // we only accept files to be dragged onto Q Control
		if ([@"qvm" isEqual:[[[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0] pathExtension]]) { // add an existing VM to the Browser
			[table setDropRow:[table numberOfRows] dropOperation: NSTableViewDropAbove]; //drop to last row
		} else if([FILE_TYPES containsObject:[[[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0] pathExtension]]) { // create a new VM with this diskimage
			[table setDropRow:[table numberOfRows] dropOperation: NSTableViewDropAbove]; //drop to last row
		} else { // copy all dragged Files to the Q shared folder of this PC
			[table setDropRow:row dropOperation: NSTableViewDropAbove]; //drop to propsed row
		}
        return NSDragOperationEvery;
	}
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	Q_DEBUG(@"acceptDrop");

    NSPasteboard *paste = [info draggingPasteboard];
    NSArray *types = [NSArray arrayWithObjects: NSFilenamesPboardType, nil];
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];

    if (nil == carriedData) {
        NSRunAlertPanel(@"Paste Error", @"Sorry, but the paste operation failed", 
            nil, nil, nil);
        return NO;
    } else {
//        if ([desiredType isEqualToString:NSFilenamesPboardType]) {
		if ([@"qvm" isEqual:[[[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0] pathExtension]]) { // add an existing VM to the Browser
			[qControl addVMToKnownVMs:[[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0]];
		} else if([FILE_TYPES containsObject:[[[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0] pathExtension]]) { // create a new VM with this diskimage
			[qControl addVMFromDragDrop:[[paste propertyListForType:@"NSFilenamesPboardType"] objectAtIndex:0]];
		} else { // copy all dragged Files to the Q shared folder of this PC
            NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
			if ([[[[qControl VMs] objectAtIndex:row] objectForKey:@"Temporary"] objectForKey:@"-smb"]) {
				int i;
				NSFileManager *fileManager = [NSFileManager defaultManager];
				for (i = 0; i < [fileArray count]; i++) {
					[fileManager copyPath:[fileArray objectAtIndex:i] toPath:[NSString stringWithFormat:@"%@/%@", [[[[qControl VMs] objectAtIndex:row] objectForKey:@"Temporary"] objectForKey:@"-smb"], [[fileArray objectAtIndex:i] lastPathComponent]] handler:nil]; 
				}
			}
        }// else {
//            NSAssert(NO, @"This can't happen");
//            return NO;
//        }
    }
    return YES;
}



#pragma mark double click
- (void) tableDoubleClick:(id)sender
{
	Q_DEBUG(@"tableDoubleClick");

    if ([table selectedRow] < 0) { // no empty line selection
//TODO:        [qControl addPC:self]; // addNewVM
    } else if ([[[[[qControl VMs] objectAtIndex:[sender clickedRow]] objectForKey:@"PC Data"] objectForKey:@"state"] isEqualTo:@"running"]) {  // move VM to front
		[(QDocument *)[[NSDocumentController sharedDocumentController] documentForURL:[[[[qControl VMs] objectAtIndex:[table selectedRow]] objectForKey:@"Temporary"] objectForKey:@"URL"]] showWindows];
	} else {
        [qControl startVMWithURL:[[[[qControl VMs] objectAtIndex:[sender clickedRow]] objectForKey:@"Temporary"] objectForKey:@"URL"]]; // start VM
    }
}



#pragma mark create tumbnails
- (NSImage *) loadThumbnailForVM:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"loadThumbnailForVM");

	NSImage *thumbnail;
	NSImage *savedImage;

	if ([[[VM objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]) { // only return thumbnail for saved VMs
		savedImage = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/QuickLook/Thumbnail.png", [[[VM objectForKey:@"Temporary"] objectForKey:@"URL"] path]]] autorelease];
		if (savedImage) { // try screen.png
			thumbnail = [[[NSImage alloc] initWithSize:NSMakeSize(100.0,  75.0)] autorelease];
			[thumbnail lockFocus];
			[savedImage drawInRect:NSMakeRect(0.0, 0.0, 100.0, 75.0) fromRect:NSMakeRect(0.0, 0.0, [savedImage size].width, [savedImage size].height) operation:NSCompositeSourceOver fraction:1.0];
			[thumbnail unlockFocus];
			return thumbnail;
		} else { // try old thumbnail.png
			savedImage = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/thumbnail.png", [[[VM objectForKey:@"Temporary"] objectForKey:@"URL"] path]]] autorelease];
			if (savedImage) {
				return savedImage;
			}
		}
	}
	return shutdownImage;
}

- (void) updateThumbnails:(id)sender
{
	Q_DEBUG(@"updateThumbnails");

    int i;
	BOOL updateAll;
	QDocument *qDocument;
	NSImage *thumbnail;
	
	updateAll = FALSE;

	if ((!VMsImages) || ([VMsImages count] != [[qControl VMs] count])) {
		updateAll = TRUE;
		if (VMsImages)
			[VMsImages release];
		VMsImages = [[NSMutableArray alloc] initWithCapacity:[[qControl VMs] count]];
	}
    for (i = 0; i < [[qControl VMs] count]; i++ ) {
		qDocument = [[NSDocumentController sharedDocumentController] documentForURL:[[[[qControl VMs] objectAtIndex:i] objectForKey:@"Temporary"] objectForKey:@"URL"]];
        if (qDocument) {
			switch ([qDocument VMState]) {
				case QDocumentPaused:
				case QDocumentRunning:
				case QDocumentSaving:
					thumbnail = [(QDocumentOpenGLView *)[qDocument screenView] screenshot:NSMakeSize(100.0, 75.0)];
					[VMsImages replaceObjectAtIndex:i withObject:thumbnail];
					break;
				case QDocumentShutdown:
					[VMsImages replaceObjectAtIndex:i withObject:shutdownImage];
					break;
				default:
					if (updateAll) {
						[VMsImages addObject:[self loadThumbnailForVM:[[qControl VMs] objectAtIndex:i]]];
					}
					break;
			}
        } else if (updateAll) {
			[VMsImages addObject:[self loadThumbnailForVM:[[qControl VMs] objectAtIndex:i]]];
        }
    }

    [table reloadData];
}
@end
