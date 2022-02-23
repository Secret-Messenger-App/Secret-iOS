//
//  NSString+ChatSecure.m
//
//  Copyright (c) 2022 Secret, Inc. All rights reserved.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "NSString+ChatSecure.h"
@import XMPPFramework;

@implementation NSString (ChatSecure)

- (NSString *)otr_stringInitialsWithMaxCharacters:(NSUInteger)maxCharacters
{
    if (![self length]) {
        return nil;
    }
    
    if (maxCharacters == 1) {
        return [self substringToIndex:1];
    } else {
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" ._-+"];
        NSArray *splitArray = [self componentsSeparatedByCharactersInSet:characterSet];
        if ([splitArray count] > maxCharacters) {
            splitArray = [splitArray subarrayWithRange:NSMakeRange(0, maxCharacters)];
        }
        
        NSMutableString *finalString = [[NSMutableString alloc] init];
        [splitArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            if ([obj length]) {
                [finalString appendString:[obj substringToIndex:1]];
            }
            
        }];
        
        return [finalString uppercaseString];
    }
}

- (NSString *)otr_stringByRemovingNonEnglishCharacters {
    NSMutableString *string = [self mutableCopy];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^A-Za-z0-9])" options:0 error:nil];
    [regex replaceMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    
    return string;
}

- (nullable NSString*) otr_nickName {
    XMPPJID *jid = [XMPPJID jidWithString:self];
    NSString *user = [jid user];
    if (!user) {
        return nil;
    }
    if ([[jid domain] isEqualToString:@"secret.me"]){
        NSString* at = @"@";
        NSString* nickname = [at stringByAppendingString: user];
        return nickname;
    }
    return self;
}

- (nullable NSString*) otr_displayName {
    XMPPJID *jid = [XMPPJID jidWithString:self];
    NSString *user = [jid user];
    if (!user) {
        return nil;
    }
    return user;
}

@end
