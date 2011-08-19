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
#import "SFHFKeychainUtils.h"
#import "Message.h"
#import "User.h"
#import "RoboRule.h"
#import "TaskMaster.h"

void NSLogRect(NSRect rect)
{
   NSLog(@"%f %f %f %f",rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

@implementation HappyCamprAppDelegate
@synthesize messageField;

@synthesize window;

-(void)applicationWillBecomeActive:(NSNotification *)notification
{
   NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
   [tile setBadgeLabel:nil];
   numberOfUnreadMessages = 0;
}

-(void)processRoboRulesAgainstMessages:(NSArray*)theMessages
{
   for( RoboRule *rule in [rulesController rules] )
   {
      for( Message *message in theMessages )
      {
         if( !NSEqualRanges([message.messageBody rangeOfString:rule.trigger], NSMakeRange(NSNotFound, 0)) )
         {
            TaskMaster *master = [[TaskMaster alloc] initWithTaskString:rule.response];
            [master executeTaskWithCompletionHandler:^(NSString *response)
             {
                [self sendTextMessage:response];
             }];
            
         }
      }
   }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   [[NSApplication sharedApplication] setPresentationOptions:NSFullScreenWindowMask];
   [[self window] setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary | NSWindowCollectionBehaviorFullScreenAuxiliary];
  // [[self window] setCollectionBehavior:NSWindowCollectionBehaviorFullScreenAuxiliary];
   NSString *screencastURL = @"http://www.screencast.stage/api/rest.ashx";
   NSString *testRunnerAPIKey = @"0bbfcdfb-3640-495b-80de-4acd36babbc1";
   NSString *testRunnerSecretKey = @"167e3ebd-7bbd-4e8b-b7a9-0b11aa276924";
   initialMessageLoad = YES;
 
    popover = [[UserPopoverController alloc] initWithNibName:@"UserPopoverController" bundle:nil];
   lastMessageID = 0;
   numberOfUnreadMessages = 0;
   
   allMessages = [NSMutableArray new];
   userCache = [NSMutableArray new];
   roboRules = [NSMutableArray new];
   
   RoboRule *rule1 = [[RoboRule alloc] initWithTrigger:@"hello" andResponse:@"http://2pep.com/funny%20pics/funny%20hilarious/super_funny_hilarious_pictures_crazy_fun_laughing_cute_kittens-4089.jpg"];
   [roboRules addObject:rule1];
   
   scCommunicator = [[ScreencastProxy alloc] initWithURL:[NSURL URLWithString:screencastURL] apiKey:testRunnerAPIKey secretKey:testRunnerSecretKey];   
   
   rooms = [NSMutableArray new];
   screencastFolders = [NSMutableArray new];
   
   NSError *error;
   campfireAuthCode = [[SFHFKeychainUtils getPasswordForUsername:@"HappyCampr" andServiceName:@"HappyCampr:AuthToken" error:&error] retain];
   
   if( campfireAuthCode )
   {
      __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"https://bravoteam.campfirenow.com/rooms.xml"]];
      
      [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
      [request setUsername:campfireAuthCode];
      [request setPassword:@"X"];
      [request setFailedBlock:^{
         NSLog(@"%@", request.error);
      }];
      [request setCompletionBlock:^{
         [saveAuthButton setTitle:@"Sign Out"];
         // Use when fetching text data
         NSString *responseString = [request responseString];
         
         NSXMLDocument *responseDoc = [[[NSXMLDocument alloc] initWithXMLString:responseString options:NSXMLDocumentTidyXML error:nil] autorelease];
         
         NSArray *roomElements = [[responseDoc rootElement] elementsForName:@"room"];
         
         for( NSXMLElement *roomElement in roomElements )
         {
            Room *room = [[Room new] autorelease];
            
            room.roomID = [[[roomElement elementsForName:@"id"] lastObject] stringValue];
            room.name = [[[roomElement elementsForName:@"name"] lastObject] stringValue];
            room.topic = [[[roomElement elementsForName:@"topic"] lastObject] stringValue];
            
            [roomPicker addItemWithTitle:room.name];
            
            [rooms addObject:room];
         }
         
      //   NSLog(@"%@", rooms);
         NSError *error;
         [SFHFKeychainUtils storeUsername:@"HappyCampr" andPassword:campfireAuthCode forServiceName:@"HappyCampr:AuthToken" updateExisting:YES error:&error];
         [apiField setHidden:YES];
      //  NSLog(@"%i", [[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedRoom"]);
         [roomPicker selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedRoom"]];
         [self roomPicked:nil];
         [[NSUserDefaults standardUserDefaults] synchronize];
         
      }];
      
      [request startAsynchronous];   
      
   }
   
   
   // Insert code here to initialize your application
}

-(void)dealloc
{
   [rooms release];
   
}

- (IBAction)roomPicked:(id)sender 
{
   initialMessageLoad = YES;
  // NSLog(@"%@", [rooms objectAtIndex:[roomPicker indexOfSelectedItem]]);
   [[NSUserDefaults standardUserDefaults] setInteger:[roomPicker indexOfSelectedItem] forKey:@"SelectedRoom"];
   [[NSUserDefaults standardUserDefaults] synchronize];
   
   lastMessageID = 0;
   [allMessages removeAllObjects];
   [self getMessagesForSelectedRoom];
   [self getUsersForSelectedRoom];
   [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(getMessagesForSelectedRoom) userInfo:nil repeats:YES];
   
   if( [stealModeCheckBox state] == NSOffState )
   {
      NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
      
      NSString *urlString = [NSString stringWithFormat:@"https://bravoteam.campfirenow.com/room/%@/join.xml",roomID];
      
      __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
      
      [request addRequestHeader:@"Content-Type" value:@"application/xml"];
      [request setPostBody:[@"<hello/>" dataUsingEncoding:NSUTF8StringEncoding]];
      [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
      [request setUsername:campfireAuthCode];
      [request setPassword:@"X"];
      
      [request setCompletionBlock:^{
        // NSString *responseString = [request responseString];
     //    NSLog(@"%@", responseString);
     //    NSLog(@"%i", request.responseStatusCode);
         
      }];
      
      [request startAsynchronous];  
      
      if( [oldRoomId length] )
      {
         NSString *urlString2 = [NSString stringWithFormat:@"https://bravoteam.campfirenow.com/room/%@/leave.xml",oldRoomId];
         
         __block ASIHTTPRequest *leaveRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString2]];
         
         [leaveRequest addRequestHeader:@"Content-Type" value:@"application/xml"];
         [leaveRequest setPostBody:[@"<hello/>" dataUsingEncoding:NSUTF8StringEncoding]];
         [leaveRequest setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
         [leaveRequest setUsername:campfireAuthCode];
         [leaveRequest setPassword:@"X"];
         
         [leaveRequest setCompletionBlock:^{
         //   NSString *responseString = [request responseString];
        //    NSLog(@"%@", responseString);
        //    NSLog(@"%i", request.responseStatusCode);
            
         }];
         
         [leaveRequest startAsynchronous];   
      }
      
      oldRoomId = [roomID retain];

   }
   
}

-(void)getUsersForSelectedRoom
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   
   NSString *urlString = [NSString stringWithFormat:@"https://bravoteam.campfirenow.com/room/%@.xml",roomID];
   
   usersInRoom = [[NSMutableArray alloc] init];
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   
   [request addRequestHeader:@"Content-Type" value:@"application/xml"];
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:campfireAuthCode];
   [request setPassword:@"X"];
   
   [request setCompletionBlock:^{
      NSString *responseString = [request responseString];
   //   NSLog(@"%@", responseString);
      
      NSXMLDocument *responseDoc = [[[NSXMLDocument alloc] initWithXMLString:responseString options:NSXMLDocumentTidyXML error:nil] autorelease];
      
      NSArray *userElements = [[[[responseDoc rootElement] elementsForName:@"users"] lastObject] elementsForName:@"user"];
      
      for( NSXMLElement *userElement in userElements )
      {
         User *user = [[User new] autorelease];
         user.userID = [[[[userElement elementsForName:@"id"] lastObject] stringValue] intValue];
         user.name = [[[userElement elementsForName:@"name"] lastObject] stringValue];
         user.email = [[[userElement elementsForName:@"email-address"] lastObject] stringValue];
         user.avatarURL = [[[userElement elementsForName:@"avatar-url"] lastObject] stringValue];
         
         [usersInRoom addObject:user];
         
      }
      
      [userCache addObjectsFromArray:usersInRoom];
      
      [userTableView reloadData];
      
   }];
   
   [request startAsynchronous];      
}

