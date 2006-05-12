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
 
#import "cocoaControlDOServer.h"

@implementation cocoaControlDOServer

- (id) init
{
//	  NSLog(@"cocoaControlDOServer: init:%@ withName:%@\n", [guest description], name);

	[super init];

	NSConnection *theConnection;
	theConnection = [NSConnection defaultConnection];
	[theConnection setRootObject:self];

	if ([theConnection registerName:@"qdoserver"] == NO) {
		NSLog(@"cocoaControlDOServer: could not establisch qcontrol server");
	}

	guests = [[NSMutableDictionary alloc] init];
	[guests retain];
	
	printf("finished init\n");
	
	return self;
}

- (BOOL) guestRegister: (id) guest withName: (NSString *) name
{
//	  NSLog(@"cocoaControlDOServer: registerGuest:%@ withName:%@\n", [guest description], name);
	
	if ([guests objectForKey:name] == nil) {
		[guests setObject:guest forKey:name];
//		NSLog(@"OK");
		return TRUE;
	} else {
		NSLog(@"cocoaControlDOServer: guestRegister: failed");
		return FALSE;
	}
}

- (BOOL) guestUnregisterWithName: (NSString *) name
{
//	  NSLog(@"cocoaControlDOServer: unregisterGuestWithName:%@\n", name);
	
	if ([guests objectForKey:name] != nil) {
		[guests removeObjectForKey:name];
//		NSLog(@"OK");
		return TRUE;
	} else {
		NSLog(@"cocoaControlDOServer: guestUnregisterWithName: failed");
		return FALSE;
	}
}

- (int) guestWindowLevel: (NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: guestWindowLevel: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestWindowLevel];
	} else {
		NSLog(@"cocoaControlDOServer: guestWindowLevel: failed");
		return FALSE;
	}
}

- (int) guestWindowNumber: (NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: guestWindowNumber: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestWindowNumber];
	} else {
		NSLog(@"cocoaControlDOServer: guestWindowNumber: failed");
		return FALSE;
	}
}

- (BOOL) guestOrderFrontRegardless: (NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: bringToFront: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestOrderFrontRegardless];
	} else {
		NSLog(@"cocoaControlDOServer: guestOrderFrontRegardless");
		return FALSE;
	}
}

- (BOOL) guestOrderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWindowNumber guest:(NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: guestOrderWindow: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestOrderWindow:place relativeTo:otherWindowNumber];
	} else {
		NSLog(@"cocoaControlDOServer: guestOrderWindow: failed");
		return FALSE;
	}
}

- (BOOL) guestHide: (NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: hide: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestHide];
	} else {
		NSLog(@"cocoaControlDOServer: guestHide: failed");
		return FALSE;
	}
}

- (BOOL) guestUnhide: (NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: show: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestUnhide];
	} else {
		NSLog(@"cocoaControlDOServer: cocoaControlDOServer: failed");
		return FALSE;
	}
}
@end