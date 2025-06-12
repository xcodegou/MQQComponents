//
//  NSFileManager+Custom.m
//  MQQSecure
//
//  Created by Kloudz Liang on 14-4-11.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "../include/NSFileManager+Custom.h"

@implementation NSFileManager (Custom)

- (BOOL)createDirectoryByForceAtPath:(NSString *)path error:(NSError **)error
{
    BOOL isDir = NO;
    BOOL existed = [self fileExistsAtPath:path isDirectory:&isDir];
    BOOL isError = NO;
    if (existed == YES) {
        // 存在路径
        if (NO == isDir) {
            // 不是文件夹
            existed = NO;
            isError = ![self removeItemAtPath:path error:error]; // 移除文件
        }
    }
    if (NO == isError) {
        if (NO == existed) {
            // 创建目录
            return [self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

- (unsigned long long)sizeOfDirectoryAtPath:(NSString *)path isEmpty:(BOOL *)isEmpty
{
    long long size = [[self attributesOfItemAtPath:path error:nil] fileSize]; // 目录本身大小
    // 枚举子目录
    NSDirectoryEnumerator *fileEnumerator = [self enumeratorAtPath:path];
    NSString *fileName = nil;
    BOOL empty = YES;
    while ((fileName = [fileEnumerator nextObject]) != nil) {
        empty = NO;
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        long long fileSize = [[self attributesOfItemAtPath:filePath error:nil] fileSize];
        size += fileSize;
    }
    if (isEmpty) { // 判断目录是否为空
        *isEmpty = empty;
    }
    return size;
}

- (NSNumber *)rootFileSystemTotalSize
{
    NSError *error = nil;
    NSDictionary *attribute = [self attributesOfFileSystemForPath:@"/" error:&error];
    if (error == nil) {
        NSNumber *freeSize = [attribute objectForKey:NSFileSystemSize];
        return freeSize;
    }
    return nil;
}

- (NSNumber *)rootFileSystemFreeSize
{
    NSError *error = nil;
    NSDictionary *attribute = [self attributesOfFileSystemForPath:@"/" error:&error];
    if (error == nil) {
        NSNumber *freeSize = [attribute objectForKey:NSFileSystemFreeSize];
        return freeSize;
    }
    return nil;
}

- (NSNumber *)userFileSystemTotalSize
{
    NSError *error = nil;
    NSDictionary *attribute = [self attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error == nil) {
        NSNumber *freeSize = [attribute objectForKey:NSFileSystemSize];
        return freeSize;
    }
    return nil;
}

- (NSNumber *)userFileSystemFreeSize
{
    NSError *error = nil;
    NSDictionary *attribute = [self attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error == nil) {
        NSNumber *freeSize = [attribute objectForKey:NSFileSystemFreeSize];
        return freeSize;
    }
    return nil;
}

@end
