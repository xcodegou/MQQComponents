//
//  MQQDBResultSet.m
//  MQQSecure
//
//  Created by SparkChen on 14-2-12.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "../include/MQQDBResultSet.h"
#import "../include/MQQDatabase.h"
#import "../include/MQQDBStatement.h"

@interface MQQDBResultSet() {
    NSMutableDictionary *_columnNameToIndexMap; // 列名称与索引的映射表（字典）
}
@property(nonatomic,assign) MQQDatabase *mDB;
@property(nonatomic,retain) NSError *error;
@end

@implementation MQQDBResultSet
@synthesize mDB = _mDB;
@synthesize statement = _statement;
@synthesize error = _error;

+ (id)resultSetWithStatement:(MQQDBStatement *)stmt database:(MQQDatabase *)db
{
    return [[[[self class] alloc] initWithStatement:stmt database:db] autorelease];
}

- (id)initWithStatement:(MQQDBStatement *)stmt database:(MQQDatabase *)db
{
    self = [super init];
    if (self) {
        self.statement = stmt;
        self.mDB = db;
    }
    return self;
}

- (void)dealloc
{
    [self close];
    self.error = nil;
    if (_columnNameToIndexMap) {
        [_columnNameToIndexMap release];
        _columnNameToIndexMap = nil;
    }
    [super dealloc];
}

- (void)close
{
    if (self.mDB) {
        [self.mDB resultSetDidClose:self];
        self.mDB = nil;
    }
    self.statement = nil;
}

- (NSError *)lastError
{
    return _error;
}

- (BOOL)next
{
    int retCode = sqlite3_step(self.statement.stmt);
    
    if (retCode != SQLITE_ROW && retCode != SQLITE_DONE) {
        sqlite3 *dbHandle = self.mDB.sqliteHandle;
        NSInteger errorCode = sqlite3_errcode(dbHandle);
        NSString *errorMsg = [NSString stringWithUTF8String:sqlite3_errmsg(dbHandle)];
        if (!errorMsg) {
            errorMsg = @"";
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
        self.error = [NSError errorWithDomain:@"MQQDatabase" code:errorCode userInfo:userInfo];
    }
    
    if (retCode != SQLITE_ROW) {
        [self close];
    }
    
    if (retCode == SQLITE_ROW) {
        // 成功执行，没有错误
        self.error = nil;
        return YES;
    } else {
        return NO;
    }
}

- (NSDictionary *)resultRowDictionary
{
    NSUInteger numCols = (NSUInteger)sqlite3_data_count(self.statement.stmt);
    
    if (numCols > 0) {
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        int columnCount = sqlite3_column_count(self.statement.stmt);
        for (int index = 0; index < columnCount; index++) {
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(self.statement.stmt, index)];
            if (columnName) {
                id objectValue = [self objectForColumnIndex:index];
                // null pass
                if (objectValue && (objectValue != [NSNull null])) {
                    [dict setObject:objectValue forKey:columnName];
                }
            }
        }
        
        return dict;
    }
    
    return nil;
}

- (NSArray *)resultArray
{
    NSMutableArray *resultArray = [NSMutableArray array];
    
    // 有些业务可能会在列字段里面插入空值，这个方法会有缺陷
    //    if ([self next]) {
    //        // first row
    //        NSUInteger numCols = (NSUInteger)sqlite3_data_count(self.statement.stmt);
    //        if (numCols > 0) {
    //
    //            // cached ColsNames and ColsType
    //            NSMutableArray *names = [NSMutableArray array];
    //            NSMutableArray *types = [NSMutableArray array];
    //
    //            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    //            int columnCount = sqlite3_column_count(self.statement.stmt);
    //            for (int index = 0; index < columnCount; index++) {
    //                NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(self.statement.stmt, index)];
    //                if (columnName) {
    //                    [names addObject:columnName];
    //                    int columnType = sqlite3_column_type(self.statement.stmt, index);
    //                    [types addObject:@(columnType)];
    //
    //                    id objectValue = [self objectForColumnIndex:index type:columnType];
    //                    // null pass
    //                    if (objectValue && (objectValue != [NSNull null])) {
    //                        [dict setObject:objectValue forKey:columnName];
    //                    }
    //                }
    //            }
    //            [resultArray addObject:dict];
    //
    //            if (names.count == types.count) {
    //                // from second row
    //                while ([self next]) {
    //                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    //                    columnCount = names.count;
    //                    for (int index = 0; index < columnCount; index++) {
    //                        NSString *columnName = [names objectAtIndex:index];
    //                        int columnType = [[types objectAtIndex:index] intValue];
    //                        id objectValue = [self objectForColumnIndex:index type:columnType];
    //                        // null pass
    //                        if (objectValue && (objectValue != [NSNull null])) {
    //                            [dict setObject:objectValue forKey:columnName];
    //                        }
    //                    }
    //                    [resultArray addObject:dict];
    //                }
    //            }
    //        }
    //    }
    
    while ([self next]) {
        NSDictionary *dict = [self resultRowDictionary];
        if (dict) {
            [resultArray addObject:dict];
        }
    }
    
    if (self.error) {
        // we get an error，return nil
        return nil;
    }
    
    return resultArray;
}

