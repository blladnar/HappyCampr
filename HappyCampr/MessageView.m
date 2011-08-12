//
//  MessageView.m
//  HappyCampr
//
//  Created by Randall Brown on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MessageView.h"
#import "NSString+FindURLs.h"
#import "NS(Attributed)String+Geometrics.h"

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
   
   NSTextField *timeStampLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 40, 20)];
   [timeStampLabel setEditable:NO];
   timeStampLabel.drawsBackground = NO;
   [timeStampLabel setBordered:NO];
   [timeStampLabel setSelectable:YES];

   NSString *dateString = [message.timeStamp descriptionWithCalendarFormat:@"%I:%M" timeZone:[NSTimeZone localTimeZone] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
   
   
   [timeStampLabel setStringValue:dateString];   
   [self addSubview:timeStampLabel];
   
   NSTextField *usernameField = [[NSTextField alloc] initWithFrame:NSMakeRect(40, 0, 60, 20)];
   [usernameField setEditable:NO];
   [usernameField setBordered:NO];
   [usernameField setStringValue:aMessage.userName];
   usernameField.drawsBackground = NO;   
   
   
   NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(100, 0, self.frame.size.width - 115, 40)];
   NSInteger height = [aMessage.messageBody heightForWidth:self.frame.size.width-115 font:[textView font]];
   textView.frame = NSMakeRect(100, 0, self.frame.size.width - 115, height);
   [textView setDrawsBackground:NO];
   [textView setEditable:NO];
   self.frame = NSMakeRect(0, 0, self.frame.size.width, height);
   
   [textView setString:aMessage.messageBody];
   
   [self addSubview:textView];
   
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
   
   [self addSubview:usernameField];
}

-(void)pressYoutubeButton:(id)sender
{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender title]]];
}

@end
