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


#import "GroupMeRequest.h"

#import "JSONKit.h"
#import "GroupMeConnect.h"

#define kTimeout 60.0f
#define kGroupMeUserAgent [NSString stringWithFormat:@"GroupMeConnect/%@ (%@)", GROUP_ME_CONNECT_VERSION, GROUP_ME_CONNECT_SDK_TYPE] 


@implementation GroupMeRequest

@synthesize requestId = _requestId;
@synthesize requestMethod = _requestMethod;
@synthesize queryString = _queryString;
@synthesize url = _url;
@synthesize params = _params;
@synthesize connection = _connection;
@synthesize responseData = _responseData;
@synthesize errors = _errors;
@synthesize delegate = _delegate;
@synthesize statusCode = _statusCode;


- (GroupMeRequest*) init {
	self = [super init];
	if (self) {
		self.requestMethod = @"GET";
	}
	return self;
}

#pragma mark -
#pragma mark Request Management

- (BOOL) loading {
	return !!_connection;
}

- (void) start {
	if ([_delegate respondsToSelector:@selector(requestStarted:)]) {
		[_delegate requestStarted:self];
	}
	
	BOOL explicitBody = ([_params objectForKey:@"_body"] != nil);
	
	if (!explicitBody)
		self.queryString = [GroupMeRequest encodeQueryStringFromParams:_params];
	
	NSString *turl = nil;
	

	if (explicitBody && [_params objectForKey:@"token"] != nil && [_params objectForKey:@"client_id"] != nil) {
		turl = [NSString stringWithFormat:@"%@?client_id=%@&token=%@", _url, 
				[GroupMeRequest encodeURLParameter:[_params objectForKey:@"client_id"]], 
				[GroupMeRequest encodeURLParameter:[_params objectForKey:@"token"]]];
	} else if (_queryString != nil && ![self.requestMethod isEqualToString: @"POST"]) {
		turl = [NSString stringWithFormat:@"%@?%@", _url, _queryString];
	} else if ([self.requestMethod isEqualToString: @"POST"] && [_params objectForKey:@"token"] != nil && [_params objectForKey:@"client_id"] != nil) {
		turl = [NSString stringWithFormat:@"%@?client_id=%@&token=%@", _url, 
				[GroupMeRequest encodeURLParameter:[_params objectForKey:@"client_id"]], 
				[GroupMeRequest encodeURLParameter:[_params objectForKey:@"token"]]];
	} else {
		turl = _url;
	}
	
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:turl]
														   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
													   timeoutInterval:kTimeout];
	
	[request setHTTPMethod:self.requestMethod];
	[request setValue:kGroupMeUserAgent forHTTPHeaderField:@"User-Agent"];
	
	if (![self.requestMethod isEqualToString: @"GET"]) {
		if (explicitBody) {
			[request setHTTPBody:[_params objectForKey:@"_body"]];
		} else {
			[request setHTTPBody:[_queryString dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	
//	NSLog(@"Starting GroupMeRequest: %@ %@\nParams: %@", _requestMethod, turl, _params);
	
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void) cancel {
	[_connection cancel];
}


#pragma mark -
#pragma mark Private Helpers

- (void) failWithError:(NSError *)error {
	if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[_delegate request:self didFailWithError:error];
	}
}

- (void) handleResponseData:(NSData *)data {
	if ([_delegate respondsToSelector:@selector(request:didLoadRawResponse:)]) {
		[_delegate request:self didLoadRawResponse:data];
	}
	
	if ([_delegate respondsToSelector:@selector(request:didLoad:)] ||
		[_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		NSError* error = nil;
		id result = ([data length] > 0 ? [data objectFromJSONDataWithParseOptions:JKParseOptionNone error:&error] : nil);
		if ([_delegate respondsToSelector:@selector(request:didLoad:)]) {
//			NSLog(@"GroupMeRequest response: %@", result);
			
			NSDictionary *responsePayload = nil;
			
			if ([result isKindOfClass:[NSDictionary class]]) {
				responsePayload = [(NSDictionary*)result objectForKey:@"response"];
				if ([[(NSDictionary*)result objectForKey:@"meta"] objectForKey:@"errors"]) {
					self.errors = [[(NSDictionary*)result objectForKey:@"meta"] objectForKey:@"errors"];
				}
			}
			
			[_delegate request:self didLoad:responsePayload];
		}
	}
}

+ (NSString *)encodeQueryStringFromParams:(NSDictionary*)params {
	
	NSMutableArray* pairs = [NSMutableArray array];
	for (NSString* key in [params keyEnumerator]) {
		
		NSString* escaped_value = [self encodeURLParameter:[params valueForKey:key]];
		
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
	}
	return [pairs componentsJoinedByString:@"&"];

}


+ (NSString *)encodeURLParameter:(NSString*)input {
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)input,
                                                                           NULL,
                                                                           CFSTR(":/=,!$&'()*+;[]@#?"),
                                                                           kCFStringEncodingUTF8);
	return [result autorelease];
}

#pragma mark -
#pragma mark Memory

- (void) dealloc {
	[_connection cancel];
	[_connection release];
	[_responseData release];
	[_requestId release];
	[_requestMethod release];
	[_queryString release];
	[_params release];
	[_url release];
	[_errors release];
	
	[super dealloc];
}


//////////////////////////////////////////////////////////////////////////////////////////////////
// NSURLConnectionDelegate

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	_responseData = [[NSMutableData alloc] init];
	
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
//	NSLog(@"GroupMeRequest status code: %d :%@ ", [httpResponse statusCode], _url);

	_statusCode = [httpResponse statusCode];
	
	if ([_delegate respondsToSelector:@selector(request:didReceiveResponse:)]) {
		[_delegate request:self didReceiveResponse:httpResponse];
	}
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
				  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
	return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
	[self handleResponseData:_responseData];
	
	[_responseData release];
	_responseData = nil;
	[_connection release];
	_connection = nil;
	
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self failWithError:error];
	
	[_responseData release];
	_responseData = nil;
	[_connection release];
	_connection = nil;
}

@end
