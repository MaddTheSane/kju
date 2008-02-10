/*
 * Q Application Controller
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

#import "QApplicationController.h"



@implementation QApplicationController
- (id) init
{
	Q_DEBUG(@"init");

    self = [super init];
    if (self) {

		// preferences
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
			[NSNumber numberWithBool:FALSE], // disable log to console
			[NSNumber numberWithBool:TRUE], // yellow
			[NSNumber numberWithBool:TRUE], // showFullscreenWarning
			[NSMutableArray array], // known VMs
			nil
		] forKeys:[NSArray arrayWithObjects:
			@"enableLogToConsole",
			@"yellow",
			@"showFullscreenWarning",
			@"knownVMs",
			nil]]];
		userDefaults = [NSUserDefaults standardUserDefaults];

		// remove obsolete entries form old preferences
		if ([userDefaults objectForKey:@"enableOpenGL"]) {
			[userDefaults removeObjectForKey:@"enableOpenGL"];
		}
		if ([userDefaults objectForKey:@"display"]) {
			[userDefaults removeObjectForKey:@"display"];
		}
		if ([userDefaults objectForKey:@"enableCheckForUpdates"]) {
			[userDefaults removeObjectForKey:@"enableCheckForUpdates"];
		}
		if ([userDefaults objectForKey:@"dataPath"]) {
			[userDefaults removeObjectForKey:@"dataPath"];
		}
#pragma mark TODO:Sparclekey for userdefaults
		
		// add necessary entries to old preferences
		if (![userDefaults objectForKey:@"dataPath"]) {
			[userDefaults setObject:[NSString stringWithFormat:@"%@/Documents/QEMU", NSHomeDirectory()] forKey:@"dataPath"];
		}

        // create PC directory
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath: [NSString stringWithFormat:@"%@/", [userDefaults objectForKey:@"dataPath"]]] == NO)
            [fileManager createDirectoryAtPath: [NSString stringWithFormat:@"%@/", [userDefaults objectForKey:@"dataPath"]] attributes: nil];
        }
        
        // uniqueDocumentIDs
        uniqueDocumentID = 7;
    return self;
}

#pragma mark overriding NSDocumentController & NSApp Methods
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	Q_DEBUG(@"applicationShouldOpenUntitledFile");

    // we want no untitled doc
    return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[userDefaults synchronize];
	[[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:self didCloseAllSelector:@selector(documentController:didCloseAll:contextInfo:) contextInfo:nil];

	return NSTerminateLater;
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	Q_DEBUG(@"openPanelDidEnd");

    if (returnCode == NSOKButton) {
        NSURL *path;
        NSDocumentController *documentController;
        NSDocument *document;
        
//        path = [NSURL URLWithString:[[panel filenames] objectAtIndex:0]];
        if ([[panel filenames] count] < 1) {
            return;
        }
        path = [[panel filenames] objectAtIndex:0];
        documentController = [NSDocumentController sharedDocumentController];
        
        // is this document already open?
        if ([documentController documentForURL:[NSURL fileURLWithPath:(NSString *)path]]) {
            NSLog(@"Document is already open");
            //Todo: show the document
        } else {

            // open the document
            document = [documentController makeDocumentWithContentsOfURL:path ofType:@"QVM" error:nil];
            if (document) {
                [documentController addDocument:document];
                [document makeWindowControllers];
                [document showWindows];
            } else {
                NSLog(@"Document was not created");
            }
        }
    }
    [panel release];
}

- (IBAction) openDocument:(id)sender
{
	Q_DEBUG(@"applicationShouldOpenUntitledFile");
    
    //myDoc
    [[[NSOpenPanel openPanel] retain]
        beginForDirectory:[userDefaults objectForKey:@"pcData"]
        file:nil
        types:[NSArray arrayWithObject:@"qvm"]
        modelessDelegate:self
        didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
        contextInfo:nil];
}

- (void)documentController:(NSDocumentController *)docController  didCloseAll: (BOOL)didCloseAll contextInfo:(void *)contextInfo
{
	Q_DEBUG(@"QApplicationController: documentController: didCloseAll");

	[NSApp replyToApplicationShouldTerminate:YES];
}


-(int) leaseAUniqueDocumentID:(id)sender
{
	Q_DEBUG(@"leaseAUniqueDocumentID");

    uniqueDocumentID++;
    
    return uniqueDocumentID;
}

#pragma mark getters
- (NSUserDefaults *) userDefaults {return userDefaults;}
@end
