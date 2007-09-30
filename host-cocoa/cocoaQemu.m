/*
 * QEMU Cocoa display driver
 * 
 * Copyright (c) 2005 - 2007 Pierre d'Herbemont
 *                           Mike Kronenberg
 *                           many code/inspiration from SDL 1.2 code (LGPL)
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

#import "cocoaQemu.h"

#import "cocoaQemuOpenGLView.h"
#import "cocoaQemuQuartzView.h"
#import "cocoaQemuQuickDrawView.h"

#import "CGSPrivate.h"

/* Pasteboard *//*
#include "sdl_keysym.h"
#include "keymaps.c"
static kbd_layout_t *kbd_layout;
*/
/* main defined in qemu/vl.c */
int qemu_main(int argc, char **argv);

/* pc */
id pc;

/* QemuCocoa Video Driver */
DisplayState current_ds;

/*
 ------------------------------------------------------
    Headers
    
 ------------------------------------------------------
*/
/*
 ------------------------------------------------------
    QemuCocoa Video Driver
 ------------------------------------------------------
*/
void cocoa_update(DisplayState *ds, int x, int y, int w, int h);
void cocoa_resize(DisplayState *ds, int w, int h);
void cocoa_refresh(DisplayState *ds);
void cocoa_display_init(DisplayState *ds, int full_screen);


/*
 ------------------------------------------------------
    QemuCocoa CD-ROM Driver
 ------------------------------------------------------
*/
kern_return_t FindEjectableCDMedia( io_iterator_t *mediaIterator );
kern_return_t GetBSDPath( io_iterator_t mediaIterator, char *bsdPath, CFIndex maxPathSize );



/*
 ------------------------------------------------------
    Implementations
    
 ------------------------------------------------------
*/
/*
 ------------------------------------------------------
    cocoaQemu
 ------------------------------------------------------
*/
@implementation cocoaQemu
/* init & dealloc */
-(id) init
{
//  NSLog(@"cocoaQemu: init");

    if ((self = [super init])) {
        /* set allowed filetypes */
        fileTypes = [[NSArray arrayWithObjects:@"qcow2", @"qcow", @"raw", @"cow", @"vmdk", @"cloop", @"img", @"iso", @"dsk", @"dmg", @"cdr", @"toast", @"flp", @"fs", nil] retain];

        /* pc */
        pcName = [@"" retain];
        pcWindowName = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] retain];
        pcPath = [[@"~/Documents/QEMU/temp.qvm" stringByExpandingTildeInPath] retain];
        pcTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector( liveThumbnail ) userInfo:nil repeats:YES];
        [self liveThumbnail];
        pcDialogs = YES;
        pc = self;

        /* set openGL as default */
        pcOpenGLView = true;

        /* setup progressWindow */
        progressWindow = [[cocoaQemuProgressWindow alloc] init];

        /* setup Q distributed object Client */
        qdoserver = [[NSConnection rootProxyForConnectionWithRegisteredName:@"qdoserver" host:nil] retain];
        [qdoserver setProtocolForProxy:@protocol(cocoaControlDOServerProto)];

        /* Pasteboard *//*
        bios_dir = [[NSString stringWithFormat:@"%@/qemu", [[NSBundle mainBundle] resourcePath]] cString];
        kbd_layout = init_keyboard_layout("de-ch");
*/      
        return self;
    }
    return nil;
}

- (void) dealloc
{
//  NSLog(@"cocoaQemu: dealloc");

    [super dealloc];
}

/* methods defined by Q distributed object Client */
- (BOOL) guestOrderFrontRegardless
{
//  NSLog(@"cocoaQemu: guestOrderFrontRegardless");

    [pcWindow orderFrontRegardless];
    return true;
}

- (int) guestWindowLevel
{
//  NSLog(@"cocoaQemu: guestWindowLevel");

    return [pcWindow level];
}

- (int) guestWindowNumber
{
//  NSLog(@"cocoaQemu: guestWindowNumber");

    return [pcWindow windowNumber];
}

- (BOOL) guestOrderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWindowNumber
{
//  NSLog(@"cocoaQemu: guestOrderWindow");

    [pcWindow orderWindow:place relativeTo:otherWindowNumber];
    return true;
}

- (BOOL) guestHide;
{
//  NSLog(@"cocoaQemu: guestHide");

    [NSApp hide:self];
    return true;
}

- (BOOL) guestUnhide;
{
//  NSLog(@"cocoaQemu: guestUnhide");

    [NSApp unhide:self];
    return true;
}

- (BOOL) guestPause;
{
//  NSLog(@"cocoaQemu: guestPause");

    [self pausePlay:self];
    return true;
}

- (BOOL) guestStop;
{
//  NSLog(@"cocoaQemu: guestStop");

    [self shutdownPC];
    return true;
}

/* getters] setters */
- (NSString *) pcName
{
//  NSLog(@"cocoaQemu: pcName");

    return pcName;
}

- (NSString *) pcWindowName
{
//  NSLog(@"cocoaQemu: pcWindowName");

    return pcWindowName;
}

-(NSString *) smbPath
{
//  NSLog(@"cocoaQemu: smbPath");

    return smbPath;
}

- (id) qdoserver
{
//  NSLog(@"cocoaQemu: qdoserver");

    return qdoserver;
}

- (BOOL) fullscreen
{
//  NSLog(@"cocoaQemu: fullscreen");

    return fullscreen;
}

- (void) setFullscreen:(BOOL)val
{
//  NSLog(@"cocoaQemu: setFullscreen");

    fullscreen = val;
}

- (void) showFullscreenAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
    // return code of no interest here, we just want to have fullscreen activated
    [sheet orderOut:self];
    [pc setFullscreen:[[pc contentView] toggleFullScreen]];
}

- (id) fullscreenController
{
// NSLog(@"cocoaQemu: fullscreenController");
    
    return fullscreenController;
}

- (void) setFullscreenController:(id)controller
{
// NSLog(@"cocoaQemu: setFullscreenController");

    fullscreenController = controller;
}   

- (BOOL) grab
{
//  NSLog(@"cocoaQemu: grab");

    return grab;
}

- (BOOL) absolute_enabled
{
//  NSLog(@"cocoaQemu: absolute_enabled");

    return absolute_enabled;
}

- (BOOL) tablet_enabled
{
//  NSLog(@"cocoaQemu: tablet_enabled");

    return tablet_enabled;
}

- (BOOL) wMStopWhenInactive
{
//  NSLog(@"cocoaQemu: wMStopWhenInactive");

    return WMStopWhenInactive;
}

- (BOOL) wMPaused
{
//  NSLog(@"cocoaQemu: wMPaused");

    return vm_running;
}

- (BOOL) wMPausedByUser
{
//  NSLog(@"cocoaQemu: wMPausedByUser");

    return wMPausedByUser;
}

- (void) setGrab:(BOOL)val
{
//  NSLog(@"cocoaQemu: setGrab");

    grab = val;
}

- (void) setAbsolute_enabled:(BOOL)val
{
//  NSLog(@"cocoaQemu: setAbsolute_enabled");

    absolute_enabled = val;
}

- (void) setTablet_enabled:(BOOL)val
{
//  NSLog(@"cocoaQemu: setTablet_enabled");

    tablet_enabled = val;
}

