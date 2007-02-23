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
		
		if ([[NSBundle mainBundle] pathForResource:@"arguments" ofType:nil inDirectory:@"Guest"]) {
        /* if arguments file is found this is a standalone Guest exported from Q.app */
            int i;
            
            NSFileManager * fileManager = [NSFileManager defaultManager];
            NSArray * directoryContents = [fileManager directoryContentsAtPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Guest"]];
            NSString * qvmPath = [NSString string];
            // search for .qvm package
            if(directoryContents != nil) {
                for(i=0; i < [directoryContents count]; i++) {
                    if([[[directoryContents objectAtIndex:i] pathExtension] isEqual:@"qvm"]) {
                        // we found it
                        qvmPath = [[directoryContents objectAtIndex:i] lastPathComponent];
                        break;
                    }
                }
            }
            
            if([qvmPath isEqual:[NSString string]]) {
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert addButtonWithTitle: NSLocalizedStringFromTable(@"applicationDidFinishLaunching:alert:defaultButton", @"Localizable", @"cocoaQemuController")];
                [alert setMessageText: NSLocalizedStringFromTable(@"applicationDidFinishLaunching:alert:messageText", @"Localizable", @"cocoaQemuController")];
                [alert setInformativeText: NSLocalizedStringFromTable(@"applicationDidFinishLaunching:alert:informativeText", @"Localizable", @"cocoaQemuController")];
                [alert setAlertStyle:NSWarningAlertStyle];
                
                if ([alert runModal] == NSAlertFirstButtonReturn) {                
                    [ NSApp terminate:self ];
                }
            }
            
            NSString * s = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"arguments" ofType:nil inDirectory:@"Guest"] encoding:NSUTF8StringEncoding error:NULL];
        
            /* reformat arguments to array containing spaces */
            NSMutableArray *arguments = [[NSMutableArray alloc] init];
            /* Arguments of thisPC */
            NSArray *array = [s componentsSeparatedByString:@" "];
            NSMutableString *option = [[NSMutableString alloc] initWithString:@""];
            NSMutableString *argument = [[NSMutableString alloc] init];
            for (i = 1; i < [array count]; i++) {
                if ([[array objectAtIndex:i] cString][0] != '-') { //Teil eines Arguments
                    [argument appendFormat:[NSString stringWithFormat:@" %@", [array objectAtIndex:i]]];
                } else {
                    if ([option length] > 0) {
				        if ([argument isEqual:@""]) {
					       [arguments addObject:[NSString stringWithString:option]];
				        } else {
					       [arguments addObject:[NSString stringWithString:option]];
					       [arguments addObject:[NSString stringWithString:[argument substringFromIndex:1]]];
				        }
				    }
                    [option setString:[array objectAtIndex:i]];
                    [argument setString:@""];
                }
            }
            /* last Object */
            if ([argument isEqual:@""]) {
                [arguments addObject:[NSString stringWithString:option]];
            } else {
                [arguments addObject:[NSString stringWithString:option]];
                [arguments addObject:[NSString stringWithString:[argument substringFromIndex:1]]];
            }
            /* end reformatting */
            /* add NSBundle path to hda|hdb|hdc|hdd|fda|fdb|cdrom
               if(smb) change path to [NSBundle resourcePath]/Guest/Q Shared Files
            */
                      
            for(i=0; i < [arguments count]; i++) {
                if([[arguments objectAtIndex:i] isEqualTo:@"-hda"] || [[arguments objectAtIndex:i] isEqualTo:@"-hdb"] || [[arguments objectAtIndex:i] isEqualTo:@"-hdc"] || [[arguments objectAtIndex:i] isEqualTo:@"-hdd"] || [[arguments objectAtIndex:i] isEqualTo:@"-fda"] || [[arguments objectAtIndex:i] isEqualTo:@"-fdb"] || [[arguments objectAtIndex:i] isEqualTo:@"-cdrom"]) {
                    [arguments replaceObjectAtIndex:i+1 withObject:[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Guest"] stringByAppendingPathComponent: [qvmPath stringByAppendingPathComponent:[arguments objectAtIndex:i+1]]]];
                } else if([[arguments objectAtIndex:i] isEqualTo:@"-smb"]) {
                    BOOL isDirectory;
                    NSString * sharedDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Guest/Q Shared Files"];
                    if(![fileManager fileExistsAtPath:sharedDir isDirectory:&isDirectory] && isDirectory)
                        [fileManager createDirectoryAtPath:sharedDir attributes:nil];                        
                    [arguments replaceObjectAtIndex:i+1 withObject:sharedDir];
                }
            }
                    
            cocoaQemu *pc = [ [ cocoaQemu alloc ] init ];
            [ pc startPCWithArgs:arguments];
            [ pc release ];
		} else {
		/* ELSE */
            NSOpenPanel *openPanel = [ [ NSOpenPanel alloc ] init ];
            [ openPanel setTitle:@"Please choose an Imagefile" ];
		
            int result;
		
            result = [ openPanel runModalForDirectory:NSHomeDirectory() file:nil types:[ NSArray arrayWithObjects:@"raw",@"img",@"iso",@"dmg",@"qcow",@"qcow2",@"cow",@"cloop",@"vmdk",nil ] ];
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
