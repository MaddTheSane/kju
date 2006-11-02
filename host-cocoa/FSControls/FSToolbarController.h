/* FSToolbarController */

#import <Cocoa/Cocoa.h>
#import "FSRoundedView.h"

#define SEMI_TRANSPARENT_COLOR [NSColor colorWithCalibratedWhite:0.0 alpha:0.6]

@interface FSToolbarController : NSObject
{
	NSWindow * window;
	FSRoundedView * view;
	NSTimer * fadeTimer;
	
	BOOL showsToolbar;
	BOOL isAnimating;
	id pc;
}
- (id) initWithSender:(id)sender;

- (void) show;
- (void) hide;
- (BOOL) showsToolbar;
- (void) setupToolbar;
- (void) addToolbarItem:(NSString *)icon withTitle:(NSString *)title rectangle:(NSRect)rectangle target:(id) target action:(SEL)action;
- (void) addCustomToolbarItem:(id)item;

- (NSWindow *) createTransparentWindow;

// fading operations
- (void) fadeIn;
- (void) fadeOut;
- (void) setAnimates:(BOOL)lock;
- (BOOL) isAnimating;
- (void) setFullscreen:(id)sender;
- (void) shutdownPC:(id)sender;
@end
