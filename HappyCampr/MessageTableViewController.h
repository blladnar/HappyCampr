//
//  MessageTableViewController.h
//  HappyCampr
//
//  Created by Randall Brown on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageTableViewController : NSObject<NSTableViewDelegate,NSTableViewDataSource>
{
   NSMutableArray *messages;
   NSMutableArray *messagesToShow;
   NSMutableArray *userCache;
   BOOL showJoinKickMessages;
}

@property (retain) NSMutableArray *messages;
@property (retain) NSMutableArray *userCache;
@property (assign) BOOL showJoinKickMessages;

-(NSString*)usernameForID:(NSInteger)userID;
@end
