/*
 * QEMU Cocoa CpuView
 * 
 * Copyright (c) 2005, 2006 Mike Kronenberg
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
#import "vl.h"

#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/task.h>
#include <mach/task_info.h>
#include <mach/thread_info.h>
#include <mach/thread_act.h>
#include <mach/mach_init.h>

struct BlockDriverState {    int64_t total_sectors;    int read_only; /* if true, the media is read only */    int inserted; /* if true, the media is present */    int removable; /* if true, the media can be removed */    int locked;    /* if true, the media cannot temporarily be ejected */    int encrypted; /* if true, the media is encrypted */
    int activityLED; /* if true, the media is accessed atm */    /* event callback when inserting/removing */    void (*change_cb)(void *opaque);    void *change_opaque;    BlockDriver *drv;    void *opaque;    int boot_sector_enabled;    uint8_t boot_sector_data[512];    char filename[1024];    char backing_file[1024]; /* if non zero, the image is a diff of                                this file image */    int is_temporary;        BlockDriverState *backing_hd;        /* NOTE: the following infos are only hints for real hardware       drivers. They are not used by the block driver */    int cyls, heads, secs, translation;    int type;    char device_name[32];    BlockDriverState *next;};

@implementation cocoaCpuView

- (void) encodeWithCoder:(NSCoder *) coder
{
//	NSLog(@"cocoaCpuView: encodeWithCoder");

	[super encodeWithCoder:coder];
	[coder encodeObject: [self image] forKey:@"regularImage"];
}

- (id) initWithCoder:(NSCoder *) coder
{
//	NSLog(@"cocoaCpuView: initWithCoder");

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
//	NSLog(@"cocoaPopUpView: initWithImage");

	if( ( self = [super initWithFrame:NSMakeRect(0.,0.,[image size].width,[image size].height)] ) ) {
		[self setImage:image];
		return self;
	}
	
	return nil;
}

- (void) dealloc
{
//	NSLog(@"cocoaCpuView: dealloc");

	[regularImage release];
	[smallImage release];

	regularImage = nil;
	smallImage = nil;

	[super dealloc];
}

