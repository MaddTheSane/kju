/*
 * QEMU Cocoa distributed object display driver
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

#include "qemu-common.h"
#include "console.h"
#include "sysemu.h"

// for IDE activity
#import "../block_int.h"

//for cpu usage
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <mach/task.h>
#import <mach/task_info.h>
#import <mach/thread_info.h>
#import <mach/thread_act.h>
#import <mach/mach_init.h>

#import <sys/mman.h> // for mmap

//#define DEBUG
#ifdef DEBUG
#define Q_DEBUG(...)  { (void) fprintf (stdout, __VA_ARGS__); }
#else
#define Q_DEBUG(...)  ((void) 0)
#endif



typedef struct QCommand
{
    char command;
    int arg1;
    int arg2;
    int arg3;
    int arg4;
} QCommand;



@protocol QDistributedObjectServerProto
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

@interface QDistributedObject : NSObject <QDistributedObjectServerProto> {
    id document;
}
- (id) initWithSender:(id)sender;
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


QDistributedObject *qDocument;
char *uniqueDocumentID;
BOOL saved;
BOOL savedVm_running;


int gArgc;
char **gArgv;



// main defined in qemu/vl.c
int qemu_main(int argc, char **argv);



// copied from monitor.c
static int eject_device(BlockDriverState *bs, int force)
{
    if (bdrv_is_inserted(bs)) {
        if (!force) {
            if (!bdrv_is_removable(bs)) {
                term_printf("device is not removable\n");
                return -1;
            }
            if (bdrv_is_locked(bs)) {
                term_printf("device is locked\n");
                return -1;
            }
        }
        bdrv_close(bs);
    }
    return 0;
}

static void do_eject(int force, const char *filename)
{
    BlockDriverState *bs;

    bs = bdrv_find(filename);
    if (!bs) {
        term_printf("device not found\n");
        return;
    }
    eject_device(bs, force);
}

static void do_change(const char *device, const char *filename)
{
    BlockDriverState *bs;
    int i;
    char password[256];

    bs = bdrv_find(device);
    if (!bs) {
        term_printf("device not found\n");
        return;
    }
    if (eject_device(bs, 0) < 0)
        return;
    bdrv_open(bs, filename, 0);
    if (bdrv_is_encrypted(bs)) {
        term_printf("%s is encrypted.\n", device);
        for(i = 0; i < 3; i++) {
            monitor_readline("Password: ", 1, password, sizeof(password));
            if (bdrv_set_key(bs, password) == 0)
                break;
            term_printf("invalid password\n");
        }
    }
}



static void getCpuIdeActivity() {

    // cpu usage
    float cpuUsage = 0.;
/*
    kern_return_t error;    
    struct thread_basic_info tbi;
    unsigned int thread_info_count;
    task_port_t task;
    thread_act_array_t threadList;                      //#include <mach/thread_act.h>
    mach_msg_type_number_t threadCount;

    threadCount = 0;
    thread_info_count = THREAD_BASIC_INFO_COUNT;
    int c;
    error = task_for_pid(
        mach_task_self(),                               //task_port_t task #include <mach/mach_init.h>
        [[NSProcessInfo processInfo] processIdentifier], //pid_t pid
        &task);                                         //task_port_t *target
#ifdef COCOAM_DEBUG
    if (error != KERN_SUCCESS)
       NSLog(@"QDocumentCpuView: Call to task_for_pid() failed");
#endif
    error = task_threads(                               //#include <mach/task.h>
        task,                                           //task_t target_task
        &threadList,                                    //thread_act_array_t *act_list
        &threadCount);                                  //mach_msg_type_number_t *act_listCnt
#ifdef COCOAM_DEBUG
    if (error != KERN_SUCCESS)
       NSLog(@"QDocumentCpuView: Call to task_threads() failed");
#endif
    for (c = 0; c < threadCount; c++) {
        thread_info_count = THREAD_BASIC_INFO_COUNT;
        error = thread_info(                            //#include <mach/thread_act.h>
            threadList[c],                              //thread_act_t target_act
            THREAD_BASIC_INFO,                          //thread_flavor_t flavor
            &tbi,                                       //thread_info_t thread_info_out
            &thread_info_count);                        //mach_msg_type_number_t *thread_info_outCnt
#ifdef COCOAM_DEBUG
        if (error != KERN_SUCCESS)
            NSLog(@"Call to thread_info() failed");
#endif  
        cpuUsage += tbi.cpu_usage;
    }
*/

    // Drive Activity Indicator
    BOOL drivesAreActive = FALSE;
    BlockDriverState *bs;

    // hda
    bs = bdrv_find([@"hda" cString]);
    if (bs) {
        if (bs->activityLED) {
            drivesAreActive = YES;
            bs->activityLED = 0;
        }
    }

    // CD-ROM
    bs = bdrv_find([@"cdrom" cString]);
    if (bs) {
        if (bs->activityLED) {
            drivesAreActive = YES;
            bs->activityLED = 0;
        }
    }

    // hdc
    bs = bdrv_find([@"hdc" cString]);
    if (bs) {
        if (bs->activityLED) {
            drivesAreActive = YES;
            bs->activityLED = 0;
        }
    }

    // hdd
    bs = bdrv_find([@"hdd" cString]);
    if (bs) {
        if (bs->activityLED) {
            drivesAreActive = YES;
            bs->activityLED = 0;
        }
    }


    [qDocument setCpu:cpuUsage ideActivity:drivesAreActive];
}



