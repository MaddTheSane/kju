/*
 * Q Document OpenGL View
 * 
 * Copyright (c) 2006 - 2008    Mike Kronenberg
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
 
 /*
Todo:
 - avoid roundingproblems in fullscreen (aka. flicker in xga guests)
   Problem: source_rect and destination_rect are not congruent
 */

#include <AvailabilityMacros.h>

#import "QDocumentOpenGLView.h"


#import "../CGSPrivate.h"
#import "../FSControls/FSController.h"

#import <sys/mman.h> // for mmap



// keymap conversion
int keymap[] =
{
//  SdlI    macI    macH    SdlH    104xtH  104xtC  sdl
    30, //  0       0x00    0x1e            A       QZ_a
    31, //  1       0x01    0x1f            S       QZ_s
    32, //  2       0x02    0x20            D       QZ_d
    33, //  3       0x03    0x21            F       QZ_f
    35, //  4       0x04    0x23            H       QZ_h
    34, //  5       0x05    0x22            G       QZ_g
    44, //  6       0x06    0x2c            Z       QZ_z
    45, //  7       0x07    0x2d            X       QZ_x
    46, //  8       0x08    0x2e            C       QZ_c
    47, //  9       0x09    0x2f            V       QZ_v
    0,  //  10      0x0A    Undefined
    48, //  11      0x0B    0x30            B       QZ_b
    16, //  12      0x0C    0x10            Q       QZ_q
    17, //  13      0x0D    0x11            W       QZ_w
    18, //  14      0x0E    0x12            E       QZ_e
    19, //  15      0x0F    0x13            R       QZ_r
    21, //  16      0x10    0x15            Y       QZ_y
    20, //  17      0x11    0x14            T       QZ_t
    2,  //  18      0x12    0x02            1       QZ_1
    3,  //  19      0x13    0x03            2       QZ_2
    4,  //  20      0x14    0x04            3       QZ_3
    5,  //  21      0x15    0x05            4       QZ_4
    7,  //  22      0x16    0x07            6       QZ_6
    6,  //  23      0x17    0x06            5       QZ_5
    13, //  24      0x18    0x0d            =       QZ_EQUALS
    10, //  25      0x19    0x0a            9       QZ_9
    8,  //  26      0x1A    0x08            7       QZ_7
    12, //  27      0x1B    0x0c            -       QZ_MINUS
    9,  //  28      0x1C    0x09            8       QZ_8
    11, //  29      0x1D    0x0b            0       QZ_0
    27, //  30      0x1E    0x1b            ]       QZ_RIGHTBRACKET
    24, //  31      0x1F    0x18            O       QZ_o
    22, //  32      0x20    0x16            U       QZ_u
    26, //  33      0x21    0x1a            [       QZ_LEFTBRACKET
    23, //  34      0x22    0x17            I       QZ_i
    25, //  35      0x23    0x19            P       QZ_p
    28, //  36      0x24    0x1c            ENTER   QZ_RETURN
    38, //  37      0x25    0x26            L       QZ_l
    36, //  38      0x26    0x24            J       QZ_j
    40, //  39      0x27    0x28            '       QZ_QUOTE
    37, //  40      0x28    0x25            K       QZ_k
    39, //  41      0x29    0x27            ;       QZ_SEMICOLON
    43, //  42      0x2A    0x2b            \       QZ_BACKSLASH
    51, //  43      0x2B    0x33            ,       QZ_COMMA
    53, //  44      0x2C    0x35            /       QZ_SLASH
    49, //  45      0x2D    0x31            N       QZ_n
    50, //  46      0x2E    0x32            M       QZ_m
    52, //  47      0x2F    0x34            .       QZ_PERIOD
    15, //  48      0x30    0x0f            TAB     QZ_TAB
    57, //  49      0x31    0x39            SPACE   QZ_SPACE
    41, //  50      0x32    0x29            `       QZ_BACKQUOTE
    14, //  51      0x33    0x0e            BKSP    QZ_BACKSPACE
    0,  //  52      0x34    Undefined
    1,  //  53      0x35    0x01            ESC     QZ_ESCAPE
    0,  //  54      0x36                            QZ_RMETA
    0,  //  55      0x37                            QZ_LMETA
    42, //  56      0x38    0x2a            L SHFT  QZ_LSHIFT
    58, //  57      0x39    0x3a            CAPS    QZ_CAPSLOCK
    56, //  58      0x3A    0x38            L ALT   QZ_LALT
    29, //  59      0x3B    0x1d            L CTRL  QZ_LCTRL
    54, //  60      0x3C    0x36            R SHFT  QZ_RSHIFT
    184,//  61      0x3D    0xb8    E0,38   R ALT   QZ_RALT
    157,//  62      0x3E    0x9d    E0,1D   R CTRL  QZ_RCTRL
    0,  //  63      0x3F    Undefined
    0,  //  64      0x40    Undefined
    0,  //  65      0x41    Undefined
    0,  //  66      0x42    Undefined
    55, //  67      0x43    0x37            KP *    QZ_KP_MULTIPLY
    0,  //  68      0x44    Undefined
    78, //  69      0x45    0x4e            KP +    QZ_KP_PLUS
    0,  //  70      0x46    Undefined
    69, //  71      0x47    0x45            NUM     QZ_NUMLOCK
    0,  //  72      0x48    Undefined
    0,  //  73      0x49    Undefined
    0,  //  74      0x4A    Undefined
    181,//  75      0x4B    0xb5    E0,35   KP /    QZ_KP_DIVIDE
    152,//  76      0x4C    0x9c    E0,1C   KP EN   QZ_KP_ENTER
    0,  //  77      0x4D    undefined
    74, //  78      0x4E    0x4a            KP -    QZ_KP_MINUS
    0,  //  79      0x4F    Undefined
    0,  //  80      0x50    Undefined
    0,  //  81      0x51                            QZ_KP_EQUALS
    82, //  82      0x52    0x52            KP 0    QZ_KP0
    79, //  83      0x53    0x4f            KP 1    QZ_KP1
    80, //  84      0x54    0x50            KP 2    QZ_KP2
    81, //  85      0x55    0x51            KP 3    QZ_KP3
    75, //  86      0x56    0x4b            KP 4    QZ_KP4
    76, //  87      0x57    0x4c            KP 5    QZ_KP5
    77, //  88      0x58    0x4d            KP 6    QZ_KP6
    71, //  89      0x59    0x47            KP 7    QZ_KP7
    0,  //  90      0x5A    Undefined
    72, //  91      0x5B    0x48            KP 8    QZ_KP8
    73, //  92      0x5C    0x49            KP 9    QZ_KP9
    0,  //  93      0x5D    Undefined
    0,  //  94      0x5E    Undefined
    0,  //  95      0x5F    Undefined
    63, //  96      0x60    0x3f            F5      QZ_F5
    64, //  97      0x61    0x40            F6      QZ_F6
    65, //  98      0x62    0x41            F7      QZ_F7
    61, //  99      0x63    0x3d            F3      QZ_F3
    66, //  100     0x64    0x42            F8      QZ_F8
    67, //  101     0x65    0x43            F9      QZ_F9
    0,  //  102     0x66    Undefined
    87, //  103     0x67    0x57            F11     QZ_F11
    0,  //  104     0x68    Undefined
    183,//  105     0x69    0xb7            QZ_PRINT
    0,  //  106     0x6A    Undefined
    70, //  107     0x6B    0x46            SCROLL  QZ_SCROLLOCK
    0,  //  108     0x6C    Undefined
    68, //  109     0x6D    0x44            F10     QZ_F10
    0,  //  110     0x6E    Undefined
    88, //  111     0x6F    0x58            F12     QZ_F12
    0,  //  112     0x70    Undefined
    110,//  113     0x71    0x0                     QZ_PAUSE
    210,//  114     0x72    0xd2    E0,52   INSERT  QZ_INSERT
    199,//  115     0x73    0xc7    E0,47   HOME    QZ_HOME
    201,//  116     0x74    0xc9    E0,49   PG UP   QZ_PAGEUP
    211,//  117     0x75    0xd3    E0,53   DELETE  QZ_DELETE
    62, //  118     0x76    0x3e            F4      QZ_F4
    207,//  119     0x77    0xcf    E0,4f   END     QZ_END
    60, //  120     0x78    0x3c            F2      QZ_F2
    209,//  121     0x79    0xd1    E0,51   PG DN   QZ_PAGEDOWN
    59, //  122     0x7A    0x3b            F1      QZ_F1
    203,//  123     0x7B    0xcb    e0,4B   L ARROW QZ_LEFT
    205,//  124     0x7C    0xcd    e0,4D   R ARROW QZ_RIGHT
    208,//  125     0x7D    0xd0    E0,50   D ARROW QZ_DOWN
    200,//  126     0x7E    0xc8    E0,48   U ARROW QZ_UP
/* completed according to http://www.libsdl.org/cgi/cvsweb.cgi/SDL12/src/video/quartz/SDL_QuartzKeys.h?rev=1.6&content-type=text/x-cvsweb-markup */
  
/* Aditional 104 Key XP-Keyboard Scancodes from http://www.computer-engineering.org/ps2keyboard/scancodes1.html */
/*
    219 //          0xdb            e0,5b   L GUI   
    220 //          0xdc            e0,5c   R GUI   
    221 //          0xdd            e0,5d   APPS    
        //              E0,2A,E0,37         PRNT SCRN   
        //              E1,1D,45,E1,9D,C5   PAUSE   
    83  //          0x53    0x53            KP .    
// ACPI Scan Codes                              
    222 //          0xde            E0, 5E  Power   
    223 //          0xdf            E0, 5F  Sleep   
    227 //          0xe3            E0, 63  Wake    
// Windows Multimedia Scan Codes                                
    153 //          0x99            E0, 19  Next Track  
    144 //          0x90            E0, 10  Previous Track  
    164 //          0xa4            E0, 24  Stop    
    162 //          0xa2            E0, 22  Play/Pause  
    160 //          0xa0            E0, 20  Mute    
    176 //          0xb0            E0, 30  Volume Up   
    174 //          0xae            E0, 2E  Volume Down 
    237 //          0xed            E0, 6D  Media Select    
    236 //          0xec            E0, 6C  E-Mail  
    161 //          0xa1            E0, 21  Calculator  
    235 //          0xeb            E0, 6B  My Computer 
    229 //          0xe5            E0, 65  WWW Search  
    178 //          0xb2            E0, 32  WWW Home    
    234 //          0xea            E0, 6A  WWW Back    
    233 //          0xe9            E0, 69  WWW Forward 
    232 //          0xe8            E0, 68  WWW Stop    
    231 //          0xe7            E0, 67  WWW Refresh 
    230 //          0xe6            E0, 66  WWW Favorites   
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



@interface BlackView : NSView
{
    float opacity;
}
- (void) setOpacity:(float)value;
@end
@implementation BlackView
- (void) drawRect:(NSRect) rect
{
    CGContextRef viewContextRef = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShouldAntialias (viewContextRef, NO);
    CGContextSetRGBFillColor(viewContextRef, 0, 0, 0, opacity);
    CGContextFillRect(viewContextRef, cgrect(rect));
}
- (void) setOpacity:(float)value {opacity = value;}
@end



@implementation QDocumentOpenGLView
- (void) dealloc
{
	Q_DEBUG(@"dealloc");
		
    // disabnle drag'n'drop
    [self unregisterDraggedTypes];

/* TODO: freezes Q up to several minutes (looks like it keeps a tap on the file)
    if (screenProperties.screenBufferSize > 0) {
		if (munmap(screenBuffer, screenProperties.screenBufferSize) == -1) {
			int errsv = errno;
			NSLog(@"QDocumentOpenGLView: dealloc: could not munmap:  errno(%D) - %s", errsv, strerror(errsv));
		}
	}
*/
    [super dealloc];
}

