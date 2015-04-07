//
//  AIBSQLite.h
//  activeinbox
//
//  Created by Thomas Parslow on 02/04/2015.
//


#import <RCTBridgeModule.h>

@interface AIBSQLite : NSObject <RCTBridgeModule>

- (void)openFromFilename:(NSString *)filename callback:(RCTResponseSenderBlock)callback;
- (void)closeDatabase:(NSString *)databaseId callback:(RCTResponseSenderBlock)callback;
- (void)prepareStatement: (NSString *)databaseId sql: (NSString *)sql andParams: (NSArray *)params callback: (RCTResponseSenderBlock)callback;
- (void)stepStatement:(NSString *)databaseId statementId: (NSString *) statementId callback:(RCTResponseSenderBlock)callback;
- (void)finalizeStatement:(NSString *)databaseId statementId: (NSString *) statementId callback:(RCTResponseSenderBlock)callback;

@end
