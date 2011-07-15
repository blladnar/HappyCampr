//
//  HappyCamprAppDelegate.h
//  HappyCampr
//
//  Created by Brown, Randall on 7/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HappyCamprAppDelegate : NSObject <NSApplicationDelegate> {
@private
   NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
