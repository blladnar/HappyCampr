//
//  MessageView.h
//  HappyCampr
//
//  Created by Randall Brown on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Message.h"

@interface MessageView : NSTableRowView
{
   Message *message;
   NSTextField *usernameField;
}

@property (retain) Message *message;

@end