static void cocoa_update(DisplayState *ds, int x, int y, int w, int h)
{
	Q_DEBUG("qemu_cocoa: cocoa_update x=%d y=%d w=%d h=%d", x, y, w, h);


/*
    int i;
    UInt8 *pixelPointer;
    NSData *data;
    pixelPointer = ds->data;
    for (i = y; i < y + h; i++) {
        data = [NSData dataWithBytesNoCopy:&pixelPointer[(i * ds->width + x) * 4] length:w * 4 freeWhenDone:NO];
        [qDocument screenBufferLine:data start:(size_t)((i * ds->width + x) * 4) length:w * 4];
    }
*/
    [qDocument displayRect:NSMakeRect(x, y, w, h)];
}



static void cocoa_resize(DisplayState *ds, int w, int h)
{
	Q_DEBUG("qemu_cocoa: cocoa_resize w=%d h=%d", w, h);


    static void *screen_pixels;

/*
    if (screen_pixels)
        free(screen_pixels);
    screen_pixels = malloc( w * 4 * h );
*/
    // screenbuffer with mmap
    int fd;
    if (screen_pixels)
        munmap(screen_pixels, ds->width * 4 * ds->height);
    fd = open([[NSString stringWithFormat:@"/tmp/%s.vga", uniqueDocumentID] cString], O_RDWR); // open file
    if(!fd)
        NSLog(@"qemu_cocoa: cocoa_resize: could not open '/tmp/%s.vga'", uniqueDocumentID);
    screen_pixels = mmap(0, w * 4 * h, PROT_READ|PROT_WRITE, MAP_FILE|MAP_SHARED, fd, 0);
    if(!screen_pixels)
        NSLog(@"qemu_cocoa: cocoa_resize: could not mmap '/tmp/%s.vga'", uniqueDocumentID);
    close(fd);

    ds->data = screen_pixels;
    ds->linesize =  (w * 4);
    ds->depth = 32;
    ds->width = w;
    ds->height = h;
#ifdef __LITTLE_ENDIAN__
    ds->bgr = 1;
#else
    ds->bgr = 0;
#endif

    [qDocument resizeTo:NSMakeSize(w, h)];
}



static void cocoa_refresh(DisplayState *ds)
{
	Q_DEBUG("qemu_cocoa: cocoa_refresh");

    // update vga state
    vga_hw_update();

	// send change in state
	if (vm_running != savedVm_running) {
		savedVm_running = vm_running;
		[qDocument setVm_running:vm_running];
	}

    // get commands
    int i;
    QCommand *commandPointer;
    NSData *data;
    data = [qDocument getComandsSetAbsolute:kbd_mouse_is_absolute()];
    commandPointer = [data bytes];
    for (i = 0; i < (int)(([data length])/sizeof(QCommand)); i++) {
//        NSLog(@"Command:%C %D %D %D %D", commandPointer[i].command, commandPointer[i].arg1, commandPointer[i].arg2, commandPointer[i].arg3, commandPointer[i].arg4);
        switch (commandPointer[i].command) {
            case 'K': // Keyboard
                kbd_put_keycode(commandPointer[i].arg1);
                break;
            case 'M': // Mouse
                kbd_mouse_event(
                    commandPointer[i].arg1,
                    commandPointer[i].arg2,
                    commandPointer[i].arg3,
                    commandPointer[i].arg4);
                break;
            case 'C': // Monitor Chars
                kbd_put_keysym(commandPointer[i].arg1);
                break;
            case 'D': // change Drives
            {
                NSData *data2;
                data2 = [qDocument getFilename:commandPointer[i].arg1];
                if (commandPointer[i].arg1 == 0) {
                    do_change("fda", [data2 bytes]);
                } else if (commandPointer[i].arg1 == 1) {
                    do_change("fdb", [data2 bytes]);
                } else {
                    do_change("cdrom", [data2 bytes]);
                }
                break;
            }
            case 'E': // eject Drives
                if (commandPointer[i].arg1 == 0) {
                    do_eject(1, "fda");
                } else if (commandPointer[i].arg1 == 1) {
                    do_eject(1, "fdb");
                } else {
                    do_eject(1, "cdrom");
                }
                break;
            case 'P': // (un)Pause vm
                if (commandPointer[i].arg1) {
                    if (vm_running)
                        vm_stop(0);
                } else {
                    if (!vm_running)
                        vm_start();
                }
                break;
            case 'Q': // Quit
                if (vm_running)
                    vm_stop(0);
                [NSApp terminate:qDocument];
                break;
            case 'R': // reset
                qemu_system_reset_request();
                break;
            case 'S': // Select Monitor
                console_select(commandPointer[i].arg1);
                break;
            case 'W': // save VM
                do_savevm([@"kju_saved" cString]);
                break;
            case 'X': // revert to previous saved state
                if (vm_running)
                    vm_stop(0);
                do_loadvm([@"kju_saved" cString]);
                vm_start();
                break;
            case 'Y': // send CPU/IDE activity
                getCpuIdeActivity();
                break;
            case 'Z': // save VM
                if (vm_running)
                    vm_stop(0);
                do_savevm([@"kju" cString]);
                saved = TRUE;
                [NSApp terminate:qDocument];
                break;
        }
    }
}



