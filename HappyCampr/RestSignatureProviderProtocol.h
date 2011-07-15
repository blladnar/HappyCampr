//
//  RestSignatureProviderProtocol.h
//  RelayRecorder
//
//  Created by Dusseau, Jim on 11/11/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

@protocol RestSignatureProviderProtocol <NSObject>

-(NSString *)callSignatureForMethodArguments:(NSDictionary *)arguments;
-(NSString *)callSignatureKey;
@end
