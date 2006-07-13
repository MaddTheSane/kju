/*
 * QEMU Cocoa Control Distributed Object Server
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
 
#import <Cocoa/Cocoa.h>

/* guest Protocol */
@protocol cocoaControlDOGuestProto
- (int) guestWindowLevel;
- (int) guestWindowNumber;
- (BOOL) guestOrderFrontRegardless;
- (BOOL) guestOrderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWindowNumber;
- (BOOL) guestHide;
- (BOOL) guestUnhide;
- (BOOL) guestPause;
- (BOOL) guestStop;
@end

/* Q Control protocol */
@protocol cocoaControlDOServerProto
- (BOOL) guestRegister: (byref id)guest withName:(bycopy NSString *) name;
- (BOOL) guestUnregisterWithName: (bycopy NSString *) name;
@end
 
 
 
@interface cocoaControlDOServer : NSObject <cocoaControlDOServerProto> {
    NSMutableDictionary * guests;
}
- (id) init;
- (BOOL) guestRegister: (id)client withName: (NSString *)name;
- (BOOL) guestUnregisterWithName: (NSString *)name;
- (int) guestWindowLevel: (NSString *) guest;
- (int) guestWindowNumber: (NSString *) guest;
- (BOOL) guestOrderFrontRegardless: (NSString *) guest;
- (BOOL) guestOrderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWindowNumber guest:(NSString *) guest;
- (BOOL) guestHide: (NSString *) guest;
- (BOOL) guestUnhide: (NSString *) guest;
- (BOOL) guestPause: (NSString *) guest;
- (BOOL) guestStop: (NSString *) guest;
@end