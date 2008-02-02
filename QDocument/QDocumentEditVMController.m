/*
 * Q Document Edit VM Controller
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

#import "QDocumentEditVMController.h"

#import "QDocument.h"
#import "QQvmManager.h"


@implementation QDocumentEditVMController
- (void)showEditVMPanel:(id)sender
{
	Q_DEBUG(@"showEditVMPanel");


	if (![editVMPanel isVisible]) {
	
		// populate panel
		
		// reset and populate Panel
		document = (QDocument *)sender;
		VM = [document configuration];
		[self resetPanel:self];
		[self populatePanel:self];
		
		// open sheet
		[NSApp beginSheet:editVMPanel
			modalForWindow:[[document screenView] window]
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];
	}
}

- (IBAction)OK:(id)sender
{
	Q_DEBUG(@"OK");

	[NSApp endSheet:editVMPanel];
	[editVMPanel orderOut:self];

}

- (IBAction)cancel:(id)sender
{
	Q_DEBUG(@"cancel");

	[NSApp endSheet:editVMPanel];
	[editVMPanel orderOut:self];
}

- (NSPanel *) editVMPanel { return editVMPanel;}

- (void) resetPanel:(id)sender
{
	Q_DEBUG(@"resetPanel");
	
	// Tab 1
	[vMName setStringValue:@""];
	[grabless setState:NSOffState];
	[qDrivers setState:NSOffState];
	[pauseWhileInactive setState:NSOffState];
	[smb selectItemAtIndex:0];
	
	// Tab 2
	[M selectItemAtIndex:0];
	[cpu selectItemAtIndex:0];
	[smp setStringValue:@"0"];
	[m setStringValue:@"128"]; // 128
	[vga selectItemAtIndex:0];
	[pcspk setState:NSOffState];
	[adlib setState:NSOffState];
	[sb16 setState:NSOffState];
	[es1370 setState:NSOffState];
	[nicModel1 selectItemAtIndex:0];
	[nicModel2 selectItemAtIndex:0];
	[fda selectItemAtIndex:0];
	[cdrom selectItemAtIndex:0];
	[hda selectItemAtIndex:0];
	[boot selectItemAtIndex:2]; // c
	
	// Tab 3
	
	// Tab 4
	[hdb selectItemAtIndex:0];
	[hdc selectItemAtIndex:0];
	[hdd selectItemAtIndex:0];
	[localtime setState:NSOffState];
	[win2kHack setState:NSOffState];
	[kernel selectItemAtIndex:0];
	[append setStringValue:@""];
	[initrd selectItemAtIndex:0];
	[onlyOptional setState:NSOffState];
	[optional setStringValue:@""];
}

- (BOOL)setOption:(NSString *)key withArgument:(NSString *)argument
{
	Q_DEBUG(@"setOption:%@ withArgument:%@", key, argument);
	
	// -name TODO: convert -name from 0.2.0.Q profile
	if ([key isEqual:@"-name"]) {
		[vMName setStringValue:argument];
		return TRUE;

	// grabless (-usbdevice tablet)
	} else if ([key isEqual:@"-usbdevice"] && [argument isEqual:@"tablet"]) {
		[grabless setState:NSOffState];
		return TRUE;

	// Q Windows driver TODO: add second CD ROM
//	} else if ([key isEqual:@"-usb"] && [argument isEqual:@"tablet"]) {
//		[grabless setState:NSOffState];
//		return TRUE;

	// -smb
	} else if ([key isEqual:@"-smb"]) {
        if ([argument isEqual:@"~/Desktop/Q Shared Files/"]) {
            [smb selectItemAtIndex:1];
        } else {
            [smb insertItemWithTitle:[NSString stringWithString:argument] atIndex:2];
            [smb selectItemAtIndex:2];
        }
		return TRUE;
		
	} else if ([key isEqual:@"-M"]) {
        if ([argument isEqual:@""]) {
            [smb selectItemAtIndex:1];
        } else {
            [smb insertItemWithTitle:[NSString stringWithString:argument] atIndex:2];
            [smb selectItemAtIndex:2];
        }

		return TRUE;

	}
	return FALSE;
}

- (void) populatePanel:(id)sender
{
	Q_DEBUG(@"populatePanel:%@", sender);
	
	int i;
	NSMutableString *optionalArguments;
	NSString *key;

	optionalArguments = [NSMutableString stringWithString:@""];
	key = nil;
	for (i = 0; i < [[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] count]; i++) {
		if ([[[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i] characterAtIndex:0] == '-') { // key
			if (key) { // store previous key
				if (![self setOption:key withArgument:@""]) {
					[optionalArguments appendFormat:@"%@ ", key];
				}
			}
			key = [[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i];
		} else { // argument
				if (![self setOption:key withArgument:[[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i]]) {
					[optionalArguments appendFormat:@"%@ ", key];
					[optionalArguments appendFormat:@"%@ ", [[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i]];
				}
			key = nil;
		}
	}
	if (key) { // store previous key
		if ([self setOption:key withArgument:[[[VM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:i]]) {
			[optionalArguments appendFormat:@"%@", key];
		}
	}
	
	// add unknown arguments to "optional"
	[optional setStringValue:optionalArguments];	

}
@end
