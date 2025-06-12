//
//  MQQDatabase+Util.m
//  MQQSecure
//
//  Created by SparkChen on 14-2-11.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "../include/MQQDatabase+Util.h"

@implementation MQQDatabase (Util)

+ (void)bindObject:(id)obj toColumn:(int)columnIndex inStatement:(sqlite3_stmt *)pStmt
{
    if (!obj || [NSNull null] == obj) {
        sqlite3_bind_null(pStmt, columnIndex);
        
    } else {
        
        if ([obj isKindOfClass:[NSData class]]) {
            const void *bytes = [obj bytes];
            if (!bytes) {
                bytes = "";
            }
            // 存的是二进制对象
            sqlite3_bind_blob(pStmt, columnIndex, bytes, (int)[obj length], SQLITE_STATIC);
            
        } else if ([obj isKindOfClass:[NSDate class]]) {
            // 存的是日期的时间戳
            sqlite3_bind_double(pStmt, columnIndex, [obj timeIntervalSince1970]);
            
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            // 获取obj对象
            const char *type = [obj objCType];
            
            if (strcmp(type, @encode(BOOL)) == 0) {
                sqlite3_bind_int(pStmt, columnIndex, ([obj boolValue] ? 1 : 0));
                
            } else if (strcmp(type, @encode(char)) == 0) {
                sqlite3_bind_int(pStmt, columnIndex, [obj charValue]);
                
            } else if (strcmp(type, @encode(unsigned char)) == 0) {
                sqlite3_bind_int(pStmt, columnIndex, [obj unsignedCharValue]);
                
            } else if (strcmp(type, @encode(short)) == 0) {
                sqlite3_bind_int(pStmt, columnIndex, [obj shortValue]);
                
            } else if (strcmp(type, @encode(unsigned short)) == 0) {
                sqlite3_bind_int(pStmt, columnIndex, [obj unsignedShortValue]);
                
            } else if (strcmp(type, @encode(int)) == 0) {
                sqlite3_bind_int(pStmt, columnIndex, [obj intValue]);
                
            } else if (strcmp(type, @encode(unsigned int)) == 0) {
                sqlite3_bind_int64(pStmt, columnIndex, (long long)[obj unsignedIntValue]);
                
            } else if (strcmp(type, @encode(long)) == 0) {
                sqlite3_bind_int64(pStmt, columnIndex, [obj longValue]);
                
            } else if (strcmp(type, @encode(unsigned long)) == 0) {
                sqlite3_bind_int64(pStmt, columnIndex, (long long)[obj unsignedLongValue]);
                
            } else if (strcmp(type, @encode(long long)) == 0) {
                sqlite3_bind_int64(pStmt, columnIndex, [obj longLongValue]);
                
            } else if (strcmp(type, @encode(unsigned long long)) == 0) {
                sqlite3_bind_int64(pStmt, columnIndex, (long long)[obj unsignedLongLongValue]);
                
            } else if (strcmp(type, @encode(float)) == 0) {
                sqlite3_bind_double(pStmt, columnIndex, [obj floatValue]);
                
            } else if (strcmp(type, @encode(double)) == 0) {
                sqlite3_bind_double(pStmt, columnIndex, [obj doubleValue]);
                
            } else {
                sqlite3_bind_text(pStmt, columnIndex, [[obj description] UTF8String], -1, SQLITE_STATIC);
            }
            
        } else {
            sqlite3_bind_text(pStmt, columnIndex, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    }
}

+ (NSString *)sqlString:(NSString *)string
{
	if (string == nil || [NSNull null] == (NSNull *)string) {
		return @"";
	}
    return [string stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

@end
