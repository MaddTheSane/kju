/*
 * QEMU Cocoa Control PC Editor Window
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

#import <Cocoa/Cocoa.h>

@interface cocoaControlEditPC : NSObject
{
	NSArray *fileTypes;
	IBOutlet id editPCPanel;
	IBOutlet id viewGeneral;
	IBOutlet id viewHardware;
	IBOutlet id viewAdvanced;
	IBOutlet id viewNetwork;
	IBOutlet id firewallPortTable;
	IBOutlet id firewallPortEditPanel;
	IBOutlet NSTextField *textFieldName;
	IBOutlet NSTextField *textFieldRAM;
	IBOutlet NSTextField *textFieldAppend;
	IBOutlet NSTextField *textFieldArguments;
	IBOutlet NSTextField *textFieldFirewallPortName;
	IBOutlet NSTextField *textFieldFirewallPortHostPorts;
	IBOutlet NSTextField *textFieldFirewallPortGuestPorts;
	IBOutlet NSTextField *textFieldFirewallPortError;
	IBOutlet NSPopUpButton *popUpButtonSmbFilesharing;
	IBOutlet NSPopUpButton *popUpButtonVGA;
	IBOutlet NSPopUpButton *popUpButtonCPU;
	IBOutlet NSPopUpButton *popUpButtonFda;
	IBOutlet NSPopUpButton *popUpButtonHda;
	IBOutlet NSPopUpButton *popUpButtonHdb;
	IBOutlet NSPopUpButton *popUpButtonHdc;
	IBOutlet NSPopUpButton *popUpButtonHdd;
	IBOutlet NSPopUpButton *popUpButtonCdrom;
	IBOutlet NSPopUpButton *popUpButtonBoot;
	IBOutlet NSPopUpButton *popUpButtonKernel;
	IBOutlet NSPopUpButton *popUpButtonInitrd;
	IBOutlet NSPopUpButton *popUpButtonFirewallAdditionalPorts;
	IBOutlet NSPopUpButton *popUpButtonFirewallServiceType;
	IBOutlet NSButton *buttonEnableAdlib;
	IBOutlet NSButton *buttonEnableSB16;
	IBOutlet NSButton *buttonEnableES1370;
	IBOutlet NSButton *buttonEnableUSBTablet;
	IBOutlet NSButton *buttonNetNicNe2000;
	IBOutlet NSButton *buttonNetNicRtl8139;
	IBOutlet NSButton *buttonNetNicPcnet;
	IBOutlet NSButton *buttonNetUser;
	IBOutlet NSButton *buttonLocaltime;
	IBOutlet NSButton *buttonWMStopWhenInactive;
	IBOutlet NSButton *buttonQWinDrivers;
	IBOutlet NSButton *buttonWin2kHack;
	IBOutlet NSButton *buttonOk;
	IBOutlet NSButton *buttonFirewallSavePort;
	id customImagePopUpButtonTemp;
	int customImageSizeHda;
	int customImageSizeHdb;
	int customImageSizeHdc;
	int customImageSizeHdd;
	NSString *customImageTypeHda;
	NSString *customImageTypeHdb;
	NSString *customImageTypeHdc;
	NSString *customImageTypeHdd;
	NSUserDefaults *userDefaults;
	id qSender;
	NSMutableDictionary *thisPC;
}
NSMutableArray *firewallPortList;
BOOL firewallPortTableEnabled;
- (NSPanel *) editPCPanel;
- (void) prepareEditPCPanel:(NSMutableDictionary *)aPC newPC:(BOOL)newPC sender:(id)sender;
- (IBAction) genericFolderSelectPanel:(id)sender;
- (IBAction) genericImageSelectPanel:(id)sender;
- (IBAction) menuItemNewImage:(id)sender;
- (IBAction) closeEditPCPanel:(id)sender;
- (IBAction) editPCEditPCPanel:(id)sender;
- (void) setCustomDIType:(NSString *)string size:(int)size;
- (IBAction) showHelp:(id)sender;
- (NSString *) createDI:(NSString *)type withSize:(int)size;
- (void)initFirewallSettings;
- (IBAction) startShowNewPort:(id)sender;
- (IBAction) startShowEditPort:(id)sender;
- (void) startEditPort:(BOOL)newPort;
- (IBAction) deletePort:(id)sender;
- (IBAction) setAdditionalPort:(id)sender;
- (IBAction) saveNewPort:(id)sender;
- (IBAction) saveEditPort:(id)sender;
- (BOOL) checkPort:(BOOL)newPort;
- (IBAction) endEditPort:(id)sender;
- (void) saveFirewallPortList;
- (NSString *) constructFirewallArguments;
@end