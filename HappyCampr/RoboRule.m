//
//  RoboRule.m
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RoboRule.h"

@implementation RoboRule
@synthesize trigger, response;
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(id)initWithTrigger:(NSString*)aTrigger andResponse:(NSString*)aResponse
{
   self = [super init];
   if (self) 
   {
      trigger = [aTrigger retain];
      response = [aResponse retain];
   }
   
   return self;
}

@end
