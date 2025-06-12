//
//  MQQDatabase.m
//  MQQSecure
//
//  Created by SparkChen on 14-2-11.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "../include/MQQDatabase.h"
#import "../include/MQQDatabase+Util.h"
#import "../include/MQQDBStatement.h"

#define kMQQDBErrorBindFail       (999)   // 数据库statement值绑定出错，传参对应失败
#define kMQQDBErrorUpdateForQuery (1000)  // 在查询函数（读操作）中，执行更新的sql语句（写操作）
#define kMQQDBErrorNotDatabase    (1001)  // 没有可用的数据库连接
#define kMQQDBErrorEmptySql       (1002)  // 没有可执行的sql语句（空）
#define kMQQDBErrorExecutingStmt  (1003)  // 数据库正在执行stmt

#define kMQQDBErrorMessageBindFail        @"Error: The bind count is not correct for the variables in the sqlString."
#define kMQQDBErrorMessageUpdateForQuery  @"Error: An executeUpdate is being called with a query string."
#define kMQQDBErrorMessageNotDatabase     @"Error: Not available database connection."
#define kMQQDBErrorMessageEmptySql        @"Error: Empty sqlString."
#define kMQQDBErrorMessageExecutingStmt   @"Error: The database is executing statement."

@interface MQQDatabase() {
    BOOL _isExecutingStatement;  // 是否有statement正在执行
}
@property(nonatomic,copy)   NSString *dbPath;
@property(nonatomic,retain) NSError  *lastError;
@property(nonatomic,retain) NSMutableDictionary *cachedStmtsDict;  // statement缓存字典
@property(nonatomic,retain) NSMutableArray *openResultSets; // 管理存储外部打开的结果集
@end

@implementation MQQDatabase
@synthesize dbPath = _dbPath;
@synthesize lastError = _lastError;
@synthesize isCachedStatements = _isCachedStatements;
@synthesize cachedStmtsDict = _cachedStmtsDict;
@synthesize openResultSets = _openResultSets;

+ (id)databaseWithPath:(NSString *)path
{
    return [[[[self class] alloc] initWithPath:path] autorelease];
}

