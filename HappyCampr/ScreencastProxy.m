//
//  ScreencastProxy.m
//  Screencast.com
//
//  Created by Dusseau, Jim on 4/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ScreencastProxy.h"

#import "ErrorConstants.h"
#import "RESTProxy.h"
#import "RestSignatureProvider.h"
#import "GDataXMLNode.h"
#import "NSString+TSCCrypto.h"

//TODOJDD there's probably a lot of duplication between the Screencast Proxy and Relay Proxy. Superclass?

@interface ScreencastProxy ()
@property (nonatomic, retain) RESTProxy *mEngine;
@end

@implementation ScreencastProxy

@synthesize mEngine;
@dynamic productForErrorDomain;

//TODOJDD delete mediaset on failure

-(RESTProxy *)engine
{
	return self.mEngine;
}

- (id) initWithURL:(NSURL *)url apiKey:(NSString *)apiKey secretKey:(NSString *)secretKey
{
   self = [super init];
   if (self != nil) {
      self.mEngine = [[RESTProxy alloc] init];
      self.mEngine.url = url;
      self.mEngine.signatureProvider = [RestSignatureProvider signatureProviderWithApiKey:apiKey secret:secretKey];
      mApiKey = [apiKey copy];
      mSecretKey = [secretKey copy];
   }
   return self;
}

- (void) dealloc
{
   self.mEngine = nil;
   [mApiKey release];
   [mSecretKey release];
   [super dealloc];
}

-(NSString *)productForErrorDomain
{
   return self.mEngine.productForErrorDomain;
}

-(void)setProductForErrorDomain:(NSString *)errorDomain
{
   self.mEngine.productForErrorDomain = errorDomain;
}

#pragma mark -
#pragma mark Request Helper Functions

-(NSString *)passwordHashForPassword:(NSString *)password
{
	NSString *hashedPassword = [password sha1String];
	hashedPassword = [hashedPassword stringByAppendingString:mSecretKey];
	hashedPassword = [hashedPassword sha1String];
	return hashedPassword;
}

-(NSDictionary *)parameters:(NSDictionary *)parameters includingAuthCode:(NSString *)authCode
{
   NSMutableDictionary *alteredParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
   if (authCode)
	{
		[alteredParameters setObject:authCode forKey:@"authCode"];
	}
   [alteredParameters setObject:mApiKey forKey:@"apiKey"];
   
   return alteredParameters;
}

#pragma mark -
#pragma mark REST Request Methods

-(GDataXMLElement *)makeGetRequest:(NSString *)methodName withParameters:(NSDictionary *)parameters authCode:(NSString *)authCode error:(NSError **)error
{
   parameters = [self parameters:parameters includingAuthCode:authCode];
   return [self.mEngine makeGetRequest:methodName withParameters:parameters error:error];
}

#pragma mark -
#pragma mark Server Status

-(BOOL)ping
{
   NSParameterAssert(self.mEngine);
   
   NSError *error;
   GDataXMLElement *rootElement = [self.mEngine makeGetRequest:@"Screencast.Info.Alive" withParameters:nil error:&error];
   
   NSError *parseError = nil;
   NSArray *nodesArray = [rootElement nodesForXPath:@"/rsp/aliveResponse" error:&parseError];
	NSAssert(parseError == nil, @"No errors should have been encountered for xPath Query");
   
   BOOL pingSucceeded = [[[nodesArray lastObject] stringValue] isEqualToString:@"alive"];
	return pingSucceeded;
}

#pragma mark -
#pragma mark Account Management

-(NSString *)createAcct:(NSString *)emailAddress andDisplayName:(NSString *)displayName andPassword:(NSString *)password andCountryCode:(NSString *)countryCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:displayName forKey:@"userName"];
	[parameters setObject:emailAddress forKey:@"email"];
	[parameters setObject:countryCode forKey:@"country"];
	[parameters setObject:[password sha1String] forKey:@"passwordHash"];
	[parameters setObject:[[NSString stringWithFormat:@"%@%@%@", displayName, @":Screencast:", password] md5String] forKey:@"md5passwordHash"];
	
   GDataXMLElement *responseNode = [self makeGetRequest:@"Screencast.Admin.User.Create" withParameters:parameters authCode:nil error:error];   
   if(!responseNode)
   {
      return nil;
   }
	
	NSString *userGUID = [[[responseNode nodesForXPath:@"/rsp/createdUser" error:error] lastObject] stringValue];
	return userGUID;
}

