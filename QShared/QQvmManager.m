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
- (NSUInteger)retainCount {return NSUIntegerMax;}  //denotes an object that cannot be released
- (oneway void)release {} //do nothing
- (id)autorelease { return self; }



#pragma mark methods
- (BOOL) saveVMConfiguration:(NSMutableDictionary *)VM
{
	Q_DEBUG(@"saveVMConfiguration %@", VM);

	NSMutableDictionary *temporary;

	temporary = [VM[@"Temporary"] copy];
	[temporary autorelease];
	[VM removeObjectForKey:@"Temporary"]; // don't store temporary items (URL can't be stored in Propertylist anyways)

    NSData *data = [NSPropertyListSerialization
        dataFromPropertyList:VM
        format: NSPropertyListXMLFormat_v1_0
        errorDescription: nil];
	if (data) {
//		[[VM objectForKey:@"Temporary"] setObject:URL forKey:@"URL"]; // reenter URL
		VM[@"Temporary"] = temporary; // reenter Temporary
		if ([data writeToFile:[NSString stringWithFormat:@"%@/configuration.plist", [VM[@"Temporary"][@"URL"] path]] atomically:YES]) {
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
	NSMutableString *arguments;
	NSMutableString *argument;
	NSString *option;

	data = [NSData dataWithContentsOfFile:[filename stringByAppendingPathComponent:@"configuration.plist"]];
	if (data) {
		tempVM = [NSPropertyListSerialization
			propertyListFromData: data
			mutabilityOption: NSPropertyListMutableContainersAndLeaves
			format: nil
			errorDescription: nil];

		// upgrade Version 0.1.0.Q to 0.2.0.Q
		if ([tempVM[@"Version"] isEqual:@"0.1.0.Q"]) {
			lookForArguments = @[@"-snapshot", @"-nographic", @"-audio-help", @"-localtime", @"-full-screen", @"-win2k-hack", @"-usb", @"-s", @"-S", @"-d", @"-std-vga"];
			arguments = [[NSMutableString alloc] init];
			for (key in tempVM[@"Arguments"]) {
				if (tempVM[@"Arguments"][key]) {
					if ([key isEqual:@"-net"] && [tempVM[@"Arguments"][key] isEqual:@"user"]) {
						[arguments appendString:@" -net nic"];
					}
					if ([lookForArguments containsObject:key]) {
						[arguments appendFormat:@" %@", key];
					} else {
						[arguments appendFormat:@" %@ %@", key, tempVM[@"Arguments"][key]];
					}
				}
			}
			tempVM[@"Arguments"] = arguments;
			tempVM[@"Version"] = @"0.2.0.Q";
		}

		// upgrade Version 0.2.0.Q to 0.2.1.Q (i.e. use doublequotes on all commands and paths)
		if ([tempVM[@"Version"] isEqual:@"0.2.0.Q"]) {
			lookForArguments = @[@"-hda", @"-hdb", @"-hdc", @"-hdd", @"-fda", @"-fdb", @"-cdrom", @"-append", @"-kernel", @"-initrd", @"-smb"];
			singleArguments = [tempVM[@"Arguments"] componentsSeparatedByString:@" "];
			arguments = [NSMutableString stringWithFormat:@"-name \"%@\" ", tempVM[@"PC Data"][@"name"]]; // add name for VM
			option = nil;
			argument = nil;
			for (i = 0; i < singleArguments.count; i++) {
				if ([singleArguments[i] UTF8String][0] != '-') { // part of argument
					if (!argument) {
						argument = [NSMutableString stringWithString:singleArguments[i]];
					} else {
						[argument appendFormat:@" %@", singleArguments[i]];
					}
				} else { // key
					if (option) { // handle previous key
						[arguments appendString:[NSString stringWithFormat:@"%@ ", option]];
						if ([lookForArguments containsObject:option]) { // path or command
							[arguments appendFormat:@"\"%@\" ", argument];
							argument = nil;
						} else if (argument) {
							[arguments appendFormat:@"%@ ", argument];
							argument = nil;
						}
						option = nil;
					}
					option = singleArguments[i];
				}
			}
			if (option) { // handle last option, argument pair
				[arguments appendString:[NSString stringWithFormat:@"%@ ", option]];
				if ([lookForArguments containsObject:option]) { // path or command
					[arguments appendFormat:@"\"%@\"", argument];
				} else if (argument) {
					[arguments appendFormat:@"%@", argument];
				}
			}
			// remove obsolte keys
			[tempVM[@"PC Data"] removeObjectForKey:@"name"];
			
			tempVM[@"Arguments"] = arguments;
			tempVM[@"Version"] = @"0.3.0.Q";
		}

		// get rid of old temporary items and add new
		if (tempVM[@"Temporary"])
			[tempVM removeObjectForKey:@"Temporary"];
		tempVM[@"Temporary"] = [NSMutableDictionary dictionary];
		
		// exploded arguments
		tempVM[@"Temporary"][@"explodedArguments"] = [[QQvmManager sharedQvmManager] explodeVMArguments:tempVM[@"Arguments"]];

		// url
		tempVM[@"Temporary"][@"URL"] = [NSURL fileURLWithPath:filename];

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
	unichar quoteChar = 0;
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

	for (i = 0; i < argumentsString.length; i++) {
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
