//
//  HappyCamprAppDelegate.h
//  HappyCampr
//
//  Created by Brown, Randall on 7/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScreencastProxy.h"
#import "UserPopoverController.h"
#import "MessageTableViewController.h"
#import "User.h"

@interface HappyCamprAppDelegate : NSObject <NSApplicationDelegate,NSTableViewDelegate, NSTableViewDataSource> {
@private
   NSWindow *window;
   IBOutlet NSPopUpButton *roomPicker;
   
   IBOutlet NSButton *saveAuthButton;
   IBOutlet NSTextField *apiField;
   IBOutlet NSPopUpButton *folderPicker;
   NSMutableArray *rooms;
   NSMutableArray *screencastFolders;
   NSMutableArray *usersInRoom;
   NSMutableArray *userCache;
   NSButton *sendMessage;
   NSTextField *messageField;
   NSString *screencastAuthCode;
   ScreencastProxy *scCommunicator;
   NSString *oldRoomId;
   
   NSString *campfireAuthCode;
   NSButton *saveAuthToken;
   
   IBOutlet NSButton *showEnterMessageCheckbox;
   IBOutlet NSButton *stealModeCheckBox;
   NSMutableArray *messages;
   NSMutableArray *allMessages;
   NSInteger lastMessageID;
   NSInteger numberOfUnreadMessages;
   
   NSMutableArray *userTableViews;
   
   IBOutlet NSTableView *messageView;
   IBOutlet MessageTableViewController *messageTableController;
   IBOutlet NSTableView *userTableView;
    UserPopoverController *popover;
}

@property (assign) IBOutlet NSWindow *window;
- (IBAction)roomPicked:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)screencastLogin:(id)sender;
- (IBAction)getFolderContents:(id)sender;
- (IBAction)theMoreYouKnowSound:(id)sender;
- (IBAction)rimShotSound:(id)sender;
- (IBAction)sadTromboneSound:(id)sender;
- (IBAction)crickets:(id)sender;
- (IBAction)doItLiveSound:(id)sender;
- (IBAction)greatJobSound:(id)sender;
- (IBAction)vuvuzelaSound:(id)sender;
- (IBAction)saveAuthToken:(id)sender;



@property (assign) IBOutlet NSTextField *messageField;

-(void)addUserToCache:(User*)user;
-(NSString*)usernameForID:(NSInteger)userID;

@end
