/*
 * Q .qvm Manager
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

#import "QQvmManager.h"

// #define QQVMMANAGER_DEBUG 1

static QQvmManager *sharedQvmManager = nil;

@implementation QQvmManager
+ (QQvmManager *)sharedQvmManager
{
	Q_DEBUG(@"sharedQvmManager");

    @synchronized(self) {
        if (sharedQvmManager == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedQvmManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedQvmManager == nil) {
            sharedQvmManager = [super allocWithZone:zone];
            return sharedQvmManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {return self; }
- (id)retain { return self;}
- (unsigned)retainCount {return UINT_MAX;}  //denotes an object that cannot be released
- (void)release {} //do nothing
- (id)autorelease { return self; }



#pragma mark methods
- (BOOL) saveVMConfiguration:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"saveVMConfiguration %@", VM);

	//NSURL *URL;
	//URL = [[[VM objectForKey:@"Temporary"] objectForKey:@"URL"] copy];
	//[[VM objectForKey:@"Temporary"] removeObjectForKey:@"URL"]; // can't be stored in Propertylist

	NSMutableDictionary *temporary;

	temporary = [[VM objectForKey:@"Temporary"] copy];
	[VM removeObjectForKey:@"Temporary"]; // don't store temporary items (URL can't be stored in Propertylist anyways)
	

    NSData *data = [NSPropertyListSerialization
        dataFromPropertyList:VM
        format: NSPropertyListXMLFormat_v1_0
        errorDescription: nil];
	if (data) {
//		[[VM objectForKey:@"Temporary"] setObject:URL forKey:@"URL"]; // reenter URL
		[VM setObject:temporary forKey:@"Temporary"]; // reenter Temporary
		if ([data writeToFile:[NSString stringWithFormat:@"%@/configuration.plist", [[[VM objectForKey:@"Temporary"] objectForKey:@"URL"] path]] atomically:YES]) {
			return TRUE;
		}
	}
	return FALSE;
}


- (NSMutableDictionary *) loadVMConfiguration:(NSString*)filename
{
	Q_DEBUG(@"loadQVM: %@", filename);

	int i;
	NSData *data;
	NSMutableDictionary *tempVM;
	id key;
	NSArray *lookForArguments;
	NSArray *singleArguments;
	NSEnumerator *enumerator;
	NSMutableString *arguments;
	NSMutableString *argument;
	NSString *option;
	NSString *name;
	int nameIndex;

	data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/configuration.plist", filename]];
	if (data) {
		tempVM = [NSPropertyListSerialization
			propertyListFromData: data
			mutabilityOption: NSPropertyListMutableContainersAndLeaves
			format: nil
			errorDescription: nil];

		// upgrade Version 0.1.0.Q to 0.2.0.Q
		if ([[tempVM objectForKey:@"Version"] isEqual:@"0.1.0.Q"]) {
			lookForArguments = [NSArray arrayWithObjects:@"-snapshot", @"-nographic", @"-audio-help", @"-localtime", @"-full-screen", @"-win2k-hack", @"-usb", @"-s", @"-S", @"-d", @"-std-vga", nil];
			enumerator = [[tempVM objectForKey:@"Arguments"] keyEnumerator];
			arguments = [[NSMutableString alloc] init];
			while ((key = [enumerator nextObject])) {
				if ([[tempVM objectForKey:@"Arguments"] objectForKey:key]) {
					if ([key isEqual:@"-net"] && [[[tempVM objectForKey:@"Arguments"] objectForKey:key] isEqual:@"user"]) {
						[arguments appendFormat:[NSString stringWithFormat:@" -net nic"]];
					}
					if ([lookForArguments containsObject:key]) {
						[arguments appendFormat:[NSString stringWithFormat:@" %@", key]];
					} else {
						[arguments appendFormat:[NSString stringWithFormat:@" %@ %@", key, [[tempVM objectForKey:@"Arguments"] objectForKey:key]]];
					}
				}
			}
			[tempVM setObject:arguments forKey:@"Arguments"];
			[tempVM setObject:@"0.2.0.Q" forKey:@"Version"];
		}

		// upgrade Version 0.2.0.Q to 0.2.1.Q (i.e. use doublequotes on all commands and paths)
		if ([[tempVM objectForKey:@"Version"] isEqual:@"0.2.0.Q"]) {
			lookForArguments = [NSArray arrayWithObjects:@"-hda", @"-hdb", @"-hdc", @"-hdd", @"-fda", @"-fdb", @"-cdrom", @"-append", @"-kernel", @"-initrd", @"-smb", nil];
			singleArguments = [[tempVM objectForKey:@"Arguments"] componentsSeparatedByString:@" "];
			arguments = [NSMutableString stringWithFormat:@"-name \"%@\" ", [[tempVM objectForKey:@"PC Data"] objectForKey:@"name"]]; // add name for VM
			option = nil;
			argument = nil;
			for (i = 0; i < [singleArguments count]; i++) {
				if ([[singleArguments objectAtIndex:i] cString][0] != '-') { // part of argument
					if (!argument) {
						argument = [NSMutableString stringWithString:[singleArguments objectAtIndex:i]];
					} else {
						[argument appendFormat:@" %@", [singleArguments objectAtIndex:i]];
					}
				} else { // key
					if (option) { // handle previous key
						[arguments appendString:[NSString stringWithFormat:@"%@ ", option]];
						if ([lookForArguments containsObject:option]) { // path or command
							[arguments appendFormat:[NSString stringWithFormat:@"\"%@\" ", argument]];
							argument = nil;
						} else if (argument) {
							[arguments appendFormat:[NSString stringWithFormat:@"%@ ", argument]];
							argument = nil;
						}
						option = nil;
					}
					option = [singleArguments objectAtIndex:i];
				}
			}
			if (option) { // handle last option, argument pair
				[arguments appendString:[NSString stringWithFormat:@"%@ ", option]];
				if ([lookForArguments containsObject:option]) { // path or command
					[arguments appendFormat:[NSString stringWithFormat:@"\"%@\"", argument]];
				} else if (argument) {
					[arguments appendFormat:[NSString stringWithFormat:@"%@", argument]];
				}
			}
			// remove obsolte keys
			[[tempVM objectForKey:@"PC Data"] removeObjectForKey:@"name"];
			
			[tempVM setObject:arguments forKey:@"Arguments"];
			[tempVM setObject:@"0.3.0.Q" forKey:@"Version"];
		}

		// get rid of old temporary items and add new
		if ([tempVM objectForKey:@"Temporary"])
			[tempVM removeObjectForKey:@"Temporary"];
		[tempVM setObject:[NSMutableDictionary dictionary] forKey:@"Temporary"];
		
		// exploded arguments
		[[tempVM objectForKey:@"Temporary"] setObject:[[QQvmManager sharedQvmManager] explodeVMArguments:[tempVM objectForKey:@"Arguments"]] forKey:@"explodedArguments"];
		
		// name
		nameIndex = [[[tempVM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] indexOfObject:@"-name"];
		if (nameIndex == NSNotFound) {
			name = @"Unknown";
			NSLog(@"name: %@", name);
		} else {
			name = [[[tempVM objectForKey:@"Temporary"] objectForKey:@"explodedArguments"] objectAtIndex:(nameIndex + 1)];
		}
		[[tempVM objectForKey:@"Temporary"] setObject:name forKey:@"name"];
		
		// url
		[[tempVM objectForKey:@"Temporary"] setObject:[NSURL fileURLWithPath:filename] forKey:@"URL"];

		return tempVM;
	}
	return nil;
}

- (NSMutableArray *) explodeVMArguments:(NSString *) argumentsString
{
	Q_DEBUG(@"explodeVMArguments: %@", argumentsString);
	
	//argumentsString = @"   -emptySwitchWithWhite  -emptySwitch -test1 escaped\\ -fakeSwitch\\ example -test2 \"doublequoted -fakeSwitch example\" -test3 'singlequoted -fakeSwitch example' nokey\\ escaped\\ 'singlequoted '\"doublequoted ' -fakeSwitch ' example\"";

	int i;
	BOOL inQuote;
	unichar quoteChar;
	BOOL isEscapedChar;
	BOOL inSwitch;
	BOOL inArgument;
	unichar argument[256];
	int argumentCharCount;
	NSString *key;
	NSMutableArray *argumentsArray;

	argumentsArray = [NSMutableArray array];
	key = nil;
	argumentCharCount = 0;
	isEscapedChar = NO;
	inQuote = NO;
	inSwitch = NO;
	inArgument = NO;

	for (i = 0; i < [argumentsString length]; i++) {
		switch ([argumentsString characterAtIndex:i]) {
			case ' ':
				if (isEscapedChar) { // add escaped whitespace
					argument[argumentCharCount] = [argumentsString characterAtIndex:i];
					argumentCharCount++;
					isEscapedChar = NO;
				} else if (inQuote) { // if we are inside a quote, accept white space
					argument[argumentCharCount] = [argumentsString characterAtIndex:i];
					argumentCharCount++;
				} else if (inSwitch) { // else, this whitespace is a separator
					key = [[[NSString alloc] initWithCharacters:argument length:argumentCharCount] autorelease];
					argumentCharCount = 0;
					inSwitch = NO;
				} else if (inArgument) {
					[argumentsArray addObject:key];
					[argumentsArray addObject:[[[NSString alloc] initWithCharacters:argument length:argumentCharCount] autorelease]];
					key = nil;
					argumentCharCount = 0;
					inArgument = NO;
				} else {
					// ignore doublewhitespace
				}
				break;
			case '-':
				if (!inArgument && !inSwitch) { // start of a switch
					if (key) { // store previous switch-only argument
					[argumentsArray addObject:key];
						key = nil;
					}
					inSwitch = TRUE;
				}
				argument[argumentCharCount] = [argumentsString characterAtIndex:i];
				argumentCharCount++;
				break;
			case '"':
				if (isEscapedChar) { // ignore escaped "
					argument[argumentCharCount] = '\\'; // we are only intrested in escaped whitespace, readd escape
					argumentCharCount++;
					isEscapedChar = NO;
					argument[argumentCharCount] = [argumentsString characterAtIndex:i];
					argumentCharCount++;
				} else {
					if (inQuote) {
						if (quoteChar == '"') { // remove "
							inQuote = NO;
						} else { // ignore "
							argument[argumentCharCount] = [argumentsString characterAtIndex:i];
							argumentCharCount++;
						}
					} else {
						inQuote = YES;
						quoteChar = '"';
					}
				}
				break;
			case '\'':
				if (isEscapedChar) { // ignore escaped '
					argument[argumentCharCount] = '\\'; // we are only intrested in escaped whitespace, readd escape
					argumentCharCount++;
					isEscapedChar = NO;
					argument[argumentCharCount] = [argumentsString characterAtIndex:i];
					argumentCharCount++;
				} else {
					if (inQuote) {
						if (quoteChar == '\'') { // remove '
							inQuote = NO;
						} else { // ignore '
							argument[argumentCharCount] = [argumentsString characterAtIndex:i];
							argumentCharCount++;
						}
					} else {
						inQuote = YES;
						quoteChar = '\'';
					}
				}
				break;
			case '\\':
				if (!inQuote && !isEscapedChar) { // remove /
					isEscapedChar = YES;
				} else { // ignore /
					argument[argumentCharCount] = [argumentsString characterAtIndex:i];
					argumentCharCount++;
				}
				break;
			default:
				if (!inSwitch && !inArgument) { //start of new argument
					inArgument = TRUE;
					if (!key)
						key = @"-hda"; // only argument without key is -hda
				}
				if (isEscapedChar) {
					argument[argumentCharCount] = '\\'; // we are only intrested in escaped whitespace, readd escape
					argumentCharCount++;
					isEscapedChar = NO;
				}
				argument[argumentCharCount] = [argumentsString characterAtIndex:i];
				argumentCharCount++;
				break;
		}
	}
	if (inSwitch) { // switch
		[argumentsArray addObject:[[[NSString alloc] initWithCharacters:argument length:argumentCharCount] autorelease]];
	} else if (inArgument) { // switch and argument
		[argumentsArray addObject:key];
		[argumentsArray addObject:[[[NSString alloc] initWithCharacters:argument length:argumentCharCount] autorelease]];
	} else {
		// must have been an empty string
	}

	return argumentsArray;
}
@end