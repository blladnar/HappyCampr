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
   BOOL showJoinKickMessages;
}

@property (retain) NSMutableArray *messages;
@property (assign) BOOL showJoinKickMessages;

@end