#pragma mark - Life Cycle

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        
        self.dbPath = path;
        // check db file path
        NSString *dirPath = [path stringByDeletingLastPathComponent];
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:dirPath]) {
            // not dir then create it
            NSError *error = nil;
            [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                // dir creation failed, unable to open db file.
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [self close];
    self.dbPath = nil;
    self.lastError = nil;
    self.cachedStmtsDict = nil;
    self.openResultSets = nil;
    [super dealloc];
}

#pragma mark - Open & Close

- (BOOL)open
{
    if (!_db) {
        int retCode = sqlite3_open([self.dbPath fileSystemRepresentation], &_db);
        if (retCode != SQLITE_OK) {
            [self handleSqliteError];
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)close
{
    // 清除所有缓存的stmt
    [self clearCachedStatements];
    // 关闭所有打开的结果集
    [self closeAllOpenResultSets];
    
    if (_db) {
        
        int  retCode;
        BOOL isRetry;
        BOOL isTriedFinalizingOpenStatements = NO;
        
        do {
            isRetry = NO;
            retCode = sqlite3_close(_db);
            if (SQLITE_BUSY == retCode || SQLITE_LOCKED == retCode) {
                if (!isTriedFinalizingOpenStatements) {
                    isTriedFinalizingOpenStatements = YES;
                    sqlite3_stmt *pStmt;
                    while ((pStmt = sqlite3_next_stmt(_db, NULL)) != NULL) {
                        // 关闭还没完成的stmt
                        sqlite3_finalize(pStmt);
                        isRetry = YES;
                    }
                }
            } else if (SQLITE_OK != retCode) {
                [self handleSqliteError];
                return NO;
            }
            
        } while (isRetry);
        
        _db = nil;
    }
    
    return YES;
}

- (BOOL)reopen
{
    return [self close] && [self open];
}

#pragma mark - Update

- (BOOL)execUpdate:(NSString *)sqlString, ...
{
    va_list args;
    va_start(args, sqlString);
    BOOL result = [self execUpdate:sqlString withVAList:args orArgumentsInArray:nil];
    va_end(args);
    return result;
}

- (BOOL)execUpdate:(NSString *)sqlString withArgumentsInArray:(NSArray *)argsArray
{
    return [self execUpdate:sqlString withVAList:nil orArgumentsInArray:argsArray];
}

- (BOOL)execUpdate:(NSString *)sqlString withVAList:(va_list)args orArgumentsInArray:(NSArray *)argsArray
{
    if (sqlString.length <= 0) {
        // 没有sql语句
        [self handleErrorWithCode:kMQQDBErrorEmptySql msg:kMQQDBErrorMessageEmptySql];
        return NO;
    }
    
    if (!_db) {
        // 没有数据库
        [self handleErrorWithCode:kMQQDBErrorNotDatabase msg:kMQQDBErrorMessageNotDatabase];
        return NO;
    }
    
    if (_isExecutingStatement) {
        // 数据库正在操作stmt
        [self handleErrorWithCode:kMQQDBErrorExecutingStmt msg:kMQQDBErrorMessageExecutingStmt];
        return NO;
    }
    
    _isExecutingStatement = YES;
    
    int retCode;
    sqlite3_stmt *pStmt = NULL;
    MQQDBStatement *cachedStmt = nil;
    
    if (_isCachedStatements) {
        // 查找缓存列表
        cachedStmt = [self cachedStatementForSqlString:sqlString];
        if (cachedStmt) {
            [cachedStmt reset];
            pStmt = cachedStmt.stmt;
        }
    }
    
    // 1. prepare statement
    if (!pStmt) {
        retCode = sqlite3_prepare_v2(_db, [sqlString UTF8String], -1, &pStmt, NULL);
        if (retCode != SQLITE_OK) {
            [self handleSqliteError];
            sqlite3_finalize(pStmt);
            pStmt = NULL;
            _isExecutingStatement = NO;
            return NO;
        }
    }
    
    // 2. bind data
    int index = 0;
    int bindParaCount = sqlite3_bind_parameter_count(pStmt);
    
    while (index < bindParaCount) {
        id obj = nil;
        if (args) {
            // 用va_arg传参
            obj = va_arg(args, id);
        } else if (argsArray && index < argsArray.count) {
            // 用数组传参
            obj = [argsArray objectAtIndex:(NSUInteger)index];
        }
        
        // sqlite3_bind的index从1开始
        index++;
        [MQQDatabase bindObject:obj toColumn:index inStatement:pStmt];
    }
    
    if (index != bindParaCount) {
        // 传入的数据没有完全绑定完
        [self handleErrorWithCode:kMQQDBErrorBindFail msg:kMQQDBErrorMessageBindFail];
        if (!cachedStmt) {
            // 没有缓存的stmt，可以直接释放
            sqlite3_finalize(pStmt);
            pStmt = NULL;
        }
        _isExecutingStatement = NO;
        return NO;
    }
    
    // 3. step statement
    retCode = sqlite3_step(pStmt);
    
    if (retCode != SQLITE_DONE) {
        if (retCode == SQLITE_ROW) {
            [self handleErrorWithCode:kMQQDBErrorUpdateForQuery msg:kMQQDBErrorMessageUpdateForQuery];
        } else {
            [self handleSqliteError];
        }
        if (!cachedStmt) {
            // 没有缓存的stmt，可以直接释放
            sqlite3_finalize(pStmt);
            pStmt = NULL;
        }
        _isExecutingStatement = NO;
        return NO;
    }
    
    if (_isCachedStatements && !cachedStmt) {
        // 缓存
        cachedStmt = [[[MQQDBStatement alloc] init] autorelease];
        cachedStmt.stmt = pStmt;
        cachedStmt.sqlString = sqlString;
        [self setCachedStatement:cachedStmt forSqlString:sqlString];
    }
    
    if (!cachedStmt) {
        // 最后还是不需要缓存，直接释放
        sqlite3_finalize(pStmt);
        pStmt = NULL;
    }
    
    _isExecutingStatement = NO;
    self.lastError = nil; // 成功执行，没有错误
    return YES;
}

#pragma mark - Query

- (MQQDBResultSet *)execQuery:(NSString *)sqlString, ...
{
    va_list args;
    va_start(args, sqlString);
    id result = [self execQuery:sqlString withVAList:args orArgumentsInArray:nil];
    va_end(args);
    return result;
}

- (MQQDBResultSet *)execQuery:(NSString *)sqlString withArgumentsInArray:(NSArray *)argsArray
{
    return [self execQuery:sqlString withVAList:nil orArgumentsInArray:argsArray];
}

- (MQQDBResultSet *)execQuery:(NSString *)sqlString withVAList:(va_list)args orArgumentsInArray:(NSArray *)argsArray
{
    if (sqlString.length <= 0) {
        // 没有sql语句
        [self handleErrorWithCode:kMQQDBErrorEmptySql msg:kMQQDBErrorMessageEmptySql];
        return nil;
    }
    
    if (!_db) {
        // 没有数据库
        [self handleErrorWithCode:kMQQDBErrorNotDatabase msg:kMQQDBErrorMessageNotDatabase];
        return nil;
    }
    
    if (_isExecutingStatement) {
        // 数据库正在操作stmt
        [self handleErrorWithCode:kMQQDBErrorExecutingStmt msg:kMQQDBErrorMessageExecutingStmt];
        return nil;
    }
    
    _isExecutingStatement = YES;
    
    int retCode;
    sqlite3_stmt *pStmt = NULL;
    MQQDBResultSet *resultSet = nil;
    MQQDBStatement *mStmt = nil;
    
    if (_isCachedStatements) {
        // 查找缓存列表
        mStmt = [self cachedStatementForSqlString:sqlString];
        if (mStmt) {
            [mStmt reset];
            pStmt = mStmt.stmt;
        }
    }
    
    // 1. prepare statement
    if (!pStmt) {
        retCode = sqlite3_prepare_v2(_db, [sqlString UTF8String], -1, &pStmt, NULL);
        if (retCode != SQLITE_OK) {
            [self handleSqliteError];
            sqlite3_finalize(pStmt);
            pStmt = NULL;
            _isExecutingStatement = NO;
            return nil;
        }
    }
    
    // 2. bind data
    int index = 0;
    int bindParaCount = sqlite3_bind_parameter_count(pStmt);
    
    while (index < bindParaCount) {
        id obj = nil;
        if (args) {
            // 用va_arg传参
            obj = va_arg(args, id);
        } else if (argsArray && index < argsArray.count) {
            // 用数组传参
            obj = [argsArray objectAtIndex:(NSUInteger)index];
        }
        
        // sqlite3_bind的index从1开始
        index++;
        [MQQDatabase bindObject:obj toColumn:index inStatement:pStmt];
    }
    
    if (index != bindParaCount) {
        // 传入的数据没有完全绑定完
        [self handleErrorWithCode:kMQQDBErrorBindFail msg:kMQQDBErrorMessageBindFail];
        if (!mStmt) {
            // 没有缓存的stmt，可以直接释放
            sqlite3_finalize(pStmt);
            pStmt = NULL;
        }
        _isExecutingStatement = NO;
        return nil;
    }
    
    if (!mStmt) {
        mStmt = [[[MQQDBStatement alloc] init] autorelease];
        mStmt.stmt = pStmt;
        mStmt.sqlString = sqlString;
        if (_isCachedStatements) {
            [self setCachedStatement:mStmt forSqlString:sqlString];
        }
    }
    
    resultSet = [MQQDBResultSet resultSetWithStatement:mStmt database:self];
    // 加入存储的结果集
    [self addOpenResultSets:resultSet];
    
    _isExecutingStatement = NO;
    self.lastError = nil; // 成功执行，没有错误
    return resultSet;
}

#pragma mark - Cache Stmts

- (MQQDBStatement *)cachedStatementForSqlString:(NSString *)sqlString
{
    if (sqlString) {
        return [self.cachedStmtsDict objectForKey:sqlString];
    }
    return nil;
}

- (void)setCachedStatement:(MQQDBStatement*)statement forSqlString:(NSString *)sqlString
{
    if (!self.cachedStmtsDict) {
        self.cachedStmtsDict = [NSMutableDictionary dictionary];
    }
    
    if (statement && sqlString) {
        [self.cachedStmtsDict setObject:statement forKey:sqlString];
    }
}

- (void)clearCachedStatements
{
    if (self.cachedStmtsDict) {
        NSArray *cachedStmts = [self.cachedStmtsDict allValues];
        for (MQQDBStatement *stmt in cachedStmts) {
            [stmt close];
        }
        [self.cachedStmtsDict removeAllObjects];
        self.cachedStmtsDict = nil;
    }
}

#pragma mark - Result Sets

- (BOOL)hasOpenResultSet
{
    return self.openResultSets.count > 0;
}

- (void)closeAllOpenResultSets
{
    if (self.openResultSets) {
        
        // copy new in case array changed outside
        NSArray *openResultSetsCopy = [NSArray arrayWithArray:self.openResultSets];
        for (MQQDBResultSet *rs in openResultSetsCopy) {
            
            [rs close];
            NSArray *cachedStmts = [self.cachedStmtsDict allValues];
            if (![cachedStmts indexOfObject:rs.statement]) {
                // 没有cached的stmt用到，可以完全关闭
                [rs.statement close];
            }
        }
        [self.openResultSets removeAllObjects];
        self.openResultSets = nil;
    }
}

- (void)addOpenResultSets:(MQQDBResultSet *)rs
{
    if (!self.openResultSets) {
        self.openResultSets = [NSMutableArray array];
    }
    if (rs) {
        [self.openResultSets addObject:rs];
    }
}

- (void)removeOpenResultSets:(MQQDBResultSet *)rs
{
    if (self.openResultSets) {
        [self.openResultSets removeObject:rs];
    }
}

- (void)resultSetDidClose:(MQQDBResultSet *)rs
{
    [self removeOpenResultSets:rs];
    NSArray *cachedStmts = [self.cachedStmtsDict allValues];
    if (!cachedStmts || NSNotFound == [cachedStmts indexOfObject:rs.statement]) {
        // 没有cached的stmt用到，可以完全关闭
        [rs.statement close];
    }
}

#pragma mark - Error

- (void)handleSqliteError
{
    if (_db) {
        NSInteger errorCode = sqlite3_errcode(_db);
        NSString *errorMsg = [NSString stringWithUTF8String:sqlite3_errmsg(_db)];
        [self handleErrorWithCode:errorCode msg:errorMsg];
    }
}

- (void)handleErrorWithCode:(NSInteger)errorCode msg:(NSString *)errorMsg
{
    if (_db) {
        if (!errorMsg) {
            // in case errorMsg=nil
            errorMsg = @"";
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
        self.lastError = [NSError errorWithDomain:@"MQQDatabase" code:errorCode userInfo:userInfo];
    }
}

- (NSError *)lastError
{
    return _lastError;
}

#pragma mark - SQLite handle

- (sqlite3 *)sqliteHandle
{
    // sqlite3指针
    return _db;
}

#pragma mark - Others

- (int)changes
{
    if (!_db) {
        // 没有数据库
        [self handleErrorWithCode:kMQQDBErrorNotDatabase msg:kMQQDBErrorMessageNotDatabase];
        return 0;
    }
    
    if (_isExecutingStatement) {
        // 数据库正在操作stmt
        [self handleErrorWithCode:kMQQDBErrorExecutingStmt msg:kMQQDBErrorMessageExecutingStmt];
        return 0;
    }
    
    _isExecutingStatement = YES;
    int ret = sqlite3_changes(_db);
    _isExecutingStatement = NO;
    return ret;
}

- (long long)lastInsertRowId
{
    if (!_db) {
        // 没有数据库
        [self handleErrorWithCode:kMQQDBErrorNotDatabase msg:kMQQDBErrorMessageNotDatabase];
        return 0;
    }
    
    if (_isExecutingStatement) {
        // 数据库正在操作stmt
        [self handleErrorWithCode:kMQQDBErrorExecutingStmt msg:kMQQDBErrorMessageExecutingStmt];
        return 0;
    }
    
    _isExecutingStatement = YES;
    long long ret = sqlite3_last_insert_rowid(_db);
    _isExecutingStatement = NO;
    return ret;
}

@end
