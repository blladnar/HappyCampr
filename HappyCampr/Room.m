//
//  Room.m
//  HappyCampr
//
//  Created by Brown, Randall on 7/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Room.h"


@implementation Room

@synthesize name, topic, roomID;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

-(NSString*)description
{
   return [NSString stringWithFormat:@"%@ %@ %@", self.name, self.roomID, self.topic];
}

@end
