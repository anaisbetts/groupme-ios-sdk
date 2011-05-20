// Copyright 2011 Mindless Dribble, Inc
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>



@protocol GroupMeRequestDelegate;

@interface GroupMeRequest : NSObject {
	
	NSString		*_requestId;
	NSString		*_url;
	NSString		*_queryString;
	NSDictionary	*_params;
	NSString		*_requestMethod; //Defaults to GET if no postData, POST if postData not nil.
	
	NSURLConnection *_connection;
	NSMutableData	*_responseData;
	NSArray			*_errors;
	NSInteger		_statusCode;

	id<GroupMeRequestDelegate> _delegate;

    
}

@property (nonatomic, retain) NSString			*requestId;
@property (nonatomic, retain) NSString			*url;
@property (nonatomic, retain) NSString			*queryString;
@property (nonatomic, retain) NSDictionary		*params;
@property (nonatomic, retain) NSString			*requestMethod;
@property (nonatomic, retain) NSURLConnection	*connection;
@property (nonatomic, retain) NSMutableData		*responseData;
@property (nonatomic, retain) NSArray			*errors;
@property (nonatomic, assign) NSInteger			statusCode;

@property (nonatomic, assign) id<GroupMeRequestDelegate> delegate;

- (void) start;
- (void) cancel;
- (BOOL) loading;

+ (NSString *)encodeURLParameter:(NSString*)input;
+ (NSString *)encodeQueryStringFromParams:(NSDictionary*)params;

@end

//This is the delegate protocol to implement if you are making direct GroupMe requests.
@protocol GroupMeRequestDelegate <NSObject>

@optional

//Called right before connecting to server
- (void)requestStarted:(GroupMeRequest *)request;

//Called when connects to server and begins getting data
- (void)request:(GroupMeRequest *)request didReceiveResponse:(NSURLResponse *)response;

//Called on error making request
- (void)request:(GroupMeRequest *)request didFailWithError:(NSError *)error;

//Called on successful completion of request, could be a NSDictionary, NSArray, or whatever is passed back from endpoint, maybe even nil if nothing to parse
- (void)request:(GroupMeRequest *)request didLoad:(id)result;

//Called on successful completion of request, always a NSData object
- (void)request:(GroupMeRequest *)request didLoadRawResponse:(NSData *)data;

@end
