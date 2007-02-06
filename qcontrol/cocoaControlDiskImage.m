/*
 * QEMU Cocoa Control Diskimage Window
 * 
 * Copyright (c) 2005 - 2007 Mike Kronenberg
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

#import "cocoaControlDiskImage.h"
#import "cocoaControlEditPC.h"

@implementation cocoaControlDiskImage
-(id) init
{
//	NSLog(@"cocoaControlEditPC: init");
	if ((self = [super init])) {
		[ [ NSNotificationCenter defaultCenter ] addObserver:self 
			selector:@selector(checkATaskStatus:) 
			name:NSTaskDidTerminateNotification 
			object:nil ];
		return self;
	}
	
	return nil;
}

- (void) dealloc
{
//	NSLog(@"cocoaControlEditPC: dealloc");

	[ [ NSNotificationCenter defaultCenter ] removeObserver:self ];
	[ super dealloc ];
}

- (void) checkATaskStatus:(NSNotification *)aNotification
{
//	NSLog(@"cocoaControlEditPC: checkATaskStatus\n");

	int status = [ [ aNotification object ] terminationStatus ];
	if (status == 0)  {
		[ dIProgressIndicator stopAnimation:self ];
		[ NSApp endSheet:dIProgressPanel ];
		[ dIWindow close ];
		[ self release ];
	} else
		NSLog(@"cocoaControlDiskImage failed.");
}
- (id) dIWindow
{
	return dIWindow;
}

- (void) setQSender:(id)sender
//	NSLog(@"cocoaControlEditPC: setQSender");
{
	qSender = sender;
}

- (void)dIPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//	NSLog(@"cocoaControlEditPC: dIPanelDidEnd");

	[ dIWindow orderOut:self ];
	[ dIWindow release ];
	[ self release ];
}

- (IBAction)dIWindowClose:(id)sender
{
//	NSLog(@"cocoaControlDiskImage: dIWindowClose");
	
	if (qSender) { /* sheet for EditPCPanel */
		[ NSApp endSheet:dIWindow ];
	} else { /* standalone Window */
		[ dIWindow close ];
		[ self release ];
	}
}

- (IBAction)dIWindowCreate:(id)sender
{
//	NSLog(@"cocoaControlDiskImage: dIWindowCreate");

	/* check size */
	if ([ dISize intValue ] < 1) {
		[ dISize setTextColor: [NSColor redColor ] ];
		return;
	}
	
	if (qSender) { /* sheet for EditPCPanel */
		[ qSender setCustomDIType:[ [ NSArray arrayWithObjects:@"raw", @"qcow2", nil ] objectAtIndex:[ dIFormat indexOfSelectedItem ] ] size:[ dISize intValue ] ];
		[ self dIWindowClose:self];
	} else { /* standalone Window */
		NSSavePanel *sp = [ [ NSSavePanel alloc ] init ];
		[ sp setRequiredFileType:[ [ NSArray arrayWithObjects:@"raw", @"qcow2", nil ] objectAtIndex:[ dIFormat indexOfSelectedItem ] ] ];
		[ sp beginSheetForDirectory:NSHomeDirectory()
			file:[ NSString stringWithFormat: NSLocalizedStringFromTable(@"dIWindowCreate:file", @"Localizable", @"cocoaControlDiskImage"),[ [ NSArray arrayWithObjects:@"raw", @"qcow2", nil ] objectAtIndex:[ dIFormat indexOfSelectedItem ] ] ]
			modalForWindow:dIWindow
			modalDelegate:self
			didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
	}
}

- (void)savePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//	NSLog(@"cocoaControlDiskImage: savePanelDidEnd");

	if(returnCode == NSOKButton) 
	{
		dIFileName = [ [ NSString stringWithFormat:@"%@", [ sheet filename ] ] retain ];
		
		/* hide Save Sheet */
		[ sheet orderOut:self ];
		
		/* prepare dIPanel */
		[ dIProgressIndicator setUsesThreadedAnimation:YES ];
		[ dIName setStringValue:[ NSString stringWithFormat: NSLocalizedStringFromTable(@"savePanelDidEnd:dIName", @"Localizable", @"cocoaControlDiskImage"), dIFileName ] ];
		
		/* show Progress Sheet */
		[ NSApp beginSheet: dIProgressPanel
			modalForWindow: dIWindow
			modalDelegate: self
			didEndSelector: nil
			contextInfo: nil ];
		
		[ dIProgressIndicator startAnimation:self ];
		
		/* create Timer for Progressbar */
//		NSTimer *timer = [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector( dIProgressbarUpdate: ) userInfo:nil repeats:YES ];
		
		/* create Image */
		NSArray *arguments = [ NSArray arrayWithObjects:@"create",@"-f",[ [ NSArray arrayWithObjects:@"raw", @"qcow2", nil ] objectAtIndex:[ dIFormat indexOfSelectedItem ] ],dIFileName,[ NSString stringWithFormat:@"%@M",[ dISize stringValue ] ],nil ];
		NSTask *task;
		task = [ [ NSTask alloc ] init ];
		[ task setLaunchPath: [ NSString stringWithFormat:@"%@/MacOS/qemu-img", [ [ [ NSBundle mainBundle ] resourcePath ] stringByDeletingLastPathComponent ] ] ];
		[ task setArguments: arguments ];
		[ task launch ];
		[ task release ];
	}
}

- (void)dIProgressPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//	NSLog(@"cocoaControlDiskImage: dIProgressPanelDidEnd");

	[ sheet orderOut:self ];
}

- (IBAction)dIProgressPanelStop:(id)sender
{
//	NSLog(@"cocoaControlDiskImage: dIProgressPanelStop");

	[ NSApp endSheet:dIProgressPanel ];
}

- (void) dIProgressbarUpdate:(id)sender
{
//	NSLog(@"cocoaControlDiskImage: dIProgressbarUpdate");

	int fsize;
	NSFileManager *fileManager = [ NSFileManager defaultManager ];
	NSDictionary *fattrs = [ fileManager fileAttributesAtPath:dIFileName traverseLink:YES ];
	if (!fattrs) {
		NSLog(@"no File");
	} else {
		NSLog(@"we got a File");
		if ((fsize = [ fattrs fileSize ])) {
			NSLog(@"File size: %d", fsize);
		} else {
			NSLog(@"no File size");
		}
	}
//	[ sender invalidate ];
}
@end
