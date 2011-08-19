//
//  TaskMaster.m
//  CommandLineRunner
//
//  Created by Randall Brown on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TaskMaster.h"
#import "NSFileManager+DirectoryLocations.h"
@implementation TaskMaster

-(id)initWithTaskString:(NSString*)taskString
{
    self = [super init];
   
    if (self) 
    {
       message = [taskString retain];
       NSRange startTaskRange = [taskString rangeOfString:@"task("];
       
       if( NSEqualRanges(startTaskRange, NSMakeRange(NSNotFound, 0)) )
          return self;
          
       int taskStart = startTaskRange.location + startTaskRange.length;
       NSRange secondRange = NSMakeRange(taskStart, taskString.length - taskStart);
       NSRange taskEnd = [taskString rangeOfString:@")" options:NSCaseInsensitiveSearch range:secondRange];
       
       NSRange taskRange = NSMakeRange(taskStart, taskEnd.location-taskStart);
       NSString *task = [taskString substringWithRange:taskRange];
       
       NSArray *taskAndArgs = [task componentsSeparatedByString:@" "];
       
       rangeToReplace = NSMakeRange(startTaskRange.location, (taskEnd.location + taskEnd.length) - startTaskRange.location);
       
       taskName = [[taskAndArgs objectAtIndex:0] retain];
       taskArguments = [[NSMutableArray alloc] init];
       for( int i=1; i< [taskAndArgs count]; i++)
       {
          [taskArguments addObject:[taskAndArgs objectAtIndex:i]];
       }
    }
    
    return self;
}

-(NSString*)executeTask
{
   
   if( taskName )
   {
      NSString *appSupportDirectory = [[NSFileManager defaultManager] applicationSupportDirectory];
      NSTask *task;
      task = [[NSTask alloc] init];
      [task setLaunchPath:[appSupportDirectory stringByAppendingPathComponent:taskName]];
      
      [task setArguments: taskArguments];
      
      NSPipe *pipe;
      pipe = [NSPipe pipe];
      [task setStandardOutput: pipe];
      
      NSFileHandle *file;
      file = [pipe fileHandleForReading];
      
      [task launch];
      
      NSData *data;
      data = [file readDataToEndOfFile];
      
      NSString *string;
      string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
      
      [task release];     
      
      message = [message stringByReplacingCharactersInRange:rangeToReplace withString:string];
   }
   
      return message;
}

-(void)executeTaskWithCompletionHandler:(void (^)(NSString *response))handler
{
   dispatch_queue_t queue = dispatch_queue_create("com.background.task",NULL);
   dispatch_queue_t main = dispatch_get_main_queue();
   
   dispatch_async(queue,^{
      
      NSString *response = [self executeTask];
      
      dispatch_async(main,^{
         handler(response);
      });
   });
}

-(void)dealloc
{
   [taskName release];
}



@end