-(NSString *)createActivateCode:(NSString *)username error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:username forKey:@"userName"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.Admin.User.CreateActivateCode" withParameters:parameters authCode:nil error:error];
   if(!responseNode)
   {
      return nil;
   }
	
	NSString *activateCode = [[[responseNode nodesForXPath:@"/rsp/activateCode" error:error] lastObject] stringValue];	
	return activateCode;
}

-(BOOL)activateUser:(NSString *)username andActivateCode:(NSString *)activateCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:username forKey:@"userName"];
	[parameters setObject:activateCode forKey:@"activateCode"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.Admin.User.ActivateUser" withParameters:parameters authCode:nil error:error];
   if(!responseNode)
   {
      return NO;
   }
	
	NSString *activateResponse = [[[responseNode nodesForXPath:@"/rsp/activateResponse" error:error] lastObject] stringValue];
	return ([activateResponse caseInsensitiveCompare:@"activated"] == NSOrderedSame);
}

-(NSDictionary *)countryList
{
   NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	
	NSError *requestError = nil;
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.Admin.Account.GetCountryList" withParameters:parameters authCode:nil error:&requestError];
   if(!responseNode)
   {
      return nil;
   }
	
	NSError *parseError = nil;
	NSArray *countryCodeArray = [[responseNode nodesForXPath:@"/rsp/countryList/country/@code" error:&parseError] valueForKeyPath:@"stringValue"];
   NSArray *countryNameArray = [[responseNode nodesForXPath:@"/rsp/countryList/country/@name" error:&parseError] valueForKeyPath:@"stringValue"];
	if(parseError || !countryCodeArray || !countryNameArray)
	{
		return nil;
	}
	
   return [NSDictionary dictionaryWithObjects:countryCodeArray forKeys:countryNameArray];
}


#pragma mark -
#pragma mark Media

-(NSString *)createMediaGroupWithTitle:(NSString *)title Description:(NSString*) description Password:(NSString*) password andAuthCode:(NSString *)authCode error:(NSError **)error
{
   NSParameterAssert( title );
   NSParameterAssert( authCode );
   
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:title forKey:@"title"];
   
   if ( description != nil )
   {
      [parameters setObject:description forKey:@"description"];
   }
   
   if (password != nil ) 
   {
      [parameters setObject:password forKey:@"password"];
   }
  	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaGroup.Create" withParameters:parameters authCode:authCode error:error];
   if(!responseNode)
   {
      return nil;
   }
   
	NSArray *nodeArray = [responseNode nodesForXPath:@"/rsp/mediaGroupId" error:error];
	NSString *mediaGroupId = [[nodeArray lastObject] stringValue];
	
	return mediaGroupId;
}

-(NSString *)createMediaSetWithTitle:(NSString *)title authCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	if(title)
	{
		[parameters setObject:title forKey:@"title"];
	}
   
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaSet.Create" withParameters:parameters authCode:authCode error:error];
	if(!responseNode)
	{
		return nil;
	}
	
	NSArray *nodes = [responseNode nodesForXPath:@"/rsp/mediaSetId" error:error];
	return [[nodes lastObject] stringValue];
}

-(BOOL)addMediaSet:(NSString *)mediaSetId toMediaGroup:(NSString *)mediaGroupId authCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:mediaSetId forKey:@"mediaSetId"];
	[parameters setObject:mediaGroupId forKey:@"mediaGroupId"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaGroup.AddMediaSet" withParameters:parameters authCode:authCode error:error];
   return (responseNode != nil);
}

-(BOOL)setDefaultMediaOfMediaSet:(NSString *)mediaSetId toUploadJobId:(NSString *)uploadJobId dimensions:(CGSize)dimensions authCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:mediaSetId forKey:@"mediaSetId"];
	[parameters setObject:uploadJobId forKey:@"mediaId"];
	[parameters setObject:[NSString stringWithFormat:@"%1.f", dimensions.width] forKey:@"width"];
	[parameters setObject:[NSString stringWithFormat:@"%1.f", dimensions.height] forKey:@"height"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaSet.SetDefaultMedia" withParameters:parameters authCode:authCode error:error];
   return responseNode != nil;
}

