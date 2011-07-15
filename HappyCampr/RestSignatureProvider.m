//
//  RestSignatureProvider.m
//  RelayRecorder
//
//  Created by Dusseau, Jim on 11/9/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "RestSignatureProvider.h"

#import "NSString+TSCCrypto.h"

@interface RestSignatureProvider ()
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, copy) NSString *apiKey;
@end

@implementation RestSignatureProvider

@synthesize secret, apiKey;

+(RestSignatureProvider *)signatureProviderWithApiKey:(NSString *)anApiKey secret:(NSString *)aSecret
{
   return [[[[self class] alloc] initWithApiKey:anApiKey secret:aSecret] autorelease];
}

- (id) initWithApiKey:(NSString *)anApiKey secret:(NSString *)aSecret
{
   self = [super init];
   if (self != nil)
   {
      self.secret = aSecret;
      self.apiKey = anApiKey;
   }
   return self;
}

- (void)dealloc {
   self.secret = nil;
   self.apiKey = nil;
   [super dealloc];
}

-(NSString *)callSignatureForMethodArguments:(NSDictionary *)arguments
{
   NSParameterAssert(self.apiKey && self.secret);
   
   NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:arguments];
   NSString *callSignature = @"";
   for(NSString *key in [[dictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)])
   {
      
      id object = [dictionary objectForKey:key];
      if([object isKindOfClass:[NSString class]])
      {
         callSignature = [callSignature stringByAppendingString:key];
         
         CFStringRef encodedValue = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
                                                                            (CFStringRef)object,
                                                                            NULL, 
                                                                            (CFStringRef)@"% <>#{}|\\^~[]`;/?:@=&$,!*'()\n\r+", 
                                                                            kCFStringEncodingUTF8);
         callSignature = [callSignature stringByAppendingString:(NSString *)encodedValue];
         CFRelease(encodedValue);
      }
      else if([object isKindOfClass:[NSData class]])
      {
         //Do nothing
      }
      else
      {
         NSAssert(NO, @"unrecognized data type");
      }
      
   }
   
   callSignature = [self.secret stringByAppendingString:callSignature];
   callSignature = [callSignature sha1String];
   
   return callSignature;
}

-(NSString *)callSignatureKey
{
   return @"callSignature";
}

@end
