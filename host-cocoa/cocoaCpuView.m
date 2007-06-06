/*
 * QEMU Cocoa CpuView
 * 
 * Copyright (c) 2005 - 2007 Mike Kronenberg
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

#import "cocoaCpuView.h"
#import "../vl.h"
#import "../block_int.h"

#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/task.h>
#include <mach/task_info.h>
#include <mach/thread_info.h>
#include <mach/thread_act.h>
#include <mach/mach_init.h>



@implementation cocoaCpuView

- (void) encodeWithCoder:(NSCoder *) coder
{
//  NSLog(@"cocoaCpuView: encodeWithCoder");

    [super encodeWithCoder:coder];
    [coder encodeObject: [self image] forKey:@"regularImage"];
}

- (id) initWithCoder:(NSCoder *) coder
{
//  NSLog(@"cocoaCpuView: initWithCoder");

    if ((self = [super initWithCoder:coder])) {
        regularImage = [[coder decodeObjectForKey:@"regularImage"] retain];
        smallImage = nil;
        ctlSize = NSRegularControlSize;
        
        return self;
    }
    return nil;
}

- (id) initWithImage:(NSImage *) image
{
//  NSLog(@"cocoaPopUpView: initWithImage");

    if( ( self = [super initWithFrame:NSMakeRect(0.,0.,[image size].width,[image size].height)] ) ) {
        [self setImage:image];
        return self;
    }
    
    return nil;
}

- (void) dealloc
{
//  NSLog(@"cocoaCpuView: dealloc");

    [regularImage release];
    [smallImage release];

    regularImage = nil;
    smallImage = nil;

    [super dealloc];
}

- (void) drawRect:(NSRect) rect
{
//  NSLog(@"cocoaCpuView: drawRect");

    /* CPU Activity */
    NSBezierPath* path = [NSBezierPath bezierPath];
    kern_return_t error;    
    struct thread_basic_info tbi;
    unsigned int thread_info_count;
    task_port_t task;
    float cpuUsage = 0.;
    thread_act_array_t threadList;                      //#include <mach/thread_act.h>
    mach_msg_type_number_t threadCount;
    threadCount = 0;
    thread_info_count = THREAD_BASIC_INFO_COUNT;
    int c;
    error = task_for_pid(
        mach_task_self(),                               //task_port_t task #include <mach/mach_init.h>
        [[NSProcessInfo processInfo] processIdentifier],//pid_t pid
        &task);                                         //task_port_t *target
#ifdef QDEBUG
    if (error != KERN_SUCCESS)
       NSLog(@"Call to task_for_pid() failed");
#endif
    error = task_threads(                               //#include <mach/task.h>
        task,                                           //task_t target_task
        &threadList,                                    //thread_act_array_t *act_list
        &threadCount);                                  //mach_msg_type_number_t *act_listCnt
#ifdef QDEBUG
    if (error != KERN_SUCCESS)
       NSLog(@"Call to task_threads() failed");
