//
//  UserPopoverController.h
//  HappyCampr
//
//  Created by Brown, Randall on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UserPopoverController : NSViewController
{
   NSPopover *popover;
   NSView *positioningView;

    IBOutlet NSImageView *avatarImageView;
    IBOutlet NSTextField *nameLabel;
   IBOutlet NSButton *emailButton;
}

@property (retain) NSView *positioningView;
- (IBAction)sendEmail:(id)sender;
@end
