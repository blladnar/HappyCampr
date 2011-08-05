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
   
   popover.behavior = NSPopoverBehaviorTransient;
   NSLog(@"%@", user.email);
   
   emailField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,100,30)];
   [emailField setStringValue:user.email];
   
   [self.view addSubview:emailField];
   
   [popover showRelativeToRect:[positioningView bounds] ofView:positioningView preferredEdge:NSMaxXEdge];
}

-(void)loadView
{
   [super loadView];
   

}



@end
