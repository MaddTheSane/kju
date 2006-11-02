/* FSController */

#import <Cocoa/Cocoa.h>
#import "FSToolbarController.h"

@interface FSController : NSObject
{
    FSToolbarController * toolbar;
    id pc;
}
- (BOOL) showsToolbar;
- (void) toggleToolbar;

@end
