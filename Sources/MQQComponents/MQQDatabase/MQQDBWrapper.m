//
//  MQQDBWrapper.m
//  MQQSecure
//
//  Created by SparkChen on 14-2-13.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "../include/MQQDBWrapper.h"

#if (MQQSECURE_JAILBROKEN == 0)
    #define kDatabaseQueueLabel @"com.tencent.mqqsecure.db"    // Appstore
#else
    #define kDatabaseQueueLabel @"com.tencent.mqqsecureJB.db"  // Jailbreak
#endif

#define kDefaultWalAutoCheckPointLogPages (1000)

@interface MQQDBWrapper()
@property(nonatomic,copy) NSString *dbPath;
@property(nonatomic,retain) NSDate *lastWalCheckDate;
@end

@implementation MQQDBWrapper
@synthesize walAutoCheckPointLogPages = _walAutoCheckPointLogPages;
@synthesize dbPath = _dbPath;
@synthesize lastWalCheckDate = _lastWalCheckDate;

+ (id)databaseWrapperWithPath:(NSString *)path
{
    return [[[[self class] alloc] initWithPath:path] autorelease];
}

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        
        self.dbPath = path;
        
        // init and open db
        _mDB = [[MQQDatabase alloc] initWithPath:self.dbPath];
        [_mDB open];
        
        // create queue
        NSString *queueLabel = [NSString stringWithFormat:@"%@.%@", kDatabaseQueueLabel, self];
        _queue = dispatch_queue_create([queueLabel UTF8String], NULL);
        dispatch_queue_set_specific(_queue, &_queue, &_queue, NULL);
        
        // 获取日志模式
        _journalMode = [self __journalMode];
        
        // 自动checkpoint的日志数（wal）
        _walAutoCheckPointLogPages = kDefaultWalAutoCheckPointLogPages;
    }
    
    return self;
}

- (void)dealloc
{
    [_mDB close];
    [_mDB release];
    _mDB = nil;
    dispatch_release(_queue);
    _queue = NULL;
    self.dbPath = nil;
    self.lastWalCheckDate = nil;
    [super dealloc];
}

#pragma mark - Private Methods

- (void)dispatchDBQueueWithBlock:(dispatch_block_t)block
{
    // 在dispatch_sync前调用[self retain]，是为了防止dispatch_sync做到一半，其他线程释放MQQDBWrapper
    [self retain];
    if (dispatch_get_specific(&_queue) != NULL) {
        // 已经在当前queue上（嵌套）
        block();
    } else {
        // 不在当前queue上
        dispatch_sync(_queue, block);
    }
    [self release];
}

- (DBJournalMode)__journalMode
{
    __block DBJournalMode mode = DBJournalModeDelete; // default
    
    [self dispatchDBQueueWithBlock:^{
        // get the journal_mode
        sqlite3 *db = [[self database] sqliteHandle];
        sqlite3_stmt *stmt = NULL;
        NSString *modeString = nil;
        int retCode = sqlite3_prepare_v2(db, "PRAGMA journal_mode;", -1, &stmt, 0);
        if (retCode == SQLITE_OK) {
            sqlite3_step(stmt);
            const char *c = (const char *)sqlite3_column_text(stmt, 0);
            if (c) {
                modeString = [NSString stringWithUTF8String:c];
            }
            sqlite3_finalize(stmt);
            stmt = NULL;
        } else {
            [[self database] handleSqliteError];
        }
        
        if (modeString.length > 0) {
            NSString *lowerModeString = [modeString lowercaseString];
            if ([lowerModeString isEqualToString:@"delete"]) {
                // DELETE
                mode = DBJournalModeDelete;
            } else if ([lowerModeString isEqualToString:@"wal"]) {
                // WAL
                mode = DBJournalModeWal;
            } else if ([lowerModeString isEqualToString:@"truncate"]) {
                // TRUNCATE
                mode = DBJournalModeTruncate;
            } else if ([lowerModeString isEqualToString:@"persist"]) {
                // PERSIST
                mode = DBJournalModePersist;
            } else if ([lowerModeString isEqualToString:@"memory"]) {
                // MEMORY
                mode = DBJournalModeMemory;
            } else if ([lowerModeString isEqualToString:@"off"]) {
                // OFF
                mode = DBJournalModeOff;
            }
        }
    }];
    
    return mode;
}

- (MQQDatabase *)database
{
    return _mDB;
}

