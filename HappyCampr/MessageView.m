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
#import "ASIHTTPRequest.h"
#import "SFHFKeychainUtils.h"
#import "HappyCamprAppDelegate.h"
#import "NSTextView+AutomaticLinkDetection.h"

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

-(Message*)message
{
   return message;
}

-(void)getUserNameFromInternetWithID:(NSInteger)userID
{
   NSString *urlString = [NSString stringWithFormat:@"https://randallbrown.campfirenow.com/users/%i.xml", userID];
   NSError* error;
   
   NSString *campfireAuthCode = [[SFHFKeychainUtils getPasswordForUsername:@"HappyCampr" andServiceName:@"HappyCampr:AuthToken" error:&error] retain];
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   
   [request addRequestHeader:@"Content-Type" value:@"application/xml"];
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:campfireAuthCode];
   [request setPassword:@"X"];
   
   [campfireAuthCode release];
   
   [request setCompletionBlock:^{
      NSString *responseString = [request responseString];
      
      NSXMLDocument *responseDoc = [[[NSXMLDocument alloc] initWithXMLString:responseString options:NSXMLDocumentTidyXML error:nil] autorelease];
      NSArray *userElement = [responseDoc rootElement];

      
      NSString *userName = [[[userElement elementsForName:@"name"] lastObject] stringValue];
      User *user = [[User new] autorelease];
      user.userID = [[[[userElement elementsForName:@"id"] lastObject] stringValue] intValue];
      user.name = [[[userElement elementsForName:@"name"] lastObject] stringValue];
      user.email = [[[userElement elementsForName:@"email-address"] lastObject] stringValue];
      user.avatarURL = [[[userElement elementsForName:@"avatar-url"] lastObject] stringValue];      
      self.message.userName = userName;
      
      [[[NSApplication sharedApplication] delegate] addUserToCache:user];
      
      if( userName )
      {
         [usernameField setStringValue:userName];
      }
      
   }];
   
   [request startAsynchronous];  
}

-(void)setMessage:(Message *)aMessage
{
   message = aMessage;
   
   NSTextField *timeStampLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 40, 20)] autorelease];
   [timeStampLabel setEditable:NO];
   timeStampLabel.drawsBackground = NO;
   [timeStampLabel setBordered:NO];
   [timeStampLabel setSelectable:YES];

   NSDate *offsetTimestamp = message.timeStamp;
   NSTimeInterval gmtOffset = [[NSTimeZone localTimeZone] secondsFromGMT];
   offsetTimestamp = [offsetTimestamp dateByAddingTimeInterval:gmtOffset];
   
   NSString *dateString = [offsetTimestamp descriptionWithCalendarFormat:@"%I:%M" timeZone:[NSTimeZone localTimeZone] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
   
   
   [timeStampLabel setStringValue:dateString];   
   [self addSubview:timeStampLabel];
   
    usernameField = [[NSTextField alloc] initWithFrame:NSMakeRect(40, 0, 60, 20)];
   [usernameField setEditable:NO];
   [usernameField setBordered:NO];
   usernameField.drawsBackground = NO;   
   
   NSString *userName = message.userName;
   
   if( ![userName length] )
   {
      userName = [[[NSApplication sharedApplication] delegate] usernameForID:message.messageId];
   }
   
   if( ![userName length])
   {
      [self getUserNameFromInternetWithID:aMessage.userID];
   }
   
   [usernameField setStringValue:userName];
   
   
   NSTextView *textView = [[[NSTextView alloc] initWithFrame:NSMakeRect(100, 0, self.frame.size.width - 115, 40)] autorelease];
   NSInteger height = [aMessage.messageBody heightForWidth:self.frame.size.width-115 font:[textView font]];
   textView.frame = NSMakeRect(100, 0, self.frame.size.width - 115, height);
   [textView setDrawsBackground:NO];
   [textView setEditable:NO];

   self.frame = NSMakeRect(0, 0, self.frame.size.width, height);
   
   [textView setString:aMessage.messageBody];
   [textView detectAndAddLinks];
   
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
         NSButton *youtubeButton = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 30, 150, 150)] autorelease];
         [youtubeButton setTitle:[linksInMessage lastObject]];
         NSString *youtubePreviewImage = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/1.jpg",videoID];
         [youtubeButton setImage:[[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:youtubePreviewImage]] autorelease]];
         
         [youtubeButton setTarget:self];
         [youtubeButton setAction:@selector(pressYoutubeButton:)];
         [self addSubview:youtubeButton];
         return;
      }
   }
   
   else if( [[linksInMessage lastObject] linkIsImage] )
   {
      NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(10, 30, 150, 150)] autorelease];
      [imageView setImage:[[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[linksInMessage lastObject]]] autorelease]];
      [self addSubview:imageView];
   }
   
   [self addSubview:usernameField];
}

-(void)pressYoutubeButton:(id)sender
{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender title]]];
}

@end
