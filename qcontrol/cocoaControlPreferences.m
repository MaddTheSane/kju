/*
 * QEMU Cocoa Control Preferences
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

#import "cocoaControlPreferences.h"

//#import "AppleHelp.h"
#import "Carbon/Carbon.h"

#import "cocoaControlController.h"

@implementation cocoaControlPreferences
- (id) init
{
//	NSLog(@"cocoaControlPreferences: init");

	if ((self = [super init])) {
		userDefaults = [NSUserDefaults standardUserDefaults];
		
		return self;
	}

	return nil;
}

- (void) dealloc
{
//	NSLog(@"cocoaControlPreferences: dealloc");

	[userDefaults release];
	[super dealloc];
}

- (void)awakeFromNib
{
//	NSLog(@"cocoaControlPreferences: awakeFromNib");

	NSToolbar *preferencesPanelToolbar = [[[NSToolbar alloc] initWithIdentifier: @"preferencesPanelToolbarIdentifier"] autorelease];
	[preferencesPanelToolbar setAllowsUserCustomization: NO]; //allow customisation
	[preferencesPanelToolbar setAutosavesConfiguration: NO]; //autosave changes
	[preferencesPanelToolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel]; //what is shown
	[preferencesPanelToolbar setSizeMode:NSToolbarSizeModeRegular]; //default Toolbar Size
	[preferencesPanelToolbar setDelegate: self]; // We are the delegate
	[preferencesPanel setToolbar: preferencesPanelToolbar]; // Attach the toolbar to the document window

	[preferencesPanelToolbar setSelectedItemIdentifier:@"general"];
}

/* Toolbar Delegates*/
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
	if ([itemIdent isEqual: @"general"]) {
		[toolbarItem setLabel: NSLocalizedStringFromTable(@"toolbar:label:general", @"Localizable", @"cocoaControlPreferences")];
		[toolbarItem setPaletteLabel: NSLocalizedStringFromTable(@"toolbar:paletteLabel:general", @"Localizable", @"cocoaControlPreferences")];
		[toolbarItem setToolTip: NSLocalizedStringFromTable(@"toolbar:toolTip:general", @"Localizable", @"cocoaControlPreferences")];
		[toolbarItem setImage: [NSImage imageNamed: @"cocoa_tb_general.png"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( viewGeneral: )];
	} else {
		toolbarItem = nil;
	}
	
	return toolbarItem;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:
		@"general",
		nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		@"general",
		nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
		@"general",
		nil];	
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	return YES;
}

- (void)viewGeneral:(id)sender
{
//	NSLog(@"awakeFromNib: viewGeneral");

	[preferencesPanel setTitle: NSLocalizedStringFromTable(@"viewGeneral:title", @"Localizable", @"cocoaControlPreferences")];
}

- (IBAction)ok:(id)sender;
{
//	NSLog(@"awakeFromNib: ok");

	if ([popUpButtonDisplay indexOfSelectedItem] == 0) {
		[userDefaults setObject:@"OpenGL" forKey:@"display"];
	} else if ([popUpButtonDisplay indexOfSelectedItem] == 1) {
		[userDefaults setObject:@"Quartz" forKey:@"display"];
	} else {
		[userDefaults setObject:@"QuickDraw" forKey:@"display"];
	}
	
	if ([buttonEnableCheckForUpdates state] == NSOnState) {
		[userDefaults setBool:TRUE forKey:@"enableCheckForUpdates"];
	} else {
		[userDefaults setBool:FALSE forKey:@"enableCheckForUpdates"];
	}
	
	[userDefaults setObject:[textFieldDataPath stringValue] forKey:@"dataPath"];
	
	/* Update qControl to new datapath */
	[qControl loadConfigurations];
	
	[preferencesPanel close];
}

- (IBAction)cancel:(id)sender
{
//	NSLog(@"awakeFromNib: cancel");

	[preferencesPanel close];
}

- (id)preferencesPanel
{
//	NSLog(@"awakeFromNib: preferencesPanel");

	return preferencesPanel;
}

- (void)preparePreferences:(id)sender
{
//	NSLog(@"awakeFromNib: preparePreferences");

    qControl = sender;

	if ([[userDefaults objectForKey:@"display"] isEqual:@"OpenGL"]) {
		[popUpButtonDisplay selectItemAtIndex:0];
	} else if ([[userDefaults objectForKey:@"display"] isEqual:@"Quartz"]) {
		[popUpButtonDisplay selectItemAtIndex:1];
	} else {
		[popUpButtonDisplay selectItemAtIndex:2];
	}
	
	if ([userDefaults boolForKey:@"enableCheckForUpdates"]) {
		[buttonEnableCheckForUpdates setState:NSOnState];
	} else {
		[buttonEnableCheckForUpdates setState:NSOffState];
	}
	
	if ([userDefaults objectForKey:@"dataPath"]) {
		[textFieldDataPath setStringValue:[userDefaults objectForKey:@"dataPath"]];
	} else {
		[textFieldDataPath setStringValue:[NSString stringWithFormat:@"%@/Documents/QEMU", NSHomeDirectory()]];
	}
}

- (void) genericFolderSelectPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
//	NSLog(@"cocoaControlPreferences: genericFolderSelectPanelDidEnd");

	/* hide Sheet */
	[ sheet orderOut:self ];
		
	/* dataPath */
	if ([contextInfo isEqual:buttonDataPathChoose]) {
		if ( returnCode == NSOKButton ) {
			[textFieldDataPath setStringValue:[sheet filename]];
		}
	}
}

- (IBAction) genericFolderSelectPanel:(id)sender
{
//	NSLog(@"cocoaControlPreferences: genericFolderSelectPanel");

	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel beginSheetForDirectory:[@"~/Documents" stringByExpandingTildeInPath]
		file:nil
		types:nil
		modalForWindow:preferencesPanel
		modalDelegate:self
		didEndSelector:@selector(genericFolderSelectPanelDidEnd:returnCode:contextInfo:)
		contextInfo:sender];
}

- (IBAction) resetDataPath: (id)sender
{
	[textFieldDataPath setStringValue:[NSString stringWithFormat:@"%@/Documents/QEMU", NSHomeDirectory()]];
}
@end
