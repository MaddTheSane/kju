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

#import <unistd.h>

#import "cocoaControlDOServer.h"

#import "cocoaControlController.h"

#import "../host-cocoa/CGSPrivate.h"

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

-(void) setSender:(id)sender
{
//	  NSLog(@"cocoaControlDOServer: setSender");

    qControl = sender;
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

- (BOOL) guestSwitch: (NSString *) name fullscreen:(BOOL)fullscreen nextGuestName:(NSString *)nextGuestName
{
//    NSLog(@"guestSwitch: windowSwitchKeyPressed:%@ fullscreen:%d nextGuest:%@\n", name, fullscreen, nextGuestName);

    int i;
    int a = 0;
    NSArray *keys = [guests allKeys];
    
    if (nextGuestName) {
        for (i = 0; i < [keys count]; i++) {
            if ([[keys objectAtIndex:i] isEqual:nextGuestName]) {
                a = i;
            }
        }
    } else {
        for (i = 0; i < [keys count]; i++) {
            if ([[keys objectAtIndex:i] isEqual:name]) {
                a = i + 1;
            }
        }
    }
    
    ProcessSerialNumber psn;
    id obj = nil;
    BOOL nFullscreen = FALSE;
    
    if (a < [keys count]) {
		/* move QEMU to front */
		GetProcessForPID( [[[qControl pcsTasks] objectForKey:[keys objectAtIndex:a]] processIdentifier], &psn );
		obj = [guests objectForKey:[keys objectAtIndex:a]];
		if ([obj fullscreen])
            nFullscreen = TRUE;
    } else
        GetProcessForPID( [[NSProcessInfo processInfo ] processIdentifier ], &psn );
    
    if (fullscreen||nFullscreen) {
        /* setup transition */        CGSConnection cid = _CGSDefaultConnection();        int transitionHandle = -1;        CGSTransitionSpec transitionSpecifications;
        transitionSpecifications.type = 7;          //transition;
        transitionSpecifications.option = 0;        //option;
        transitionSpecifications.wid = 0;           //wid        transitionSpecifications.backColour = 0;    //background color        /* freeze desktop: OSStatus CGSNewTransition(const CGSConnection cid, const CGSTransitionSpec* transitionSpecifications, int *transitionHandle) */        CGSNewTransition(cid, &transitionSpecifications, &transitionHandle);                            
        /* change windows */
        if (nFullscreen)
            [obj guestUnhide];

        if (fullscreen)
            [[guests objectForKey:name] guestHide];

        if (a < [keys count]) //avoid activating "Q Control"
            SetFrontProcess( &psn );
        else {
            [[qControl mainWindow] orderWindow:NSWindowAbove relativeTo:[[guests objectForKey:name] guestWindowNumber]];
            SetFrontProcess( &psn );
        }
                      
        /* wait */        usleep(10000);
                       
        /* run transition: OSStatus CGSInvokeTransition(const CGSConnection cid, int transitionHandle, float duration) */        CGSInvokeTransition(cid, transitionHandle, 1.0);

        /* release transition: OSStatus CGSReleaseTransition(const CGSConnection cid, int transitionHandle) */
//        CGSReleaseTransition(cid, transitionHandle);
    } else {
        if (a < [keys count]) //avoid activating "Q Control"
            SetFrontProcess( &psn );
        else {
            [[qControl mainWindow] orderWindow:NSWindowAbove relativeTo:[[guests objectForKey:name] guestWindowNumber]];
            SetFrontProcess( &psn );
        }
    }
    
    
    
	return true;	
//    id obj = [guests objectAtIndex:a];
//    return [self guestOrderFrontRegardless:[keys objectAtIndex:a]];
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

- (BOOL) guestPause: (NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: pause: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestPause];
	} else {
		NSLog(@"cocoaControlDOServer: cocoaControlDOServer: failed");
		return FALSE;
	}
}

- (BOOL) guestStop: (NSString *) guest
{
//	NSLog(@"cocoaControlDOServer: stop: %@", guest);

	id obj = [guests objectForKey:guest];
	if (obj != nil) {
//		NSLog(@"OK");
		return [obj guestStop];
	} else {
		NSLog(@"cocoaControlDOServer: cocoaControlDOServer: failed");
		return FALSE;
	}
}
@end