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
    NSString *tupel;
    NSString *oid;
    NSDictionary *tupelDictionary;
    NSString *list;
    NSArray *listItems;
    
    NSMutableDictionary *original = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *comments = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *translation = [[NSMutableDictionary alloc] init];

//    NSLog(@"Basefile: %@", [[[NSProcessInfo processInfo] arguments] objectAtIndex:1]);
//    NSLog(@"old Translation File: %@", [[[NSProcessInfo processInfo] arguments] objectAtIndex:2]);
//    NSLog(@"new Transaltion File: %@", [[[NSProcessInfo processInfo] arguments] objectAtIndex:3]);

    //extract original and comments and key it to oid
    list = [NSString stringWithContentsOfFile:[[[NSProcessInfo processInfo] arguments] objectAtIndex:1] encoding:NSUnicodeStringEncoding error:NULL];
    listItems = [list componentsSeparatedByString:@"\";\n\n/* "]; //@"\";\n/* "
    for (i = 0; i < [listItems count]; i++) {
        tupel = [NSString stringWithFormat:@"/* %@\";", [listItems objectAtIndex:i]];
        oid = [tupel substringWithRange:[tools rangeBetweenStrings:@"oid:" and:@") */" of:tupel]]; // (oid:447) */
        [comments setObject:[tupel substringWithRange:[tools rangeBetweenStrings:@"/* " and:@" */" of:tupel]] forKey:oid];
        tupelDictionary = [tupel propertyListFromStringsFileFormat];
        [original setObject:[[tupelDictionary allValues] objectAtIndex:0] forKey:oid];
//        NSLog(@"oid:%@ Comments:%@ Translation:%@", oid, [comments objectForKey:oid], [original objectForKey:oid]);
    }
        
    //extract transaltion and key it to oid
    list = [NSString stringWithContentsOfFile:[[[NSProcessInfo processInfo] arguments] objectAtIndex:2] encoding:NSUnicodeStringEncoding error:NULL];
    listItems = [list componentsSeparatedByString:@"\";\n\n/* "]; //@"\";\n/* "
    for (i = 0; i < [listItems count]; i++) {
        tupel = [NSString stringWithFormat:@"/* %@\";", [listItems objectAtIndex:i]];
        oid = [tupel substringWithRange:[tools rangeBetweenStrings:@"oid:" and:@") */" of:tupel]]; // (oid:447) */
        tupelDictionary = [tupel propertyListFromStringsFileFormat];
        [translation setObject:[[tupelDictionary allValues] objectAtIndex:0] forKey:oid];
//        NSLog(@"oid:%@ Translation:%@", oid, [translation objectForKey:oid]);
    }

    //export new File
    NSMutableString *output = [[NSMutableString alloc] init];
    NSEnumerator *enumerator = [original keyEnumerator];
    NSString *translationString;
    id key;
    while ((key = [enumerator nextObject])) {
        if (!(translationString = [translation objectForKey:key])) {
            translationString = [original objectForKey:key];
        }
        [output appendFormat:@"/* %@ */\n\"%@\" = \"%@\"\n\n", [comments objectForKey:key], [original objectForKey:key], translationString];
    }
//    NSLog(output);
    [output writeToFile:[[[NSProcessInfo processInfo] arguments] objectAtIndex:3] atomically:NO encoding:NSUnicodeStringEncoding error:NULL];

    [pool release];
    return 0;
}
