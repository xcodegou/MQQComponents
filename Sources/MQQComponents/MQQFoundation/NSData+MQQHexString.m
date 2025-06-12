//
//  NSData+MQQHexString.m
//  MQQComponents
//
//  Created by klaudz on 15/7/2019.
//

#import "../include/NSData+MQQHexString.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (MQQHexString)

+ (nullable instancetype)mqqDataWithHexString:(NSString *)hexString
{
    NSUInteger hexStringLength = [hexString length];
    if (hexStringLength % 2 != 0) {
        hexString = [@"0" stringByAppendingString:hexString];
    }
    
    NSUInteger dataLength = hexStringLength / 2;
    NSMutableData *data = [NSMutableData dataWithCapacity:dataLength];
    
    char char_buf[3] = { '\0', '\0', '\0' };
    for (NSUInteger i = 0; i < dataLength; i++) {
        NSUInteger j = i * 2;
        char_buf[0] = [hexString characterAtIndex:j];
        char_buf[1] = [hexString characterAtIndex:j + 1];
        char *end_ptr = NULL;
        long byte_buf = strtol(char_buf, &end_ptr, 16);
        if (end_ptr != char_buf + 2) {
            return nil;
        }
        [data appendBytes:&byte_buf length:1];
    }
    
    return [NSData dataWithData:data];
}

- (NSString *)mqqHexString
{
    NSUInteger dataLength = [self length];
    const unsigned char *bytes = (const unsigned char *)[self bytes];
    
    NSMutableString *hexString = [NSMutableString stringWithCapacity:dataLength * 2];
    for (NSUInteger i = 0; i < dataLength; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    
    return [NSString stringWithString:hexString];
}

@end

NS_ASSUME_NONNULL_END
