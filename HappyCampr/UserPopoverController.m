//
//  UserPopoverController.m
//  HappyCampr
//
//  Created by Brown, Randall on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UserPopoverController.h"
#import <HappyCampfire/User.h>

@implementation UserPopoverController
@synthesize positioningView;

-(void)showPopoverForUser:(User*)user
{
   if( !popover )
   {
      popover = [NSPopover new];
      popover.contentViewController = self;
   }
   
   popover.behavior = NSPopoverBehaviorSemitransient;
   NSLog(@"%@", user.email);

   [nameLabel setStringValue:user.name];
   [emailButton setTitle:user.email];
   [avatarImageView setImage:[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:user.avatarURL]]];

   
   [popover showRelativeToRect:[positioningView bounds] ofView:positioningView preferredEdge:NSMaxXEdge];
}

-(void)dealloc
{
   [popover release];
   [super dealloc];
}


- (IBAction)sendEmail:(id)sender
{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@",[sender title]]]];
}
@end