- (void)reshape
{
	Q_DEBUG(@"reshape");
	
	[[self openGLContext] makeCurrentContext];
    glViewport([self bounds].origin.x, [self bounds].origin.y, [self bounds].size.width, [self bounds].size.height);
}

- (void)awakeFromNib
{
	Q_DEBUG(@"awakeFromNib");

	// set screen properties and resize to initial value
    screenProperties.bitsPerComponent = 8;
    screenProperties.bitsPerPixel = 32;
	screenProperties.width = 640;
	screenProperties.height = 480;
	screenProperties.screenBufferSize = 0;
	
	displayProperties.x = 0.0;
	displayProperties.y = ICON_BAR_HEIGHT;
	displayProperties.width = 640;
	displayProperties.height = 480;
	displayProperties.zoom = 1.0;
	
	// initialize OpenGL and load play overlay
	[self prepareOpenGL];
	[self updateSavedImage:self];
	textures[QDocumentOpenGLTextureOverlay] = [self createTextureFromImagePath:[NSString stringWithFormat:@"%@/q_overlay_play.png", [[NSBundle mainBundle] resourcePath]]];

    // enable drag'n'drop for files
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];

    // QEMU state
    mouseGrabed = FALSE; // we start non grabbed
    is_graphic_console = TRUE; // we start in grafic mode

}

