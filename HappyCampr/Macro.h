//
//  Macro.h
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Macro : NSObject
{
   NSString *shortenedValue;
   NSString *expandedValue;
}

@property (retain) NSString *shortenedValue;
@property (retain) NSString *expandedValue;
@end
