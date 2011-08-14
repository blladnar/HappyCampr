//
//  RoboRule.h
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RoboRule : NSObject
{
   NSString *trigger;
   NSString *response;
}

-(id)initWithTrigger:(NSString*)aTrigger andResponse:(NSString*)aResponse;
@property (retain) NSString *trigger;
@property (retain) NSString *response;

@end