- (void) openGLDrawRect:(NSRect) rect inRect:(NSRect) vPortRect
{
	float onePixel[2];
	onePixel[0] = 2.0/vPortRect.size.width;
	onePixel[1] = 2.0/vPortRect.size.height;
		
	glBegin(GL_QUADS);
	glVertex2f(rect.origin.x * onePixel[0] - 1, rect.origin.y * onePixel[1] - 1);
	glVertex2f(rect.origin.x * onePixel[0] - 1, (rect.origin.y + rect.size.height) * onePixel[1] - 1);
	glVertex2f((rect.origin.x + rect.size.width) * onePixel[0] - 1, (rect.origin.y + rect.size.height) * onePixel[1] - 1);
	glVertex2f((rect.origin.x + rect.size.width) * onePixel[0] - 1, rect.origin.y * onePixel[1] - 1);
	glEnd();
}

- (void) drawRect:(NSRect) rect
{
	Q_DEBUG(@"drawRect: rect(%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	float onePixel[2];
    onePixel[0] = 2.0 / displayProperties.width;
    onePixel[1] = 2.0 / displayProperties.height;

	if ([document VMState] == QDocumentShutdown) {

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glClearColor(.0, .0, .0, .0);

	} else if ([document VMState] == QDocumentSaved) {

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glClearColor(0.0, 0.0, 0.0, 1.0);

		// draw saved image
		if (textures[QDocumentOpenGLTextureSavedImage] != 0) {
			glEnable(GL_TEXTURE_RECTANGLE_ARB);
			glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textures[QDocumentOpenGLTextureSavedImage]); // Select the Texture
			glBegin(GL_QUADS);
			{
			glTexCoord2f((GLfloat)screenProperties.width, (GLfloat)screenProperties.height); glVertex2f(1.0f, -1.0f);
			glTexCoord2f(0.0f, (GLfloat)screenProperties.height); glVertex2f(-1.0f, -1.0f);
			glTexCoord2f(0.0f, 0.0f); glVertex2f(-1.0f, 1.0f);
			glTexCoord2f((GLfloat)screenProperties.width, 0.0f); glVertex2f(1.0f, 1.0f);
			}
			glEnd();
			glDisable(GL_TEXTURE_RECTANGLE_ARB);
		}

    } else if ((int)screenBuffer != -1) {

		// remove old texture
		if( textures[QDocumentOpenGLTextureScreen] != 0) {
			glDeleteTextures(1, &textures[QDocumentOpenGLTextureScreen]);
		}

		textures[QDocumentOpenGLTextureScreen] = 1;
		
		// calculate the texure rect
		NSRect clipRect;
		clipRect = NSMakeRect(
			0.0, // we update the whole width, as QEMU in vga is always updating whole memory pages)
			floor((float)screenProperties.height - (rect.origin.y + rect.size.height) / displayProperties.dy),
			(float)screenProperties.width,
			ceil(rect.size.height / displayProperties.dy));
		int start = (int)clipRect.origin.y * screenProperties.width * 4;
		unsigned char *startPointer = screenBuffer;

		// adapt the drawRect to the textureRect
		rect = NSMakeRect(
			0.0, // we update the whole width, as QEMU in vga is always updating whole memory pages)
			(screenProperties.height - (clipRect.origin.y + clipRect.size.height)) * displayProperties.dy,
			displayProperties.width,
			clipRect.size.height * displayProperties.dy);

		glEnable(GL_TEXTURE_RECTANGLE_ARB); // enable rectangle textures

		// bind screenBuffer to texture
		glPixelStorei(GL_UNPACK_ROW_LENGTH, screenProperties.width); // Sets the appropriate unpacking row length for the bitmap.
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1); // Sets the byte-aligned unpacking that's needed for bitmaps that are 3 bytes per pixel.

		glBindTexture (GL_TEXTURE_RECTANGLE_ARB, textures[QDocumentOpenGLTextureScreen]); // Binds the texture name to the texture target.
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Sets filtering so that it does not use a mipmap, which would be redundant for the texture rectangle extension

		// optimize loading of texture
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE); // 
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE); // bypass OpenGL framework
		glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, (int)clipRect.size.height * screenProperties.width * 4, &startPointer[start]); // bypass OpenGL driver

		glTexImage2D(
			GL_TEXTURE_RECTANGLE_ARB,
			0,
			GL_RGBA,
			screenProperties.width,
			(int)clipRect.size.height,
			0,
#if __LITTLE_ENDIAN__
			GL_RGBA,
			GL_UNSIGNED_BYTE,
#else
			GL_BGRA,
			GL_UNSIGNED_INT_8_8_8_8_REV,
#endif
			&startPointer[start]);

		glBegin(GL_QUADS);
		{
		glTexCoord2f(0.0f, 0.0f); glVertex2f(-1.0f, (GLfloat)(onePixel[1] * (rect.origin.y + rect.size.height) - 1.0));
		glTexCoord2f(0.0f, (GLfloat)clipRect.size.height); glVertex2f(-1.0f, (GLfloat)(onePixel[1] * rect.origin.y - 1.0));
		glTexCoord2f((GLfloat)clipRect.size.width, (GLfloat)clipRect.size.height); glVertex2f(1.0f, (GLfloat)(onePixel[1] * rect.origin.y - 1.0));
		glTexCoord2f((GLfloat)clipRect.size.width, 0.0f); glVertex2f(1.0f, (GLfloat)(onePixel[1] * (rect.origin.y + rect.size.height) - 1.0));
		}
		glEnd();
		glDisable(GL_TEXTURE_RECTANGLE_ARB);

	} else {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

    // drag'n'drop overlay
    if (drag) {
		
		NSColor	 *rgbColor = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		glColor3f([rgbColor redComponent], [rgbColor greenComponent], [rgbColor blueComponent]);

		glBegin(GL_QUAD_STRIP);
		{
		glVertex2f(-1.0, -1.0); glVertex2f(3 * onePixel[0] - 1, 3 * onePixel[1] - 1);
		glVertex2f(1.0, -1.0); glVertex2f((rect.size.width - 3) * onePixel[0] - 1, 3 * onePixel[1] - 1);
		glVertex2f(1.0, 1.0); glVertex2f(([self bounds].size.width - 3) * onePixel[0] - 1, ([self bounds].size.height - 3) * onePixel[1] - 1);
		glVertex2f(-1.0, 1.0); glVertex2f(3 * onePixel[0] - 1, ([self bounds].size.height - 3) * onePixel[1] - 1);
		glVertex2f(-1.0, -1.0); glVertex2f(3 * onePixel[0] - 1, 3 * onePixel[1] - 1);
		}
		glEnd();
	}

	// play overlay
	if ([document VMState] != QDocumentRunning) {

		// draw background
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE);
		glBegin(GL_QUADS);
		{
		glColor4f(1.0f, 1.0f, 1.0f, .25f);
		glVertex2f(-1.0, -1.0);
		glVertex2f(1.0, -1.0);
		glVertex2f(1.0, 1.0);
		glVertex2f(-1.0, 1.0);
		}
		glEnd();

		// draw overlay
		glEnable(GL_TEXTURE_RECTANGLE_ARB);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textures[QDocumentOpenGLTextureOverlay]); // Select the Texture
		glBegin(GL_QUADS);
		{
		glTexCoord2f(0.0f, 200.0f); glVertex2f(-onePixel[0] * 100.0f, -onePixel[1] * 100.0f);
		glTexCoord2f(200.0f, 200.0f); glVertex2f(onePixel[0] * 100.0f, -onePixel[1] * 100.0f);
		glTexCoord2f(200.0f, 0.0f); glVertex2f(onePixel[0] * 100.0f, onePixel[1] * 100.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex2f(-onePixel[0] * 100.0f, onePixel[1] * 100.0f);
		}
		glEnd();
		glDisable(GL_BLEND);
		glDisable(GL_TEXTURE_RECTANGLE_ARB);

	}

    glFlush();
}



