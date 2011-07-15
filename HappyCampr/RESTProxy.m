//
//  RESTProxy.m
//  RelayRecorder
//
//  Created by Dusseau, Jim on 11/3/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "RESTProxy.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "GDataXMLNode.h"
#import "GDataXMLDocument+UTF16.h"

NSString *kVerbGet = @"GET";
NSString *kVerbPost = @"POST";

@implementation RESTProxy

@synthesize url, signatureProvider;
@synthesize productForErrorDomain;
@synthesize validateSSLCertificates;

-(id)init
{
   self = [super init];
   if(self)
   {
      self.productForErrorDomain = @"unsetProductName";
      self.validateSSLCertificates = YES;
   }
   return self;
}

- (void)dealloc {
   self.url = nil;
   self.signatureProvider = nil;
   self.productForErrorDomain = nil;
   [super dealloc];
}

-(NSString *)errorDomainWithErrorType:(NSString *)errorType
{
   NSParameterAssert(errorType);
   return [NSString stringWithFormat:@"%@.%@.%@", @"com.techsmith", self.productForErrorDomain, errorType];
}

-(GDataXMLElement *)procesResponse:(NSString *)responseString error:(NSError **)error
{
   NSError *requestError = nil;
   GDataXMLDocument *xmlResponse = [[[GDataXMLDocument alloc] initWithUTF16XMLString:responseString options:0 error:&requestError] autorelease];
   if(!xmlResponse || requestError != nil)
   {
      if(error && requestError) *error = requestError;
      return nil;
   }
   
   NSArray *responseNodeArray = [xmlResponse nodesForXPath:@"/rsp" error:&requestError];
   NSAssert(requestError == nil, @"No errors should have been encountered for xPath Query");
   GDataXMLElement *rspNode = [responseNodeArray lastObject];
   if (!rspNode)
   {
      if(error)
      {
         *error = [NSError errorWithDomain:[self errorDomainWithErrorType:@"server"] code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Unexpected response from server. Respond didn't contain an rsp node" forKey:NSLocalizedDescriptionKey]];
      }
      return nil;
   }
   
   NSString *responseStatus = [[rspNode attributeForName:@"stat"] stringValue];
   if([responseStatus isEqualToString:@"ok"])
   {
      return rspNode;
   }
   else
   {
      if(error)
      {
         GDataXMLElement *errNode = [[rspNode elementsForName:@"err"] lastObject];
         NSString *errorCode = [[errNode attributeForName:@"code"] stringValue];
         NSString *message = [[errNode attributeForName:@"msg"] stringValue];
         
         *error = [NSError errorWithDomain:[self errorDomainWithErrorType:@"server"] code:[errorCode intValue] userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
      }
      return nil;
   }
   
   return rspNode;
}

#pragma mark -

-(NSDictionary *)addMethod:(NSString *)method toParameters:(NSDictionary *)parameters
{
   NSMutableDictionary *parametersIncludingMethod = [NSMutableDictionary dictionaryWithDictionary:parameters];
   [parametersIncludingMethod setValue:method forKey:@"method"];
   return parametersIncludingMethod;
}

-(NSDictionary *)parametersWithCallSignatureFromParameters:(NSDictionary *)parameters
{
   NSMutableDictionary *parametersWithSignature = [NSMutableDictionary dictionaryWithDictionary:parameters];
   if(self.signatureProvider)
   {
      NSString *sig = [self.signatureProvider callSignatureForMethodArguments:parametersWithSignature];
      [parametersWithSignature setValue:sig forKey:[self.signatureProvider callSignatureKey]];
   }
   return parametersWithSignature;
}

- (NSString *) stringFromParameters: (NSDictionary *) parameters
{
   NSMutableString *params = [[NSMutableString alloc] init];
   for (id key in parameters)
   {
      NSAssert1([[parameters objectForKey:key] isKindOfClass:[NSString class]], @"Unexpected parameter type found: %@", [parameters objectForKey:key]);
      
      NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      CFStringRef value = (CFStringRef)[[parameters objectForKey:key] copy];
      // Escape even the "reserved" characters for URLs 
      // as defined in http://www.ietf.org/rfc/rfc2396.txt
      CFStringRef encodedValue = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
                                                                         value,
                                                                         NULL, 
                                                                         (CFStringRef)@";/?:@&=+$,", 
                                                                         kCFStringEncodingUTF8);
      [params appendFormat:@"%@=%@&", encodedKey, encodedValue];
      CFRelease(value);
      CFRelease(encodedValue);
   }
   [params deleteCharactersInRange:NSMakeRange([params length] - 1, 1)];
   return [params autorelease];
}


-(GDataXMLElement *)makeGetRequest:(NSString *)method withParameters:(NSDictionary *)parameters error:(NSError **)requestError
{
   NSParameterAssert(method);
   
   parameters = [self addMethod:method toParameters:parameters];
   parameters = [self parametersWithCallSignatureFromParameters:parameters];
   
   NSString *params = [self stringFromParameters: parameters];
   NSString *urlWithParams = [NSString stringWithFormat:@"%@?%@", [self.url absoluteString], params];
   
   ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlWithParams]];
   request.validatesSecureCertificate = self.validateSSLCertificates;
   [request startSynchronous];
   
   if(request.error)
   {
      if(requestError)
      {
         *requestError = request.error;
      }
      return nil;
   }
   
   return [self procesResponse:[request responseString] error:requestError];
}

-(GDataXMLElement *)makePostRequest:(NSString *)method withParameters:(NSDictionary *)parameters error:(NSError **)requestError
{
   parameters = [self addMethod:method toParameters:parameters];
   parameters = [self parametersWithCallSignatureFromParameters:parameters];
   
   ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:self.url];
   request.validatesSecureCertificate = self.validateSSLCertificates;
   for(NSString *key in parameters)
   {
      NSObject *value = [parameters objectForKey:key];
      if([value isKindOfClass:[NSData class]])
      {
         [request addData:(NSData *)value forKey:key];
      }
      else
      {
         [request addPostValue:value forKey:key];
      }
   }

   [request startSynchronous];
   
   if(request.error)
   {
      if(requestError)
      {
         *requestError = request.error;
      }
      return nil;
   }
   
   return [self procesResponse:[request responseString] error:requestError];
}

@end