- (void) grabMouse
{
//  NSLog(@"cocoaQemu: grabMouse");

    if (!grab) {
        grab = YES;
        [pcWindow setTitle: [NSString stringWithFormat: NSLocalizedStringFromTable(@"grabMouse:title", @"Localizable", @"cocoaQemu"), pcWindowName, pcName]];
        [NSCursor hide];
        CGAssociateMouseAndMouseCursorPosition ( FALSE );
    }
}

- (void) ungrabMouse
{
//  NSLog(@"cocoaQemu: ungrabMouse");

    if (grab) {
        grab = NO;
        [pcWindow setTitle: [NSString stringWithFormat:@"%@ - %@", pcWindowName, pcName]];
        [NSCursor unhide];
        CGAssociateMouseAndMouseCursorPosition ( TRUE );
    }
}

- (int) modifierAtIndex:(int)index
{
//  NSLog(@"cocoaQemu: modifierAtIndex");

    return modifiers_state[index];
}

- (void) setModifierAtIndex:(int)index to:(int)value
{
//  NSLog(@"cocoaQemu: setModifierAtIndex");

    modifiers_state[index] = value;
}

- (void) resetModifiers
{
//  NSLog(@"cocoaQemu: resetModifiers");

    int i;
    for(i = 0; i < 256; i++) {
        if (modifiers_state[i]) {
            if (i & 0x80)
                kbd_put_keycode(0xe0);
            kbd_put_keycode(i | 0x80);
            modifiers_state[i] = 0;
        }
    }
}

- (id) pcWindow
{
//  NSLog(@"cocoaQemu: pcWindow");

    return pcWindow;
}

- (id) contentView
{
//  NSLog(@"cocoaQemu: contentView");

    return contentView;
}

- (void) liveThumbnail
{
//  NSLog(@"cocoaQemu: liveThumbnail <%@>", pcPath);

    if (![pcName isEqual:@""]) {
        /* create liveThumbnail */
        NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData: [[contentView screenshot:NSMakeSize(100,75)] TIFFRepresentation]];
        NSData *data = [bitmapImageRep representationUsingType: NSPNGFileType properties: nil];
        [data writeToFile: [NSString stringWithFormat: @"%@/thumbnail.png", pcPath] atomically: YES];
    }
}

- (void) stopVM
{
//  NSLog(@"cocoaQemu: stopVM");

    if (vm_running)
        vm_stop(0);
    [pcWindow display];
}

- (void) startVM
{
//  NSLog(@"cocoaQemu: startVM");

    if (!vm_running)
        vm_start();
    [pcWindow display];
}

- (void) saveVM
{
//  NSLog(@"cocoaQemu: saveVM");

    /* show progressWindow */
    [progressWindow showProgressWindow:pcWindow text: NSLocalizedStringFromTable(@"saveVM:text", @"Localizable", @"cocoaQemu") name:pcName];

    /* stop VM */
    vm_stop(0);

    /* generate Preview */
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData: [[contentView screenshot:NSMakeSize(100,75)] TIFFRepresentation]];
    NSData *data = [bitmapImageRep representationUsingType: NSPNGFileType properties: nil];
    [data writeToFile: [NSString stringWithFormat: @"%@/thumbnail.png", pcPath] atomically: YES];

    /* save VM */
    do_savevm([@"kju" cString]);

    /* hide progressWindow */
    [progressWindow hideProgressWindow];
}

- (void) closeProgressWindow
{
//  NSLog(@"cocoaQemu: closeProgressWindow");
    
    if (vm_running) {
        [progressWindowTimer invalidate];
        [progressWindow hideProgressWindow];
        
    }
}

/* pc */
- (void) startPCWithArgs:(id)arguments
{
//  NSLog(@"cocoaQemu: startPCWithArgs");

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    /* overrun defaults for bios_dir, so we can run qemu everywhere */
    bios_dir = [[NSString stringWithFormat:@"%@/qemu", [[NSBundle mainBundle] resourcePath]] cString];

    /* setup QEMU Window */
    pcWindow = [[cocoaQemuWindow  alloc] initWithSender:self];
    if ([arguments containsObject:@"-cocoaquickdraw"]) {
        contentView = [[[cocoaQemuQuickDrawView alloc] initWithFrame:NSMakeRect(0,0,640,400) sender:self] autorelease];
    } else if ([arguments containsObject:@"-cocoaquartz"]) {
        contentView = [[[cocoaQemuQuartzView alloc] initWithFrame:NSMakeRect(0,0,640,400) sender:self] autorelease];
    } else {
        contentView = [[[cocoaQemuOpenGLView alloc] initWithFrame:NSMakeRect(0,0,640,400) sender:self] autorelease];
    }
    [contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

    /* scrollview */
/*  NSScrollView * scrollView = [[NSScrollView alloc] init];
    [scrollView setHasVerticalScroller:TRUE];
    [scrollView setHasHorizontalScroller:TRUE];
    [scrollView setAutohidesScrollers:FALSE];
    [scrollView setScrollsDynamically:TRUE]; //
    [scrollView setBorderType:NSLineBorder];
    [scrollView setDocumentView:contentView];
    [pcWindow setContentView:scrollView];*/

    
    [pcWindow setContentView:contentView];
    [pcWindow setMyContentView:contentView];

    /* filter cocoa arguments */
    int i;
    int i2 = 0;
    char **argv2 = (char**)malloc( sizeof(char*)*[arguments count] );

    for (i = 0; i < [arguments count]; i++) {
//      NSLog(@"Arguments: %@", [arguments objectAtIndex:i]);
        
        if ( [[arguments objectAtIndex:i] isEqual:@"-cocoaquickdraw"] ) {
            pcOpenGLView = false;
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-cocoaquartz"] ) {
            pcOpenGLView = false;
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-cocoaname"] ) {
            i++;
            pcName = [arguments objectAtIndex:i];
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-cocoawindowname"] ) {
            i++;
            pcWindowName = [arguments objectAtIndex:i];
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-cocoapath"] ) {
            i++;
            pcPath = [arguments objectAtIndex:i];
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-cocoalivethumbnail"] ) {
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-cocoanodialogs"] ) {
            pcDialogs = NO;
            NSLog(@"pcDialogs: %d\n", pcDialogs);
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-wmstopwheninactive"] ) {
            WMStopWhenInactive = true;
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-full-screen"] ) {
            fullscreen = [contentView toggleFullScreen];
        } else if ( [[arguments objectAtIndex:i] isEqual:@"-cdrom"] ) {
            if ( [[arguments objectAtIndex:i+1] isEqual:@"/dev/cdrom"] ) {
                kern_return_t kernResult;
                io_iterator_t mediaIterator;
                char bsdPath[MAXPATHLEN];
                
                kernResult = FindEjectableCDMedia( &mediaIterator );
                kernResult = GetBSDPath( mediaIterator, bsdPath, sizeof( bsdPath ) );
                
                if ( bsdPath[0] == '\0' ) {
                    i++;
                } else {
                    asprintf(&argv2[i2], "%s", [[arguments objectAtIndex:i] cString]);
                    i2++;
                    i++;
                    asprintf(&argv2[i2], "%s", [[arguments objectAtIndex:i] cString]);
                    i2++;
                }
                
                if ( mediaIterator )
                    IOObjectRelease( mediaIterator );
            } else {
                asprintf(&argv2[i2], "%s", [[arguments objectAtIndex:i] cString]);
                i2++;
                i++;
                asprintf(&argv2[i2], "%s", [[arguments objectAtIndex:i] cString]);
                i2++;
            }
        } else {
            if ([[arguments objectAtIndex:i] isEqual:@"-smb"])
                smbPath = [[NSString alloc] initWithString:[arguments objectAtIndex:i + 1]];
            
            if ([[arguments objectAtIndex:i] isEqual:@"-hda"])
                if ([[arguments objectAtIndex:i+1] rangeOfString:@"qcow2"].length > 0)
                    WMSupportsSnapshots = TRUE;
            asprintf(&argv2[i2], "%s", [[arguments objectAtIndex:i] cString]);
            i2++;
        }
    }
    
//  for (i = 0; i < i2; i++)
//      NSLog(@"Argv :%s\n", argv2[i]);

    /* set window- and frameAutosaveName */
    [pcWindow setFrameAutosaveName: [NSString stringWithFormat:@"%@ - %@",pcWindowName, pcName]];
    [pcWindow setTitle: [NSString stringWithFormat:@"%@ - %@",pcWindowName, pcName]];

    /* show progressWindow */
    [progressWindow showProgressWindow:pcWindow text: NSLocalizedStringFromTable(@"startPCWithArgs:text", @"Localizable", @"cocoaQemu") name:pcName];

    /* register with Q distributed objects server */
    if (![qdoserver guestRegister: self withName:pcName]) {
        [qdoserver release];
        qdoserver = nil;
        NSLog(@"KO");
    }

    /* update status */
    pcStatus = @"running";

    /* hide progressWindow */
    progressWindowTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector( closeProgressWindow ) userInfo:nil repeats:YES];

    /* launch VM, QEMU is up and running here */
    qemu_main(i2, argv2);

    /* remove pcWindow */
    [pcWindow close];

    [pool release];

    /* unregister with Q distributed objects server */
    if (![qdoserver guestUnregisterWithName:pcName]) {
        NSLog(@"KO");
    }
    [qdoserver release];
    qdoserver = nil;

    /* saved: return 2, so qemu-control knows */
    if ([pcStatus isEqual:@"saved"]) {
        exit(2);
    } else {
        [NSApp terminate:self];
    }
}

