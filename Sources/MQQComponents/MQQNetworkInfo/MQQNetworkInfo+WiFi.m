//
//  MQQNetworkInfo+WiFi.m
//  MQQSecure
//
//  Created by klaudz on 3/28/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

#import "../include/MQQNetworkInfo+Protected.h"
#import "../include/MQQNetworkInfo+WiFi.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation MQQWiFiInfo

- (void)dealloc
{
    self.SSID = nil;
    self.BSSID = nil;
    [super dealloc];
}

@end


@implementation MQQNetworkInfo (WiFi)

#if TARGET_OS_IOS
+ (MQQWiFiInfo *)currentWiFiInfo
{
#if TARGET_IPHONE_SIMULATOR
    MQQWiFiInfo *currentWiFiInfo = [[[MQQWiFiInfo alloc] init] autorelease];
    currentWiFiInfo.SSID = @"Simulator";
    currentWiFiInfo.BSSID = @"00:00:00:00:00:00";
    return currentWiFiInfo;
#else
    MQQWiFiInfo *currentWiFiInfo = nil;
    CFArrayRef supportedInterfaces = CNCopySupportedInterfaces(); // Get supported interfaces
    if (supportedInterfaces != NULL) {
        NSString *supportedInterfaceName = ((NSArray *)supportedInterfaces).firstObject;
        if (supportedInterfaceName) {
            CFDictionaryRef wifiInfoDictionary = CNCopyCurrentNetworkInfo((CFStringRef)supportedInterfaceName); // Get current network info
            if (wifiInfoDictionary != NULL) {
                currentWiFiInfo = [[[MQQWiFiInfo alloc] init] autorelease];
                currentWiFiInfo.SSID = [(NSDictionary *)wifiInfoDictionary objectForKey:(NSString *)kCNNetworkInfoKeySSID];
                NSString *BSSID = [(NSDictionary *)wifiInfoDictionary objectForKey:(NSString *)kCNNetworkInfoKeyBSSID];
                currentWiFiInfo.BSSID = [self formattedBSSID:BSSID];
                CFRelease(wifiInfoDictionary);
            }
        }
        CFRelease(supportedInterfaces);
    }
    return currentWiFiInfo;
#endif
}
#else
+ (MQQWiFiInfo *)currentWiFiInfo
{
    return nil;
}
#endif

+ (MQQWiFiStatus)currentWiFiStatus
{
    MQQWiFiStatus currentWiFiStatus = MQQWiFiStatusDisconnected;
    /*
    if ([self currentWiFiInfo] != nil) {
        if ([[[self sharedInfo] reachability] currentReachabilityStatus] == MQQSecureNetworkStatusReachableViaWiFi) {
            currentWiFiStatus = MQQWiFiStatusConnected;
        } else {
            currentWiFiStatus = MQQWiFiStatusConnecting;
        }
    }
     */
    if ([[[self sharedInfo] reachability] currentReachabilityStatus] == MQQSecureNetworkStatusReachableViaWiFi) {
        currentWiFiStatus = MQQWiFiStatusConnected;
    } else if ([self currentWiFiInfo] != nil) {
        currentWiFiStatus = MQQWiFiStatusConnecting;
    }
    return currentWiFiStatus;
}

+ (NSString *)formattedBSSID:(NSString *)BSSID
{
    if ([BSSID length] > 0) {
        NSArray *components = [BSSID componentsSeparatedByString:@":"];
        if ([components count] > 0) {
            NSMutableString *formattedBSSID = [NSMutableString string];
            for (NSString *elem in components) {
                if ([elem length] == 1) {
                    [formattedBSSID appendFormat:@"0%@:", elem];
                } else {
                    [formattedBSSID appendFormat:@"%@:", elem];
                }
            }
            return [formattedBSSID substringToIndex:[formattedBSSID length] - 1];
        }
    }
    return BSSID;
}

+ (NSString *)localIPAddress
{
    NSString *localIP = nil;
    [self getLocalIPAddress:&localIP broadcastIPAddress:NULL];
    return localIP;
}

+ (NSString *)broadcastIPAddress
{
    NSString *broadcastIP = nil;
    [self getLocalIPAddress:NULL broadcastIPAddress:&broadcastIP];
    return broadcastIP;
}

+ (void)getLocalIPAddress:(NSString **)ip broadcastIPAddress:(NSString **)bip
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    // retrieve the current interfaces - returns 0 on success
    int success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    if (ip != NULL) {
                        *ip = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    }
                    if (bip != NULL) {
                        *bip = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                    }
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
}

@end
