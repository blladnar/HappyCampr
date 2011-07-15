//
//  ScreencastMediaItem.m
//  RESTLibrary
//
//  Created by Dusseau, Jim on 3/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ScreencastMediaItem.h"

@implementation ScreencastMediaItem


@synthesize mediaURL;
@synthesize size;
@synthesize title;

-(id)init
{
   self = [super init];
   if(self)
   {
      mediaURL = nil;
      size = CGSizeZero;
      title = nil;
   }
   return self;
}

-(id)initWithImagePath:(NSString *)path title:(NSString *)aTitle
{
   self = [self init];
   if(self)
   {
      mediaURL = [[NSURL fileURLWithPath:path] retain];
      NSImage *image = [NSImage imageWithContentsOfFile:path];
      size = image.size;
      title = [aTitle retain];
   }
   return self;
}

- (void)dealloc {
   [mediaURL release];
   [title release];
   [super dealloc];
}



@end