static void cocoa_cleanup(void) 
{
	Q_DEBUG("qemu_cocoa: cocoa_cleanup");

}



void cocoa_display_init(DisplayState *ds, int full_screen)
{
Q_DEBUG("qemu_cocoa: cocoa_display_init");

    // register vga outpu callbacks
    ds->dpy_update = cocoa_update;
    ds->dpy_resize = cocoa_resize;
    ds->dpy_refresh = cocoa_refresh;

    // give window a initial Size
    cocoa_resize(ds, 640, 400);

    // register cleanup function
    atexit(cocoa_cleanup);
}



/*
 ------------------------------------------------------
    QemuCocoaAppController
 ------------------------------------------------------
*/

/* to be implemented by qemu */
@protocol QDistributedObjectClientProto
- (void) do_test:(int)test;
@end

@interface QemuCocoaAppController : NSObject <QDistributedObjectClientProto>
{
}
- (void)applicationDidFinishLaunching: (NSNotification *) note;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
- (void)startEmulationWithArgc:(int)argc argv:(char**)argv;

- (void) do_test:(int)test;
@end



@implementation QemuCocoaAppController
- (void)applicationDidFinishLaunching: (NSNotification *) note
{
	Q_DEBUG("qemu_cocoa: applicationDidFinishLaunching");


    uniqueDocumentID = gArgv[gArgc - 1];
    qDocument = [[NSConnection rootProxyForConnectionWithRegisteredName:[NSString stringWithCString:gArgv[gArgc - 1]] host:nil] retain];
    if(!qDocument) {
        NSLog(@"qemu_cocoa: applicationDidFinishLaunching: Could not connect to %s", uniqueDocumentID);
        [NSApp terminate:self];
    } else {
        // register Ourselves
        if (![qDocument qemuRegister:self]) {
            NSLog(@"qemu_cocoa: applicationDidFinishLaunching: Could not register with %s", uniqueDocumentID);
            [NSApp terminate:self];
        } else {
            // start emulation
            gArgv[gArgc - 1] = "";
            gArgv[gArgc - 2] = "";
            gArgc = gArgc - 2;
            [self startEmulationWithArgc:gArgc argv:gArgv];
        }
    }
}



- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	Q_DEBUG("qemu_cocoa: applicationWillTerminate");

    // unregister
    [qDocument qemuUnRegister:self];

    // shutdown qemu and send error code
    qemu_system_shutdown_request();
    if (saved) {
        exit(2);
    } else {
        exit(0);
    }
}



- (void)startEmulationWithArgc:(int)argc argv:(char**)argv
{
	Q_DEBUG("qemu_cocoa: startEmulationWithArgc: %D", argc);

    int status;
    status = qemu_main(argc, argv);
    exit(status);
}



//DO Object
- (void) do_test:(int)test {NSLog(@"DO TEST %D", test);}
@end



int main (int argc, const char * argv[]) {

    // terminate if no argument were passed or if qemu was launched from the finder ( the Finder passes "-psn" )
    if( argc <= 1 || strncmp (argv[1], "-psn", 4) == 0) {

        NSLog(@"QEMU DO can only be run by Q");

    } else {

        gArgc = argc;
        gArgv = argv;

        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        [NSApplication sharedApplication];

        QemuCocoaAppController *appController = [[QemuCocoaAppController alloc] init];
        [NSApp setDelegate:appController];

        /* Start the main event loop */
        [NSApp run];

        [appController release];
        [pool release];

    }

    return 0;
}