#pragma mark saved image and screenshots
- (GLuint) createTextureFromImagePath:(NSString *)path
{
	Q_DEBUG(@"loadTextureFromImagePath: %@", path);

	GLuint texture;
	CGImageSourceRef sourceRef;
	CGImageRef imageRef;
	CGColorSpaceRef colorSpaceRef;
	CGContextRef contextRef;
	void * textureData;
	CGRect textureRect;
	size_t textureWidth;
	size_t textureHeight;

	sourceRef = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
	if (!sourceRef)
		return 0;

	imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
	textureWidth = CGImageGetWidth(imageRef);
    textureHeight = CGImageGetHeight(imageRef);
	textureRect = CGRectMake(0, 0, textureWidth, textureHeight);
	textureData = calloc(textureWidth * 4, textureHeight);
	colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	contextRef = CGBitmapContextCreate (textureData, textureWidth, textureHeight, 8, textureWidth*4, colorSpaceRef, kCGImageAlphaPremultipliedLast);

	CGContextDrawImage(contextRef, textureRect, imageRef);
	CGContextRelease(contextRef);
	CFRelease(imageRef);
	CFRelease(sourceRef);

	glPixelStorei(GL_UNPACK_ROW_LENGTH, textureWidth);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glGenTextures(1, &texture);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(
		GL_TEXTURE_RECTANGLE_ARB,
		0,
		GL_RGBA8,
		textureWidth,
		textureHeight,
		0,
#if __LITTLE_ENDIAN__
		GL_RGBA,
		GL_UNSIGNED_BYTE,
#else
		GL_BGRA,
		GL_UNSIGNED_INT_8_8_8_8_REV,
#endif
		textureData);

	free(textureData);

	return texture;
}

- (void) updateSavedImage:(id)sender
{
	Q_DEBUG(@"updateSavedImage");


	[[self openGLContext] makeCurrentContext];

	// remove old texture
	if( textures[QDocumentOpenGLTextureSavedImage] != 0) {
		glDeleteTextures(1, &textures[QDocumentOpenGLTextureSavedImage]);
	}

	textures[QDocumentOpenGLTextureSavedImage] = [self createTextureFromImagePath:[NSString stringWithFormat:@"%@/QuickLook/Thumbnail.png", [[[[document configuration] objectForKey:@"Temporary"] objectForKey:@"URL"] path]]];
	if (textures[QDocumentOpenGLTextureSavedImage] != 0) {
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textures[QDocumentOpenGLTextureSavedImage]);
		glGetTexLevelParameteriv( GL_TEXTURE_RECTANGLE_ARB, 0, GL_TEXTURE_WIDTH, (GLint*)&screenProperties.width );
		glGetTexLevelParameteriv( GL_TEXTURE_RECTANGLE_ARB, 0, GL_TEXTURE_HEIGHT, (GLint*)&screenProperties.height ); 	
	}
	[self resizeContentToWidth:screenProperties.width height:screenProperties.height ];
}

