/*
 * Q Application
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

#import "QApplication.h"

#import "../QDocument/QDocument.h"
#import "../FSControls/FSController.h"


@implementation QApplication
- (id) init
{
	Q_DEBUG(@"init");

    self = [super init];
    if (self) {
        applicationController = [[QApplicationController alloc] init];
        [self setDelegate: applicationController];
    }
    return self;
}



- (void) dealloc
{
	Q_DEBUG(@"dealloc");

    [applicationController dealloc];
    [super dealloc];
}



- (void) sendEvent:(NSEvent *)anEvent
{
	Q_DEBUG(@"sendEvent");

    QDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
    
    // handle command Key Combos
    if (([anEvent type] == NSKeyDown) && ([anEvent modifierFlags] & NSCommandKeyMask)) {
        switch ([anEvent keyCode]) {
                    
            // fullscreen
            case 3: // cmd+f
                [[document screenView] toggleFullScreen];
                break;

            // fullscreen toolbar
            case 11: // cmd+b
                if ([[document screenView] fullscreen]) {
                    [[[document screenView] fullscreenController] toggleToolbar];
                }
                break;
            
            // default
            default:
                [super sendEvent:anEvent];
                break;
        }

    // handle mouseGrabed
    } else if ([[document screenView] mouseGrabed]) {
        [[document screenView] handleEvent:anEvent];

    // default
    } else {
        [super sendEvent:anEvent];
    }
}




- (QApplicationController *) applicationController { return applicationController;}
@end