#pragma mark - columnName-Index Map

- (NSMutableDictionary *)columnNameToIndexMap
{
    if (!_columnNameToIndexMap) {
        int columnCount = sqlite3_column_count(self.statement.stmt);
        _columnNameToIndexMap = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)columnCount];
        for (int index = 0; index < columnCount; index++) {
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(self.statement.stmt, index)];
            if (columnName) {
                // change the key to lowercase
                [_columnNameToIndexMap setObject:@(index) forKey:[columnName lowercaseString]];
            }
        }
    }
    return _columnNameToIndexMap;
}

- (int)columnIndexForName:(NSString *)columnName
{
    // change the key to lowercase
    columnName = [columnName lowercaseString];
    NSNumber *number = [[self columnNameToIndexMap] objectForKey:columnName];
    if (nil != number) {
        return [number intValue];
    }
    return -1;
}

#pragma mark - int/long/double/data/string/obj via columnIndex

- (int)intForColumnIndex:(int)columnIndex
{
    return sqlite3_column_int(self.statement.stmt, columnIndex);
}

- (long long)longLongForColumnIndex:(int)columnIndex
{
    return sqlite3_column_int64(self.statement.stmt, columnIndex);
}

- (double)doubleForColumnIndex:(int)columnIndex
{
    return sqlite3_column_double(self.statement.stmt, columnIndex);
}

- (BOOL)boolForColumnIndex:(int)columnIndex
{
    return ([self intForColumnIndex:columnIndex] != 0);
}

- (NSData *)dataForColumnIndex:(int)columnIndex
{
    if (sqlite3_column_type(self.statement.stmt, columnIndex) == SQLITE_NULL || (columnIndex < 0)) {
        return nil;
    }
    
    int dataSize = sqlite3_column_bytes(self.statement.stmt, columnIndex);
    const void *src = sqlite3_column_blob(self.statement.stmt, columnIndex);
    if (src) {
        NSMutableData *data = [NSMutableData dataWithLength:(NSUInteger)dataSize];
        memcpy([data mutableBytes], src, dataSize);
        return data;
    }
    
    return nil;
}

- (NSString *)stringForColumnIndex:(int)columnIndex
{
    if (sqlite3_column_type(self.statement.stmt, columnIndex) == SQLITE_NULL || (columnIndex < 0)) {
        return nil;
    }
    
    const char *c = (const char *)sqlite3_column_text(self.statement.stmt, columnIndex);
    if (!c) {
        return nil;
    }
    return [NSString stringWithUTF8String:c];
}

- (id)objectForColumnIndex:(int)columnIndex
{
    int columnType = sqlite3_column_type(self.statement.stmt, columnIndex);
    return [self objectForColumnIndex:columnIndex type:columnType];
}

- (id)objectForColumnIndex:(int)columnIndex type:(int)columnType
{
    // 根据列索引和列类型查询对应内容
    if (columnType == SQLITE_INTEGER) {
        return @([self longLongForColumnIndex:columnIndex]);
    }
    else if (columnType == SQLITE_FLOAT) {
        return @([self doubleForColumnIndex:columnIndex]);
    }
    else if (columnType == SQLITE_BLOB) {
        return [self dataForColumnIndex:columnIndex];
    }
    else if (columnType == SQLITE_TEXT) {
        return [self stringForColumnIndex:columnIndex];
    }
    
    return [NSNull null];
}

# pragma mark - int/long/double/data/string/obj via columnName

- (int)intForColumnName:(NSString *)columnName
{
    return [self intForColumnIndex:[self columnIndexForName:columnName]];
}

- (long long)longLongForColumnName:(NSString *)columnName
{
    return [self longLongForColumnIndex:[self columnIndexForName:columnName]];
}

- (double)doubleForColumnName:(NSString *)columnName
{
    return [self doubleForColumnIndex:[self columnIndexForName:columnName]];
}

- (BOOL)boolForColumnName:(NSString *)columnName
{
    return [self boolForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSData *)dataForColumnName:(NSString *)columnName
{
    return [self dataForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSString *)stringForColumnName:(NSString *)columnName
{
    return [self stringForColumnIndex:[self columnIndexForName:columnName]];
}

- (id)objectForColumnName:(NSString *)columnName
{
    return [self objectForColumnIndex:[self columnIndexForName:columnName]];
}

@end
