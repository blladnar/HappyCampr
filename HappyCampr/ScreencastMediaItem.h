//
//  ScreencastMediaItem.h
//  RESTLibrary
//
//  Created by Dusseau, Jim on 3/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScreencastMediaProtocol.h"

@interface ScreencastMediaItem : NSObject <ScreencastMediaProtocol> {

}

-(id)initWithImagePath:(NSString *)path title:(NSString *)aTitle;

@end