- (NSImage *) screenshot:(NSSize)size
{
	Q_DEBUG(@"screenshot NSSize(%f,  %f)", size.width, size.height);

	// if no size is set, make a fullsize shot
	if (size.width == 0.0 || size.height == 0.0) 
		size = [self bounds].size;

	NSBitmapImageRep* sBitmapImageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
		pixelsWide:size.width
		pixelsHigh:size.height
		bitsPerSample:8
		samplesPerPixel:3
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSDeviceRGBColorSpace
		bytesPerRow:(size.width * 4)
		bitsPerPixel:32] autorelease];
	
	NSImage* image = [[[NSImage alloc] initWithSize:NSMakeSize(size.width, size.height)] autorelease];
	[image addRepresentation:sBitmapImageRep];
		
	[image lockFocusOnRepresentation:sBitmapImageRep];

	// setup CG
	CGContextRef viewContextRef = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetInterpolationQuality (viewContextRef, kCGInterpolationLow);
	CGContextSetShouldAntialias (viewContextRef, YES);

	// draw screen bitmap directly to Core Graphics context
	CGDataProviderRef dataProviderRef;
	dataProviderRef = CGDataProviderCreateWithData(NULL, screenBuffer, screenProperties.width * 4 * screenProperties.height, NULL);
	if (dataProviderRef) {
		CGImageRef imageRef = CGImageCreate(
			screenProperties.width, //width
			screenProperties.height, //height
			8, //bitsPerComponent
			32, //bitsPerPixel
			(screenProperties.width * 4), //bytesPerRow
#if __LITTLE_ENDIAN__
			CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), //colorspace for OX S >= 10.4
			kCGImageAlphaNoneSkipLast,
#else
			CGColorSpaceCreateDeviceRGB(), //colorspace for OS X < 10.4 (actually ppc)
			kCGImageAlphaNoneSkipFirst, //bitmapInfo
#endif
			dataProviderRef, //provider
			NULL, //decode
			0, //interpolate
			kCGRenderingIntentDefault //intent
		);
		CGContextDrawImage (viewContextRef, CGRectMake(0, 0, size.width, size.height), imageRef);
		CGImageRelease (imageRef);
	}
	CGDataProviderRelease(dataProviderRef);
	
	[image unlockFocus];

	return image;
}



#pragma mark QEMU
- (void) grabMouse
{
	Q_DEBUG(@"grabMouse");

    if (isFullscreen) {
        if(fullscreenController && [fullscreenController showsToolbar]) {
           [fullscreenController toggleToolbar];
           return; // else we have a doublegrab (Mouse will remain hidden)
       }
    } else {
        [normalWindow setTitle: [NSString stringWithFormat:NSLocalizedStringFromTable(@"grabMouse:title", @"Localizable", @"cocoaQemu"), [document displayName]]];
    }
    [NSCursor hide];
    CGAssociateMouseAndMouseCursorPosition(FALSE);
    mouseGrabed = TRUE; // while mouseGrabed = TRUE, Q App sends all events to [QQartzView handleEvent:]
}

- (void) ungrabMouse
{
	Q_DEBUG(@"ungrabMouse");

	[normalWindow setTitle:[document displayName]];
    [NSCursor unhide];
    CGAssociateMouseAndMouseCursorPosition(TRUE);
    mouseGrabed = FALSE;
}



#pragma mark fullscreen
- (void) setContentDimensionsForFrame:(NSRect)rect
{
    Q_DEBUG(@"setContentDimensionsForFrame: NSRect(%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	if (isFullscreen) {
		if (([[NSScreen mainScreen] frame].size.width / screenProperties.width) > ([[NSScreen mainScreen] frame].size.height / screenProperties.height)) {
			displayProperties.dx = [[NSScreen mainScreen] frame].size.height / (float)screenProperties.height;
		} else {
			displayProperties.dx = [[NSScreen mainScreen] frame].size.width / (float)screenProperties.width;
		}
        if (displayProperties.dx < 2.0) {
            displayProperties.dx = (float)((int)(displayProperties.dx * 4)) / 4.0; //only allow factors of .25/.5/.75/1.0/1.25/1.5/1.75
        } else {
            displayProperties.dx = (float)(int)displayProperties.dx; //only allow full factors
        }
        displayProperties.dy = displayProperties.dx;
        displayProperties.width = screenProperties.width * displayProperties.dx;
        displayProperties.height = screenProperties.height * displayProperties.dy;
        displayProperties.x = ([[NSScreen mainScreen] frame].size.width - displayProperties.width) / 2.0;
        displayProperties.y = ([[NSScreen mainScreen] frame].size.height - displayProperties.height) / 2.0;
		[self setFrame:NSMakeRect(displayProperties.x, displayProperties.y, displayProperties.width, displayProperties.height)];
	} else {
		displayProperties.dx = rect.size.width / (float)screenProperties.width;
		displayProperties.dy = rect.size.height / (float)screenProperties.height;
		displayProperties.width = rect.size.width;
		displayProperties.height = rect.size.height;
		displayProperties.x = 0.0;
		displayProperties.y = ICON_BAR_HEIGHT;
	}

//	[self setFrame:NSMakeRect(displayProperties.x, displayProperties.y, displayProperties.width, displayProperties.height)];
	[self display]; // apply the new rect
    [self update];
}

