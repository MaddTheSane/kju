/*
 * localizationStringsUpdate
 * 
 * Copyright (c) 2007 Mike Kronenberg
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


#import <Foundation/Foundation.h>

@interface KBergTools : NSObject
{
}
- (NSRange) rangeBetweenStrings:(NSString *)start and:(NSString *)end of:(NSString *)string;
@end
@implementation KBergTools
- (NSRange) rangeBetweenStrings:(NSString *)start and:(NSString *)end of:(NSString *)string {
    NSRange rangeStartTag = [string rangeOfString:start];
    int startLocation = rangeStartTag.location + rangeStartTag.length;
    NSRange rangeEndTag = [[string substringWithRange:NSMakeRange(startLocation, [string length] - startLocation)] rangeOfString:end];
    
    return NSMakeRange(rangeStartTag.location + rangeStartTag.length, rangeEndTag.location);
}
@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    KBergTools *tools = [[[KBergTools alloc] init] autorelease];

    int i;
    NSError *error;
    NSString *tupel;
    NSString *oid;
    NSDictionary *tupelDictionary;
    NSString *list;
    NSArray *listItems;
    NSFileManager *fileManager;

    NSMutableDictionary *original = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *comments = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *translation = [[[NSMutableDictionary alloc] init] autorelease];

    //check arguments
    if (
        argc < 3
    ) {
        NSLog(@"\nusage: localizationStringsUpdate basetranslationfile oldtranslationfile newtranslationfile");
        [pool release];
        return 1;
    }
    fileManager = [NSFileManager defaultManager];
    for (i = 0; i < 2; i++) {
        if (
            ![fileManager fileExistsAtPath:[[[NSProcessInfo processInfo] arguments] objectAtIndex:i]]
        ) {
            switch (i) {
                case 0:
                    NSLog(@"\nlocalizationStringsUpdate\nFile not found for base translation: %@", [[[NSProcessInfo processInfo] arguments] objectAtIndex:i]);
                    break;
                case 1:
                    NSLog(@"\nlocalizationStringsUpdate\nFile not found for old translation: %@", [[[NSProcessInfo processInfo] arguments] objectAtIndex:i]);
                    break;
            }
            [pool release];
            return 1;
        }
    }

    //extract original and comments and key it to oid
    list = [NSString stringWithContentsOfFile:[[[NSProcessInfo processInfo] arguments] objectAtIndex:1] encoding:NSUnicodeStringEncoding error:&error];
    if (!list && error) {
        NSLog(@"\nlocalizationStringsUpdate\nError while loading base translation file: %@", [[error userInfo] objectForKey:NSLocalizedDescriptionKey]);
        [pool release];
        return 1;
    }
    listItems = [list componentsSeparatedByString:@"\";\n\n/* "];
    for (i = 0; i < [listItems count]; i++) {
        tupel = [NSString stringWithFormat:@"/* %@\";", [listItems objectAtIndex:i]];
        oid = [tupel substringWithRange:[tools rangeBetweenStrings:@"oid:" and:@") */" of:tupel]];
        [comments setObject:[tupel substringWithRange:[tools rangeBetweenStrings:@"/* " and:@" */" of:tupel]] forKey:oid];
        tupelDictionary = [tupel propertyListFromStringsFileFormat];
        [original setObject:[[tupelDictionary allValues] objectAtIndex:0] forKey:oid];
    }

    //extract transaltion and key it to oid
    list = [NSString stringWithContentsOfFile:[[[NSProcessInfo processInfo] arguments] objectAtIndex:2] encoding:NSUnicodeStringEncoding error:NULL];
    if (!list && error) {
        NSLog(@"\nlocalizationStringsUpdate\nError while loading old translation file: %@", [[error userInfo] objectForKey:NSLocalizedDescriptionKey]);
        [pool release];
        return 1;
    }
    listItems = [list componentsSeparatedByString:@"\";\n\n/* "];
    for (i = 0; i < [listItems count]; i++) {
        tupel = [NSString stringWithFormat:@"/* %@\";", [listItems objectAtIndex:i]];
        oid = [tupel substringWithRange:[tools rangeBetweenStrings:@"oid:" and:@") */" of:tupel]];
        tupelDictionary = [tupel propertyListFromStringsFileFormat];
        [translation setObject:[[tupelDictionary allValues] objectAtIndex:0] forKey:oid];
    }

    //export new File
    BOOL written;
    NSMutableString *output = [[[NSMutableString alloc] init] autorelease];
    NSEnumerator *enumerator = [original keyEnumerator];
    NSString *translationString;
    id key;
    while ((key = [enumerator nextObject])) {
        if (!(translationString = [translation objectForKey:key])) {
            translationString = [original objectForKey:key];
        }
        [output appendFormat:@"/* %@ */\n\"%@\" = \"%@\";\n\n", [comments objectForKey:key], [original objectForKey:key], translationString];
    }
    written = [output writeToFile:[[[NSProcessInfo processInfo] arguments] objectAtIndex:3] atomically:NO encoding:NSUnicodeStringEncoding error:&error];
    if (!written && error) {
        NSLog(@"\nlocalizationStringsUpdate\nError while writing new translation file: %@", [[error userInfo] objectForKey:NSLocalizedDescriptionKey]);
        [pool release];
        return 1;
    }

    //cleanup
    [pool release];
    return 0;
}
