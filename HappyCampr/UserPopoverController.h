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

}

@property NSView *positioningView;
@end