- (void) setFullScreen
{
	Q_DEBUG(@"setFullScreen");

    fullScreenWindow = [[NSWindow alloc] initWithContentRect:[[NSScreen mainScreen] frame]
        styleMask:NSBorderlessWindowMask
        backing:NSBackingStoreBuffered
        defer:NO];

    if(fullScreenWindow != nil) {
	
        // initialize FSController
        fullscreenController = [[FSController alloc] initWithSender:document];
		
		isFullscreen = TRUE;
        [self grabMouse];
		
        [fullScreenWindow setTitle: @"Q fullScreenWindow"];
        [fullScreenWindow setBackgroundColor: [NSColor clearColor]]; // we want to have a transparent background
        [fullScreenWindow setOpaque:NO]; // we want to see thru unrendered parts of the window
        [fullScreenWindow setReleasedWhenClosed:YES];
        [fullScreenWindow setHasShadow:NO];
        [fullScreenWindow setContentView:[[[BlackView alloc] initWithFrame:[[NSScreen mainScreen] frame]] autorelease]];
        [[fullScreenWindow contentView] setOpacity:0.75];
        [NSMenu setMenuBarVisible:NO];

        // grow transition
		[fullScreenWindow setFrame:[normalWindow frame] display:NO animate:NO];		
        [fullScreenWindow makeKeyAndOrderFront:self];
        [fullScreenWindow setFrame:[[NSScreen mainScreen] frame] display:YES animate:YES];
		
		// add view
        [[fullScreenWindow contentView] addSubview:self];
        [self setContentDimensionsForFrame:NSMakeRect(0.0, 0.0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height)];
        [fullScreenWindow display];

    }
}

- (void)showFullscreenAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	Q_DEBUG(@"showFullscreenAlertSheetDidEnd");
    
    // show alert in the Future?
    if (returnCode == NSAlertOtherReturn) {
        [[[document qApplication] userDefaults] setBool:FALSE forKey:@"showFullscreenWarning"];
    }

    [sheet orderOut:self];
    [self setFullScreen];
}

- (void) toggleFullScreen
{
	Q_DEBUG(@"toggleFullScreen");

    if (isFullscreen) {
        // switch from fullscreen to desktop
        
        // remove fullscreenController
        [fullscreenController release];
		
        isFullscreen = FALSE;
        [self ungrabMouse];

        // shrink transition
        [fullScreenWindow setFrame:[normalWindow frame] display:NO animate:YES];

        // set view
        [fullScreenWindow close];
        [[normalWindow contentView] addSubview:self];
        [self setContentDimensionsForFrame:NSMakeRect(0.0, 0.0, screenProperties.width * displayProperties.zoom, screenProperties.height * displayProperties.zoom)];
		[self setFrame:NSMakeRect(displayProperties.x, displayProperties.y, displayProperties.width, displayProperties.height)];
        [normalWindow makeKeyAndOrderFront: self];
        [NSMenu setMenuBarVisible:YES];

    } else {
     
        // switch from desktop to fullscreen
        if ([[[document qApplication] userDefaults] boolForKey:@"showFullscreenWarning"]) {
            NSBeginAlertSheet(
                NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:standardAlert", @"Localizable", @"cocoaQemu"),
                NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:defaultButton", @"Localizable", @"cocoaQemu"),
                nil,
                NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:otherButton", @"Localizable", @"cocoaQemu"),
                normalWindow,
                self,
                @selector(showFullscreenAlertSheetDidEnd:returnCode:contextInfo:),
                nil,
                nil,
                NSLocalizedStringFromTable(@"cocoa_refresh:showFullscreen:informativeText", @"Localizable", @"cocoaQemu"));
        } else {
            [self setFullScreen];
        }
        
    }
}

- (void) resizeContentToWidth:(int)w height:(int)h
{
	Q_DEBUG(@"resizeContent width:%d height:%d", w, h);

    // screenbuffer with mmap
    int fd;
    if (screenProperties.screenBufferSize > 0) {
        if (munmap(screenBuffer, screenProperties.screenBufferSize) == -1) {
			int errsv = errno;
			NSLog(@"QDocumentOpenGLView: resizeContent: could not munmap:  errno(%D) - %s", errsv, strerror(errsv));
			screenProperties.screenBufferSize;
			return;
		}
	}
    fd = open([[NSString stringWithFormat:@"/private/tmp/qDocument_%D.vga", [document uniqueDocumentID]] cString], O_RDONLY); // open file
    if(fd == -1) {
		int errsv = errno;
        NSLog(@"QDocumentOpenGLView: resizeContent: could not open '/private/tmp/qDocument_%D.vga': errno(%D) - %s", [document uniqueDocumentID], errsv, strerror(errsv));
		screenProperties.screenBufferSize = 0;
		return;
    }
	screenProperties.screenBufferSize = w * 4 * h;
	screenBuffer = mmap(0, screenProperties.screenBufferSize, PROT_READ, MAP_FILE|MAP_SHARED, fd, 0);
    if(screenBuffer == MAP_FAILED) {
		int errsv = errno;
        NSLog(@"QDocumentOpenGLView: resizeContent: could not mmap '/private/tmp/qDocument_%D.vga': errno(%D) - %s", [document uniqueDocumentID], errsv, strerror(errsv));
		screenProperties.screenBufferSize = 0;
		close(fd);
		return;
    }
	close(fd);

    // update screen state
    screenProperties.width = w;
    screenProperties.height = h;

    NSSize normalWindowSize;
    normalWindowSize = NSMakeSize(
        (float)w * displayProperties.zoom,
        (float)h * displayProperties.zoom + TITLE_BAR_HEIGHT + ICON_BAR_HEIGHT
    );

    // keep Window in correct aspect ratio
    [normalWindow setMaxSize:NSMakeSize(screenProperties.width, screenProperties.height + TITLE_BAR_HEIGHT + ICON_BAR_HEIGHT)];
//	[normalWindow setAspectRatio:NSMakeSize(screenProperties.width, screenProperties.height + TITLE_BAR_HEIGHT + ICON_BAR_HEIGHT)];
//	[normalWindow setResizeIncrements:NSMakeSize(10,10)];
    // update windows
    if (isFullscreen) {
        [self setContentDimensionsForFrame:[[NSScreen mainScreen] frame]];
        [normalWindow setFrame:NSMakeRect([normalWindow frame].origin.x, [normalWindow frame].origin.y + [normalWindow frame].size.height - normalWindowSize.height, normalWindowSize.width, normalWindowSize.height) display:NO animate:NO];
    } else {
		[self setContentDimensionsForFrame:NSMakeRect(0, 0, w * displayProperties.zoom, h * displayProperties.zoom)];
        [normalWindow setFrame:NSMakeRect([normalWindow frame].origin.x, [normalWindow frame].origin.y + [normalWindow frame].size.height - normalWindowSize.height, normalWindowSize.width, normalWindowSize.height) display:YES animate:YES];
	}
}



