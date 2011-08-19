//
//  TaskMaster.h
//  CommandLineRunner
//
//  Created by Randall Brown on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskMaster : NSObject
{
   NSString* taskName;
   NSMutableArray *taskArguments;
   NSRange rangeToReplace;
   NSString *message;
}

-(id)initWithTaskString:(NSString*)taskString;
-(NSString*)executeTask;
-(void)executeTaskWithCompletionHandler:(void (^)(NSString *response))handler;

@end
