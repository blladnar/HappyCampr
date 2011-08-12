//
//  MessageTableViewController.m
//  HappyCampr
//
//  Created by Randall Brown on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MessageTableViewController.h"
#import "MessageView.h"
#import "NSString+FindURLs.h"
#import "User.h"

@implementation MessageTableViewController
@dynamic messages;
@synthesize showJoinKickMessages;
@synthesize userCache;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
   int i=0;
   
   if( !showJoinKickMessages )
   {
   
      for( Message *message in messages )
      {
         if(  ![message.messageType isEqualToString:@"KickMessage"] && ![message.messageType isEqualToString:@"EnterMessage"] && ![message.messageType isEqualToString:@"LeaveMessage"] )
         {
            i++;
         }
      }
   
      NSLog(@"Number of rows in tableview %i",i);
      return i; 
   }
   
   return [messagesToShow count];
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
   MessageView *view = [[MessageView alloc] initWithFrame:NSMakeRect(0, 0, tableView.frame.size.width, 20)];
   
   view.emphasized = row%2 == 0;
   
   Message *message = [messagesToShow objectAtIndex:row];
      message.userName = [self usernameForID:message.userID];
   
   view.message = message;
   NSLog(@"%i %@", row, message.messageBody );
   return view;

}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
   return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
   Message *message = [messagesToShow objectAtIndex:row];

   NSArray *linksInMessage = [message.messageBody arrayOfLinks];
   
   for( NSString* link in linksInMessage )
   {
      NSRange range = [link rangeOfString:@"youtube"];
      if( [link hasSuffix:@"png"] || [link hasSuffix:@"jpg"] || [link rangeOfString:@"youtube"].location != NSNotFound)
      {
         return 200;
      }
   }
   
   MessageView *view = [[MessageView alloc] initWithFrame:NSMakeRect(0, 0, tableView.frame.size.width, 20)];
   message.userName = @"";
   view.message = message;
   
   return view.frame.size.height + 5;
}

-(void)setMessages:(NSMutableArray *)theMessages
{
   messages = [theMessages retain];
   [messagesToShow removeAllObjects];
   if( !showJoinKickMessages )
   {
      if( !messagesToShow )
      {
         messagesToShow = [[NSMutableArray alloc] init];
      }
      
      for( Message *message in messages )
      {
         if(  ![message.messageType isEqualToString:@"KickMessage"] && ![message.messageType isEqualToString:@"EnterMessage"] && ![message.messageType isEqualToString:@"LeaveMessage"] )
         {
            [messagesToShow addObject:message];
         }
      }
   }
   else
   {
      messagesToShow = messages;
   }
   NSLog(@"%@", messagesToShow);
}

-(NSString*)usernameForID:(NSInteger)userID
{
   for( User *user in userCache )
   {
      if (userID == user.userID ) 
      {
         return user.name;
      }
   }
   return @"";
}

@end