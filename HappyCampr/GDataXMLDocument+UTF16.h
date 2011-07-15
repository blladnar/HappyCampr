//
//  GDataXMLDocument+UTF16.h
//  MathCastr
//
//  Created by Malinak, Michael on 2/23/11.
//  Copyright 2011 TechSmith Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GDataXMLDocument(UTF16)
 - (id)initWithUTF16XMLString:(NSString *)str options:(unsigned int)mask error:(NSError **)error;
@end
