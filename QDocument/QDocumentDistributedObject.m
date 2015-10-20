/*
 * Q Document Distributed Object
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

#import "QDocumentDistributedObject.h"
#import "QDocument.h"
#import "QDocumentOpenGLView.h"


@implementation QDocumentDistributedObject
{
	NSConnection *theConnection;
}
- (instancetype) initWithSender:(QDocument*)sender
{
	Q_DEBUG(@"init");

    self = [super init];
    if (self) {
        
        // we are part of this document
        document = sender;
    
        // initialize qemu environmentt
        commandBuffer = malloc(Q_COMMANDS_MAX*sizeof(QCommand));

        // Open a connection, so the QEMU instance can connect to us
        theConnection = [NSConnection new];
		[theConnection runInNewThread]; //we must run multithreaded: applicationShouldTerminate blocks the main thread
        theConnection.rootObject = self;
        if ([theConnection registerName:[NSString stringWithFormat:@"qDocument_%D", document.uniqueDocumentID]] == NO) {
            NSLog(@"QDistributedObject: could not establisch qDocument_%D server", document.uniqueDocumentID);
            return nil;
        }

    }
    return self;
}

- (void) dealloc
{
	Q_DEBUG(@"dealloc");

	free(commandBuffer);
}



-(id) qemu { return qemu;}




// everything DO related
- (BOOL) qemuRegister:(id)sender
{
	Q_DEBUG(@"qemuRegister");

    qemu = sender;
    return TRUE;
}

- (BOOL) qemuUnRegister:(id)sender
{
	Q_DEBUG(@"qemuUnRegister");

    qemu = nil;
    return TRUE;
}

- (BOOL) sendMessage:(NSData*)data
{
	Q_DEBUG(@"sendMessage");

    NSLog(@"QDistributedObject: sendMessage: %s", data.bytes);
    return TRUE;
}
/*
- (BOOL) screenBufferLine:(NSData*)data start:(size_t)start length:(size_t)length
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"QDistributedObject: screenBufferLine: start:%d length:%d", start, length);
#endif
    
    UInt8 *pixelPointer;
    pixelPointer = [(QDocumentQuartzView *)[(QDocument *)document screenView] screenBuffer];
    memcpy(&pixelPointer[start], [data bytes], length);
    
    return TRUE;
}
*/
- (BOOL) displayRect:(NSRect)rect
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"QDistributedObject: displayRect: rect(%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
#endif

    NSRect tRect;
	tRect = NSMakeRect(
		rect.origin.x * document.screenView.displayProperties.dx,
		(document.screenView.screenProperties.height - rect.origin.y - rect.size.height) * document.screenView.displayProperties.dy,
		rect.size.width * document.screenView.displayProperties.dx,
		rect.size.height * document.screenView.displayProperties.dy);

    [document.screenView displayRect:tRect];

    return true;
}

- (BOOL) resizeTo:(NSSize)size
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"QDistributedObject: resizeTo: rect(%f, %f)", size.width, size.height);
#endif

    [document.screenView resizeContentToWidth:(int)size.width height:(int)size.height];
    
    return true;
}

- (NSData*) getComandsSetAbsolute:(BOOL)absolute
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"QDistributedObject: getComandsSetAbsolute");
#endif

    // mouse absolute_enabled
    if (absolute != document.absolute_enabled) { // action is needed
        if (absolute) { // enable  tablet
            if (document.screenView.mouseGrabed)
                [document.screenView ungrabMouse];
            [document setAbsolute_enabled:TRUE];
        } else { // disable tablet
            [document setAbsolute_enabled:FALSE];
        }
    }
    
    // prepare commands to be sent
    NSData *data = [NSData dataWithBytesNoCopy:commandBuffer length:commandCount * sizeof(QCommand) freeWhenDone:NO];

    // reset commands
    commandCount = 0;
    commandPointer = commandBuffer;
    
    return data;
}

- (NSData*) getFilename:(int)drive
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"getFilename: drive %D", drive);
#endif

	NSString *fileStr = document.driveFileNames[drive];
	const char* fileSysRep = fileStr.fileSystemRepresentation;
	
    return [NSData dataWithBytes:fileSysRep length:strlen(fileSysRep)];
}

- (void) setCpu:(float)tCpuUsage ideActivity:(BOOL)tIdeActivity
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"QDistributedObject: tCpuUsage: %f %D", tCpuUsage, tIdeActivity);
#endif

    document.cpuUsage = tCpuUsage;
    document.ideActivity = tIdeActivity;
}

- (BOOL) setVm_running:(BOOL)isRunning
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"QDistributedObject: setVm_running: %D", isRunning);
#endif
	if (isRunning) {
		document.VMState = QDocumentRunning;
	} else {
		document.VMState = QDocumentPaused;
	}
	return TRUE;
}

- (void) setCommand:(char)command arg1:(int)arg1 arg2:(int)arg2 arg3:(int)arg3 arg4:(int)arg4
{
#ifdef QDOCUMENTDISTIBUTEDOBJECT_DEBUG
    NSLog(@"QDistributedObject: setCommand: %C %D %D %D %D", command, arg1, arg2, arg3, arg4);
#endif

    if (!commandPointer)
        return;
  
    if (commandCount < Q_COMMANDS_MAX) {
        commandPointer->command = command;
        commandPointer->arg1 = arg1;
        commandPointer->arg2 = arg2;
        commandPointer->arg3 = arg3;
        commandPointer->arg4 = arg4;
        commandPointer++;
        commandCount++;
    }
}
@end
