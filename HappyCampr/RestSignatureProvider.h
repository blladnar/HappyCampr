//
//  RestSignatureProvider.h
//  RelayRecorder
//
//  Created by Dusseau, Jim on 11/9/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RestSignatureProviderProtocol.h"

@interface RestSignatureProvider : NSObject <RestSignatureProviderProtocol> {

   NSString *secret;
   NSString *apiKey;
}

+(RestSignatureProvider *)signatureProviderWithApiKey:(NSString *)anApiKey secret:(NSString *)aSecret;
- (id) initWithApiKey:(NSString *)anApiKey secret:(NSString *)aSecret;

@end
