//
//  MQQNetworkInfo.m
//  MQQSecure
//
//  Created by SparkChen on 13-4-17. (MQQNetworkManager)
//  Updated by klaudz on 3/28/16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "../include/MQQNetworkInfo+Protected.h"
#import "../include/MQQNetworkInfo+WiFi.h"

#if defined TARGET_OS_APPLICATION || defined TARGET_OS_APPLICATION
#   define MQQNetworkInfo_Application
#endif

__attribute__((constructor))
static void MQQNetworkInfoInitialize(void)
{
    [MQQNetworkInfo sharedInfo];
}

NSString *const MQQNetworkInfoDidChangeNotification = @"MQQNetworkInfoDidChangeNotification";  //网络变化通知

@implementation MQQNetworkInfo

//+ (void)initialize
//{
//    [self sharedInfo]; // Init sharedInfo, such as starting notifier
//}

+ (instancetype)sharedInfo
{
    static MQQNetworkInfo *sharedInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInfo = [[self alloc] init];
    });
    return sharedInfo;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkDidChange:)
                                                     name:kMQQSecureReachabilityChangedNotification
                                                   object:nil];
        
        self.cachedNetworkType = [self currentNetworkType];
        self.cachedWiFiInfo = [[self class] currentWiFiInfo];
        
#ifdef MQQNetworkInfo_Application // Application
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            // Active
            [self.reachability startNotifier];
        }
        
#else // Extension
        [self.reachability startNotifier];
#endif
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_cachedWiFiInfo release];
    
    [_reachability stopNotifier];
    [_reachability release];
    
#if TARGET_OS_IOS
    [_telephonyNetworkInfo release];
#endif
    
    [super dealloc];
}

- (MQQSecureReachability *)reachability
{
    if (_reachability == nil) {
        _reachability = [[MQQSecureReachability reachabilityForInternetConnection] retain];
    }
    return _reachability;
}

#pragma mark -

- (MQQNetworkType)currentNetworkType
{
    MQQNetworkType networkType = MQQNetworkTypeNone;
    
    MQQSecureNetworkStatus networkStatus = [[self reachability] currentReachabilityStatus];
    if (networkStatus == MQQSecureNetworkStatusReachableViaWiFi) {
        // WiFi
        networkType = MQQNetworkTypeWiFi;
    } else if (networkStatus == MQQSecureNetworkStatusReachableViaWWAN) {
        // WWAN
        networkType = MQQNetworkTypeWWAN;
    }
    
#ifdef TMF_MESS_TEMP_LICENSE_CHECK_POINT
    TMF_MESS_TEMP_LICENSE_CHECK_POINT
#endif
    
    return networkType;
}

+ (MQQNetworkType)currentNetworkType
{
    MQQNetworkType networkType = MQQNetworkTypeNone;
    
    MQQSecureNetworkStatus networkStatus = [[[self sharedInfo] reachability] currentReachabilityStatus];
    if (networkStatus == MQQSecureNetworkStatusReachableViaWiFi) {
        // WiFi
        networkType = MQQNetworkTypeWiFi;
    } else if (networkStatus == MQQSecureNetworkStatusReachableViaWWAN) {
        // WWAN
        networkType = MQQNetworkTypeWWAN;
    }
    
    return networkType;
}

#pragma mark - Notification

- (void)networkDidChange:(NSNotification *)notification
{
#ifdef MQQNetworkInfo_Application // Application
    // Note:
    //  背景: 在进入后台后需要停止Reachability的监听。
    //  问题: 发现可能存在不能停止Reachability监听的情况，因此增加逻辑判断，在后台模式不post变更通知
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return;
    }
#endif
    
#ifdef TMF_MESS_TEMP_LICENSE_CHECK_POINT
    TMF_MESS_TEMP_LICENSE_CHECK_POINT
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 据 QQ 浏览器反馈，在主线程获取网络信息会引起卡顿。
        // 临时先以下接口的调用放到子线程中，后面进行优化。
        MQQNetworkType currentNetworkType = [[self class] currentNetworkType];
        MQQWiFiInfo *currentWiFiInfo = [[self class] currentWiFiInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cachedNetworkType = currentNetworkType;
            self.cachedWiFiInfo = currentWiFiInfo;
            [[NSNotificationCenter defaultCenter] postNotificationName:MQQNetworkInfoDidChangeNotification object:nil];
        });
    });
}

#ifdef MQQNetworkInfo_Application // Application

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self checkNetworkIfChanged];
    [self.reachability stopNotifier];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self checkNetworkIfChanged];
    [self.reachability startNotifier];
}

#endif

#pragma mark -

+ (void)checkNetworkIfChanged
{
    [[self sharedInfo] checkNetworkIfChanged];
}

- (void)checkNetworkIfChanged
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 据 QQ 浏览器反馈，在主线程获取网络信息会引起卡顿。
        // 临时先以下接口的调用放到子线程中，后面进行优化。
        MQQNetworkType currentNetworkType = [[self class] currentNetworkType];
        MQQWiFiInfo *currentWiFiInfo = [[self class] currentWiFiInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL networkDidChange = NO;
            if (![self networkType:currentNetworkType isEqualToNetworkType:self.cachedNetworkType]
                || ![self wifiInfo:currentWiFiInfo isEqualToWiFiInfo:self.cachedWiFiInfo])
            {
                // Network did change
                networkDidChange = YES;
            }
            self.cachedNetworkType = currentNetworkType;
            self.cachedWiFiInfo = currentWiFiInfo;
            if (networkDidChange) {
                [[NSNotificationCenter defaultCenter] postNotificationName:MQQNetworkInfoDidChangeNotification object:nil];
            }
        });
    });
}

- (BOOL)networkType:(MQQNetworkType)networkType1 isEqualToNetworkType:(MQQNetworkType)networkType2
{
    return (networkType1 == networkType2);
}

- (BOOL)wifiInfo:(MQQWiFiInfo *)wifiInfo1 isEqualToWiFiInfo:(MQQWiFiInfo *)wifiInfo2
{
    if (wifiInfo1.BSSID == nil && wifiInfo2.BSSID == nil) {
        return YES;
    } else if (wifiInfo1.BSSID != nil && wifiInfo2.BSSID != nil
               && [wifiInfo1.BSSID isEqualToString:wifiInfo2.BSSID]) {
        return YES;
    } else {
        return NO;
    }
}

@end

