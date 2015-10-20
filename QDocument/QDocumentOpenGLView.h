/*
 * Q Document OpenGL View
 * 
 * Copyright (c) 2006 - 2007    Mike Kronenberg
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
#import <OpenGL/gl.h>

#import "../QApplication/QApplicationController.h"
#import "QDocument.h"

// some defines from from vl.h
#define MOUSE_EVENT_LBUTTON 0x01
#define MOUSE_EVENT_RBUTTON 0x02
#define MOUSE_EVENT_MBUTTON 0x04

#define TITLE_BAR_HEIGHT 21.0
#define ICON_BAR_HEIGHT 30.0

NS_ASSUME_NONNULL_BEGIN

typedef struct {
	int width;
	int height;
	int bitsPerComponent;
	int bitsPerPixel;
	size_t screenBufferSize;
} QScreen;

typedef struct {
    float x;
    float y;
    float width;
    float height;
    float dx;
    float dy;
    float zoom;
} QDisplayProperties;

typedef NS_ENUM(NSInteger, QDocumentOpenGLTextures) {
	QDocumentOpenGLTextureScreen = 0,
	QDocumentOpenGLTextureOverlay = 1,
	QDocumentOpenGLTextureSavedImage = 2
};

@class FSController;

@interface QDocumentOpenGLView : NSOpenGLView

@property (weak) IBOutlet QDocument *document;
@property (weak) IBOutlet NSWindow *normalWindow;

// saved image and screenshot
- (GLuint) createTextureFromImage:(NSImage *)image;
- (GLuint) createTextureFromImagePath:(NSString *)path DEPRECATED_ATTRIBUTE;
- (GLuint) createTextureFromImageURL:(NSURL *)url;
- (void) updateSavedImage:(nullable id)sender;
- (NSImage *) screenshot:(NSSize)size;

// QEMU
- (void) grabMouse;
- (void) ungrabMouse;

// fullscreen
- (void) setFullScreen;
- (void) setContentDimensionsForFrame:(NSRect)rect;
- (void) toggleFullScreen;
- (void) resizeContentToWidth:(int)w height:(int)h;

// event handling
- (void) handleEvent:(NSEvent *)event;

// getters
@property (readonly) BOOL mouseGrabed;
@property (readonly, getter=isFullscreen) BOOL fullscreen;
@property (readonly) QScreen screenProperties;
@property (readonly) QDisplayProperties displayProperties;
- (void) displayPropertiesSetZoom:(CGFloat)tZoom;
@property (readonly) void *screenBuffer NS_RETURNS_INNER_POINTER;
@property (readonly, strong) FSController *fullscreenController;
@end

NS_ASSUME_NONNULL_END
