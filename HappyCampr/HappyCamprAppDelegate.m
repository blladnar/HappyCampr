//
//  HappyCamprAppDelegate.m
//  HappyCampr
//
//  Created by Brown, Randall on 7/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HappyCamprAppDelegate.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Room.h"
#import "ScreencastProxy.h"

@implementation HappyCamprAppDelegate
@synthesize messageField;

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   NSString *screencastURL = @"http://www.screencast.stage/api/rest.ashx";
   NSString *testRunnerAPIKey = @"0bbfcdfb-3640-495b-80de-4acd36babbc1";
   NSString *testRunnerSecretKey = @"167e3ebd-7bbd-4e8b-b7a9-0b11aa276924";
   
   scCommunicator = [[ScreencastProxy alloc] initWithURL:[NSURL URLWithString:screencastURL] apiKey:testRunnerAPIKey secretKey:testRunnerSecretKey];   
   
   rooms = [NSMutableArray new];
   screencastFolders = [NSMutableArray new];
   
   
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"https://bravoteam.campfirenow.com/rooms.xml"]];
   
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:@"e5a0a21c647ad0977f3f2a34dc9b67044184a991"];
   [request setPassword:@"X"];
   
   [request setCompletionBlock:^{
      // Use when fetching text data
      NSString *responseString = [request responseString];
      
      NSXMLDocument *responseDoc = [[NSXMLDocument alloc] initWithXMLString:responseString options:NSXMLDocumentTidyXML error:nil];
      
      NSArray *roomElements = [[responseDoc rootElement] elementsForName:@"room"];
      
      for( NSXMLElement *roomElement in roomElements )
      {
         Room *room = [Room new];
         
         room.roomID = [[[roomElement elementsForName:@"id"] lastObject] stringValue];
         room.name = [[[roomElement elementsForName:@"name"] lastObject] stringValue];
         room.topic = [[[roomElement elementsForName:@"topic"] lastObject] stringValue];
         
         [roomPicker addItemWithTitle:room.name];
         
         [rooms addObject:room];
      }
      
      NSLog(@"%@", rooms);
      
   }];
   
   [request startAsynchronous];
   
   // Insert code here to initialize your application
}

-(void)dealloc
{
   [rooms release];
   
}

- (IBAction)roomPicked:(id)sender 
{
   NSLog(@"%@", [rooms objectAtIndex:[roomPicker indexOfSelectedItem]]);
}

-(NSString*)messageWithType:(NSString*)messageType andMessage:(NSString*)message
{
   return [NSString stringWithFormat:@"<message><type>%@</type><body>%@</body></message>", messageType, message];
}

- (IBAction)sendMessage:(id)sender 
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   
   NSString *urlString = [NSString stringWithFormat:@"https://bravoteam.campfirenow.com/room/%@/speak.xml",roomID];
   
   
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   
   [request addRequestHeader:@"Content-Type" value:@"application/xml"];
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:@"e5a0a21c647ad0977f3f2a34dc9b67044184a991"];
   [request setPassword:@"X"];
   
   NSString *postBody = [self messageWithType:@"TextMessage" andMessage:[messageField stringValue]];

   [request setPostBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
   
   [request setCompletionBlock:^{
      NSLog(@"%@", [request responseString]);
   }];
   
   [request startAsynchronous];
    
    
}

- (IBAction)screencastLogin:(id)sender 
{   
   screencastAuthCode = [[scCommunicator loginWithEmail:@"r.brown@techsmith.com" andPassword:@"stuff" error:nil] retain];
   
   NSDictionary *mediaGroupList = [scCommunicator mediaGroupListWithAuthCode:screencastAuthCode error:nil];
   NSLog(@"%@", mediaGroupList);
   
   for( NSString* key in [mediaGroupList allKeys] )
   {
      [screencastFolders addObject:[mediaGroupList objectForKey:key]];
      [folderPicker addItemWithTitle:key];
   }
   
}

- (IBAction)getFolderContents:(id)sender 
{
  NSArray *mediaSets = [scCommunicator getInfoAboutMediaGroup:[screencastFolders objectAtIndex:[folderPicker indexOfSelectedItem]] authCode:screencastAuthCode error:nil];
   
   for( NSDictionary *mediaSet in mediaSets )
   {
      NSError *error;
      NSLog(@"%@", [scCommunicator getInfoAboutMediaSet:[mediaSet objectForKey:@"mediaSetGuid"] mediaGroupId:[screencastFolders objectAtIndex:[folderPicker indexOfSelectedItem]] authCode:screencastAuthCode error:&error]);
      NSLog(@"%@", error);
   }
   
   
   
}


-(void)sendSoundMessageWithSound:(NSString*)sound
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   
   NSString *urlString = [NSString stringWithFormat:@"https://bravoteam.campfirenow.com/room/%@/speak.xml",roomID];
   
   
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   
   [request addRequestHeader:@"Content-Type" value:@"application/xml"];
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:@"e5a0a21c647ad0977f3f2a34dc9b67044184a991"];
   [request setPassword:@"X"];
   
   NSString *postBody = [self messageWithType:@"SoundMessage" andMessage:sound];
   
   [request setPostBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
   
   [request setCompletionBlock:^{
      NSLog(@"%@", [request responseString]);
   }];
   
   [request startAsynchronous];
}

- (IBAction)theMoreYouKnowSound:(id)sender 
{
   [self sendSoundMessageWithSound:@"tmyk"];
}

- (IBAction)rimShotSound:(id)sender 
{
   [self sendSoundMessageWithSound:@"rimshot"];
}

- (IBAction)sadTromboneSound:(id)sender 
{
   [self sendSoundMessageWithSound:@"trombone"];
}

- (IBAction)crickets:(id)sender 
{
   [self sendSoundMessageWithSound:@"crickets"];
}

- (IBAction)doItLiveSound:(id)sender 
{
   [self sendSoundMessageWithSound:@"live"];
}

- (IBAction)greatJobSound:(id)sender 
{
   [self sendSoundMessageWithSound:@"greatjob"];
}

- (IBAction)vuvuzelaSound:(id)sender 
{
   [self sendSoundMessageWithSound:@"vuvuzela"];
}

@end