-(NSDictionary *)mediaGroupListWithAuthCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:@"TitleAsc" forKey:@"sortOrder"];
	[parameters setObject:@"TRUE" forKey:@"includeBasicInfo"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaGroup.GetList" withParameters:parameters authCode:authCode error:error];
   if(!responseNode)
   {
      return nil;
   }
	
	NSArray *nodeArray = [responseNode nodesForXPath:@"/rsp/mediaGroupInfoList/mediaGroupInfo" error:error];
	if (!nodeArray)
	{
		return nil;
	}
	
   //TODOJDD I think this code could be simpler
	NSMutableDictionary *mediaGroupDict = [NSMutableDictionary dictionaryWithCapacity:[nodeArray count]];
	for(GDataXMLElement *mediaGroupNode in nodeArray)
	{
		NSString *mediaGroupID = [[[mediaGroupNode elementsForName:@"mediaGroupId"] lastObject] stringValue];
		NSString *mediaGroupTitle = [[[mediaGroupNode elementsForName:@"title"] lastObject] stringValue];
		[mediaGroupDict setObject:mediaGroupID forKey:mediaGroupTitle];
	}
	return mediaGroupDict;
}

-(NSArray *)getInfoAboutMediaGroup:(NSString*)mediaGroupID authCode:(NSString*)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:@"TRUE" forKey:@"includeList"];
	[parameters setObject:mediaGroupID forKey:@"mediaGroupId"];
   [parameters setObject:@"TitleAsc" forKey:@"sortOrder"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaGroup.GetInfo" withParameters:parameters authCode:authCode error:error];
   if(!responseNode)
   {
      return nil;
   }

	NSArray *nodeArray = [responseNode nodesForXPath:@"/rsp/mediaSetInfoList/mediaSetInfo" error:error];
	if (!nodeArray)
	{
      
		return nil;
	}
   
   NSMutableArray *mediaSets = [[NSMutableArray alloc] init];
   
   for( GDataXMLElement *element in nodeArray )
   {
      NSMutableDictionary *mediaSetInfo = [[[NSMutableDictionary alloc] init] autorelease];
      [mediaSetInfo setObject:[[[element elementsForName:@"title"] lastObject] stringValue] forKey:@"title"];
      [mediaSetInfo setObject:[[[element elementsForName:@"mediaSetGuid"] lastObject] stringValue] forKey:@"mediaSetGuid"];
      
      
      [mediaSets addObject:mediaSetInfo];
      
   }
	return mediaSets;   
}

-(NSDictionary *)getInfoAboutMediaSet:(NSString*)defaultMediaSetId  mediaGroupId:(NSString*)mediaGroupID authCode:(NSString*)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:@"bd537386-0c27-4a84-a1fa-ae91a530d8d3" forKey:@"mediaSetId"];
   [parameters setObject:@"dca16542-5f20-4a21-a323-cd0b419a3ea0" forKey:@"mediaGroupId"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaSet.GetInfo" withParameters:parameters authCode:authCode error:error];
   if(!responseNode)
   {
      return nil;
   }
   
	GDataXMLElement *mediaSetElement = [[responseNode nodesForXPath:@"/rsp/mediaSetInfo" error:error] lastObject];
	if (!mediaSetElement)
	{
      
		return nil;
	}
   
   NSMutableDictionary *mediaSetDictionary = [[[NSMutableDictionary alloc] init] autorelease];
   
   
   NSString* defaultContentURL = [[[mediaSetElement nodesForXPath:@"/contentUrlList/defaultMediaContentUrl" error:nil] lastObject] stringValue];
   
   [mediaSetDictionary setObject:defaultContentURL forKey:@"defaultMediaContentUrl"];
   [mediaSetDictionary setObject:[[[mediaSetElement elementsForName:@"title"] lastObject] stringValue] forKey:@"title"];
   
   return mediaSetDictionary;
   
}

-(BOOL)delete:(NSString *)mediaSetId authCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:mediaSetId forKey:@"mediaSetId"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaSet.Delete" withParameters:parameters authCode:authCode error:error];
   return responseNode != nil;
}

#pragma mark -
#pragma mark User

