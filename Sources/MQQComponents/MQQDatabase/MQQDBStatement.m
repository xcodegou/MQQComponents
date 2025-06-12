//
//  MQQDBStatement.m
//  MQQSecure
//
//  Created by SparkChen on 14-2-12.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "../include/MQQDBStatement.h"

@implementation MQQDBStatement
@synthesize stmt = _stmt;
@synthesize sqlString = _sqlString;

- (void)reset
{
    if (_stmt) {
        sqlite3_reset(_stmt);
    }
}

- (void)close
{
    [self _finalize];
}

- (void)_finalize
{
    if (_stmt) {
        sqlite3_finalize(_stmt);
        _stmt = NULL;
    }
}

- (void)dealloc
{
    [self _finalize];
    self.sqlString = nil;
    [super dealloc];
}

@end
