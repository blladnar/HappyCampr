//
//  MessageView.h
//  HappyCampr
//
//  Created by Randall Brown on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HappyCampfire/HCMessage.h>

@interface MessageView : NSTableRowView
{
   HCMessage *message;
   NSTextField *usernameField;
}

@property (retain) HCMessage *message;

@end
