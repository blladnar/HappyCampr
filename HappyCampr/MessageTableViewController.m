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

@implementation MessageTableViewController
@synthesize messages;

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
   return [messages count];
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
   MessageView *view = [[MessageView alloc] initWithFrame:NSMakeRect(0, 0, tableView.frame.size.width, 20)];
   
   view.emphasized = row%2 == 0;
   
   view.message = [messages objectAtIndex:row];
   
   return view;

}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
   return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
   Message *message = [messages objectAtIndex:row];

   NSArray *linksInMessage = [message.messageBody arrayOfLinks];
   
   for( NSString* link in linksInMessage )
   {
      NSRange range = [link rangeOfString:@"youtube"];
      if( [link hasSuffix:@"png"] || [link hasSuffix:@"jpg"] || [link rangeOfString:@"youtube"].location != NSNotFound)
      {
         return 200;
      }
   }
   
   
   
   return 30;
}

@end