- (void) changeFda:(id)sender
{
//  NSLog(@"cocoaQemu: changeFda");

        NSOpenPanel *op = [[NSOpenPanel alloc] init];
        [op setPrompt: NSLocalizedStringFromTable(@"changeFda:prompt", @"Localizable", @"cocoaQemu")];
        [op setMessage: NSLocalizedStringFromTable(@"changeFda:message", @"Localizable", @"cocoaQemu")];
        [op beginSheetForDirectory:nil
        file:nil
        types:fileTypes
        modalForWindow:pcWindow
        modalDelegate:self
        didEndSelector:@selector(changeDeviceSheetDidEnd:returnCode:contextInfo:)
        contextInfo:@"fda"];
}

- (void) changeFdb:(id)sender
{
//  NSLog(@"cocoaQemu: changeFdb");

    NSOpenPanel *op = [[NSOpenPanel alloc] init];
        [op setPrompt: NSLocalizedStringFromTable(@"changeFdb:prompt", @"Localizable", @"cocoaQemu")];
        [op setMessage: NSLocalizedStringFromTable(@"changeFdb:message", @"Localizable", @"cocoaQemu")];
        [op beginSheetForDirectory:nil
        file:nil
        types:fileTypes
        modalForWindow:pcWindow
        modalDelegate:self
        didEndSelector:@selector(changeDeviceSheetDidEnd:returnCode:contextInfo:)
        contextInfo:@"fdb"];
}

- (void) changeCdrom:(id)sender
{
//  NSLog(@"cocoaQemu: changeCdrom");

    NSOpenPanel *op = [[NSOpenPanel alloc] init];
        [op setPrompt: NSLocalizedStringFromTable(@"changeCdrom:prompt", @"Localizable", @"cocoaQemu")];
        [op setMessage: NSLocalizedStringFromTable(@"changeCdrom:message", @"Localizable", @"cocoaQemu")];
        [op beginSheetForDirectory:nil
        file:nil
        types:fileTypes
        modalForWindow:pcWindow
        modalDelegate:self
        didEndSelector:@selector(changeDeviceSheetDidEnd:returnCode:contextInfo:)
        contextInfo:@"cdrom"];
}

- (void)changeDeviceSheetDidEnd: (NSOpenPanel *)sheet
    returnCode:(int)returnCode
    contextInfo:(NSString *)contextInfo
{
//  NSLog(@"cocoaQemu: changeDeviceSheetDidEnd");

    if(returnCode == NSOKButton)
        [self changeDeviceImage:[contextInfo cString] filename:[[sheet filename] cString] withForce:1];
}

- (void) useCdrom: (id)sender
{
//  NSLog(@"cocoaQemu: useCdrom");

    [self changeDeviceImage:[@"cdrom" cString] filename:[@"/dev/cdrom" cString] withForce:1];
}

- (void) ejectFda: (id)sender
{
//  NSLog(@"cocoaQemu: ejectFda");

        [self ejectImage:[@"fda" cString] withForce:1];
}

- (void) ejectFdb: (id)sender
{
//  NSLog(@"cocoaQemu: ejectFdb");

        [self ejectImage:[@"fdb" cString] withForce:1];
}

- (void) ejectCdrom: (id)sender
{
//  NSLog(@"cocoaQemu: ejectCdrom");

        [self ejectImage:[@"cdrom" cString] withForce:1];
}

/* copied and adapted from monitor.c */
- (int) ejectDevice: (BlockDriverState *) bs
    withForce: (int) force
{
    if (bdrv_is_inserted(bs)) {
        if (!force) {
            if (!bdrv_is_removable(bs)) {
                printf("device is not removable\n");
                return -1;
            }
            if (bdrv_is_locked(bs)) {
                printf("device is locked\n");
                return -1;
            }
        }
        bdrv_close(bs);
    }
    return 0;
}

- (void) ejectImage:(const char *) filename
    withForce: (int) force
{
    BlockDriverState *bs;

    bs = bdrv_find(filename);
    if (!bs) {
        printf("device not found\n");
        return;
    }
    [self ejectDevice:bs withForce:force];
}

- (void) changeDeviceImage: (const char *) device
    filename: (const char *) filename
    withForce: (int) force
{
    BlockDriverState *bs;
    int i;
    char password[256];

    bs = bdrv_find(device);
    if (!bs) {
        printf("device not found\n");
        return;
    }
    if ([self ejectDevice:bs withForce:force] < 0)
        return;
    bdrv_open(bs, filename, 0);
    if (bdrv_is_encrypted(bs)) {
        printf("%s is encrypted.\n", device);
        for(i = 0; i < 3; i++) {
            monitor_readline("Password: ", 1, password, sizeof(password));
            if (bdrv_set_key(bs, password) == 0)
                break;
            printf("invalid password\n");
        }
    }
}

