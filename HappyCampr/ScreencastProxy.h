//
//  ScreencastProxy.h
//  Screencast.com
//
//  Created by Dusseau, Jim on 4/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScreencastMediaProtocol.h"

#import "UploadProgressProtocol.h"

@class RESTProxy;

@interface ScreencastProxy : NSObject {
   RESTProxy *mEngine;
   NSObject<UploadProgressProtocol> *mProgressDelegate;
   NSString *mApiKey;
   NSString *mSecretKey;
	
	BOOL	isUploading;
	BOOL	cancelUploading;
}

@property (retain) NSString *productForErrorDomain;

- (id) initWithURL:(NSURL *)url apiKey:(NSString *)apiKey secretKey:(NSString *)secretKey;

-(BOOL)ping;

//Account Management
-(NSString *)createAcct:(NSString *)emailAddress andDisplayName:(NSString *)displayName andPassword:(NSString *)password andCountryCode:(NSString *)countryCode error:(NSError **)error;
-(NSString *)createActivateCode:(NSString *)username error:(NSError **)error;
-(BOOL)activateUser:(NSString *)username andActivateCode:(NSString *)activateCode error:(NSError **)error;
-(NSDictionary *)countryList;

//User
-(NSString *)getStatusForUser:(NSString *)username withAuthCode:(NSString *)authCode;
-(BOOL)checkAuthCode:(NSString *)authCode error:(NSError **)error;
-(NSString *)loginWithEmail:(NSString *)emailAddress andPassword:(NSString *)password error:(NSError **)error;

//Media
-(NSDictionary *)mediaGroupListWithAuthCode:(NSString *)authCode error:(NSError **)error;
-(BOOL)delete:(NSString *)mediaSetId authCode:(NSString *)authCode error:(NSError **)error;

//Upload
-(NSDictionary *)uploadMedia:(id<ScreencastMediaProtocol>)media toFolderName:(NSString *)folderName authCode:(NSString *)authCode progressDelegate:(id <UploadProgressProtocol>)progressDelegate error:(NSError **)error;

-(void)cancelUpload;
-(NSString *)getUrl:(NSString *)mediaSetId mediaGroupId:(NSString *)mediaGroupId authCode:(NSString *)authCode error:(NSError **)error;



@end
