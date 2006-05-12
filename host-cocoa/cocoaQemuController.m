/*
 * QEMU Cocoa Qemu Controller
 * 
 * Copyright (c) 2005, 2006 Pierre d'Herbemont
 *                          Mike Kronenberg
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

#import "cocoaQemuController.h"

#import "cocoaQemu.h"

@implementation cocoaQemuController
- (id) initWithArgc:(int)argc argv:(char**)argv
{
	if (( self = [super init] )) {
		gArgc = argc;
		gArgv = argv;
		
		return self;
	} else
		return nil;
}

- (void)applicationDidFinishLaunching: (NSNotification *) note
{
	if( gArgc <= 1 || strncmp (gArgv[1], "-psn", 4) == 0) {
		NSOpenPanel *openPanel = [ [ NSOpenPanel alloc ] init ];
		[ openPanel setTitle:@"Please choose a Imagefile" ];
		
		int result;
		
		result = [ openPanel runModalForDirectory:NSHomeDirectory() file:nil types:[ NSArray arrayWithObjects:@"raw",@"img",@"iso",@"dmg",@"qcow",@"cow",@"cloop",@"vmdk",nil ] ];
		if (result == NSOKButton) {
			NSMutableArray *arguments = [ [ NSMutableArray alloc ] init ];
			[ arguments addObject:@"qemu" ];
			[ arguments addObject:[ openPanel filename ] ];
		
			cocoaQemu *pc = [ [ cocoaQemu alloc ] init ];
			[ pc startPCWithArgs:arguments];
			[ pc release ];
		} else {
			[ NSApp terminate:self ];
		}
	} else {
		int i;
		NSMutableArray *arguments = [ [ NSMutableArray alloc ] init ];
		for (i = 0; i < gArgc; i++)
			[ arguments addObject: [ NSString stringWithFormat:@"%s", gArgv[i] ] ];

		cocoaQemu *pc = [ [ cocoaQemu alloc ] init ];
		[ pc startPCWithArgs:arguments];
		[ pc release ];
	}
}
@end
