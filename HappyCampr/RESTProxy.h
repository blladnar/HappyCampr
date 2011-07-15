//
//  RESTProxy.h
//  RelayRecorder
//
//  Created by Dusseau, Jim on 11/3/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RestSignatureProviderProtocol.h"

@class GDataXMLElement;

@interface RESTProxy : NSObject {

}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) id<RestSignatureProviderProtocol> signatureProvider;
@property (nonatomic, copy) NSString *productForErrorDomain;
@property (assign) BOOL validateSSLCertificates;

-(GDataXMLElement *)makeGetRequest:(NSString *)method withParameters:(NSDictionary *)parameters error:(NSError **)requestError;
-(GDataXMLElement *)makePostRequest:(NSString *)method withParameters:(NSDictionary *)parameters error:(NSError **)requestError;

@end
