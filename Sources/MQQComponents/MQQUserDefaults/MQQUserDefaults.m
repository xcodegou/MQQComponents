//
//  MQQPCUserDefaults.m
//  MQQSecure
//
//  Created by Kloudz Liang on 13-10-30.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "../include/MQQUserDefaults.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface MQQUserDefaults ()
{
    NSLock *_lock;
    BOOL _defaultChanged; // 设置是否有改变
}
@property(nonatomic,copy)   NSString *filePath;
@property(nonatomic,retain) NSMutableDictionary *defaults;
- (void)loadDefaults;  // 读取
@end

@implementation MQQUserDefaults

@synthesize filePath = _filePath;
@synthesize defaults = _defaults;

- (id)initWithFilePath:(NSString *)path;
{
    self = [self init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _defaultChanged = NO;
        self.filePath = path;
        [self loadDefaults];
#if TARGET_OS_IOS
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self synchronize];
    self.filePath = nil;
    self.defaults = nil;
    [_lock release];
    _lock = nil;
    
    [super dealloc];
}

- (BOOL)synchronize
{
    [_lock lock];
    if (_defaultChanged && self.defaults) {
        _defaultChanged = NO;
        NSData *defaultsData = [NSPropertyListSerialization dataWithPropertyList:self.defaults
                                                                          format:NSPropertyListBinaryFormat_v1_0
                                                                         options:NSPropertyListImmutable
                                                                           error:nil];
        [_lock unlock];
        
        if (defaultsData) {
            if ([defaultsData writeToFile:self.filePath atomically:YES]) {
                return YES;
            }
        }
    } else {
        [_lock unlock];
    }
    return NO;
}

- (void)loadDefaults
{
#ifdef TMF_MESS_TEMP_LICENSE_CHECK_POINT
    TMF_MESS_TEMP_LICENSE_CHECK_POINT
#endif
    
    NSData *defaultsData = [NSData dataWithContentsOfFile:self.filePath];
    if (defaultsData) {
        NSPropertyListFormat listFormat = NSPropertyListXMLFormat_v1_0;
        NSDictionary *defaults = [NSPropertyListSerialization propertyListWithData:defaultsData
                                                                           options:NSPropertyListImmutable
                                                                            format:&listFormat
                                                                             error:nil];
        if (defaults) {
            [_lock lock];
            self.defaults = [NSMutableDictionary dictionaryWithDictionary:defaults];
            [_lock unlock];
            return;
        }
    }
    // 没有加载到，认为数据是空，新建
    [_lock lock];
    self.defaults = [NSMutableDictionary dictionary];
    [_lock unlock];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
#ifdef TMF_MESS_TEMP_LICENSE_CHECK_POINT
    TMF_MESS_TEMP_LICENSE_CHECK_POINT
#endif
    
    [self synchronize];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self synchronize];
}

#pragma mark -

- (id)objectForKey:(NSString *)defaultName
{
    [_lock lock];
    id value = [self.defaults objectForKey:defaultName];
    [[value retain] autorelease];
    [_lock unlock];
    return value;
}

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
    [_lock lock];
    _defaultChanged = YES;
    [self.defaults setObject:value forKey:defaultName];
    [_lock unlock];
}

- (void)removeObjectForKey:(NSString *)defaultName
{
    [_lock lock];
    _defaultChanged = YES;
    [self.defaults removeObjectForKey:defaultName];
    [_lock unlock];
}

- (NSString *)stringForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

- (NSArray *)arrayForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

- (NSDictionary *)dictionaryForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

- (NSData *)dataForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

- (NSArray *)stringArrayForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

- (NSInteger)integerForKey:(NSString *)defaultName
{
    return [[self objectForKey:defaultName] integerValue];
}

- (float)floatForKey:(NSString *)defaultName
{
    return [[self objectForKey:defaultName] floatValue];
}

- (double)doubleForKey:(NSString *)defaultName
{
    return [[self objectForKey:defaultName] doubleValue];
}

- (BOOL)boolForKey:(NSString *)defaultName
{
    return [[self objectForKey:defaultName] boolValue];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName
{
    [self setObject:[NSNumber numberWithInteger:value]
             forKey:defaultName];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName
{
    [self setObject:[NSNumber numberWithFloat:value]
             forKey:defaultName];
}

- (void)setDouble:(double)value forKey:(NSString *)defaultName
{
    [self setObject:[NSNumber numberWithDouble:value]
             forKey:defaultName];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName
{
    [self setObject:[NSNumber numberWithBool:value]
             forKey:defaultName];
}

- (NSArray *)allKeys {
    return [_defaults allKeys];
}

@end
