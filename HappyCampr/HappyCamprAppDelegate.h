//
//  HappyCamprAppDelegate.h
//  HappyCampr
//
//  Created by Brown, Randall on 7/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HappyCamprAppDelegate : NSObject <NSApplicationDelegate> {
@private
   NSWindow *window;
   IBOutlet NSPopUpButton *roomPicker;
   
   NSMutableArray *rooms;
   NSButton *sendMessage;
   NSTextField *messageField;
}

@property (assign) IBOutlet NSWindow *window;
- (IBAction)roomPicked:(id)sender;
- (IBAction)sendMessage:(id)sender;

@property (assign) IBOutlet NSTextField *messageField;

@end
