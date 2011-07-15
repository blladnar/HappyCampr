//
//  ScreencastMediaProtocol.h
//  RESTLibrary
//
//  Created by Dusseau, Jim on 3/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ScreencastMediaProtocol <NSObject>

@property (readonly) NSString *title;
@property (readonly) CGSize size;
@property (readonly) NSURL *mediaURL;

@end
