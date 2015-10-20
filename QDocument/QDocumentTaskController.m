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


@implementation QDocumentTaskController {
	__weak QDocument *document;
}
@synthesize task;

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
		if (task.running) { //make shure it's dead
			[task terminate];
		}
    }
}

- (void) checkATaskStatus:(NSNotification *)aNotification
{
	Q_DEBUG(@"checkATaskStatus: %D", [[aNotification object] terminationStatus]);

    // we are only intrested in our instance of QEMU!
    if (task.processIdentifier != [aNotification.object processIdentifier])
        return;

    int status = [aNotification.object terminationStatus];

    // we have clean shutdown
    if (status == 0) {
		document.VMState = QDocumentShutdown;

    // we have clean save and shutdown
    } else if (status == 2) {
		document.VMState = QDocumentSaved;

    // we have an error here
    } else {
        
        // save shutdownstate
		document.VMState = QDocumentShutdown;

        // error management here, we display the qemu output, if the user has enabled it
        if ([[document.qApplication userDefaults] boolForKey:@"enableLogToConsole"]) {
            NSData * pipedata;
            while ((pipedata = [task.standardOutput fileHandleForReading].availableData) && pipedata.length) {
                NSString * console_out = [[NSString alloc] initWithData:pipedata encoding:NSUTF8StringEncoding];
                // trim string to only contain the error
                NSArray * comps = [console_out componentsSeparatedByString:@": "];
                [document defaultAlertMessage:@"Error: QEMU quited unexpected!" informativeText:comps[1]];
            }
        } else {
			[document defaultAlertMessage:@"Error: QEMU quited unexpected!" informativeText:@"TODO: This should be replaced by real output"];
		}
    }

    // cleanup
	if (document.canCloseDocumentClose) { // callback for closeAllDocumentsWithDelegate
		[document docShouldClose:self];
	} else {
		[document.screenView display];
	}
}

- (BOOL) addArgumentTo:(id)arguments option:(id)option argument:(id)argument filename:(NSString*)filename
{
	Q_DEBUG(@"addArgumentTo: option:%@ argument:%@ filename:%@", option, argument, filename);

    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *relativePathKeys = @[@"-fda", @"-fdb", @"-hda", @"-hdb", @"-hdc", @"-hdd", @"-cdrom", @"-kernel", @"-initrd"];

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
			NSURL *sharedFiles = [[fileManager URLForDirectory:NSDesktopDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil] URLByAppendingPathComponent:@"Q Shared Files" isDirectory:YES];
			[fileManager createDirectoryAtURL:sharedFiles withIntermediateDirectories:NO attributes:nil error:nil];
            [arguments addObject:@"-smb"];
            [arguments addObject:sharedFiles.path];
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
	NSMutableArray *arguments;
	NSString *key;
	NSMutableArray *explodedArguments;
	
	NSDictionary *cpuTypes = @{@"x86": @"i386-softmmu",@"x86-64": @"x86_64-softmmu",@"PowerPC": @"ppc-softmmu",@"SPARC": @"sparc-softmmu",@"MIPS": @"mips-softmmu",@"ARM": @"arm-softmmu"};

    // if this PC is already running, abort
    if ([[document configuration][@"PC Data"][@"state"] isEqual:@"running"]) {
        [document defaultAlertMessage:@"QDocumentTaskController: Guest already running!" informativeText:nil];
        return;
    }
    
    // set qemu properties
    // WMStopWhenInactive
    if ([document configuration][@"Temporary"][@"WMStopWhenInactive"])
        [document VMSetPauseWhileInactive:TRUE];
        
    // add Arguments for Q
    arguments = [[NSMutableArray alloc] init];

    // Q Windows Drivers
    if ([document configuration][@"Temporary"][@"QWinDrivers"]) {
        [arguments addObject: @"-hdb"];
        [arguments addObject:[[NSBundle mainBundle] pathForResource:@"qdrivers" ofType:@"qcow"]];
    }
 
    // Arguments of configuration
	explodedArguments = [[[QQvmManager sharedQvmManager] explodeVMArguments:[document configuration][@"Arguments"]] mutableCopy];
	key = nil;
	for (i = 0; i < explodedArguments.count; i++) {
		if ([explodedArguments[i] characterAtIndex:0] == '-') { // key
			if (key) { // store previous key
				if (![self addArgumentTo:arguments option:key argument:@"" filename:filename]) {
					[document defaultAlertMessage:@"QDocumentTaskController: can't add argument" informativeText:nil];
					return;
				}
			}
			key = explodedArguments[i];
		} else { // argument
			if (![self addArgumentTo:arguments option:key argument:explodedArguments[i] filename:filename]) {
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
    if ([[document configuration][@"PC Data"][@"state"] isEqual:@"saved"]) {
        [arguments addObject: @"-loadvm"];
        [arguments addObject: @"kju"];
    }
    
    // add uniqueDocumentID for distributed object
    [arguments addObject: @"-distributedobject"];
    [arguments addObject: [NSString stringWithFormat:@"qDocument_%D", document.uniqueDocumentID]];
	NSLog(@"ARGUMENTS: %@", arguments);
    // save Status
    [document configuration][@"PC Data"][@"state"] = @"running";
    [[QQvmManager sharedQvmManager] saveVMConfiguration:[document configuration]];

    task = [[NSTask alloc] init];
	NSString *binDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bin"];
    task.currentDirectoryPath = binDir;
	task.launchPath = [binDir stringByAppendingPathComponent:cpuTypes[[document configuration][@"PC Data"][@"architecture"]]];
    task.arguments = arguments;

    if ([[document.qApplication userDefaults] boolForKey:@"enableLogToConsole"]) {
        // prepare nstask output to grab exit codes and display a standardAlert when the qemu instance crashed
        NSPipe * pipe = [NSPipe pipe];
        task.standardOutput = pipe;
        task.standardError = pipe;
    }
    
	document.VMState = QDocumentLoading;
    [task launch];
}

@end
