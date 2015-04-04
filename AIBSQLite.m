//
//  AIBSQLite.m
//  activeinbox
//
//  Created by Thomas Parslow on 02/04/2015.
//

#import "AIBSQLite.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import <Foundation/Foundation.h>
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

#import <sqlite3.h>

// From RCTAsyncLocalStorage, make a queue so we can serialise our interactions
static dispatch_queue_t AIBSQLiteQueue(void)
{
    static dispatch_queue_t sqliteQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // All JS is single threaded, so a serial queue is our only option.
        sqliteQueue = dispatch_queue_create("com.activeinboxhq.sqlite", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(sqliteQueue,
                                  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    });

    return sqliteQueue;
}



@implementation AIBSQLite
{
    NSMutableDictionary *openDatabases;
    int nextId;
}

@synthesize bridge = _bridge;

- (id) init
{
    self = [super init];
    if (self) {
        openDatabases = [NSMutableDictionary dictionaryWithCapacity: 1];
        nextId = 0;
    }
    return self;
}

- (void)openFromFilename:(NSString *)filename callback:(RCTResponseSenderBlock)callback
{
    RCT_EXPORT();

    if (!callback) {
        RCTLogError(@"Called openFromFilename without a callback.");
        return;
    }
    dispatch_async(AIBSQLiteQueue(), ^{
        // TODO: Allow creation of database in Library or tmp
        // directories. Maybe also add an option to open read-only
        // direct from the bundle.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:filename];

        if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
          // If the db file doesn't exist in the documents directory
          // but it does exist in the bundle then copy it over now
          NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
          NSError *error;
          if ([[NSFileManager defaultManager] fileExistsAtPath:sourcePath]) {
            [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:dbPath error:&error];
            if (error != nil) {
              callback(@[[error localizedDescription], [NSNull null]]);
            }
          }
        }

        sqlite3 *db;
        BOOL openDatabaseResult = sqlite3_open([dbPath UTF8String], &db);
        if(openDatabaseResult != SQLITE_OK) {
          callback(@[@"Couldn't open database", [NSNull null]]);
          return;
        }
        NSString *databaseId = [[NSNumber numberWithInt: nextId++] stringValue];
        [openDatabases setValue:[NSValue valueWithPointer:db] forKey:databaseId];
        callback(@[[NSNull null], databaseId]);
      });
}

- (void)closeDatabase:(NSString *)databaseId callback:(RCTResponseSenderBlock)callback
{
    RCT_EXPORT();

    if (!callback) {
        RCTLogError(@"Called openFromFilename without a callback.");
        return;
    }
    dispatch_async(AIBSQLiteQueue(), ^{
        NSValue *database = [openDatabases valueForKey:databaseId];
        if (database == nil) {
            callback(@[@"No open database found"]);
            return;
        }
        sqlite3 *db = (sqlite3*) [database pointerValue];
        sqlite3_close(db);
        [openDatabases removeObjectForKey: databaseId];
        callback(@[[NSNull null]]);
    });
}

- (void)execOnDatabase:(NSString *)databaseId withSQL: (NSString *)sql andParams: (NSArray *)params rowEvent: (NSString *) rowEvent callback:(RCTResponseSenderBlock)callback
{
    RCT_EXPORT();

    if (!callback) {
        RCTLogError(@"Called openFromFilename without a callback.");
    }

    dispatch_async(AIBSQLiteQueue(), ^{
        NSValue *database = [openDatabases valueForKey:databaseId];
        if (database == nil) {
            callback(@[@"No open database found", [NSNull null]]);
            return;
        }
        sqlite3 *db = (sqlite3*) [database pointerValue];
        sqlite3_stmt *stmt;

        int rc = sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, NULL);
        if (rc != SQLITE_OK) {
            callback(@[[NSString stringWithUTF8String:sqlite3_errmsg(db)]]);
            return;
        }

        for (int i=0; i < [params count]; i++){
            NSObject *param = [params objectAtIndex: i];
            if ([param isKindOfClass: [NSString class]]) {
                NSString *str = (NSString*) param;
                int strLength = (int) [str lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
                sqlite3_bind_text(stmt, i+1, [str UTF8String], strLength, SQLITE_TRANSIENT);
            } else if ([param isKindOfClass: [NSNumber class]]) {
                sqlite3_bind_double(stmt, i+1, [(NSNumber *)param doubleValue]);
            } else if ([param isKindOfClass: [NSNull class]]) {
                sqlite3_bind_null(stmt, i+1);
            } else {
                sqlite3_finalize(stmt);
                callback(@[@"Parameters must be either numbers or strings" ]);
                return;
            }
        }

        while(1) {
            rc = sqlite3_step(stmt);
            if (rc == SQLITE_ROW) {
                int totalColumns = sqlite3_column_count(stmt);
                NSMutableDictionary *rowData = [NSMutableDictionary dictionaryWithCapacity: totalColumns];
                // Go through all columns and fetch each column data.
                for (int i=0; i<totalColumns; i++){
                    // Convert the column data to text (characters).

                    NSObject *value;
                    NSData *data;
                    switch (sqlite3_column_type(stmt, i)) {
                        case SQLITE_INTEGER:
                            value = [NSNumber numberWithLongLong: sqlite3_column_int64(stmt, i)];
                            break;
                        case SQLITE_FLOAT:
                            value = [NSNumber numberWithDouble: sqlite3_column_double(stmt, i)];
                            break;
                        case SQLITE_NULL:
                            value = [NSNull null];
                            break;
                        case SQLITE_BLOB:
                            sqlite3_finalize(stmt);
                            // TODO: How should we support blobs? Maybe base64 encode them?
                            callback(@[@"BLOBs not supported" ]);
                            return;
                            break;
                        case SQLITE_TEXT:
                        default:
                            data = [NSData dataWithBytes: sqlite3_column_blob(stmt, i) length: sqlite3_column_bytes16(stmt, i)];
                            value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            break;
                    }
                    char *columnName = (char *)sqlite3_column_name(stmt, i);
                    // Convert the characters to string.
                    [rowData setValue: value forKey: [NSString stringWithUTF8String: columnName]];
                }
                [_bridge.eventDispatcher sendDeviceEventWithName:rowEvent
                                                            body:rowData];
            } else if (rc == SQLITE_DONE) {
                callback(@[[NSNull null]]);
                break;
            } else {
                callback(@[[NSString stringWithUTF8String:sqlite3_errmsg(db)]]);
                break;
            }
        }
        sqlite3_finalize(stmt);
    });

}

@end
