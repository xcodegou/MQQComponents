//
//  NSObject+MQQValueExtended.m
//  MQQSecure
//
//  Created by klaudz on 4/29/15.
//  Copyright (c) 2015 Tencent. All rights reserved.
//

#import "../include/NSObject+MQQValueExtended.h"

#pragma mark

NSNumber *MQQNumberValue(id object, NSNumber *defaultValue)
{
    if ([object isKindOfClass:[NSNumber class]]) {
        return object;
    } else {
        return defaultValue;
    }
}

NSString *MQQStringValue(id object, NSString *defaultValue)
{
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    } else {
        return defaultValue;
    }
}

NSDictionary *MQQDictionaryValue(id object, NSDictionary *defaultValue)
{
    if ([object isKindOfClass:[NSDictionary class]]) {
        return object;
    } else {
        return defaultValue;
    }
}

NSArray *MQQArrayValue(id object, NSArray *defaultValue)
{
    if ([object isKindOfClass:[NSArray class]]) {
        return object;
    } else {
        return defaultValue;
    }
}

NSData *MQQDataValue(id object, NSData *defaultValue)
{
    if ([object isKindOfClass:[NSData class]]) {
        return object;
    } else {
        return defaultValue;
    }
}

#pragma mark

double MQQDoubleValue(id object, double defaultValue)
{
    if ([object respondsToSelector:@selector(doubleValue)]) {
        return [object doubleValue];
    } else {
        return defaultValue;
    }
}

float MQQFloatValue(id object, float defaultValue)
{
    if ([object respondsToSelector:@selector(floatValue)]) {
        return [object floatValue];
    } else {
        return defaultValue;
    }
}

int MQQIntValue(id object, int defaultValue)
{
    if ([object respondsToSelector:@selector(intValue)]) {
        return [object intValue];
    } else {
        return defaultValue;
    }
}

NSInteger MQQIntegerValue(id object, NSInteger defaultValue)
{
    if ([object respondsToSelector:@selector(integerValue)]) {
        return [object integerValue];
    } else {
        return defaultValue;
    }
}

long long MQQLongLongValue(id object, long long defaultValue)
{
    if ([object respondsToSelector:@selector(longLongValue)]) {
        return [object longLongValue];
    } else {
        return defaultValue;
    }
}

BOOL MQQBoolValue(id object, BOOL defaultValue)
{
    if ([object respondsToSelector:@selector(boolValue)]) {
        return [object boolValue];
    } else {
        return defaultValue;
    }
}
