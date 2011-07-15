//
//  UploadProgressProtocol.h
//  Screencast.com
//
//  Created by Dusseau, Jim on 4/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@protocol UploadProgressProtocol

-(void)uploadProgressedTo:(NSInteger)uploadedBytes ofTotal:(NSInteger)totalBytes;

@end