#pragma mark dragging delegates
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
	Q_DEBUG(@"draggingEntered");

    if ((NSDragOperationCopy & [sender draggingSourceOperationMask]) == NSDragOperationCopy) {
        // show a border, so the user knows he's droppin into this view
        drag = true;
        [self display];
        
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
	Q_DEBUG(@"draggingExited");

    // hide border
    drag = false;
    [self display];
}

- (void) draggingEnded:(id <NSDraggingInfo>)sender
{
	Q_DEBUG(@"draggingEnded");

    // hide border
    drag = false;
    [self display];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	Q_DEBUG(@"prepareForDragOperation");

    return true;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	Q_DEBUG(@"performDragOperation");
    
    NSPasteboard *paste = [sender draggingPasteboard];
    NSArray *types = [NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil];
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];

    if (nil == carriedData) {
        NSRunAlertPanel(@"Paste Error", @"Sorry, but the past operation failed", nil, nil, nil);
        return NO;
    } else {
        if ([desiredType isEqualToString:NSFilenamesPboardType]) {
            NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
            // copy all dragged Files into smb folder
            if ([document smbPath]) {
                int i;
                NSFileManager *fileManager = [NSFileManager defaultManager];
                for (i=0; i<[fileArray count]; i++) {
                    [fileManager copyPath:[fileArray objectAtIndex:i] toPath:[NSString stringWithFormat:@"%@/%@", [document smbPath], [[fileArray objectAtIndex:i] lastPathComponent]] handler:nil]; 
                }
            }
        } else {
            NSAssert(NO, @"This can't happen");
            return NO;
        }
    }
    return YES;
}

- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
	Q_DEBUG(@"concludeDragOperation");

    // hide border
    drag = false;
    [self display];
}



#pragma mark firstresponder
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder { return YES; }



