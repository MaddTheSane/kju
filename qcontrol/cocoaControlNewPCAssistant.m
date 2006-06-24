/*
 * QEMU Cocoa Control New PC Assistant
 * 
 * Copyright (c) 2006 Mike Kronenberg
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

#import "cocoaControlNewPCAssistant.h"
#import "cocoaControlController.h"

@implementation cocoaControlNewPCAssistant
- (void) setQSender:(id)sender
{
    qControl = sender;
}

- (NSPanel *) npaPanel
{
    return npaPanel;
}

- (IBAction) closeNewPCAssistantPanel:(id)sender
{
    [ NSApp endSheet:npaPanel ];
}

- (void)npaPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
//	NSLog(@"cocoaControlEditPC: dIPanelDidEnd");
    [ npaPanel orderOut:self ];
	[ npaPanel release ];
	[ self release ];
}

- (IBAction) preparePC:(id)sender
{
    NSMutableDictionary *thisPC = [[[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:
        [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"Q", @"none", [NSDate date], @"Q guest PC", nil] forKeys:[NSArray arrayWithObjects: @"Author", @"Copyright", @"Date", @"Description", nil]],
        [[NSMutableString alloc] initWithString:@"-m 128 -net nic -net user -cdrom /dev/cdrom -boot c -localtime -smb ~/Desktop/Q Shared Files/"],
        [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[textFieldName stringValue], @"shutdown", @"x86", nil] forKeys:[NSArray arrayWithObjects: @"name", @"state", @"architecture", nil]],
        [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObjects: nil] forKeys:[NSArray arrayWithObjects: nil]],
        @"0.2.0.Q",
        nil
    ] forKeys:[NSArray arrayWithObjects:@"About", @"Arguments", @"PC Data", @"Temporary", @"Version", nil]] retain];
   
    switch ([popUpButtonOS indexOfSelectedItem]) {
        case 0: /* DOS */
        	[thisPC setObject:[[NSMutableString alloc] initWithString:@"-m 16 -net nic -net user -cdrom /dev/cdrom -boot c -hda createNew100"] forKey:@"Arguments"];
            break;
        case 1: /* Win9x */
        	[thisPC setObject:[[NSMutableString alloc] initWithString:@"-m 128 -net nic -net user -cdrom /dev/cdrom -boot c -localtime -smb ~/Desktop/Q Shared Files/ -soundhw sb16 -hda createNew1024"] forKey:@"Arguments"];
            break;
        case 2: /* Win2K */
        	[thisPC setObject:[[NSMutableString alloc] initWithString:@"-m 256 -net nic -net user -cdrom /dev/cdrom -boot c -localtime -smb ~/Desktop/Q Shared Files/ -win2k-hack -soundhw sb16"] forKey:@"Arguments"];
            break;
        case 3: /* WinXP */
        	[thisPC setObject:[[NSMutableString alloc] initWithString:@"-m 256 -net nic -net user -cdrom /dev/cdrom -boot c -localtime -smb ~/Desktop/Q Shared Files/ -soundhw es1370"] forKey:@"Arguments"];
            break;
        case 4: /* WinVista */
        	[thisPC setObject:[[NSMutableString alloc] initWithString:@"-m 512 -net nic -net user -cdrom /dev/cdrom -boot c -localtime -smb ~/Desktop/Q Shared Files/ -win2k-hack -hda createNew15360"] forKey:@"Arguments"];
            break;
        default:
            break;
    }
    [ NSApp endSheet:npaPanel ];
    
    [qControl addPCFromAssistant:thisPC];
}
@end
