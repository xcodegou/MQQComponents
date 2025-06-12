//
//  MQQNetworkInfo+Telephony.m
//  MQQSecure
//
//  Created by klaudz on 3/28/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "../include/MQQNetworkInfo+Protected.h"
#import "../include/MQQNetworkInfo+Telephony.h"

@implementation MQQNetworkInfo (Telephony_Protected)

#if TARGET_OS_IOS
- (CTTelephonyNetworkInfo *)telephonyNetworkInfo
{
    if ([CTTelephonyNetworkInfo class] == Nil) {
        return nil;
    }
    if (_telephonyNetworkInfo == nil) {
        _telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    }
    return _telephonyNetworkInfo;
}
#endif // TARGET_OS_IOS

@end

@implementation MQQNetworkInfo (Telephony)

+ (BOOL)supportsCurrentRadioAccessTechnology
{
#if TARGET_OS_IOS
    return ([CTTelephonyNetworkInfo class] != Nil && [[[UIDevice currentDevice] systemVersion] integerValue] >= 7);
#else
    return NO;
#endif
}

#if TARGET_OS_IOS
+ (MQQRATType)currentRadioAccessTechnology
{
#if TARGET_OS_APPLICATION
    // 在后台状态调用 -currentRadioAccessTechnology 可能引起crash
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return MQQRATTypeUnknown;
    }
#endif
    
    if (![self supportsCurrentRadioAccessTechnology]) {
        return MQQRATTypeUnknown;
    }
    
    NSString *RAT = [[self sharedInfo] telephonyNetworkInfo].currentRadioAccessTechnology;
    if ([RAT length] == 0) {
        return MQQRATTypeUnknown;
    }
    
    MQQRATType currentRATType = MQQRATTypeUnknown;
    if ([RAT isEqualToString:CTRadioAccessTechnologyGPRS]) {
        currentRATType = MQQRATTypeGPRS;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyEdge]) {
        currentRATType = MQQRATTypeEdge;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        currentRATType = MQQRATTypeWCDMA;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyHSDPA]) {
        currentRATType = MQQRATTypeHSDPA;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyHSUPA]) {
        currentRATType = MQQRATTypeHSUPA;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
        currentRATType = MQQRATTypeCDMA1x;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
        currentRATType = MQQRATTypeCDMAEVDORev0;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
        currentRATType = MQQRATTypeCDMAEVDORevA;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
        currentRATType = MQQRATTypeCDMAEVDORevB;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        currentRATType = MQQRATTypeeHRPD;
    } else if ([RAT isEqualToString:CTRadioAccessTechnologyLTE]) {
        currentRATType = MQQRATTypeLTE;
    }
    return currentRATType;
}
#endif // TARGET_OS_IOS

#if TARGET_OS_IOS
+ (MQQCNTType)currentCellularNetworkTechnology
{
#if TARGET_OS_APPLICATION
    // 在后台状态调用 -currentRadioAccessTechnology 可能引起crash
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return MQQCNTTypeUnknown;
    }
#endif
    
    if (![self supportsCurrentRadioAccessTechnology]) {
        return MQQCNTTypeUnknown;
    }
    
    NSString *RAT = [[self sharedInfo] telephonyNetworkInfo].currentRadioAccessTechnology;
    if ([RAT length] == 0) {
        return MQQCNTTypeUnknown;
    }
    
    static NSDictionary<NSNumber/* <MQQCNTType> */ *, NSSet<NSString *> *> *RAT2CNTTypeMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RAT2CNTTypeMap = [@{ @(MQQCNTType2G): [NSSet setWithArray:@[ CTRadioAccessTechnologyGPRS,
                                                                     CTRadioAccessTechnologyEdge,
                                                                     CTRadioAccessTechnologyCDMA1x,
                                                                     ]],
                             @(MQQCNTType3G): [NSSet setWithArray:@[ CTRadioAccessTechnologyWCDMA,
                                                                     CTRadioAccessTechnologyHSDPA,
                                                                     CTRadioAccessTechnologyHSUPA,
                                                                     CTRadioAccessTechnologyCDMAEVDORev0,
                                                                     CTRadioAccessTechnologyCDMAEVDORevA,
                                                                     CTRadioAccessTechnologyCDMAEVDORevB,
                                                                     CTRadioAccessTechnologyeHRPD,
                                                                     ]],
                             @(MQQCNTType4G): [NSSet setWithArray:@[ CTRadioAccessTechnologyLTE,
                                                                     ]],
                             } retain];
    });
    
    MQQCNTType currentCNTType = MQQCNTTypeUnknown;
    for (NSNumber *CNTTypeNumber in RAT2CNTTypeMap) {
        NSSet<NSString *> *RATs = RAT2CNTTypeMap[CNTTypeNumber];
        if ([RATs containsObject:RAT]) {
            currentCNTType = [CNTTypeNumber integerValue];
            break;
        }
    }
    return currentCNTType;
}
#endif // TARGET_OS_IOS

@end