-(void)getMessagesForSelectedRoom
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   
   NSString *urlString = [NSString stringWithFormat:@"https://bravoteam.campfirenow.com/room/%@/recent.xml?since_message_id=%i",roomID, lastMessageID];
   
   messages = [[NSMutableArray alloc] init];
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   
   [request addRequestHeader:@"Content-Type" value:@"application/xml"];
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:campfireAuthCode];
   [request setPassword:@"X"];
   
   [request setCompletionBlock:^{

      NSString *responseString = [request responseString];

      NSXMLDocument *responseDoc = [[[NSXMLDocument alloc] initWithXMLString:responseString options:NSXMLDocumentTidyXML error:nil] autorelease];
      
      NSArray *messageElements = [[responseDoc rootElement] elementsForName:@"message"];
      
      [messages removeAllObjects];
      
      int newMessageCount = 0;
      for( NSXMLElement *messageElement in messageElements )
      {
         Message *message = [[Message new] autorelease];
         
         message.messageId = [[[[messageElement elementsForName:@"id"] lastObject] stringValue] intValue];
         
         NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
         [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
         [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
         message.timeStamp = [dateFormatter dateFromString:[[[messageElement elementsForName:@"created-at"] lastObject] stringValue]];
         message.roomID = [[[[messageElement elementsForName:@"room-id"] lastObject] stringValue] intValue];
         message.userID = [[[[messageElement elementsForName:@"user-id"] lastObject] stringValue] intValue];
         message.messageBody = [[[messageElement elementsForName:@"body"] lastObject] stringValue];
         message.messageType = [[[messageElement elementsForName:@"type"] lastObject] stringValue];
         
      //   NSLog(@"%@", message.messageType);
         // ![message.messageType isEqualToString:@"KickMessage"] && ![message.messageType isEqualToString:@"EnterMessage"]
         if( ![message.messageType isEqualToString:@"TimestampMessage"] )
         {
            if( ![message.messageType isEqualToString:@"KickMessage"] && ![message.messageType isEqualToString:@"EnterMessage"] && ![message.messageType isEqualToString:@"LeaveMessage"] )
            {
               newMessageCount++;
            }
            [messages addObject:message];
         }
      }
      
      if( [[messages lastObject] messageId] > lastMessageID )
      {
         lastMessageID = [[messages lastObject] messageId];
      }
      
      if( !initialMessageLoad )
      {
         [self processRoboRulesAgainstMessages:messages];
      }
      else
      {
         initialMessageLoad = NO;
      }
      
      [allMessages addObjectsFromArray:messages];
      messageTableController.showJoinKickMessages = [showEnterMessageCheckbox state] == NSOnState;
      messageTableController.messages = allMessages;
      
      BOOL scrollDown = NO;
      if( [messageView visibleRect].origin.y + [messageView visibleRect].size.height == messageView.bounds.size.height )
      {
         scrollDown = YES;
      }
      
      [messageView reloadData];
     
      if( scrollDown )
      {
         [messageView scrollToEndOfDocument:nil];
      }
      

      
      if( newMessageCount )
      {
         
         if( ![[NSApplication sharedApplication] isActive] )
         {
            NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
            numberOfUnreadMessages += [messages count];
            
            [tile setBadgeLabel:[NSString stringWithFormat:@"%i", newMessageCount]];
            [[NSApplication sharedApplication] requestUserAttention:NSInformationalRequest];
         }
      }
   }];
   
   [request startAsynchronous];   
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

-(NSString*)messageWithType:(NSString*)messageType andMessage:(NSString*)message
{
   return [NSString stringWithFormat:@"<message><type>%@</type><body>%@</body></message>", messageType, message];
}

-(void)sendTextMessage:(NSString*)text
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   
   NSString *urlString = [NSString stringWithFormat:@"https://bravoteam.campfirenow.com/room/%@/speak.xml",roomID];
   
   
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   
   [request addRequestHeader:@"Content-Type" value:@"application/xml"];
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:campfireAuthCode];
   [request setPassword:@"X"];
   
   NSString *postBody = [self messageWithType:@"TextMessage" andMessage:text];
   
   [request setPostBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
   
   [request setCompletionBlock:^{
      //  NSLog(@"%@", [request responseString]);
   }];
   
   [request startAsynchronous];
}

- (IBAction)openMacrosWindow:(id)sender 
{
   [macrosWindow makeKeyAndOrderFront:sender];
}

- (IBAction)sendMessage:(id)sender 
{
   NSString *longMessage = [macrosController processMacrosWithMessage:[messageField stringValue]];
   
   
   if( longMessage )
   {
      TaskMaster *master = [[TaskMaster alloc] initWithTaskString:longMessage];
      [master executeTaskWithCompletionHandler:^(NSString *response)
       {
          [self sendTextMessage:response];
       }];
   }
   else
   {
      TaskMaster *master = [[TaskMaster alloc] initWithTaskString:[messageField stringValue]];
      [master executeTaskWithCompletionHandler:^(NSString *response)
       {
          [self sendTextMessage:response];
       }];  
   }
   [messageField setStringValue:@""];
    
}

- (IBAction)screencastLogin:(id)sender 
{   
   NSError *error;
   screencastAuthCode = [[scCommunicator loginWithEmail:@"r.brown@techsmith.com" andPassword:@"stuff" error:&error] retain];
   
   NSDictionary *mediaGroupList = [scCommunicator mediaGroupListWithAuthCode:screencastAuthCode error:nil];
 //  NSLog(@"%@", mediaGroupList);
   
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
   [request setUsername:campfireAuthCode];
   [request setPassword:@"X"];
   
   NSString *postBody = [self messageWithType:@"SoundMessage" andMessage:sound];
   
   [request setPostBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
   
   [request setCompletionBlock:^{
   //   NSLog(@"%@", [request responseString]);
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

- (IBAction)saveAuthToken:(id)sender 
{
   if( [campfireAuthCode length] )
   {
      [saveAuthButton setTitle:@"Save"];
      campfireAuthCode = @"";
      [apiField setHidden:NO];
      [roomPicker removeAllItems];
      NSError *error;
      [SFHFKeychainUtils storeUsername:@"HappyCampr" andPassword:campfireAuthCode forServiceName:@"HappyCampr:AuthToken" updateExisting:YES error:&error];
   }
   else
   {
      [saveAuthButton setTitle:@"Sign Out"];
      campfireAuthCode = [[apiField stringValue] retain];
      
      __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"https://bravoteam.campfirenow.com/rooms.xml"]];
      
      [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
      [request setUsername:campfireAuthCode];
      [request setPassword:@"X"];
      
      [request setCompletionBlock:^{
         // Use when fetching text data
         NSString *responseString = [request responseString];
         
         NSXMLDocument *responseDoc = [[[NSXMLDocument alloc] initWithXMLString:responseString options:NSXMLDocumentTidyXML error:nil] autorelease];
         
         NSArray *roomElements = [[responseDoc rootElement] elementsForName:@"room"];
         
         for( NSXMLElement *roomElement in roomElements )
         {
            Room *room = [[Room new] autorelease];
            
            room.roomID = [[[roomElement elementsForName:@"id"] lastObject] stringValue];
            room.name = [[[roomElement elementsForName:@"name"] lastObject] stringValue];
            room.topic = [[[roomElement elementsForName:@"topic"] lastObject] stringValue];
            
            [roomPicker addItemWithTitle:room.name];
            
            [rooms addObject:room];
         }
         
         NSError *error;
         [SFHFKeychainUtils storeUsername:@"HappyCampr" andPassword:campfireAuthCode forServiceName:@"HappyCampr:AuthToken" updateExisting:YES error:&error];
         
      }];
      
      [request startAsynchronous];   
      [apiField setHidden:YES];
   }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
   return [usersInRoom count];
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
   NSTableRowView *rowView = [[[NSTableRowView alloc] initWithFrame:NSMakeRect(33, 0, tableView.frame.size.width-33, 20)] autorelease];

   NSTextField *textField = [[[NSTextField alloc] initWithFrame:NSMakeRect(33, 0, tableView.frame.size.width-33, 20)] autorelease];
   [textField setEditable:NO];
   textField.drawsBackground = NO;
   textField.bezeled = NO;
   
   User *user = [usersInRoom objectAtIndex:row];
   [textField setStringValue:[user name]];
   
   [rowView addSubview:textField];
   
   NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 30, 30)];
   NSImage *image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[user avatarURL]]];
   imageView.image = image;
   [rowView addSubview:imageView];
   
   rowView.emphasized = row % 2;
   
   
   
   return rowView;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
   return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
   return 30;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
  // NSLog(@"%@",[usersInRoom objectAtIndex:rowIndex] );
   
   id view = [userTableView rowViewAtRow:rowIndex makeIfNecessary:YES];
   
   popover.positioningView = view;
   [popover showPopoverForUser:[usersInRoom objectAtIndex:rowIndex]];

   return NO;
}

-(void)addUserToCache:(User*)user
{
   [userCache addObject:user];
}

- (IBAction)openRulesWindow:(id)sender 
{
   [rulesWindow makeKeyAndOrderFront:sender];
}
@end
