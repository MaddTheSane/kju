/*
 * Q Document Edit VM Controller
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

NS_ASSUME_NONNULL_BEGIN

@class QDocument;

typedef NS_ENUM(NSInteger, QDocumentEditVMMachine) {
   QDocumentEditVMMachinePc = 0,
   QDocumentEditVMMachineIsapc = 1,
   QDocumentEditVMMachineG3bw = 2,
   QDocumentEditVMMachineMac99 = 3,
   QDocumentEditVMMachinePrep = 4,
   QDocumentEditVMMachineRef405ep = 5,
   QDocumentEditVMMachineTaihu = 6,
   QDocumentEditVMMachineSS2 = 7,
   QDocumentEditVMMachineSS5 = 8,
   QDocumentEditVMMachineSS10 = 9,
   QDocumentEditVMMachineSS20 = 10,
   QDocumentEditVMMachineSS600MP = 11,
   QDocumentEditVMMachineSS1000 = 12,
   QDocumentEditVMMachineSS2000 = 13,
   QDocumentEditVMMachineMips = 14,
   QDocumentEditVMMachineMalta = 15,
   QDocumentEditVMMachinePica61 = 16,
   QDocumentEditVMMachineMipssim = 17,
   QDocumentEditVMMachineArm1 = 18,
   QDocumentEditVMMachineArm2 = 19,
   QDocumentEditVMMachineArm3 = 20,
   QDocumentEditVMMachineArm4 = 21,
   QDocumentEditVMMachineArm5 = 22,
   QDocumentEditVMMachineArm6 = 23,
   QDocumentEditVMMachineArm7 = 24,
   QDocumentEditVMMachineM68k1 = 25,
   QDocumentEditVMMachineM68k2 = 26,
   QDocumentEditVMMachineCris = 27
};

@interface QDocumentEditVMController : NSObject

// Panel
@property (weak) IBOutlet NSPanel *editVMPanel;
@property (weak) IBOutlet NSButton *editVMPanelButtonOK;
@property (weak) IBOutlet NSButton *editVMPanelButtonCancel;

// Tab 1
@property (weak) IBOutlet NSButton *grabless;
@property (weak) IBOutlet NSButton *qDrivers;
@property (weak) IBOutlet NSButton *pauseWhileInactive;
@property (weak) IBOutlet NSPopUpButton *smb;

// Tab 2
@property (weak) IBOutlet NSPopUpButton *M;
@property (weak) IBOutlet NSPopUpButton *cpu;
@property (weak) IBOutlet NSTextField *smp;
@property (weak, setter=setm:) IBOutlet NSTextField *m;
@property (weak) IBOutlet NSPopUpButton *vga;
@property (weak) IBOutlet NSButton *pcspk;
@property (weak) IBOutlet NSButton *adlib;
@property (weak) IBOutlet NSButton *sb16;
@property (weak) IBOutlet NSButton *es1370;
@property (weak) IBOutlet NSPopUpButton *nicModel1;
@property (weak) IBOutlet NSPopUpButton *nicModel2;
@property (weak) IBOutlet NSPopUpButton *fda;
@property (weak) IBOutlet NSPopUpButton *cdrom;
@property (weak) IBOutlet NSPopUpButton *hda;
@property (weak) IBOutlet NSPopUpButton *boot;

// Tab 3

// Tab 4
@property (weak) IBOutlet NSPopUpButton *hdb;
@property (weak) IBOutlet NSPopUpButton *hdc;
@property (weak) IBOutlet NSPopUpButton *hdd;
@property (weak) IBOutlet NSButton *localtime;
@property (weak) IBOutlet NSButton *win2kHack;
@property (weak) IBOutlet NSPopUpButton *kernel;
@property (weak) IBOutlet NSTextField *append;
@property (weak) IBOutlet NSPopUpButton *initrd;
@property (weak) IBOutlet NSButton *onlyOptional;
@property (weak) IBOutlet NSTextField *optional;

- (void)showEditVMPanel:(QDocument*)sender;

- (IBAction)OK:(nullable id)sender;
- (IBAction)cancel:(nullable id)sender;

- (IBAction) resetPanel:(nullable id)sender;
- (void) setMachine:(QDocumentEditVMMachine)machine;
- (BOOL) setOption:(NSString *)key withArgument:(NSString *)argument;
- (IBAction) populatePanel:(nullable id)sender;
@end

NS_ASSUME_NONNULL_END