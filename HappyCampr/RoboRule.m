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

-(void) encodeWithCoder: (NSCoder*) coder 
{
   [coder encodeObject: self.response forKey: @"response"];
   [coder encodeObject: self.response forKey: @"trigger"];
}

-(id) initWithCoder: (NSCoder*) coder
{
   self = [super init];
   if ( ! self) return nil;
   
   self.trigger = [coder decodeObjectForKey:@"trigger"];
   self.response = [coder decodeObjectForKey:@"response"];
   
   return self;
}

@end
