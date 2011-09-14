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
#import "SFHFKeychainUtils.h"
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

-(User*)getAuthenticatedUser
{
   if( !authenticatedUser )
   {
      [campfire getAuthenticatedUserInfo:^(User* user, NSError *error){
         authenticatedUser = [user retain];
      }];
   }
   return authenticatedUser;
}

-(void)processRoboRulesAgainstMessages:(NSArray*)theMessages
{
   for( RoboRule *rule in [rulesController rules] )
   {
      for( Message *message in theMessages )
      {
         if( !NSEqualRanges([message.messageBody rangeOfString:rule.trigger], NSMakeRange(NSNotFound, 0)) && message.userID != [self getAuthenticatedUser].userID )
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

-(BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
   NSLog(@"%@", filename);
   
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   [campfire postFile:filename toRoom:roomID completionHandler:^(UploadFile *file, NSError *error){
      NSLog(@"%@", file.fullURL);
   }];
   return YES;
}

-(BOOL)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   for( NSString *filename in filenames )
   {      
      [campfire postFile:filename toRoom:roomID completionHandler:^(UploadFile *file, NSError *error){
         NSLog(@"%@", file.fullURL);
      }];
   }
   return YES;
}

-(void)showURLSheet
{
   [NSApp beginSheet:urlSheet modalForWindow:self.window modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   NSView *themeFrame = [[self.window contentView] superview];
   NSRect titleBarRect = [themeFrame frame];
   
   int buttonWidth = 100;
   int buttonHeight = 20;
   
   NSButton *urlButton = [[NSButton alloc] initWithFrame:NSMakeRect(titleBarRect.size.width - buttonWidth - 30, titleBarRect.size.height-buttonHeight-1, buttonWidth, buttonHeight)];
   [urlButton setTitle:@"Change URL"];
   [urlButton setBezelStyle:NSRoundRectBezelStyle];
   [urlButton setTarget:self];
   [urlButton setAction:@selector(showURLSheet)];
   
   [themeFrame addSubview:urlButton];
   

   
   [[NSApplication sharedApplication] setPresentationOptions:NSFullScreenWindowMask];
   [[self window] setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary | NSWindowCollectionBehaviorFullScreenAuxiliary];
  // [[self window] setCollectionBehavior:NSWindowCollectionBehaviorFullScreenAuxiliary];

   initialMessageLoad = YES;
 
    popover = [[UserPopoverController alloc] initWithNibName:@"UserPopoverController" bundle:nil];
   lastMessageID = 0;
   numberOfUnreadMessages = 0;
   
   allMessages = [NSMutableArray new];
   userCache = [NSMutableArray new];
   roboRules = [NSMutableArray new];
   
   rooms = [NSMutableArray new];
   
   NSError *error;
   campfireAuthCode = [[SFHFKeychainUtils getPasswordForUsername:@"HappyCampr" andServiceName:@"HappyCampr:AuthToken" error:&error] retain];
   
   campfire = [[Campfire alloc] initWithCampfireURL:@"https://bravoteam.campfirenow.com"];
   
   if( campfireAuthCode )
   {
      campfire.authToken = campfireAuthCode;
      [self getAndUpdateRooms];
      
   }
   // Insert code here to initialize your application   if( !campfire )
   {
      [NSApp beginSheet:urlSheet modalForWindow:[self window] modalDelegate:self didEndSelector:NULL  contextInfo:nil];
   }
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
      
      [campfire joinRoom:roomID WithCompletionHandler:^(NSError* error){
         
      }];
      
      if( [oldRoomId length] )
      {
         [campfire leaveRoom:oldRoomId WithCompletionHandler:^(NSError *error){
            
         }];
      }
      
      oldRoomId = [roomID retain];

   }
   
}

-(void)getUsersForSelectedRoom
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   
   [campfire getRoomWithID:roomID completionHandler:^(Room *room){
      usersInRoom = [[NSMutableArray alloc] initWithArray:room.users];
      [userCache addObjectsFromArray:usersInRoom];
      
      [userTableView reloadData];
      
   }];      
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
            
            if( [message.messageType isEqualToString:@"LeaveMessage"] || [message.messageType isEqualToString:@"JoinMessage"] )
            {
               [self getUsersForSelectedRoom];
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
   
   [campfire sendText:text toRoom:roomID];
}

- (IBAction)openMacrosWindow:(id)sender 
{
   [macrosWindow makeKeyAndOrderFront:sender];
}

- (IBAction)saveCampfireURL:(id)sender 
{
   if( [[urlBox stringValue] length] )
   {
      campfire = [[Campfire alloc] initWithCampfireURL:[urlBox stringValue]];
      [campfire authenticateUserWithName:@"" password:@"" completionHandler:^(User* user, NSError *error){
         
         NSLog(@"%@", user);
         campfire.authToken = user.authToken;
         [self getAndUpdateRooms];
      }];
      
      
      
   }
   
   [NSApp endSheet:urlSheet];
   [urlSheet orderOut:sender];
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



-(void)sendSoundMessageWithSound:(NSString*)sound
{
   NSString *roomID = [[rooms objectAtIndex:[roomPicker indexOfSelectedItem]] roomID];
   
   [campfire sendSound:sound toRoom:roomID];
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

-(void)getAndUpdateRooms
{
   [campfire getVisibleRoomsWithHandler:^(NSArray* visibleRooms){
      [saveAuthButton setTitle:@"Sign Out"];
      // Use when fetching text data
      
      for( Room *room in visibleRooms )
      {
         [roomPicker addItemWithTitle:room.name];
         
         [rooms addObject:room];
      }
      
      NSError *error;
      [SFHFKeychainUtils storeUsername:@"HappyCampr" andPassword:campfireAuthCode forServiceName:@"HappyCampr:AuthToken" updateExisting:YES error:&error];
      [apiField setHidden:YES];
      [roomPicker selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedRoom"]];
      [self roomPicked:nil];
      [[NSUserDefaults standardUserDefaults] synchronize];         
   }];
   
   [self getAuthenticatedUser];
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
      campfireAuthCode = [[apiField stringValue] retain];
      campfire.authToken = campfireAuthCode;
      [self getAndUpdateRooms];
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
