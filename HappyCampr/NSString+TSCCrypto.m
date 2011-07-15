//
//  NSString+TSCCrypto.m
//  RESTLibrary
//
//  Created by Dusseau, Jim on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+TSCCrypto.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation NSString (NSString_TSCCrypto)

-(NSString *)sha1String
{
	unsigned char bytes[CC_SHA1_DIGEST_LENGTH];
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	CC_SHA1([data bytes], [data length], bytes);
	NSMutableString *hashedString = [NSMutableString stringWithCapacity:2*CC_SHA1_DIGEST_LENGTH];
	size_t i;
	for(i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
	{
		[hashedString appendFormat:@"%02x", bytes[i]];
	}
	
	return hashedString;
}

-(NSString *)md5String
{
   const char *cStr = [self UTF8String];
	unsigned char result[16];
	CC_MD5( cStr, strlen(cStr), result );
	return [NSString stringWithFormat:
           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
           result[0], result[1], result[2], result[3], 
           result[4], result[5], result[6], result[7],
           result[8], result[9], result[10], result[11],
           result[12], result[13], result[14], result[15]
           ];	
}

@end
