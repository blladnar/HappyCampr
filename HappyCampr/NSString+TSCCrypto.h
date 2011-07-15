//
//  NSString+TSCCrypto.h
//  RESTLibrary
//
//  Created by Dusseau, Jim on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NSString_TSCCrypto)

-(NSString *)sha1String;
-(NSString *)md5String;

@end
