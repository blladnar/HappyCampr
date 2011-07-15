//
//  GDataXMLDocument+UTF16.m
//  MathCastr
//
//  Created by Malinak, Michael on 2/23/11.
//  Copyright 2011 TechSmith Corporation. All rights reserved.
//

#import "GDataXMLNode.h"
#import "GDataXMLDocument+UTF16.h"


@implementation GDataXMLDocument(UTF16)

- (id)initWithUTF16XMLString:(NSString *)str options:(unsigned int)mask error:(NSError **)error 
{   
   NSData *data = [str dataUsingEncoding:NSUTF16StringEncoding];
   GDataXMLDocument *doc = [self initWithData:data options:mask error:error];
   return doc;
}

@end
