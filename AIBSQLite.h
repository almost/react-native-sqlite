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
- (void)execOnDatabase:(NSString *)databaseId withSQL: (NSString *)sql andParams: (NSArray *)params rowEvent: (NSString *) rowEvent callback:(RCTResponseSenderBlock)callback;

@end