-(NSString *)loginWithEmail:(NSString *)emailAddress andPassword:(NSString *)password error:(NSError **)error
{	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:emailAddress forKey:@"emailAddress"];
	[parameters setObject:[self passwordHashForPassword:password] forKey:@"hashedPassword"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.Auth.GetCode" withParameters:parameters authCode:nil error:error];
   if(!responseNode)
   {
      return nil;
   }
	
	NSString *authCode = [[[responseNode nodesForXPath:@"/rsp/authCode" error:error] lastObject] stringValue];
	return authCode;
}

-(BOOL)checkAuthCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	
	NSError *requestError = nil;
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.Auth.CheckCode" withParameters:parameters authCode:authCode error:&requestError];
   if(!responseNode)
   {
      return NO;
   }
	
	NSArray *nodesArray = [responseNode nodesForXPath:@"/rsp/status" error:error];
	if(!nodesArray)
	{
		return NO;
	}
	
	NSString *responseText = [[nodesArray lastObject] stringValue];
	return [responseText isEqualToString:@"valid"];
}

-(NSString *)getStatusForUser:(NSString *)username withAuthCode:(NSString *)authCode
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:username forKey:@"userName"];
	
	NSError *anError = nil;
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.User.GetStatus" withParameters:parameters authCode:authCode error:&anError];
	NSString *response = [responseNode XMLString];
	if(anError)
	{
		return [anError localizedDescription];
	}
	else
	{
		return response;
	}
}

#pragma mark -
#pragma mark Upload

-(NSString *)getUrl:(NSString *)mediaSetId mediaGroupId:(NSString *)mediaGroupId authCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:mediaSetId forKey:@"mediaSetId"];
	[parameters setObject:mediaGroupId forKey:@"mediaGroupId"];
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.MediaSet.GetUrl" withParameters:parameters authCode:authCode error:error];
   if(!responseNode)
   {
      return nil;
   }
	
	NSArray *nodeArray = [responseNode nodesForXPath:@"url" error:error];
	NSString *url = [[nodeArray lastObject] stringValue];
	return url;
}

-(NSString *)folderIdForNameCreatingIfNecessary:(NSString *)folderName authCode:(NSString *)authCode error:(NSError **)error
{
   NSDictionary *mediaGroupDict = [self mediaGroupListWithAuthCode:authCode error:error];
   if(!mediaGroupDict)
   {
      return nil;
   }
   
   NSString *folderId = nil;
	if (folderName)
	{
      folderId = [mediaGroupDict objectForKey:folderName];
      if(!folderId)
      {
         folderId = [self createMediaGroupWithTitle:folderName Description:nil Password:nil andAuthCode:authCode error:error];
      }
	}
   else
   {
      folderId = [mediaGroupDict objectForKey:@"Default"];
   }
   
   return folderId;
}

//Wrapper for Screencast.Upload.BeginUpload call
-(NSString *)beginUploadToMediaSet:(NSString *)mediaSetId fileName:(NSString *)fileName size:(int)sizeInBytes isAttachment:(bool)isAttachment authCode:(NSString *)authCode error:(NSError **)error
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:@"Screencast.Upload.BeginUpload" forKey:@"method"];
	[parameters setObject:[[NSNumber numberWithInt:sizeInBytes] stringValue] forKey:@"dataLength"];
	[parameters setObject:fileName forKey:@"fileName"];
	[parameters setObject:mediaSetId forKey:@"mediaSetId"];
	if (isAttachment)
   {
      [parameters setObject:[NSString stringWithFormat:@"%d", isAttachment] forKey:@"isAttachment"];
   }
	
   GDataXMLNode *responseNode = [self makeGetRequest:@"Screencast.Upload.BeginUpload" withParameters:parameters authCode:authCode error:error];
   if(!responseNode)
   {
      return nil;
   }
	
	NSArray *nodeArray = [responseNode nodesForXPath:@"/rsp/mediaId" error:error];
	NSString *uploadJobId = [[nodeArray lastObject] stringValue];
	//NSLog(@"uploadJobId : %@", uploadJobId);
	return uploadJobId;
}

