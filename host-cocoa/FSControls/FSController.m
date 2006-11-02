#import "FSController.h"
#import "../cocoaQemu.h"

@implementation FSController

- (id) initWithSender:(id)sender
{
    pc = sender;
    // init connections to fullscreen controls
    toolbar = [[FSToolbarController alloc] initWithSender: pc];
    
    // return
    return self;
}

#pragma mark Toolbar

- (BOOL) showsToolbar
{
    return [toolbar showsToolbar];
}

- (void) toggleToolbar
{
    if(![toolbar isAnimating]) {
    // avoid animation loop
        if([toolbar showsToolbar]) {
            [toolbar hide];
            [pc grabMouse];
        } else {
            [toolbar show];
            [pc ungrabMouse];
        }
    }
}

#pragma mark -

- (void) dealloc
{
    [toolbar release];
    [super dealloc];
}

@end
