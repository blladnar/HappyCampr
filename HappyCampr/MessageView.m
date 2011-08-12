//
//  MessageView.m
//  HappyCampr
//
//  Created by Randall Brown on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MessageView.h"
#import "NSString+FindURLs.h"

@implementation MessageView
@dynamic message;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setMessage:(Message *)aMessage
{
   message = aMessage;
   
   NSTextField *timeStampLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 60, 20)];
   [timeStampLabel setEditable:NO];
   timeStampLabel.drawsBackground = NO;
   [timeStampLabel setBordered:NO];
   [timeStampLabel setSelectable:YES];
   
   NSLog(@"%@", message.timeStamp);
   
   NSString *dateString = [message.timeStamp descriptionWithCalendarFormat:@"%I:%M" timeZone:[NSTimeZone timeZoneWithName:@"EST"] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
   
   NSLog(@"%@" ,dateString);
   
   [timeStampLabel setStringValue:dateString];   
   [self addSubview:timeStampLabel];
   
   
   
   NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(60, 0, self.frame.size.width, 20)];
   [textField setEditable:NO];
   [textField setBordered:NO];
   
   [textField setStringValue:aMessage.messageBody];
   textField.drawsBackground = NO;
   
   NSArray *linksInMessage = [aMessage.messageBody arrayOfLinks];
   if( [[linksInMessage lastObject] rangeOfString:@"youtube"].location != NSNotFound)
   {
      
      NSString *query = [[NSURL URLWithString:[linksInMessage lastObject]] query];
      NSArray *queryPairs = [query componentsSeparatedByString:@"&"];
      NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
      for (NSString *queryPair in queryPairs) 
      {
         NSArray *bits = [queryPair componentsSeparatedByString:@"="];
         if ([bits count] != 2) { continue; }
         
         NSString *key = [[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         NSString *value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         
         [pairs setObject:value forKey:key];
      }
      
      NSString* videoID = [pairs objectForKey:@"v"];
      if( videoID )
      {
         NSButton *youtubeButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 30, 150, 150)];
         [youtubeButton setTitle:[linksInMessage lastObject]];
         NSString *youtubePreviewImage = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/1.jpg",videoID];
         [youtubeButton setImage:[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:youtubePreviewImage]]];
         
         [youtubeButton setTarget:self];
         [youtubeButton setAction:@selector(pressYoutubeButton:)];
         [self addSubview:youtubeButton];
         return;
      }
   }
   
   else if( [[linksInMessage lastObject] hasSuffix:@"png"] || [[linksInMessage lastObject] hasSuffix:@"jpg"] )
   {
      NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10, 30, 150, 150)];
      [imageView setImage:[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[linksInMessage lastObject]]]];
      [self addSubview:imageView];
   }
   
   
   [self addSubview:textField];
}

-(void)pressYoutubeButton:(id)sender
{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender title]]];
}

@end
