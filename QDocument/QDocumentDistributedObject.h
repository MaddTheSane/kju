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

 
#import <Cocoa/Cocoa.h>

#define Q_COMMANDS_MAX 100

typedef struct QCommand
{
    char command;
    int arg1;
    int arg2;
    int arg3;
    int arg4;
} QCommand;

// to be implemented by QEMU
@protocol QDocumentDistributedObjectClientProto <NSObject>
@property (readonly, copy) NSString *testClient;
- (BOOL) do_kbd_put_keycode:(int)keycode;
- (BOOL) do_kbd_mouse_eventDx:(int)dx dy:(int)dy dz:(int)dz bs:(int)sb;
@end

// to be implemented by Q Control
@protocol QDocumentDistributedObjectServerProto <NSObject>
- (BOOL) qemuRegister:(id)sender;
- (BOOL) qemuUnRegister:(id)sender;
- (BOOL) sendMessage:(NSData*)data;
//- (BOOL) screenBufferLine:(NSData*)data start:(size_t)start length:(size_t)length;
- (BOOL) displayRect:(NSRect)rect;
- (BOOL) resizeTo:(NSSize)size;
- (NSData*) getComandsSetAbsolute:(BOOL)absolute;
- (void) setCpu:(float)tCpuUsage ideActivity:(BOOL)tIdeActivity;
- (NSData*) getFilename:(int)drive;
- (BOOL) setVm_running:(BOOL)isRunning;
@end

@class QDocument;

@interface QDocumentDistributedObject : NSObject <QDocumentDistributedObjectServerProto>
@property (readonly, strong) id qemu;
- (instancetype) initWithSender:(QDocument*)sender NS_DESIGNATED_INITIALIZER;
- (void) setCommand:(char)command arg1:(int)arg1 arg2:(int)arg2 arg3:(int)arg3 arg4:(int)arg4;

- (BOOL) qemuRegister:(id)sender;
- (BOOL) qemuUnRegister:(id)sender;
- (BOOL) sendMessage:(NSData*)data;
//- (BOOL) screenBufferLine:(NSData*)data start:(size_t)start length:(size_t)length;
- (BOOL) displayRect:(NSRect)rect;
- (BOOL) resizeTo:(NSSize)size;
- (NSData*) getComandsSetAbsolute:(BOOL)absolute;
- (void) setCpu:(float)tCpuUsage ideActivity:(BOOL)tIdeActivity;
- (NSData*) getFilename:(int)drive;
- (BOOL) setVm_running:(BOOL)isRunning;
@end