- (void) drawRect:(NSRect) rect
{
//	NSLog(@"cocoaCpuView: drawRect");
	
    NSBezierPath* path = [NSBezierPath bezierPath];
	
	/* HD Activity */
	BlockDriverState *bs;
	bs = bdrv_find([@"hda" cString]);
	if (bs) {
        path = [NSBezierPath bezierPath];
        if( ctlSize == NSRegularControlSize ) {
            [path setLineWidth:2.0];
            [path appendBezierPathWithOvalInRect:NSMakeRect(1,1,16,16)];
        } else {
            [path appendBezierPathWithOvalInRect:NSMakeRect(1,1,12,12)];
        }
        [[NSColor blackColor] setStroke];
        if (bs->activityLED) {
            [[NSColor greenColor] setFill];
            bs->activityLED = 0;
        } else {
            [[NSColor yellowColor] setFill];
        }
        [path fill];
        [path stroke];
	}
	
	/* CD-ROM Activity */
//	BlockDriverState *bs;
	bs = bdrv_find([@"cdrom" cString]);
	if (bs) {
        path = [NSBezierPath bezierPath];
        if( ctlSize == NSRegularControlSize ) {
            [path setLineWidth:2.0];
            [path appendBezierPathWithOvalInRect:NSMakeRect(39,1,16,16)];
        } else {
            [path appendBezierPathWithOvalInRect:NSMakeRect(29,1,12,12)];
        }
        [[NSColor blackColor] setStroke];
        if (bs->activityLED) {
            [[NSColor greenColor] setFill];
            bs->activityLED = 0;
        } else {
            [[NSColor yellowColor] setFill];
        }
        [path fill];
        [path stroke];
        path = [NSBezierPath bezierPath];
        if( ctlSize == NSRegularControlSize ) {
            [path appendBezierPathWithOvalInRect:NSMakeRect(44,6,6,6)];
        } else {
            [path appendBezierPathWithOvalInRect:NSMakeRect(33,5,4,4)];
        }
        [[NSColor blackColor] setFill];
        [path fill];
	}
	 
    /* CPU Activity */
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
#ifdef qdebug
    if (error != KERN_SUCCESS)
       NSLog(@"Call to task_for_pid() failed");
#endif
    error = task_threads(                               //#include <mach/task.h>
        task,                                           //task_t target_task
        &threadList,                                    //thread_act_array_t *act_list
        &threadCount);                                  //mach_msg_type_number_t *act_listCnt
#ifdef qdebug
    if (error != KERN_SUCCESS)
       NSLog(@"Call to task_threads() failed");
#endif
    for (c = 0; c < threadCount; c++) {
        thread_info_count = THREAD_BASIC_INFO_COUNT;
        error = thread_info(                            //#include <mach/thread_act.h>
            threadList[c],                              //thread_act_t target_act
            THREAD_BASIC_INFO,                          //thread_flavor_t flavor            &tbi,                                       //thread_info_t thread_info_out            &thread_info_count);                        //mach_msg_type_number_t *thread_info_outCnt
#ifdef qdebug
        if (error != KERN_SUCCESS)
            NSLog(@"Call to thread_info() failed");
#endif	
        cpuUsage += tbi.cpu_usage;
    }
    cpuUsage = cpuUsage * 0.05;

	[[NSColor blackColor] set]; 
	path = [NSBezierPath bezierPath];

	if( ctlSize == NSRegularControlSize ) {
		[regularImage compositeToPoint:NSMakePoint(12,0) operation:NSCompositeSourceOver];
		[path moveToPoint:NSMakePoint(28, 0)];
		[path lineToPoint:NSMakePoint(28. - cos(pi / 180. * (65. + cpuUsage)) * 28., sin(pi / 180. * (65. + cpuUsage)) * 28.)];
	} else {
		[smallImage compositeToPoint:NSMakePoint(9,0) operation:NSCompositeSourceOver];
		[path moveToPoint:NSMakePoint(21, 0)];
		[path lineToPoint:NSMakePoint(21. - cos(pi / 180. * (65. + cpuUsage)) * 20., sin(pi / 180. * (65. + cpuUsage)) * 20.)];
	}
	[path stroke];
	
}

- (void) mouseDown:(NSEvent *) theEvent
{
//	NSLog(@"cocoaCpuView: mouseDown");

}

- (NSControlSize) controlSize
{
//	NSLog(@"cocoaCpuView: controlSize");

	return ( ctlSize ? ctlSize : NSRegularControlSize );
}

- (void) setControlSize:(NSControlSize) controlSize {
	if( controlSize == NSRegularControlSize ) {
		[toolbarItem setMinSize:NSMakeSize( 56., 32. )];
		[toolbarItem setMaxSize:NSMakeSize( 56., 32. )];
	} else if( controlSize == NSSmallControlSize ) {
		[toolbarItem setMinSize:NSMakeSize( 42., 24. )];
		[toolbarItem setMaxSize:NSMakeSize( 42., 24. )];
	}
	ctlSize = controlSize;
}
- (NSImage *) image;
{
//	NSLog(@"cocoaPopUpView: image");

	return regularImage;
}

- (void) setImage:(NSImage *) image
{
//	NSLog(@"cocoaPopUpView: setImage");

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
//	NSLog(@"cocoaCpuView: toolbarItem");

	return [[toolbarItem retain] autorelease];
}

- (void) setToolbarItem:(NSToolbarItem *) item {
	toolbarItem = item;
}

- (void) updateToolbarItem:(NSTimer*) timer
{
//	NSLog(@"cocoaCpuView: updateToolbarItem");

	[self setNeedsDisplay:YES];
}
@end