- (void) pausePlay: (id)sender
{
//  NSLog(@"cocoaQemu: pausePlay");

    if (vm_running) {
        [self stopVM];
        wMPausedByUser = TRUE;
    } else {
        [self startVM];
        wMPausedByUser = FALSE;
    }
}

- (void) ctrlAltDel: (id)sender
{
//  NSLog(@"cocoaQemu: ctrlAltDel");

    /* press keys */
    if (56 & 0x80) /* ctrl */
        kbd_put_keycode(0xe0);
    kbd_put_keycode(56 & 0x7f);
    if (29 & 0x80) /* alt */
        kbd_put_keycode(0xe0);
    kbd_put_keycode(29 & 0x7f);
    if (211 & 0x80) /* del */
        kbd_put_keycode(0xe0);
    kbd_put_keycode(211 & 0x7f);
    
    /* release keys */
    if (56 & 0x80) /* ctrl */
        kbd_put_keycode(0xe0);
    kbd_put_keycode(56 | 0x80);
    if (29 & 0x80) /* alt */
        kbd_put_keycode(0xe0);
    kbd_put_keycode(29 | 0x80);
    if (211 & 0x80) /* del */
        kbd_put_keycode(0xe0);
    kbd_put_keycode(211 | 0x80);
}

- (void) shutdownPC
{
//  NSLog(@"cocoaQemu: shutdownPC");

    /* exit fullscreen */
    if (fullscreen)
        [pc setFullscreen:[[pc contentView] toggleFullScreen]];

    if (!pcDialogs) {
        pcStatus = @"shutdown";
        qemu_system_shutdown_request();
    } else if ( !WMSupportsSnapshots ) {
        NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"shutdownPC:text:1", @"Localizable", @"cocoaQemu")
            defaultButton: NSLocalizedStringFromTable(@"shutdownPC:defaultButton:1", @"Localizable", @"cocoaQemu")
            alternateButton: NSLocalizedStringFromTable(@"shutdownPC:alternateButton:1", @"Localizable", @"cocoaQemu")
            otherButton:@""
            informativeTextWithFormat: NSLocalizedStringFromTable(@"shutdownPC:informativeTextWithFormat:1", @"Localizable", @"cocoaQemu")];
        [alert beginSheetModalForWindow:pcWindow
            modalDelegate:self
            didEndSelector:@selector(shutdownPC2SheetDidEnd:returnCode:contextInfo:)
            contextInfo:nil];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedStringFromTable(@"shutdownPC:text:2", @"Localizable", @"cocoaQemu")
            defaultButton: NSLocalizedStringFromTable(@"shutdownPC:defaultButton:2", @"Localizable", @"cocoaQemu")
            alternateButton: NSLocalizedStringFromTable(@"shutdownPC:alternateButton:2", @"Localizable", @"cocoaQemu")
            otherButton: NSLocalizedStringFromTable(@"shutdownPC:otherButton:2", @"Localizable", @"cocoaQemu")
            informativeTextWithFormat: NSLocalizedStringFromTable(@"shutdownPC:informativeTextWithFormat:2", @"Localizable", @"cocoaQemu")];
        [alert beginSheetModalForWindow:pcWindow
            modalDelegate:self
            didEndSelector:@selector(shutdownPCSheetDidEnd:returnCode:contextInfo:)
            contextInfo:nil];
    }
}

- (void) shutdownPCSheetDidEnd: (NSWindow *)sheet
    returnCode: (int)returnCode
    contextInfo: (void *)contextInfo
{
//  NSLog(@"cocoaQemu: shutdownPCSheetDidEnd");

    [[sheet window] orderOut:self];
    if (returnCode == NSAlertDefaultReturn) {
        [self saveVM];
        pcStatus = @"saved";
        qemu_system_shutdown_request();
        vm_start();
    } else if (returnCode == NSAlertOtherReturn) {
        pcStatus = @"shutdown";
        if([[NSFileManager defaultManager] fileExistsAtPath: [NSString stringWithFormat: @"%@/thumbnail.png", pcPath]]) [[NSFileManager defaultManager] removeFileAtPath: [NSString stringWithFormat: @"%@/thumbnail.png", pcPath] handler: nil];
        qemu_system_shutdown_request();
        vm_start();
    }
}

- (void) shutdownPC2SheetDidEnd: (NSWindow *)sheet
    returnCode: (int)returnCode
    contextInfo: (void *)contextInfo
{
//  NSLog(@"cocoaQemu: shutdownPC2SheetDidEnd");

    [[sheet window] orderOut:self];
    if (returnCode == NSAlertDefaultReturn) {
    } else {
        if ( [pcStatus isEqual: @"running"] )
            pcStatus = @"shutdown";
            if([[NSFileManager defaultManager] fileExistsAtPath: [NSString stringWithFormat: @"%@/thumbnail.png", pcPath]]) [[NSFileManager defaultManager] removeFileAtPath: [NSString stringWithFormat: @"%@/thumbnail.png", pcPath] handler: nil];
        qemu_system_shutdown_request();
        vm_start();
    }
}

- (void) resetPC
{
//  NSLog(@"cocoaQemu: resetPC");

    qemu_system_reset_request();
}

- (void) screenshot
{
//  NSLog(@"screenshot: resetPC");

    /* generate Screenshot */   
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData: [[contentView screenshot:[contentView frame].size] TIFFRepresentation]];
    NSData *data = [bitmapImageRep representationUsingType: NSPNGFileType properties: nil];
    
    /* save it to the desktop */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int i = 1;
    while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/Q Screenshot %D.png", [@"~/Desktop" stringByExpandingTildeInPath], i]])
        i++;

    [data writeToFile: [NSString stringWithFormat:@"%@/Q Screenshot %D.png", [@"~/Desktop" stringByExpandingTildeInPath], i] atomically: YES];
}
@end



/*
 ------------------------------------------------------
    keymap conversion
 ------------------------------------------------------
*/

