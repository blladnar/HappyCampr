//
//  Macro.m
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Macro.h"

@implementation Macro
@synthesize shortenedValue, expandedValue;
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void) encodeWithCoder: (NSCoder*) coder 
{
   [coder encodeObject: self.shortenedValue forKey: @"shortValue"];
   [coder encodeObject: self.expandedValue forKey: @"expandedValue"];
}

-(id) initWithCoder: (NSCoder*) coder
{
   self = [super init];
   if ( ! self) return nil;
   
   self.shortenedValue = [coder decodeObjectForKey:@"shortValue"];
   self.expandedValue = [coder decodeObjectForKey:@"expandedValue"];
   
   return self;
}

@end
