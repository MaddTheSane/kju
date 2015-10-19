/*
 * Q Document Task Controller
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

#import "QDocumentTaskController.h"
#import "QDocument.h"
#import "../QShared/QQvmManager.h"
#import "QDocumentOpenGLView.h"


@implementation QDocumentTaskController
- (instancetype) initWithFile:(NSString *)file sender:(QDocument*)sender
{
	Q_DEBUG(@"initWithFile: %@", file);

    self = [super init];
    if (self) {
        
        // we are part of this document
        document = (QDocument *)sender;

        // we want to be notified when QEMU quits
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkATaskStatus:) name:NSTaskDidTerminateNotification object:nil];
    
        // start a qemu instance
        [self startQemuForFile:file];

    }
    return self;
}



- (void) dealloc
{
	Q_DEBUG(@"dealloc");

    // remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // make sure QEMU does not survive!
    if (task) {
		if ([task isRunning]) { //make shure it's dead
			[task terminate];
		}
    }
}



- (void) checkATaskStatus:(NSNotification *)aNotification
{
	Q_DEBUG(@"checkATaskStatus: %D", [[aNotification object] terminationStatus]);

    // we are only intrested in our instance of QEMU!
    if ([task processIdentifier] != [[aNotification object] processIdentifier])
        return;

    int status = [[aNotification object] terminationStatus];

    // we have clean shutdown
    if (status == 0) {
		[document setVMState:QDocumentShutdown];

    // we have clean save and shutdown
    } else if (status == 2) {
		[document setVMState:QDocumentSaved];

    // we have an error here
    } else {
        
        // save shutdownstate
		[document setVMState:QDocumentShutdown];

        // error management here, we display the qemu output, if the user has enabled it
        if ([[[document qApplication] userDefaults] boolForKey:@"enableLogToConsole"]) {
            NSData * pipedata;
            while ((pipedata = [[[task standardOutput] fileHandleForReading] availableData]) && [pipedata length]) {
                NSString * console_out = [[NSString alloc] initWithData:pipedata encoding:NSUTF8StringEncoding];
                // trim string to only contain the error
                NSArray * comps = [console_out componentsSeparatedByString:@": "];
                [document defaultAlertMessage:@"Error: QEMU quited unexpected!" informativeText:[comps objectAtIndex:1]];
            }
        } else {
			[document defaultAlertMessage:@"Error: QEMU quited unexpected!" informativeText:@"TODO: This should be replaced by real output"];
		}
    }

    // cleanup
	if ([document canCloseDocumentClose]) { // callback for closeAllDocumentsWithDelegate
		[document docShouldClose:self];
	} else {
		[[document screenView] display];
	}
}



- (BOOL) addArgumentTo:(id)arguments option:(id)option argument:(id)argument filename:(NSString*)filename
{
	Q_DEBUG(@"addArgumentTo: option:%@ argument:%@ filename:%@", option, argument, filename);

    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *relativePathKeys = [NSArray arrayWithObjects:@"-fda", @"-fdb", @"-hda", @"-hdb", @"-hdc", @"-hdd", @"-cdrom", @"-kernel", @"-initrd", nil];

    // find the first cdrom of the mac
    if ([argument isEqual:@"/dev/cdrom"]) {
        NSString *CDROMPath = [document firstCDROMDrive];
        if (CDROMPath) {
            NSLog(@"CDROM: %@", CDROMPath);
            [arguments addObject:@"-cdrom"];
            [arguments addObject:CDROMPath];
        }
    
    // if files have relative Paths, we guess they are stored in .qvm
    } else if ([relativePathKeys containsObject:option]) {
        [arguments addObject:[NSString stringWithString:option]];
        if ([argument isAbsolutePath]) {
            [arguments addObject:[NSString stringWithString:argument]]; //remove for bools!!!
        } else {
            [arguments addObject:[NSString stringWithFormat:@"%@/%@", filename, argument]]; //remove for bools!!!
        }

    // "-smb", prepare Folder for Q Filesharing
    } else if ([option isEqual:@"-smb"]) {
        // Q Filesharing
        if ([argument isEqual:@"~/Desktop/Q Shared Files/"]) {
			[fileManager createDirectoryAtPath:[@"~/Desktop/Q Shared Files/" stringByExpandingTildeInPath] attributes: @{}];
            [arguments addObject:@"-smb"];
            [arguments addObject:[@"~/Desktop/Q Shared Files/" stringByExpandingTildeInPath]];
        // normal SMB
        } else if ([fileManager fileExistsAtPath:argument]) {
            [arguments addObject:@"-smb"];
            [arguments addObject:[NSString stringWithString:argument]];
        }
        
    // standard
    } else {    
        [arguments addObject:[NSString stringWithString:option]];
        if (![argument isEqual:@""]) {
            [arguments addObject:[NSString stringWithString:argument]];
        }
    }
    return TRUE;
}



- (void) startQemuForFile:(NSString *)filename
{
	Q_DEBUG(@"startPC:%@", filename);

	int i;
    NSDictionary *cpuTypes;
	NSMutableArray *arguments;
	NSString *key;
	NSMutableArray *explodedArguments;
	
	cpuTypes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"i386-softmmu",@"x86_64-softmmu",@"ppc-softmmu",@"sparc-softmmu",@"mips-softmmu",@"arm-softmmu",nil] forKeys:[NSArray arrayWithObjects:@"x86",@"x86-64",@"PowerPC",@"SPARC",@"MIPS",@"ARM",nil]];

    // if this PC is already running, abort
    if ([[[[document configuration] objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"running"]) {
        [document defaultAlertMessage:@"QDocumentTaskController: Guest already running!" informativeText:nil];
        return;
    }
    
    // set qemu properties
    // WMStopWhenInactive
    if ([[[document configuration] objectForKey:@"Temporary"] objectForKey:@"WMStopWhenInactive"])
        [document VMSetPauseWhileInactive:TRUE];
        
    // add Arguments for Q
    arguments = [[NSMutableArray alloc] init];

    // Q Windows Drivers
    if ([[[document configuration] objectForKey:@"Temporary"] objectForKey:@"QWinDrivers"]) {
        [arguments addObject: @"-hdb"];
        [arguments addObject:[NSString stringWithFormat:@"%@/Contents/Resources/qdrivers.qcow", [[NSBundle mainBundle] bundlePath]]];
    }
 
    // Arguments of configuration
	explodedArguments = [[QQvmManager sharedQvmManager] explodeVMArguments:[[document configuration] objectForKey:@"Arguments"]];
	key = nil;
	for (i = 0; i < [explodedArguments count]; i++) {
		if ([[explodedArguments objectAtIndex:i] characterAtIndex:0] == '-') { // key
			if (key) { // store previous key
				if (![self addArgumentTo:arguments option:key argument:@"" filename:filename]) {
					[document defaultAlertMessage:@"QDocumentTaskController: can't add argument" informativeText:nil];
					return;
				}
			}
			key = [explodedArguments objectAtIndex:i];
		} else { // argument
			if (![self addArgumentTo:arguments option:key argument:[explodedArguments objectAtIndex:i] filename:filename]) {
                [document defaultAlertMessage:@"QDocumentTaskController: can't add argument" informativeText:nil];
                return;
			}
			key = nil;
		}
	}
	if (key) { // store previous key
		if (![self addArgumentTo:arguments option:key argument:@"" filename:filename]) {
			[document defaultAlertMessage:@"QDocumentTaskController: can't add argument" informativeText:nil];
			return;
		}
	}
              
    // start a saved vm
    if ([[[[document configuration] objectForKey:@"PC Data"] objectForKey:@"state"] isEqual:@"saved"]) {
        [arguments addObject: @"-loadvm"];
        [arguments addObject: @"kju"];
    }
    
    // add uniqueDocumentID for distributed object
    [arguments addObject: @"-distributedobject"];
    [arguments addObject: [NSString stringWithFormat:@"qDocument_%D", [document uniqueDocumentID]]];
NSLog(@"ARGUMENTS: %@", arguments);
    // save Status
    [[[document configuration] objectForKey:@"PC Data"] setObject:@"running" forKey:@"state"];
    [[QQvmManager sharedQvmManager] saveVMConfiguration:[document configuration]];

    task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:[NSString stringWithFormat:@"%@/Contents/Resources/bin/", [[NSBundle mainBundle] bundlePath]]];
    [task setLaunchPath:[NSString stringWithFormat:@"%@/Contents/Resources/bin/%@", [[NSBundle mainBundle] bundlePath], [cpuTypes objectForKey:[[[document configuration] objectForKey:@"PC Data"] objectForKey:@"architecture"]], [cpuTypes objectForKey:[[[document configuration] objectForKey:@"PC Data"] objectForKey:@"architecture"]]]];
    [task setArguments:arguments];

    if ([[[document qApplication] userDefaults] boolForKey:@"enableLogToConsole"]) {
        // prepare nstask output to grab exit codes and display a standardAlert when the qemu instance crashed
        NSPipe * pipe = [[NSPipe alloc] init];
        [task setStandardOutput:pipe];
        [task setStandardError:pipe];
        
    }
    
	[document setVMState:QDocumentLoading];
    [task launch];
}


- (NSTask *) task {return task;}
@end
