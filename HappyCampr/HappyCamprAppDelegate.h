//
//  HappyCamprAppDelegate.h
//  HappyCampr
//
//  Created by Brown, Randall on 7/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScreencastProxy.h"

@interface HappyCamprAppDelegate : NSObject <NSApplicationDelegate> {
@private
   NSWindow *window;
   IBOutlet NSPopUpButton *roomPicker;
   
   IBOutlet NSPopUpButton *folderPicker;
   NSMutableArray *rooms;
   NSMutableArray *screencastFolders;
   NSButton *sendMessage;
   NSTextField *messageField;
   NSString *screencastAuthCode;
   ScreencastProxy *scCommunicator;
   NSButton *sadTromboneSound;
   NSButton *cricketsSound;
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


@property (assign) IBOutlet NSTextField *messageField;

@end