-(BOOL)appendData:(NSData *)uploadData toUploadJob:(NSString *)uploadJobId atOffset:(int)offset authCode:(NSString *)authCode error:(NSError **)error
{
   NSAutoreleasePool *pool = [NSAutoreleasePool new];
   
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:uploadJobId forKey:@"mediaId"];
	[parameters setObject:[NSString stringWithFormat:@"%d", offset] forKey:@"offset"];
	[parameters setObject:[NSString stringWithFormat:@"%d",[uploadData length]] forKey:@"dataLength"];
	[parameters setObject:uploadData forKey:@"fileData"];
   NSDictionary *authenticatedParams = [self parameters:parameters includingAuthCode:authCode];
	
   GDataXMLElement *resultNode = [self.mEngine makePostRequest:@"Screencast.Upload.AppendData" withParameters:authenticatedParams error:error];
   
   BOOL appendSucceeded = (resultNode != nil);
   [pool release];   //TODOJDD am I going to have a problem with the NSError here?
   
	return appendSucceeded;
}

-(BOOL)uploadData:(NSData *)uploadData withUploadJobId:(NSString *)uploadJobId mediaSetId:(NSString *)mediaSetId dataOffset:(NSInteger)dataOffset authCode:(NSString *)authCode error:(NSError **)error
{
   //TODOJDD this code is going to be duplicated in the relay uploader. Come up with something
	int chunkSize = 10000;
	unsigned int offset = 0;
	for (offset = dataOffset; offset < [uploadData length];)
	{
		if (cancelUploading) 
		{
			/*BOOL deleteSucceeded = */[self delete:mediaSetId authCode:authCode error:error];
			return NO;
		}
		
		int bytesRemaining = [uploadData length] - offset;
		int currentChunkSize = bytesRemaining < chunkSize ? bytesRemaining : chunkSize ;
		NSRange dataRange = {offset, currentChunkSize};
		NSData *dataToUploader = [uploadData subdataWithRange:dataRange];
		
		BOOL appendErrorSucceeded = [self appendData:dataToUploader toUploadJob:uploadJobId atOffset:offset authCode:authCode error:error];
		if(!appendErrorSucceeded)
		{
			return NO;
		}
		
		offset += chunkSize;
		[mProgressDelegate uploadProgressedTo:offset ofTotal:[uploadData length]];
	}
   return YES;
}

-(NSDictionary *)uploadMedia:(id<ScreencastMediaProtocol>)media toFolderName:(NSString *)folderName authCode:(NSString *)authCode progressDelegate:(id <UploadProgressProtocol>)progressDelegate error:(NSError **)error;
{
	NSAssert(authCode, @"Auth code must be set");
   cancelUploading = NO;
   
   NSString *title = media.title;
   
   NSString *folderId = [self folderIdForNameCreatingIfNecessary:folderName authCode:authCode error:error];
   if(!folderId)
   {
      return nil;
   }
	
	NSString *mediaSetId = [self createMediaSetWithTitle:title authCode:authCode error:error];
	if (!mediaSetId)
	{
		return nil;
	}
	
	BOOL mediaSetSucceeded = [self addMediaSet:mediaSetId toMediaGroup:folderId authCode:authCode error:error];
	if (!mediaSetSucceeded)
	{
		return nil;
	}
   
   NSImage *image = [NSImage imageWithContentsOfFile:[media.mediaURL path]];
   NSData *mediaData;// = UIImagePNGRepresentation(image);
	
	NSString *uploadJobId = [self beginUploadToMediaSet:mediaSetId fileName:title size:[mediaData length] isAttachment:false authCode:authCode error:error];
	if(!uploadJobId)
	{
		return nil;
	}
   
   BOOL uploadSucceeded = [self uploadData:mediaData withUploadJobId:uploadJobId mediaSetId:mediaSetId dataOffset:0 authCode:authCode error:error];
   if(!uploadSucceeded)
   { 
      return nil;
   }
   
   BOOL mediaSetDefaultSucceeded = [self setDefaultMediaOfMediaSet:mediaSetId toUploadJobId:uploadJobId dimensions:media.size authCode:authCode error:error];
   if(!mediaSetDefaultSucceeded)
   {
      return nil;
   }
   
   NSString *url = [self getUrl:mediaSetId mediaGroupId:folderId authCode:authCode error:error];

	return [NSDictionary dictionaryWithObjectsAndKeys:
           mediaSetId, @"mediaSetId",
           folderId, @"mediaGroupId",
           uploadJobId, @"mediaId",
           url, @"url",
           nil];
}

-(void)cancelUpload
{
	if (isUploading) 
	{
		cancelUploading = YES;
	}
}

@end