int keymap[] =
{
//  SdlI        macI    macH    SdlH    104xtH  104xtC  sdl
    30,     //  0       0x00    0x1e            A       QZ_a
    31,     //  1       0x01    0x1f            S       QZ_s
    32,     //  2       0x02    0x20            D       QZ_d
    33,     //  3       0x03    0x21            F       QZ_f
    35,     //  4       0x04    0x23            H       QZ_h
    34,     //  5       0x05    0x22            G       QZ_g
    44,     //  6       0x06    0x2c            Z       QZ_z
    45,     //  7       0x07    0x2d            X       QZ_x
    46,     //  8       0x08    0x2e            C       QZ_c
    47,     //  9       0x09    0x2f            V       QZ_v
    0,      //  10      0x0A    Undefined
    48,     //  11      0x0B    0x30            B       QZ_b
    16,     //  12      0x0C    0x10            Q       QZ_q
    17,     //  13      0x0D    0x11            W       QZ_w
    18,     //  14      0x0E    0x12            E       QZ_e
    19,     //  15      0x0F    0x13            R       QZ_r
    21,     //  16      0x10    0x15            Y       QZ_y
    20,     //  17      0x11    0x14            T       QZ_t
    2,      //  18      0x12    0x02            1       QZ_1
    3,      //  19      0x13    0x03            2       QZ_2
    4,      //  20      0x14    0x04            3       QZ_3
    5,      //  21      0x15    0x05            4       QZ_4
    7,      //  22      0x16    0x07            6       QZ_6
    6,      //  23      0x17    0x06            5       QZ_5
    13,     //  24      0x18    0x0d            =       QZ_EQUALS
    10,     //  25      0x19    0x0a            9       QZ_9
    8,      //  26      0x1A    0x08            7       QZ_7
    12,     //  27      0x1B    0x0c            -       QZ_MINUS
    9,      //  28      0x1C    0x09            8       QZ_8
    11,     //  29      0x1D    0x0b            0       QZ_0
    27,     //  30      0x1E    0x1b            ]       QZ_RIGHTBRACKET
    24,     //  31      0x1F    0x18            O       QZ_o
    22,     //  32      0x20    0x16            U       QZ_u
    26,     //  33      0x21    0x1a            [       QZ_LEFTBRACKET
    23,     //  34      0x22    0x17            I       QZ_i
    25,     //  35      0x23    0x19            P       QZ_p
    28,     //  36      0x24    0x1c            ENTER   QZ_RETURN
    38,     //  37      0x25    0x26            L       QZ_l
    36,     //  38      0x26    0x24            J       QZ_j
    40,     //  39      0x27    0x28            '       QZ_QUOTE
    37,     //  40      0x28    0x25            K       QZ_k
    39,     //  41      0x29    0x27            ;       QZ_SEMICOLON
    43,     //  42      0x2A    0x2b            \       QZ_BACKSLASH
    51,     //  43      0x2B    0x33            ,       QZ_COMMA
    53,     //  44      0x2C    0x35            /       QZ_SLASH
    49,     //  45      0x2D    0x31            N       QZ_n
    50,     //  46      0x2E    0x32            M       QZ_m
    52,     //  47      0x2F    0x34            .       QZ_PERIOD
    15,     //  48      0x30    0x0f            TAB     QZ_TAB
    57,     //  49      0x31    0x39            SPACE   QZ_SPACE
    41,     //  50      0x32    0x29            `       QZ_BACKQUOTE
    14,     //  51      0x33    0x0e            BKSP    QZ_BACKSPACE
    0,      //  52      0x34    Undefined
    1,      //  53      0x35    0x01            ESC     QZ_ESCAPE
    0,      //  54      0x36                            QZ_RMETA
    0,      //  55      0x37                            QZ_LMETA
    42,     //  56      0x38    0x2a            L SHFT  QZ_LSHIFT
    58,     //  57      0x39    0x3a            CAPS    QZ_CAPSLOCK
    56,     //  58      0x3A    0x38            L ALT   QZ_LALT
    29,     //  59      0x3B    0x1d            L CTRL  QZ_LCTRL
    54,     //  60      0x3C    0x36            R SHFT  QZ_RSHIFT
    184,    //  61      0x3D    0xb8    E0,38   R ALT   QZ_RALT
    157,    //  62      0x3E    0x9d    E0,1D   R CTRL  QZ_RCTRL
    0,      //  63      0x3F    Undefined
    0,      //  64      0x40    Undefined
    0,      //  65      0x41    Undefined
    0,      //  66      0x42    Undefined
    55,     //  67      0x43    0x37            KP *    QZ_KP_MULTIPLY
    0,      //  68      0x44    Undefined
    78,     //  69      0x45    0x4e            KP +    QZ_KP_PLUS
    0,      //  70      0x46    Undefined
    69,     //  71      0x47    0x45            NUM     QZ_NUMLOCK
    0,      //  72      0x48    Undefined
    0,      //  73      0x49    Undefined
    0,      //  74      0x4A    Undefined
    181,    //  75      0x4B    0xb5    E0,35   KP /    QZ_KP_DIVIDE
    152,    //  76      0x4C    0x9c    E0,1C   KP EN   QZ_KP_ENTER
    0,      //  77      0x4D    undefined
    74,     //  78      0x4E    0x4a            KP -    QZ_KP_MINUS
    0,      //  79      0x4F    Undefined
    0,      //  80      0x50    Undefined
    0,      //  81      0x51                            QZ_KP_EQUALS
    82,     //  82      0x52    0x52            KP 0    QZ_KP0
    79,     //  83      0x53    0x4f            KP 1    QZ_KP1
    80,     //  84      0x54    0x50            KP 2    QZ_KP2
    81,     //  85      0x55    0x51            KP 3    QZ_KP3
    75,     //  86      0x56    0x4b            KP 4    QZ_KP4
    76,     //  87      0x57    0x4c            KP 5    QZ_KP5
    77,     //  88      0x58    0x4d            KP 6    QZ_KP6
    71,     //  89      0x59    0x47            KP 7    QZ_KP7
    0,      //  90      0x5A    Undefined
    72,     //  91      0x5B    0x48            KP 8    QZ_KP8
    73,     //  92      0x5C    0x49            KP 9    QZ_KP9
    125,    //  93    0x5D    Backslash (NIP)
    115,    //  94    0x5E    Underline (NIP)
    0,      //  95      0x5F    Undefined
    63,     //  96      0x60    0x3f            F5      QZ_F5
    64,     //  97      0x61    0x40            F6      QZ_F6
    65,     //  98      0x62    0x41            F7      QZ_F7
    61,     //  99      0x63    0x3d            F3      QZ_F3
    66,     //  100     0x64    0x42            F8      QZ_F8
    67,     //  101     0x65    0x43            F9      QZ_F9
    0,      //  102     0x66    Undefined
    87,     //  103     0x67    0x57            F11     QZ_F11
    0,      //  104     0x68    Undefined
    183,    //  105     0x69    0xb7            QZ_PRINT
    0,      //  106     0x6A    Undefined
    70,     //  107     0x6B    0x46            SCROLL  QZ_SCROLLOCK
    0,      //  108     0x6C    Undefined
    68,     //  109     0x6D    0x44            F10     QZ_F10
    0,      //  110     0x6E    Undefined
    88,     //  111     0x6F    0x58            F12     QZ_F12
    0,      //  112     0x70    Undefined
    110,    //  113     0x71    0x0                     QZ_PAUSE
    210,    //  114     0x72    0xd2    E0,52   INSERT  QZ_INSERT
    199,    //  115     0x73    0xc7    E0,47   HOME    QZ_HOME
    201,    //  116     0x74    0xc9    E0,49   PG UP   QZ_PAGEUP
    211,    //  117     0x75    0xd3    E0,53   DELETE  QZ_DELETE
    62,     //  118     0x76    0x3e            F4      QZ_F4
    207,    //  119     0x77    0xcf    E0,4f   END     QZ_END
    60,     //  120     0x78    0x3c            F2      QZ_F2
    209,    //  121     0x79    0xd1    E0,51   PG DN   QZ_PAGEDOWN
    59,     //  122     0x7A    0x3b            F1      QZ_F1
    203,    //  123     0x7B    0xcb    e0,4B   L ARROW QZ_LEFT
    205,    //  124     0x7C    0xcd    e0,4D   R ARROW QZ_RIGHT
    208,    //  125     0x7D    0xd0    E0,50   D ARROW QZ_DOWN
    200,    //  126     0x7E    0xc8    E0,48   U ARROW QZ_UP
/* completed according to http: //www.libsdl.org/cgi/cvsweb.cgi/SDL12/src/video/quartz/SDL_QuartzKeys.h?rev=1.6&content-type=text/x-cvsweb-markup */
  
/* Aditional 104 Key XP-Keyboard Scancodes from http:   //www.computer-engineering.org/ps2keyboard/scancodes1.html */
/*
    219,    //          0xdb            e0,5b   L GUI   
    220,    //          0xdc            e0,5c   R GUI   
    221,    //          0xdd            e0,5d   APPS    
            //              E0,2A,E0,37         PRNT SCRN   
            //              E1,1D,45,E1,9D,C5   PAUSE   
    83,     //          0x53    0x53            KP .    
// ACPI Scan Codes                              
    222,    //          0xde            E0, 5E  Power   
    223,    //          0xdf            E0, 5F  Sleep   
    227,    //          0xe3            E0, 63  Wake    
// Windows Multimedia Scan Codes                                
    153,    //          0x99            E0, 19  Next Track  
    144,    //          0x90            E0, 10  Previous Track  
    164,    //          0xa4            E0, 24  Stop    
    162,    //          0xa2            E0, 22  Play/Pause  
    160,    //          0xa0            E0, 20  Mute    
    176,    //          0xb0            E0, 30  Volume Up   
    174,    //          0xae            E0, 2E  Volume Down 
    237,    //          0xed            E0, 6D  Media Select    
    236,    //          0xec            E0, 6C  E-Mail  
    161,    //          0xa1            E0, 21  Calculator  
    235,    //          0xeb            E0, 6B  My Computer 
    229,    //          0xe5            E0, 65  WWW Search  
    178,    //          0xb2            E0, 32  WWW Home    
    234,    //          0xea            E0, 6A  WWW Back    
    233,    //          0xe9            E0, 69  WWW Forward 
    232,    //          0xe8            E0, 68  WWW Stop    
    231,    //          0xe7            E0, 67  WWW Refresh 
    230     //          0xe6            E0, 66  WWW Favorites   
*/
};