#endif
    for (c = 0; c < threadCount; c++) {
        thread_info_count = THREAD_BASIC_INFO_COUNT;
        error = thread_info(                            //#include <mach/thread_act.h>
            threadList[c],                              //thread_act_t target_act
            THREAD_BASIC_INFO,                          //thread_flavor_t flavor
            &tbi,                                       //thread_info_t thread_info_out
            &thread_info_count);                        //mach_msg_type_number_t *thread_info_outCnt
#ifdef QDEBUG
        if (error != KERN_SUCCESS)
            NSLog(@"Call to thread_info() failed");
#endif  
        cpuUsage += tbi.cpu_usage;
    }
    cpuUsage = cpuUsage * 0.05;

    [[NSColor blackColor] set]; 
    path = [NSBezierPath bezierPath];

    if( ctlSize == NSRegularControlSize ) {
        [regularImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver]; //(12,0)
        [path moveToPoint:NSMakePoint(16, 1)];
        [path lineToPoint:NSMakePoint(16. - cos(pi / 180. * (65. + cpuUsage)) * 16., sin(pi / 180. * (65. + cpuUsage)) * 29.)];
    } else {
        [smallImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver]; //(9,0)
        [path moveToPoint:NSMakePoint(12, 2)];
        [path lineToPoint:NSMakePoint(12. - cos(pi / 180. * (65. + cpuUsage)) * 11., sin(pi / 180. * (65. + cpuUsage)) * 22.)];
    }
    [path stroke];


    /* Drive Activity Indicator */
    BOOL DrivesAreActive = FALSE;
    BlockDriverState *bs;

    /* hda */
    bs = bdrv_find([@"hda" cString]);
    if (bs) {
        if (bs->activityLED) {
            DrivesAreActive = YES;
            bs->activityLED = 0;
        }
    }

    /* CD-ROM */
    bs = bdrv_find([@"cdrom" cString]);
    if (bs) {
        if (bs->activityLED) {
            DrivesAreActive = YES;
            bs->activityLED = 0;
        }
    }

    /* hdc */
    bs = bdrv_find([@"hdc" cString]);
    if (bs) {
        if (bs->activityLED) {
            DrivesAreActive = YES;
            bs->activityLED = 0;
        }
    }

    /* hdd */
    bs = bdrv_find([@"hdd" cString]);
    if (bs) {
        if (bs->activityLED) {
            DrivesAreActive = YES;
            bs->activityLED = 0;
        }
    }

    /* draw Indicator */
    if (DrivesAreActive) {
//        [[NSColor yellowColor] setFill]; //E3BD00 //D9D401
        [[NSColor colorWithDeviceRed:.89 green:.74 blue:.0 alpha:1.] setFill];
    } else {
        [[NSColor blackColor] setFill];
    }
    if( ctlSize == NSRegularControlSize ) {
        NSRectFill(NSMakeRect(3,2,26,2));
    } else {
        NSRectFill(NSMakeRect(2,2,20,2));
    }
}

- (void) mouseDown:(NSEvent *) theEvent
{
//  NSLog(@"cocoaCpuView: mouseDown");

}

- (NSControlSize) controlSize
{
//  NSLog(@"cocoaCpuView: controlSize");

    return ( ctlSize ? ctlSize : NSRegularControlSize );
}

- (void) setControlSize:(NSControlSize) controlSize {
    if( controlSize == NSRegularControlSize ) {
        [toolbarItem setMinSize:NSMakeSize( 32., 32. )];
        [toolbarItem setMaxSize:NSMakeSize( 32., 32. )];
    } else if( controlSize == NSSmallControlSize ) {
        [toolbarItem setMinSize:NSMakeSize( 24., 24. )];
        [toolbarItem setMaxSize:NSMakeSize( 24., 24. )];
    }
    ctlSize = controlSize;
}
- (NSImage *) image;
{
//  NSLog(@"cocoaPopUpView: image");

    return regularImage;
}

- (void) setImage:(NSImage *) image
{
//  NSLog(@"cocoaPopUpView: setImage");

    int i;
    BOOL g = false;
    BOOL s = false;

    NSArray *reps = [image representations];
    for (i=0; i<[reps count]; i++) {
        if ([[reps objectAtIndex:i] pixelsHigh] == 32) {
            [regularImage autorelease];
            regularImage = [[NSImage alloc] initWithSize:NSMakeSize( 32., 32. )];
            [regularImage addRepresentation:[reps objectAtIndex:i]];
            g = true;
        } else if ([[reps objectAtIndex:i] pixelsHigh] == 24) {
            [smallImage autorelease];
            smallImage = [[NSImage alloc] initWithSize:NSMakeSize( 24., 24. )];
            [smallImage addRepresentation:[reps objectAtIndex:i]];
            s = true;
        }
    }
    
    if (!g) {
        [regularImage autorelease];
        regularImage = [image copy];
    }
    
    if (!s) {
        NSImageRep *sourceImageRep = [image bestRepresentationForDevice:nil];
        [smallImage autorelease];
        smallImage = [[NSImage alloc] initWithSize:NSMakeSize( 24., 24. )];
        [smallImage lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImageRep drawInRect:NSMakeRect( 0., 0., 24., 24. )];
        [smallImage unlockFocus];
    }
}

- (NSToolbarItem *) toolbarItem
{
//  NSLog(@"cocoaCpuView: toolbarItem");

    return [[toolbarItem retain] autorelease];
}

- (void) setToolbarItem:(NSToolbarItem *) item {
    toolbarItem = item;
}

- (void) updateToolbarItem:(NSTimer*) timer
{
//  NSLog(@"cocoaCpuView: updateToolbarItem");

    [self setNeedsDisplay:YES];
}
@end
