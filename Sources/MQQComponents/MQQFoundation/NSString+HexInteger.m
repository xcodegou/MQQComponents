//
//  NSString+HexInteger.m
//  MQQSecure
//
//  Created by 徐森圣 on 2018/1/9.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "../include/NSString+HexInteger.h"

@implementation NSString (HexInteger)

#if TARGET_OS_IPHONE
- (UIColor *)hexColor
#else
- (NSColor *)hexColor
#endif
{
    NSString *hexString = nil;
    if ([self hasPrefix:@"0x"]) {
        hexString = [self substringFromIndex:2];
    }
    else if ([self hasPrefix:@"#"]) {
        hexString = [self substringFromIndex:1];
    }
    else {
        hexString = [NSString stringWithString:self];
    }
    
    if (hexString.length == 6) {
        hexString = [hexString stringByAppendingString:@"FF"];
    }
    else if (hexString.length != 8) {
        return nil;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    unsigned int hexNum;
    if (![scanner scanHexInt:&hexNum]) {
        return nil;
    }
    
    int r,g,b,a;
    
    r = (hexNum >> 030) & 0xFF;
    g = (hexNum >> 020) & 0xFF;
    b = (hexNum >> 010) & 0xFF;
    a = hexNum & 0xFF;

#if TARGET_OS_IPHONE
    return [UIColor colorWithRed:r / 255.0f
                           green:g / 255.0f
                            blue:b / 255.0f
                           alpha:a / 255.0f];
#else
    return [NSColor colorWithRed:r / 255.0f
                           green:g / 255.0f
                            blue:b / 255.0f
                           alpha:a / 255.0f];
#endif
}

@end