int cocoa_keycode_to_qemu(int keycode)
{
    if((sizeof(keymap)/sizeof(int)) <= keycode)
    {
        printf("(cocoa) warning unknow keycode 0x%x\n", keycode);
        return 0;
    }
    return keymap[keycode];
}



/*
 ------------------------------------------------------
    Qemu Video Driver

 ------------------------------------------------------
*/
void cocoa_update(DisplayState *ds, int x, int y, int w, int h)
{
//  NSLog(@"cocoa: update");

    if ([[[pc contentView] class] isEqual:[cocoaQemuQuartzView class]]) {

        /* new selective drawing code (draws only dirty rectangles) */
        [[pc contentView] setNeedsDisplayInRect:NSMakeRect(
            x * [[pc contentView] cdx],
            [[pc contentView] frame].size.height - (h + y) * [[pc contentView] cdy],
            w * [[pc contentView] cdx],
            h * [[pc contentView] cdy]
        )];

    } else {

        /* old drawing code (draws everything) */
        [[pc contentView] drawContent:ds];
        
    }
}

void cocoa_resize(DisplayState *ds, int w, int h)
{
//  NSLog(@"cocoa: resize\n");

    [[pc contentView] resizeContent:ds width:w height:h];
}

void cocoa_refresh(DisplayState *ds)
{
//  NSLog(@"cocoa: refresh\n");

    if (kbd_mouse_is_absolute()) {
        if (![pc absolute_enabled]) {
            if ([pc grab]) {
                [pc ungrabMouse];
            }
        }
        [pc setAbsolute_enabled:1];
    }

    NSEvent *event;
    do {
        event = [ NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[ NSDate distantPast ]
                        inMode: NSDefaultRunLoopMode dequeue:YES ];
        if (event != nil) {
            switch ([event type])
            {

                case NSFlagsChanged:
                    {
                        int keycode = cocoa_keycode_to_qemu([event keyCode]);
                        [pc setModifierAtIndex:keycode to: ([pc modifierAtIndex:keycode] == 0) ? 1 : 0];

                        if ( [pc modifierAtIndex:keycode] ) { /* Keydown */
                            if (keycode & 0x80)
                                kbd_put_keycode(0xe0);
                            kbd_put_keycode(keycode & 0x7f);
                        } else { /* Keyup */
                            if (keycode & 0x80)
                                kbd_put_keycode(0xe0);
                            kbd_put_keycode(keycode | 0x80);
                        }

                        /* emulate caps lock and num lock keyup */
                        if ((keycode == 58) || (keycode == 69))
                        {
                            [pc setModifierAtIndex:keycode to:0];
                            if (keycode & 0x80)
                                kbd_put_keycode(0xe0);
                            kbd_put_keycode(keycode | 0x80);
                        }

                        /* release Mouse grab when pressing ctrl+alt */
                        if ((![pc fullscreen]) && ([event modifierFlags] & NSControlKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))
                            [pc ungrabMouse];
                    }
                    break;
                    
                case NSKeyDown:
                    {
                        int keycode = cocoa_keycode_to_qemu([event keyCode]);               
                        
                        /* handle command Key Combos */
                        if ([event modifierFlags] & NSCommandKeyMask) {
                            switch ([event keyCode]) {

                                /* toggle fullscreen */
                                case 3: /* f key */
                                    // show hint to exit fullscreen, fast os switch, toolbar
                                    if(![pc fullscreen]) {
                                    #if kju_debug
                                       NSLog(@"init FSController");
                                    #endif
                                        NSBeginAlertSheet(NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:standardAlert", @"Localizable", @"cocoaQemu"),NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:defaultButton", @"Localizable", @"cocoaQemu"),nil,nil,[pc pcWindow],pc,@selector(showFullscreenAlertSheetDidEnd:returnCode:contextInfo:),nil,nil,NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:informativeText", @"Localizable", @"cocoaQemu"));
                                       [pc setFullscreenController:[[FSController alloc] initWithSender:pc]];
                                    } else {
                                    #if kju_debug
                                        NSLog(@"release FSController");
                                    #endif
                                        [pc setFullscreen:[[pc contentView] toggleFullScreen]];
                                        [[pc fullscreenController] release];
                                    }
                                    return;

//                              /* paste text in Host Clipboard to Guest */
//                              case 9: /* v key */
//                              {
//                                  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//                                  NSString *string = [NSString stringWithString:[pasteboard stringForType:NSStringPboardType]];
//                                  if (string) {
//                                      NSLog(@"PASTE: %@", string);
//                                      int ii;
//                                      int maxChars = 24;
//                                      if ([string length] < maxChars)
//                                          maxChars = [string length];
//                                      for (ii=0; ii<maxChars; ii++) {
//                                          /* keycode */
//                                          keycode = keysym2scancode(kbd_layout, [string characterAtIndex:ii]);
//
//                                          if (keycode!=0) {
//                                              /* key down events */
//                                              if (keycode & 0x80)
//                                                  kbd_put_keycode(0xe0);
//                                              kbd_put_keycode(keycode & 0x7f);
//                                          
//                                              /* key up events */
//                                              if (keycode & 0x80)
//                                                  kbd_put_keycode(0xe0);
//                                              kbd_put_keycode(keycode | 0x80);
//                                          }
//                                      }
//                                      [string release];
//                                  }
//                                  return;
//                              }

                                /* quit */
                                case 12: /* q key */
                                    /* switch to windowed View */
                                    if ([pc fullscreen]) {
                                        [pc setFullscreen:[[pc contentView] toggleFullScreen]];
                                        [[pc fullscreenController] release];
                                    }
                                    [[pc pcWindow] performClose:nil];
                                    return;

                                /* minimize Window */
                                case 46: /* m key */
                                    if ([pc fullscreen])
                                        [pc setFullscreen:[[pc contentView] toggleFullScreen]];
                                    [[pc pcWindow] miniaturize:nil];
                                    return;

//                              /* app switch *//* does not work, as dock is ogging command-tab */
//                              case 48: /* tab key */
//                                  if ([pc fullscreen])
//                                      [pc setFullscreen:[[pc contentView] toggleFullScreen]];
//                                  return;

                                /* window switch */
                                case 50: /* backquote key */
                                    if ([event modifierFlags] & NSShiftKeyMask) { /* previous Window */
                                        if ([[pc qdoserver] guestSwitch:[pc pcName] fullscreen:[pc fullscreen] previousGuestName:nil])
                                            return;
                                        else
                                            break;
                                    } else { /* next Window */
                                        if ([[pc qdoserver] guestSwitch:[pc pcName] fullscreen:[pc fullscreen] nextGuestName:nil])
                                            return;
                                        else
                                            break;
                                    }

                                /* fullscreen toolbar */
                                case 11: /* B-key */
                                    if ([pc fullscreen]) {
                                        [[pc fullscreenController] toggleToolbar];
                                        return;
                                    } else {
                                        break;
                                    }

                            }
                        }

                        /* handle control + alt Key Combos */
                        if (([event modifierFlags] & NSControlKeyMask) && ([event modifierFlags] & NSAlternateKeyMask)) {
                            switch (keycode) {
                                /* toggle Monitor */
                                case 0x02 ... 0x0a: /* '1' to '9' keys */
                                    {
                                        /* setup transition */
                                        CGSConnection cid = _CGSDefaultConnection();
                                        int transitionHandle = -1;
                                        CGSTransitionSpec transitionSpecifications;

                                        transitionSpecifications.type = 9; //transition;
                                        if (keycode - 0x02 == 0)
                                            transitionSpecifications.option=CGSLeft | (1<<7); //option;
                                        else
                                            transitionSpecifications.option=CGSRight | (1<<7); //option;
                                        transitionSpecifications.wid = [[pc pcWindow] windowNumber]; //wid
                                        transitionSpecifications.backColour = 0; //background color

                                        /* freeze desktop: OSStatus CGSNewTransition(const CGSConnection cid, const CGSTransitionSpec* transitionSpecifications, int *transitionHandle) */
                                        CGSNewTransition(cid, &transitionSpecifications, &transitionHandle);

                                        /* change monitor */
                                        console_select(keycode - 0x02);
                                        vga_hw_update();

                                        /* wait */
                                        usleep(10000);

                                        /* run transition: OSStatus CGSInvokeTransition(const CGSConnection cid, int transitionHandle, float duration) */
                                        CGSInvokeTransition(cid, transitionHandle, 1.0);

                                        break;
                                    }
//                                  console_select(keycode - 0x02);
//                                  break;
                                /* toggle Fullscreen */
                                case 0x21: /* 'f' key */
                                    // show hint to exit fullscreen, fast os switch, toolbar
                                    if(![pc fullscreen]) {
                                        NSBeginAlertSheet(NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:standardAlert", @"Localizable", @"cocoaQemu"),NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:defaultButton", @"Localizable", @"cocoaQemu"),nil,nil,[pc pcWindow],pc,@selector(showFullscreenAlertSheetDidEnd:returnCode:contextInfo:),nil,nil,NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:informativeText", @"Localizable", @"cocoaQemu"));
                                    } else {
                                        [pc setFullscreen:[[pc contentView] toggleFullScreen]];
                                    }
                                    break;
                            }
                        } else {
                            /* handle standard key events */
                            if (is_graphic_console()) {
                                if (keycode & 0x80) //check bit for e0 in front
                                    kbd_put_keycode(0xe0);
                                kbd_put_keycode(keycode & 0x7f); //remove e0 bit in front
                            /* handle monitor key events */
                            } else {
                                switch([event keyCode]) {
                                    case 123:
                                        kbd_put_keysym(QEMU_KEY_LEFT);
                                        break;
                                    case 124:
                                        kbd_put_keysym(QEMU_KEY_RIGHT);
                                        break;
                                    case 125:
                                        kbd_put_keysym(QEMU_KEY_DOWN);
                                        break;
                                    case 126:
                                        kbd_put_keysym(QEMU_KEY_UP);
                                        break;
                                    default:
                                    {
                                        NSString *ks = [event characters];
                                        if ([ks length] > 0)
                                            kbd_put_keysym([ks characterAtIndex:0]);
                                    }
                                }
                            }
                        }
                    }
                    break;

                case NSKeyUp:
                    {
                        int keycode = cocoa_keycode_to_qemu([event keyCode]);
                        if (is_graphic_console()) {
                            if (keycode & 0x80)
                                kbd_put_keycode(0xe0);
                            kbd_put_keycode(keycode | 0x80); //add 128 to signal release of key
                        }
                    }
                    break;

                case NSMouseMoved:
                    if ([pc absolute_enabled]) {
                        NSPoint p = [event locationInWindow];
                        if (p.x < 0 || p.x > ds->width || p.y < 0 || p.y > ds->height || ![[pc pcWindow] isKeyWindow]) {
                            if ([pc tablet_enabled])
                                [NSCursor unhide];
                            [pc setTablet_enabled:0];
                        } else {
                            if (![pc tablet_enabled])
                                [NSCursor hide];
                            [pc setTablet_enabled:1];
                            int dx = p.x * 0x7FFF / ds->width;
                            int dy = (ds->height - p.y) * 0x7FFF / ds->height;
                            int dz = [event deltaZ];
                            int buttons = 0;
                            kbd_mouse_event(dx, dy, dz, buttons);
                        }
                    } else if ([pc grab]) {
                        int dx = [event deltaX];
                        int dy = [event deltaY];
                        int dz = [event deltaZ];
                        int buttons = 0;
                        kbd_mouse_event(dx, dy, dz, buttons);
                    }
                    break;

                case NSLeftMouseDown:
                    if ([pc grab]||[pc tablet_enabled]) {
                        int buttons = 0;
                        
                        /* leftclick+command simulates rightclick */
                        if ([event modifierFlags] & NSCommandKeyMask) {
                            buttons |= MOUSE_EVENT_RBUTTON;
                        } else {
                            buttons |= MOUSE_EVENT_LBUTTON;
                        }
                        kbd_mouse_event(0, 0, 0, buttons);
                    } else {
                        [NSApp sendEvent: event];
                    }
                    break;

                case NSLeftMouseDragged:
                    if ([pc tablet_enabled]) {
                        NSPoint p = [event locationInWindow];
                        int dx = p.x * 0x7FFF / ds->width;
                        int dy = (ds->height - p.y) * 0x7FFF / ds->height;
                        int dz = [event deltaZ];
                        int buttons = 0;
                        if ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) { //leftclick+command simulates rightclick
                            buttons |= MOUSE_EVENT_RBUTTON;
                        } else {
                            buttons |= MOUSE_EVENT_LBUTTON;
                        }
                        kbd_mouse_event(dx, dy, dz, buttons);
                    } else if ([pc grab]) {
                        int dx = [event deltaX];
                        int dy = [event deltaY];
                        int dz = [event deltaZ];
                        int buttons = 0;
                        if ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) { //leftclick+command simulates rightclick
                            buttons |= MOUSE_EVENT_RBUTTON;
                        } else {
                            buttons |= MOUSE_EVENT_LBUTTON;
                        }
                        kbd_mouse_event(dx, dy, dz, buttons);
                    }
                    break;

                case NSLeftMouseUp:
/*                  if ([pc absolute_enabled] && ![pc tablet_enabled]) {
                        [NSApp sendEvent: event];
                    } else*/
                    if ([pc grab]||[pc tablet_enabled]) {
                        kbd_mouse_event(0, 0, 0, 0);
                    } else {
                        [NSApp sendEvent: event];
                    }
                    break;

                case NSRightMouseDown:
                    if ([pc grab]||[pc tablet_enabled]) {
                        int buttons = 0;
                        
                        buttons |= MOUSE_EVENT_RBUTTON;
                        kbd_mouse_event(0, 0, 0, buttons);
                    } else {
                        [NSApp sendEvent: event];
                    }
                    break;

                case NSRightMouseDragged:
                    if ([pc tablet_enabled]) {
                        NSPoint p = [event locationInWindow];
                        int dx = p.x * 0x7FFF / ds->width;
                        int dy = (ds->height - p.y) * 0x7FFF / ds->height;
                        int dz = [event deltaZ];
                        int buttons = 0;
                        buttons |= MOUSE_EVENT_RBUTTON;
                        kbd_mouse_event(dx, dy, dz, buttons);
                    } else if ([pc grab]) {
                        int dx = [event deltaX];
                        int dy = [event deltaY];
                        int dz = [event deltaZ];
                        int buttons = 0;
                        buttons |= MOUSE_EVENT_RBUTTON;
                        kbd_mouse_event(dx, dy, dz, buttons);
                    }
                    break;

                case NSRightMouseUp:
                    if ([pc grab]||[pc tablet_enabled]) {
                        kbd_mouse_event(0, 0, 0, 0);
                    } else {
                        [NSApp sendEvent: event];
                    }
                    break;

                case NSOtherMouseDragged:
                    if ([pc tablet_enabled]) {
                        NSPoint p = [event locationInWindow];
                        int dx = p.x * 0x7FFF / ds->width;
                        int dy = (ds->height - p.y) * 0x7FFF / ds->height;
                        int dz = [event deltaZ];
                        int buttons = 0;
                        buttons |= MOUSE_EVENT_MBUTTON;
                        kbd_mouse_event(dx, dy, dz, buttons);
                    } else if ([pc grab]) {
                        int dx = [event deltaX];
                        int dy = [event deltaY];
                        int dz = [event deltaZ];
                        int buttons = 0;
                        buttons |= MOUSE_EVENT_MBUTTON;
                        kbd_mouse_event(dx, dy, dz, buttons);
                    }
                    break;

                case NSOtherMouseDown:
                    if ([pc grab]||[pc tablet_enabled]) {
                        int buttons = 0;
                        buttons |= MOUSE_EVENT_MBUTTON;
                        kbd_mouse_event(0, 0, 0, buttons);
                    } else {
                        [NSApp sendEvent:event];
                    }
                    break;

                case NSOtherMouseUp:
                    if ([pc grab]||[pc tablet_enabled]) {
                        kbd_mouse_event(0, 0, 0, 0);
                    } else {
                        [NSApp sendEvent: event];
                    }
                    break;

                case NSScrollWheel:
                    if ([pc grab]||[pc tablet_enabled]) {
                        int dz = [event deltaY];
                        kbd_mouse_event(0, 0, -dz, 0);
                    }
                    break;

                default: [NSApp sendEvent:event];
            }
        }
    } while(event != nil);

    vga_hw_update();
}

