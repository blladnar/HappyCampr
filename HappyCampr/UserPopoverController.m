//
//  UserPopoverController.m
//  HappyCampr
//
//  Created by Brown, Randall on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UserPopoverController.h"
#import "User.h"

@implementation UserPopoverController
@synthesize positioningView;

-(void)showPopoverForUser:(User*)user
{
   if( !popover )
   {
      popover = [NSPopover new];
      popover.contentViewController = self;
   }
   
   [popover showRelativeToRect:[positioningView bounds] ofView:positioningView preferredEdge:NSMaxXEdge];
}



@end
