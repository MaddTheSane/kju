/*
 * QEMU Cocoa Control Diskimage Window
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

#import <Cocoa/Cocoa.h>

@interface cocoaControlDiskImage : NSObject
{
	IBOutlet id dIWindow;
	IBOutlet id dIProgressPanel;
	IBOutlet NSPopUpButton *dIFormat;
	IBOutlet NSTextField *dISize;
	IBOutlet NSProgressIndicator *dIProgressIndicator;
	IBOutlet NSTextField *dIName;
	IBOutlet NSTextField *dIProgress;
	
	id qSender;
	NSString *dIFileName;
}
- (id) init;
- (void) dealloc;
- (void) checkATaskStatus:(NSNotification *)aNotification;
- (id) dIWindow;
- (void) setQSender:(id)sender;
- (IBAction) dIWindowClose:(id)sender;
- (IBAction) dIWindowCreate:(id)sender;
- (void) dIPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

/* SavePanel */
- (void) savePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

/* Progress Panel */
- (IBAction) dIProgressPanelStop:(id)sender;
- (void) dIProgressPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void) dIProgressbarUpdate:(id)sender;
@end