#pragma mark - Public Methods

- (void)setIsCachedStatements:(BOOL)isCachedStatements
{
    if (_isCachedStatements != isCachedStatements) {
        [self dispatchDBQueueWithBlock:^{
            MQQDatabase *db = [self database];
            db.isCachedStatements = isCachedStatements;
        }];
    }
}

- (void)setWalAutoCheckPointLogPages:(NSUInteger)walAutoCheckPointLogPages
{
    if (_journalMode == DBJournalModeWal) {
        // 仅对wal模式
        if (_walAutoCheckPointLogPages != walAutoCheckPointLogPages) {
            __block BOOL res = NO;
            [self dispatchDBQueueWithBlock:^{
                sqlite3 *db = [[self database] sqliteHandle];
                NSString *sqlString = [NSString stringWithFormat:@"PRAGMA wal_autocheckpoint=%lu;", (unsigned long)walAutoCheckPointLogPages];
                int retCode = sqlite3_exec(db, [sqlString UTF8String], NULL, NULL, NULL);
                if (retCode == SQLITE_OK) {
                    res = YES;
                } else {
                    [[self database] handleSqliteError];
                }
            }];
            if (res) {
                // 成功设置
                _walAutoCheckPointLogPages = walAutoCheckPointLogPages;
            }
        }
    }
}

- (BOOL)walCheckPoint
{
    __block BOOL res = NO;
    [self dispatchDBQueueWithBlock:^{
        sqlite3 *db = [[self database] sqliteHandle];
        // EXEC
        int retCode = sqlite3_wal_checkpoint(db, NULL);
        /*
         int pnLog;
         int pnCkpt;
         int retCode = sqlite3_wal_checkpoint_v2(db, NULL, SQLITE_CHECKPOINT_PASSIVE, &pnLog, &pnCkpt);
         NSLog(@"pnLog  %d", pnLog);
         NSLog(@"pnCkpt %d", pnCkpt);
         */
        if (retCode == SQLITE_OK) {
            res = YES;
        }
    }];
    return res;
}

- (void)setJournalMode:(DBJournalMode)journalMode
{
    if (_journalMode != journalMode) {
        
        NSString *modeString = nil;
        if (journalMode == DBJournalModeDelete) {
            // DELETE
            modeString = @"DELETE";
        } else if(journalMode == DBJournalModeWal) {
            // WAL
            modeString = @"WAL";
        } else if(journalMode == DBJournalModeTruncate) {
            // TRUNCATE
            modeString = @"TRUNCATE";
        } else if(journalMode == DBJournalModePersist) {
            // PERSIST
            modeString = @"PERSIST";
        } else if(journalMode == DBJournalModeMemory) {
            // MEMORY
            modeString = @"MEMORY";
        } else if(journalMode == DBJournalModeOff) {
            // OFF
            modeString = @"OFF";
        }
        
        if (modeString.length > 0) {
            
            __block BOOL res = NO;
            [self dispatchDBQueueWithBlock:^{
                sqlite3 *db = [[self database] sqliteHandle];
                NSString *sqlString = [NSString stringWithFormat:@"PRAGMA journal_mode=%@;", modeString];
                // set the journal_mode
                int retCode = sqlite3_exec(db, [sqlString UTF8String], NULL, NULL, NULL);
                if (retCode == SQLITE_OK) {
                    res = YES;
                } else {
                    [[self database] handleSqliteError];
                }
            }];
            if (res) {
                // 成功设置模式
                _journalMode = journalMode;
            }
        }
    }
}

- (DBJournalMode)journalMode
{
    return _journalMode;
}

- (void)inDatabase:(void (^)(MQQDatabase *db))block
{
    [self dispatchDBQueueWithBlock:^{
        MQQDatabase *aDB = [self database];
        // EXEC
        block(aDB);
    }];
}

- (void)inTransaction:(void (^)(MQQDatabase *db, BOOL *rollback))block
{
    [self dispatchDBQueueWithBlock:^{
        MQQDatabase *aDB = [self database];
        
        BOOL shouldRollback = NO;
        // BEGIN
        [aDB execUpdate:@"begin transaction"];
        // EXEC
        block(aDB, &shouldRollback);
        
        if (shouldRollback) {
            // ROLLBACK
            [aDB execUpdate:@"rollback transaction"];
        } else {
            // COMMIT
            [aDB execUpdate:@"commit transaction"];
        }
    }];
}

@end