#pragma mark event handling
- (void) handleEvent:(NSEvent *)event
{
	Q_DEBUG(@"handleEvent");

    int buttons;
    int keycode;
    switch ([event type]) {
        case NSFlagsChanged:
            keycode = cocoa_keycode_to_qemu([event keyCode]);
            if (keycode) {
                // emulate caps lock and num lock keydown and keyup
                if (keycode == 58 || keycode == 69) {
                    [[document distributedObject]setCommand:'K' arg1:keycode arg2:0 arg3:0 arg4:0];
                    [[document distributedObject]setCommand:'K' arg1:keycode | 0x80 arg2:0 arg3:0 arg4:0];
                    
                } else if (is_graphic_console) {
                    if (keycode & 0x80)
                        [[document distributedObject]setCommand:'K' arg1:0xe0 arg2:0 arg3:0 arg4:0];

                    // keydown
                    if (modifiers_state[keycode] == 0) {
                        [[document distributedObject]setCommand:'K' arg1:keycode & 0x7f arg2:0 arg3:0 arg4:0];
                        modifiers_state[keycode] = 1;

                    // keyup
                    } else {
                        [[document distributedObject]setCommand:'K' arg1:keycode | 0x80 arg2:0 arg3:0 arg4:0];
                        modifiers_state[keycode] = 0;
                    }
                }
            }
                
            // release Mouse grab when pressing ctrl+alt
            if (!isFullscreen && ([event modifierFlags] & NSControlKeyMask) && ([event modifierFlags] & NSAlternateKeyMask)) {
                [self ungrabMouse];
            }
            break;
        case NSKeyDown:
            keycode = cocoa_keycode_to_qemu([event keyCode]);
                               
            // handle control + alt Key Combos (ctrl+alt is reserved for QEMU)
            if (([event modifierFlags] & NSControlKeyMask) && ([event modifierFlags] & NSAlternateKeyMask)) {
                switch (keycode) {

                    // enable graphic console
                    case 0x02: // '1' to '9' keys
                        is_graphic_console = TRUE;
                        [[document distributedObject]setCommand:'S' arg1:keycode - 0x02 arg2:0 arg3:0 arg4:0];
                        break;

                    // enable monitor
                    case 0x03 ... 0x0a: // '1' to '9' keys
                        is_graphic_console = FALSE;
                        [[document distributedObject]setCommand:'S' arg1:keycode - 0x02 arg2:0 arg3:0 arg4:0];
                        break;
                }

            // handle keys for graphic console
            } else if (is_graphic_console) {
                if (keycode & 0x80) //check bit for e0 in front
                    [[document distributedObject]setCommand:'K' arg1:0xe0 arg2:0 arg3:0 arg4:0];
                [[document distributedObject]setCommand:'K' arg1:keycode & 0x7f arg2:0 arg3:0 arg4:0];

            // handlekeys for Monitor
            } else {
                int keysym = 0;
                switch([event keyCode]) {
                case 115:
                    keysym = 1 | 0xe100; // QEMU_KEY_HOME;
                    break;
                case 117:
                    keysym = 3 | 0xe100; // QEMU_KEY_DELETE;
                    break;
                case 119:
                    keysym = 4 | 0xe100; // QEMU_KEY_END;
                    break;
                case 123:
                    keysym = 'D' | 0xe100; // QEMU_KEY_LEFT;
                    break;
                case 124:
                    keysym = 'C' | 0xe100; // QEMU_KEY_RIGHT;
                    break;
                case 125:
                    keysym = 'B' | 0xe100; // QEMU_KEY_DOWN;
                    break;
                case 126:
                    keysym = 'A' | 0xe100; // QEMU_KEY_UP;
                    break;
                default:
                    {
                        NSString *ks = [event characters];
                        if ([ks length] > 0)
                            keysym = [ks characterAtIndex:0];
                    }
                }
                if (keysym)
                    [[document distributedObject]setCommand:'C' arg1:keysym arg2:0 arg3:0 arg4:0];
            }
            break;
        case NSKeyUp:
            keycode = cocoa_keycode_to_qemu([event keyCode]);   
            if (is_graphic_console) {
                if (keycode & 0x80)
                    [[document distributedObject]setCommand:'K' arg1:0xe0 arg2:0 arg3:0 arg4:0];
                [[document distributedObject]setCommand:'K' arg1:keycode | 0x80 arg2:0 arg3:0 arg4:0];
            }
            break;
        case NSMouseMoved:
            if ([document absolute_enabled]) {
                NSPoint p = [event locationInWindow];
                if (p.x < 0 || p.x > screenProperties.width || p.y < 0 || p.y > screenProperties.height || ![[self window] isKeyWindow]) {
                    if (tablet_enabled) {// if we leave the window, deactivate the tablet
                        [NSCursor unhide];
                        tablet_enabled = FALSE;
                    }
                } else {
                    if (!tablet_enabled) {// if we enter the window, activate the tablet
                        [NSCursor hide];
                        tablet_enabled = TRUE;
                    }
                    [[document distributedObject]setCommand:'M' arg1:(int)(p.x * 0x7FFF / screenProperties.width) arg2:(int)((screenProperties.height - p.y) * 0x7FFF / screenProperties.height) arg3:(int)[event deltaZ] arg4:0];
                    }
                } else {
                    [[document distributedObject]setCommand:'M' arg1:(int)[event deltaX] arg2:(int)[event deltaY] arg3:(int)[event deltaZ] arg4:0];
            }
            break;
        case NSLeftMouseDown:
        case NSLeftMouseDragged:
            if ([event modifierFlags] & NSCommandKeyMask) {
                buttons |= MOUSE_EVENT_RBUTTON;
            } else {
                buttons |= MOUSE_EVENT_LBUTTON;
            }
            if (tablet_enabled) {
                NSPoint p = [event locationInWindow];
                [[document distributedObject]setCommand:'M' arg1:(int)(p.x * 0x7FFF / screenProperties.width) arg2:(int)((screenProperties.height - p.y) * 0x7FFF / screenProperties.height) arg3:(int)[event deltaZ] arg4:buttons];
            } else {
                [[document distributedObject]setCommand:'M' arg1:(int)[event deltaX] arg2:(int)[event deltaY] arg3:(int)[event deltaZ] arg4:buttons];
            }
            break;
        case NSRightMouseDown:
        case NSRightMouseDragged:
            if (tablet_enabled) {
                NSPoint p = [event locationInWindow];
                [[document distributedObject]setCommand:'M' arg1:(int)(p.x * 0x7FFF / screenProperties.width) arg2:(int)((screenProperties.height - p.y) * 0x7FFF / screenProperties.height) arg3:(int)[event deltaZ] arg4:buttons |= MOUSE_EVENT_RBUTTON];
            } else {
                [[document distributedObject]setCommand:'M' arg1:(int)[event deltaX] arg2:(int)[event deltaY] arg3:(int)[event deltaZ] arg4:buttons |= MOUSE_EVENT_RBUTTON];
            }
            break;
        case NSOtherMouseDown:
        case NSOtherMouseDragged:
            if (tablet_enabled) {
                NSPoint p = [event locationInWindow];
                [[document distributedObject]setCommand:'M' arg1:(int)(p.x * 0x7FFF / screenProperties.width) arg2:(int)((screenProperties.height - p.y) * 0x7FFF / screenProperties.height) arg3:(int)[event deltaZ] arg4:buttons |= MOUSE_EVENT_MBUTTON];
            } else {
                [[document distributedObject]setCommand:'M' arg1:(int)[event deltaX] arg2:(int)[event deltaY] arg3:(int)[event deltaZ] arg4:buttons |= MOUSE_EVENT_MBUTTON];
            }
            break;
        case NSLeftMouseUp:
        case NSRightMouseUp:
        case NSOtherMouseUp:
            [[document distributedObject]setCommand:'M' arg1:0 arg2:0 arg3:0 arg4:0];
            break;
        case NSScrollWheel:
            [[document distributedObject]setCommand:'M' arg1:0 arg2:0 arg3:[event deltaY] arg4:0];
            break;
    }
}
- (void) flagsChanged:(NSEvent *)event { [self handleEvent:event];}
- (void) keyDown:(NSEvent *)event { [self handleEvent:event];}
- (void) keyUp:(NSEvent *)event { [self handleEvent:event];}
- (void) mouseMoved:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}
- (void) mouseDown:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}
- (void) rightMouseDown:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}
- (void) otherMouseDown:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}
- (void) mouseDraged:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}
- (void) rightMouseDraged:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}
- (void) otherMouseDraged:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}
- (void) mouseUp:(NSEvent *)event
{
    if ([document VMState]==QDocumentShutdown||[document VMState]==QDocumentSaved) {
		[document VMStart:self];
    } else if (tablet_enabled) {
        [self handleEvent:event];
    } else {
        [self grabMouse];
    }
}   
- (void) scrollWheel:(NSEvent *)event { if(tablet_enabled) {[self handleEvent:event];}}



#pragma mark getters
- (BOOL) mouseGrabed { return mouseGrabed;}
- (BOOL) isFullscreen { return isFullscreen;}
- (QScreen) screenProperties { return screenProperties;}
- (QDisplayProperties) displayProperties { return displayProperties;}
- (void) displayPropertiesSetZoom:(float)tZoom {displayProperties.zoom = tZoom;}
- (void *) screenBuffer { return screenBuffer;}
- (NSWindow *) normalWindow { return normalWindow;}
- (id) fullscreenController { return fullscreenController;}
@end