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
#import "RoboRulesController.h"
#import "MacroController.h"
#import <HappyCampfire/HappyCampfire.h>

@interface HappyCamprAppDelegate : NSObject <NSApplicationDelegate,NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate> {
@private
   NSWindow *window;
   NSPopUpButton *roomPicker;
   
   IBOutlet NSButton *saveAuthButton;
   IBOutlet NSTextField *apiField;
   IBOutlet NSPopUpButton *folderPicker;
   NSMutableArray *rooms;
   NSMutableArray *screencastFolders;
   NSMutableArray *usersInRoom;
   NSMutableArray *userCache;
   NSMutableArray *roboRules;
   NSButton *sendMessage;
   NSTextField *messageField;
   NSString *screencastAuthCode;
   ScreencastProxy *scCommunicator;
   NSString *oldRoomId;
   NSButton *mainSignIn;
   
   NSString *campfireAuthCode;
   NSButton *saveAuthToken;
   
   IBOutlet NSButton *showEnterMessageCheckbox;
   IBOutlet NSButton *stealModeCheckBox;
   IBOutlet NSButton *signInWindowButton;
   IBOutlet NSTextField *userNameField;
   IBOutlet NSTextField *passwordField;
   NSMutableArray *messages;
   NSMutableArray *allMessages;
   NSInteger lastMessageID;
   NSInteger numberOfUnreadMessages;
   
   IBOutlet MacroController *macrosController;
   NSMutableArray *userTableViews;
   
   IBOutlet NSTableView *messageView;
   IBOutlet MessageTableViewController *messageTableController;
   IBOutlet NSTableView *userTableView;
    UserPopoverController *popover;
   
   IBOutlet NSWindow *macrosWindow;
   IBOutlet NSWindow *rulesWindow;
   BOOL initialMessageLoad;
   IBOutlet RoboRulesController *rulesController;
   IBOutlet NSTextField *urlBox;
   IBOutlet NSWindow *signInWindow;
   IBOutlet NSProgressIndicator *networkSpinner;
   
   HappyCampfire *campfire;
   
   HCUser* authenticatedUser;
   
   NSString *campfireURL;
   int networkCommunications;
}
- (IBAction)openRulesWindow:(id)sender;

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
-(void)sendTextMessage:(NSString*)text;
- (IBAction)openMacrosWindow:(id)sender;
- (IBAction)saveCampfireURL:(id)sender;

-(void)incrementNetworkActivity;
-(void)decrementNetworkActivity;
-(void)getAndUpdateRooms;


@property (assign) IBOutlet NSTextField *messageField;

-(void)addUserToCache:(HCUser*)user;
-(NSString*)usernameForID:(NSInteger)userID;

@end
