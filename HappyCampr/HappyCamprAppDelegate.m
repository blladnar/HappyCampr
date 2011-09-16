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
      [self incrementNetworkActivity];
      [campfire getAuthenticatedUserInfo:^(User* user, NSError *error){
         authenticatedUser = [user retain];
         [self decrementNetworkActivity];
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
   [NSApp beginSheet:signInWindow modalForWindow:self.window modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
   NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
   NSButton *zoomButton = [window standardWindowButton:NSWindowZoomButton];
   NSButton *minimizeButton = [window standardWindowButton:NSWindowMiniaturizeButton];
   
   closeButton.frame = NSMakeRect(closeButton.frame.origin.x+5, closeButton.frame.origin.y-12, closeButton.frame.size.height, closeButton.frame.size.width);
   zoomButton.frame = NSMakeRect(zoomButton.frame.origin.x+5, zoomButton.frame.origin.y-12, zoomButton.frame.size.height, zoomButton.frame.size.width);
   minimizeButton.frame = NSMakeRect(minimizeButton.frame.origin.x+5, minimizeButton.frame.origin.y-12, minimizeButton.frame.size.height, minimizeButton.frame.size.width);  
   
   return proposedFrameSize;
}

-(void)windowDidResize:(NSNotification *)notification
{
   NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
   NSButton *zoomButton = [window standardWindowButton:NSWindowZoomButton];
   NSButton *minimizeButton = [window standardWindowButton:NSWindowMiniaturizeButton];
   
   closeButton.frame = NSMakeRect(closeButton.frame.origin.x+5, closeButton.frame.origin.y-12, closeButton.frame.size.height, closeButton.frame.size.width);
   zoomButton.frame = NSMakeRect(zoomButton.frame.origin.x+5, zoomButton.frame.origin.y-12, zoomButton.frame.size.height, zoomButton.frame.size.width);
   minimizeButton.frame = NSMakeRect(minimizeButton.frame.origin.x+5, minimizeButton.frame.origin.y-12, minimizeButton.frame.size.height, minimizeButton.frame.size.width);  
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   networkCommunications = 0;
//   [[NSApplication sharedApplication] setPresentationOptions:NSFullScreenWindowMask];
//   [[self window] setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary | NSWindowCollectionBehaviorFullScreenAuxiliary];

   roomPicker = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(78, window.frame.size.height - 30 - 9, 200, 30)];
   [roomPicker setAction:@selector(roomPicked:)];
   [roomPicker setTarget:self];
   [roomPicker setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
   [roomPicker setBezelStyle:NSRoundedBezelStyle];
   [roomPicker setBezelStyle:NSTexturedRoundedBezelStyle];
   
   NSRect logoRect = NSMakeRect(window.frame.size.width-45 - 5, window.frame.size.height-45, 45, 45);
   NSImageView *logoView = [[NSImageView alloc] initWithFrame:logoRect];
   logoView.image = [NSImage imageNamed:@"happyCamper"];
   [logoView setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
   
   NSView *themeFrame = [[self.window contentView] superview];
   NSRect titleBarRect = [themeFrame frame];

   
   mainSignIn = [[NSButton alloc] initWithFrame:NSMakeRect(titleBarRect.size.width - 200, titleBarRect.size.height - 30-8, 100, 30)];
   

   [mainSignIn setTitle:@"Sign In"];
   [mainSignIn setTarget:self];
   [mainSignIn setAction:@selector(showURLSheet)];
   [mainSignIn setBezelStyle:NSTexturedRoundedBezelStyle];
   [mainSignIn setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
   
   networkSpinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(titleBarRect.size.width - 80, titleBarRect.size.height-30, 20, 20)];
   [networkSpinner setDisplayedWhenStopped:NO];
   [networkSpinner setStyle:NSProgressIndicatorSpinningStyle];
   [networkSpinner setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];

   [themeFrame addSubview:roomPicker];
   [themeFrame addSubview:logoView];
   [themeFrame addSubview:mainSignIn];
   [themeFrame addSubview:networkSpinner];
     // [[self window] setCollectionBehavior:NSWindowCollectionBehaviorFullScreenAuxiliary];

   initialMessageLoad = YES;
 
    popover = [[UserPopoverController alloc] initWithNibName:@"UserPopoverController" bundle:nil];
   lastMessageID = 0;
   numberOfUnreadMessages = 0;
   
   allMessages = [NSMutableArray new];
   userCache = [NSMutableArray new];
   roboRules = [NSMutableArray new];
   
   rooms = [NSMutableArray new];
   
//   NSError *error;
//   campfireAuthCode = [[SFHFKeychainUtils getPasswordForUsername:@"HappyCampr" andServiceName:@"HappyCampr:AuthToken" error:&error] retain];
//   
//   if( campfireAuthCode )
//   {
//      campfire = [[Campfire alloc] initWithCampfireURL:@"https://randallbrown.campfirenow.com"];
//      campfire.authToken = campfireAuthCode;
//      [self getAndUpdateRooms];
//      
//   }
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
   
   NSString *urlString = [NSString stringWithFormat:@"https://randallbrown.campfirenow.com/room/%@/recent.xml?since_message_id=%i",roomID, lastMessageID];
   
   messages = [[NSMutableArray alloc] init];
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   
   [request addRequestHeader:@"Content-Type" value:@"application/xml"];
   [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
   [request setUsername:[campfire authToken]];
   [request setPassword:@"X"];
   
   [request setFailedBlock:^{
      NSLog(@"%@", [request error]); 
      [self decrementNetworkActivity];
   }];
   
   [request setCompletionBlock:^{
      [self decrementNetworkActivity];
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
   
   [self incrementNetworkActivity];
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
      
      [self incrementNetworkActivity];
      [campfire authenticateUserWithName:[userNameField stringValue] password:[passwordField stringValue] completionHandler:^(User* user, NSError *error){
         
         [self decrementNetworkActivity];
         if( user )
         {
            NSLog(@"%@", user);
            campfire.authToken = user.authToken;
            [self getAndUpdateRooms];
            
            NSError *saveerror;
            [SFHFKeychainUtils storeUsername:@"HappyCampr" andPassword:campfireAuthCode forServiceName:@"HappyCampr:AuthToken" updateExisting:YES error:&saveerror];
            [apiField setHidden:YES];
            [mainSignIn setTitle:@"Sign Out"];
         }
         else
         {
            [[NSAlert alertWithError:error] runModal];
         }
      }];
      
      
      
   }
   
   [NSApp endSheet:signInWindow];
   [signInWindow orderOut:sender];
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
      
      [roomPicker selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedRoom"]];
      [self roomPicked:nil];
      [[NSUserDefaults standardUserDefaults] synchronize];         
   }];
   
   [self getAuthenticatedUser];
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

-(void)incrementNetworkActivity
{
   networkCommunications++;

   [networkSpinner startAnimation:nil];
}
-(void)decrementNetworkActivity
{
   networkCommunications--;
   if( networkCommunications <= 0 )
   {
      [networkSpinner stopAnimation:nil];
   }
}
@end