void cocoa_display_init(DisplayState *ds, int full_screen)
{
//  NSLog(@"cocoa: init\n");

    ds->dpy_update = cocoa_update;
    ds->dpy_resize = cocoa_resize;
    ds->dpy_refresh = cocoa_refresh;

#ifdef __LITTLE_ENDIAN__
    ds->bgr = 1;
#else
    ds->bgr = 0;
#endif

    cocoa_resize(ds, 640, 400);
}


/*
 ------------------------------------------------------
    QemuCocoa CD-ROM Driver
    
 ------------------------------------------------------
*/
kern_return_t FindEjectableCDMedia( io_iterator_t *mediaIterator )
{
    kern_return_t       kernResult; 
    mach_port_t     masterPort;
    CFMutableDictionaryRef  classesToMatch;
    
    kernResult = IOMasterPort( MACH_PORT_NULL, &masterPort );
    if ( KERN_SUCCESS != kernResult ) {
        printf( "IOMasterPort returned %d\n", kernResult );
    }
    
    classesToMatch = IOServiceMatching( kIOCDMediaClass ); 
    if ( classesToMatch == NULL ) {
        printf( "IOServiceMatching returned a NULL dictionary.\n" );
    } else {
        CFDictionarySetValue( classesToMatch, CFSTR( kIOMediaEjectableKey ), kCFBooleanTrue );
    }
    kernResult = IOServiceGetMatchingServices( masterPort, classesToMatch, mediaIterator );
    if ( KERN_SUCCESS != kernResult )
    {
        printf( "IOServiceGetMatchingServices returned %d\n", kernResult );
    }
    
    return kernResult;
}

kern_return_t GetBSDPath( io_iterator_t mediaIterator, char *bsdPath, CFIndex maxPathSize )
{
    io_object_t     nextMedia;
    kern_return_t   kernResult = KERN_FAILURE;
    *bsdPath = '\0';
    nextMedia = IOIteratorNext( mediaIterator );
    if ( nextMedia )
    {
        CFTypeRef   bsdPathAsCFString;
        bsdPathAsCFString = IORegistryEntryCreateCFProperty( nextMedia, CFSTR( kIOBSDNameKey ), kCFAllocatorDefault, 0 );
        if ( bsdPathAsCFString ) {
            size_t devPathLength;
            strcpy( bsdPath, _PATH_DEV );
            strcat( bsdPath, "r" );
            devPathLength = strlen( bsdPath );
            if ( CFStringGetCString( bsdPathAsCFString, bsdPath + devPathLength, maxPathSize - devPathLength, kCFStringEncodingASCII ) ) {
//               printf( "BSD path: %s\n", bsdPath );
                kernResult = KERN_SUCCESS;
            }
            CFRelease( bsdPathAsCFString );
        }
        IOObjectRelease( nextMedia );
    }
    
    return kernResult;
}
