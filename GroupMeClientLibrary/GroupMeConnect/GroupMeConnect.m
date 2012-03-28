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


#import "GroupMeConnect.h"
#import "JSONKit.h"

#define GROUP_ME_DEFAULT_DEVICE_ID @"GroupMeDeviceId"
#define GROUP_ME_DEFAULT_TOKEN @"GroupMeToken"
#define GROUP_ME_DEFAULT_USER_ID @"GroupMeUserId"
#define GROUP_ME_DEFAULT_NAME @"GroupMeName"
#define GROUP_ME_DEFAULT_LAST_PHONE_ATTEMPTED @"GroupMeLastPhoneAttempted"
#define GROUP_ME_DEFAULT_HAS_SENT_PIN @"GroupMeHasSentPIN"
#define GROUP_ME_DEFAULT_GROUPS @"GroupMeGroups"

#define GROUP_ME_AUTH_CLIENT_CREDENTIALS @"client_credentials"
#define GROUP_ME_AUTH_WITH_PIN @"authorization_code"
#define GROUP_ME_AUTH_SAVE_NAME @"save_name"

//#define TEST_DEVICE_ID @"jeremytest4"

static BOOL _storeStateInDefaults = NO;
static NSString *_defaultGroupName = @"My Group";
static NSString *_clientId = nil;
static NSString *_clientSecret = nil;
static NSString *_callbackUrl = nil;
static NSString *_callbackTitle = nil;
static NSString *_defaultAddressBookPrefix = @"GroupMe";
static GroupMeConnect *_sharedGroupMe = nil;


@implementation GroupMeConnect

@synthesize token = _token;
@synthesize userId = _userId;
@synthesize name = _name;
@synthesize registrationDelegate = _registrationDelegate;
@synthesize sendSMSAsDefaultWhenAvailable = _sendSMSAsDefaultWhenAvailable;
@synthesize showGroupMeLinkOnBottomOfGroupView = _showGroupMeLinkOnBottomOfGroupView;
@synthesize hideGroupMeLinkInGroupView = _hideGroupMeLinkInGroupView;
@dynamic groups;

#pragma mark -
#pragma mark Initialization

- (GroupMeConnect*) init {
	self = [super init];
	if (self) {
		
		_hasSentPIN = NO;
		_hideGroupMeLinkInGroupView = NO;
		_showGroupMeLinkOnBottomOfGroupView = NO;
		
		if (_storeStateInDefaults 
			&& [[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_TOKEN] != nil 
			&& [[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_USER_ID] != nil) 
		{
			self.token = [[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_TOKEN];
			self.userId = [[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_USER_ID];
			self.name = [[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_NAME];
			_lastPhoneNumber = [[[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_LAST_PHONE_ATTEMPTED] copy];
			if ([[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_GROUPS] != nil) 
			{
				_groups = [[[[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_GROUPS] objectFromJSONString] copy];
			}
		} 
		else if (_storeStateInDefaults && [[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_LAST_PHONE_ATTEMPTED] != nil) 
		{
			_lastPhoneNumber = [[[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_LAST_PHONE_ATTEMPTED] copy];
			if ([[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_HAS_SENT_PIN]) 
			{
				_hasSentPIN = [[NSUserDefaults standardUserDefaults] boolForKey:GROUP_ME_DEFAULT_HAS_SENT_PIN];
			}
		}


	}
	return self;
}

+ (GroupMeConnect*)sharedGroupMe {
	if (_sharedGroupMe == nil && _clientId != nil && _clientSecret != nil) {
		_sharedGroupMe = [[GroupMeConnect alloc] init];
	}
	
	return _sharedGroupMe;
}

#pragma mark - Generate Device Ids

+ (NSString *)hexForData:(NSData*)theData {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
	
    const unsigned char *dataBuffer = (const unsigned char *)[theData bytes];
	
    if (!dataBuffer)
        return [NSString string];
	
    NSUInteger          dataLength  = [theData length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
	
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02x", (unsigned long)dataBuffer[i]]];
	
    return [NSString stringWithString:hexString];
}

+ (NSString *) secureRandomDeviceId {
	
	NSMutableData *data = [NSMutableData dataWithLength:40];
	
	int result = SecRandomCopyBytes(kSecRandomDefault, 
									40,
									data.mutableBytes);
	
	if (result == 0) {
		return [self hexForData:data];
	} else {
		return nil;
	}
}

- (NSString*) secureDeviceId {
	NSString *deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:GROUP_ME_DEFAULT_DEVICE_ID];
	if (deviceId == nil) {
		deviceId = [GroupMeConnect secureRandomDeviceId];
		[[NSUserDefaults standardUserDefaults] setValue:deviceId forKey:GROUP_ME_DEFAULT_DEVICE_ID];
	}
	return deviceId;
}

#pragma mark - Dynamic Properties

- (void) addGroupToGroups:(NSDictionary*)group {
	
	if ([self groups] != nil) {
		self.groups = [[self groups] arrayByAddingObject:group];
	} else {
		self.groups = [NSArray arrayWithObject:group];
	}
	
}

- (void) removeGroupFromGroups:(NSDictionary*)group {
	
	if ([self groups] != nil && [[self groups] containsObject:group]) {
		NSMutableArray *newGroups = [[self groups] mutableCopy];
		[newGroups removeObject:group];
		self.groups = newGroups;
		[newGroups release];
	}
	
}

- (NSArray*) groups {
	return _groups;
}

- (void) setGroups:(NSArray*)groups {
	[_groups release];
	_groups = nil;
	
	
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"updated_at" ascending:NO];
	_groups = [[groups sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]] retain];
	[sd release];
	
	if (_storeStateInDefaults && _groups) {
		[[NSUserDefaults standardUserDefaults] setObject:[_groups JSONString] forKey:GROUP_ME_DEFAULT_GROUPS];
		[[NSUserDefaults standardUserDefaults] synchronize];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:GROUP_ME_DEFAULT_GROUPS];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

}

- (NSDictionary*) groupForExternalId:(NSString*)externalId {

	//experimental - don't try anything with external_id's for now
	if ([_groups count] > 0) {
		
		for (NSDictionary* group in _groups) {
			if ([[group objectForKey:@"external_id"] isEqualToString:externalId]) {
				return group;
			}
		}
	}
	return nil;
}

#pragma mark -
#pragma mark Requests

- (GroupMeRequest*)requestWithMethodName:(NSString *)methodName
							   andParams:(NSMutableDictionary *)params
						   andHttpMethod:(NSString *)httpMethod
							andRequestId:(NSString *)requestId
							 andDelegate:(id <GroupMeRequestDelegate>)delegate {
	
	
	GroupMeRequest *req = [[[GroupMeRequest alloc] init] autorelease];
	
	if (params == nil) {
		params = [NSMutableDictionary dictionary];
	}
	
	if (_token) {
		[params setValue:_token forKey:@"token"];
	}
	
	if (_clientId) {
		[params setValue:_clientId forKey:@"client_id"];
	}
	
	
	req.params = params;
	req.url = [NSString stringWithFormat:@"%@/clients/%@", GROUP_ME_BASE_API_URL, methodName];
	req.requestMethod = httpMethod;
	req.requestId = requestId;
	req.delegate = delegate;
	
	[req start];
	
	return req;
	
}


#pragma mark -
#pragma mark Authorization

- (void) authorizeForPhoneNumber:(NSString*)phoneNumber andDelegate:(id<GroupMeRegistrationDelegate>)delegate {
	self.registrationDelegate = delegate;
	_lastPhoneNumber = [phoneNumber copy];
	
	if (_storeStateInDefaults) {
		[[NSUserDefaults standardUserDefaults] setObject:_lastPhoneNumber forKey:GROUP_ME_DEFAULT_LAST_PHONE_ATTEMPTED];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[params setValue:_clientId forKey:@"client_id"];
	[params setValue:_clientSecret forKey:@"client_secret"];

	[params setValue:phoneNumber forKey:@"phone_number"];
	[params setValue:[self secureDeviceId] forKey:@"device_id"];
#ifdef TEST_DEVICE_ID
	[params setValue:TEST_DEVICE_ID forKey:@"device_id"];
#endif

	[params setValue:GROUP_ME_AUTH_CLIENT_CREDENTIALS forKey:@"grant_type"];
	
	GroupMeRequest *req = [[[GroupMeRequest alloc] init] autorelease];

	req.params = params;
	req.url = [NSString stringWithFormat:@"%@/clients/tokens", GROUP_ME_BASE_API_URL];
	req.requestMethod = @"POST";
	req.requestId = GROUP_ME_AUTH_CLIENT_CREDENTIALS;
	req.delegate = self;
	
	[req start];

}


- (void) validatePin:(NSString*)pin andDelegate:(id<GroupMeRegistrationDelegate>)delegate {

	self.registrationDelegate = delegate;
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[params setValue:_clientId forKey:@"client_id"];
	[params setValue:_clientSecret forKey:@"client_secret"];
	
	[params setValue:_lastPhoneNumber forKey:@"phone_number"];
	[params setValue:[pin uppercaseString] forKey:@"code"];
	[params setValue:[self secureDeviceId] forKey:@"device_id"];
#ifdef TEST_DEVICE_ID
	[params setValue:TEST_DEVICE_ID forKey:@"device_id"];
#endif
	
	
	[params setValue:GROUP_ME_AUTH_WITH_PIN forKey:@"grant_type"];
	
	
	GroupMeRequest *req = [[[GroupMeRequest alloc] init] autorelease];
	
	req.params = params;
	req.url = [NSString stringWithFormat:@"%@/clients/tokens", GROUP_ME_BASE_API_URL];
	req.requestMethod = @"POST";
	req.requestId = GROUP_ME_AUTH_WITH_PIN;
	req.delegate = self;

	[req start];

	
}

- (void) saveName:(NSString*)name andDelegate:(id<GroupMeRegistrationDelegate>)delegate {
	
	self.registrationDelegate = delegate;

	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[params setValue:name forKey:@"user[name]"];

	[self requestWithMethodName:[NSString stringWithFormat:@"users/%@", self.userId] 
					  andParams:params
				  andHttpMethod:@"PUT"
				   andRequestId:GROUP_ME_AUTH_SAVE_NAME
					andDelegate:self];
	
}



#pragma mark - Groups

- (GroupMeRequest*) createGroupWithName:(NSString*)groupName andMembers:(NSArray*)members andDelegate:(id<GroupMeRequestDelegate>)delegate {
	
	//https://api.groupme.com/clients/YOUR_CLIENT_ID/groups
	
	NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithCapacity:1];
	NSMutableDictionary *group = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[payload setObject:group forKey:@"group"];
	
	[group setObject:groupName forKey:@"topic"];
	[group setObject:members forKey:@"memberships"];
	
	NSData *jsonData = [payload JSONData];
	
	return [self requestWithMethodName:@"groups" 
							 andParams:[NSMutableDictionary dictionaryWithObject:jsonData forKey:@"_body"] 
						 andHttpMethod:@"POST"
						  andRequestId:nil
						   andDelegate:delegate];
	
	
}

- (GroupMeRequest*) refreshGroupsWithDelegate:(id<GroupMeRequestDelegate>)delegate {
	
	return [self requestWithMethodName:@"groups" 
							 andParams:nil 
						 andHttpMethod:@"GET"
						  andRequestId:nil
						   andDelegate:delegate];
}


- (GroupMeRequest*) postMessage:(NSString*) message toGroup:(NSDictionary*)group andDelegate:(id<GroupMeRequestDelegate>)delegate {
	return [self postMessage:message toGroup:group withLocationName:nil atLatitude:nil andLongitude:nil andDelegate:delegate];
}


- (GroupMeRequest*) postMessage:(NSString*) message toGroup:(NSDictionary*)group withLocationName:(NSString*)locationName atLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude andDelegate:(id<GroupMeRequestDelegate>)delegate {
	
	NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithCapacity:1];
	NSMutableDictionary *line = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[payload setObject:line forKey:@"line"];
	
	[line setObject:message forKey:@"text"];
	
	if (locationName != nil && longitude != nil && latitude != nil) {
		NSMutableDictionary *location = [NSMutableDictionary dictionaryWithCapacity:3];
		[location setObject:locationName forKey:@"name"];
		[location setObject:[latitude stringValue] forKey:@"lat"];
		[location setObject:[longitude stringValue] forKey:@"lng"];
		[line setObject:location forKey:@"location"];
	}
	
	NSData *jsonData = [payload JSONData];
	
	return [self requestWithMethodName:[NSString stringWithFormat:@"groups/%@/lines", [group objectForKey:@"id"]] 
							 andParams:[NSMutableDictionary dictionaryWithObject:jsonData forKey:@"_body"] 
						 andHttpMethod:@"POST"
						  andRequestId:nil
						   andDelegate:delegate];
	
}
#pragma mark - Session

- (void) clearSession {
	self.token = nil;
	self.userId = nil;
	self.name = nil;
	self.groups = nil;
	[_lastPhoneNumber release];
	_lastPhoneNumber = nil;
	_hasSentPIN = NO;
	if ([[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_TOKEN] != nil 
		|| [[NSUserDefaults standardUserDefaults] objectForKey:GROUP_ME_DEFAULT_LAST_PHONE_ATTEMPTED] != nil) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:GROUP_ME_DEFAULT_TOKEN];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:GROUP_ME_DEFAULT_USER_ID];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:GROUP_ME_DEFAULT_NAME];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:GROUP_ME_DEFAULT_LAST_PHONE_ATTEMPTED];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:GROUP_ME_DEFAULT_GROUPS];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:GROUP_ME_DEFAULT_HAS_SENT_PIN];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	
}

- (NSString*) lastPhoneNumberAttempted {
	return _lastPhoneNumber;
}

- (BOOL) hasSentPIN {
	return _hasSentPIN;
}

- (BOOL) userMissingName {
	return (_token != nil && _name == nil);
}


#pragma mark -
#pragma mark Sessions

- (BOOL) isSessionValid {
	return (_token != nil && _userId != nil && _name != nil);
}

#pragma mark -
#pragma mark Configuration

+ (void) setClientId:(NSString*)clientId andClientSecret:(NSString*)clientSecret {
	_clientId = [clientId retain];
	_clientSecret = [clientSecret retain];
}

+ (void) storeStateInUserDefaults:(BOOL)storeIt {
	_storeStateInDefaults = storeIt;
}

+ (void) setDefaultGroupName:(NSString*)groupName {
	[_defaultGroupName release]; 
	_defaultGroupName = [groupName copy];
}

+ (NSString*)defaultGroupName {
	return _defaultGroupName;
}

+ (void) setDefaultAddressBookPrefix:(NSString*)prefix {
	[_defaultAddressBookPrefix release]; 
	_defaultAddressBookPrefix = [prefix copy];
}

+ (NSString*)defaultAddressBookPrefix {
	return _defaultAddressBookPrefix;
}

+ (void) setDefaultCallbackUrl:(NSString*)url andTitle:(NSString*)title {
	[_callbackUrl release];
	[_callbackTitle release];
	_callbackUrl = [url copy];
	_callbackTitle = [title copy];
	
}

- (void) dealloc {
	[_lastPhoneNumber release];
	[_groups release];
	[_token release];
	[_userId release];
	[super dealloc];
}

#pragma mark - Inter-app stuff

+ (BOOL) hasGroupMeAppInstalled {
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/test", GROUP_ME_PROTOCOL]]];
}
			
+ (void) openGroupMeAppForGroup:(NSDictionary*)group {

	//new iphone app can take group_id
	if ([group objectForKey:@"id"] != nil && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/client", GROUP_ME_CALLBACK_PROTOCOL]]]) {
		if (_callbackUrl != nil) {
			
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@client?gid=%@&callback=%@&title=%@", 
																			 GROUP_ME_CALLBACK_PROTOCOL, 
																			 [group objectForKey:@"id"],
																			 [GroupMeRequest encodeURLParameter:_callbackUrl],
																			 (_callbackTitle != nil ? [GroupMeRequest encodeURLParameter:_callbackTitle] : @"")
																			 ]]];
			
		} else {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@client?gid=%@", GROUP_ME_CALLBACK_PROTOCOL, [group objectForKey:@"id"]]]];
		}
	//old one can only handle phone numbers
	} else if ([group objectForKey:@"phone_number"] != nil && [[group objectForKey:@"phone_number"] isKindOfClass:[NSString class]]) {
		NSString *normalizedPhoneNumber = [self normalizePhoneNumber:[group objectForKey:@"phone_number"]];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", GROUP_ME_PROTOCOL, normalizedPhoneNumber]]];
	}
}

+ (void) openGroupMeAppForGroup:(NSDictionary*)group withCallBackUrl:(NSString*)url andCallbackTitle:(NSString*)title {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/client", GROUP_ME_CALLBACK_PROTOCOL]]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@client?gid=%@&callback=%@&title=%@", 
																		 GROUP_ME_CALLBACK_PROTOCOL, 
																		 [group objectForKey:@"id"],
																		 [GroupMeRequest encodeURLParameter:url],
																		 (title != nil ? [GroupMeRequest encodeURLParameter:title] : @"")
																		 ]]];
	} else {
		[self openGroupMeAppForGroup:group];
	}
}

+ (void) downloadGroupMeApp {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:GROUP_ME_DOWNLOAD_URL]];
}


#pragma mark -
#pragma mark Versions

+ (NSString*) version {
	return GROUP_ME_CONNECT_VERSION;
}

+ (NSString*) sdkType {
	return GROUP_ME_CONNECT_SDK_TYPE;
}

#pragma mark -
#pragma mark GroupMeRequestDelegate

- (BOOL) requestIsForNameUpdate:(GroupMeRequest*)request {
	return [request.requestId isEqualToString:GROUP_ME_AUTH_SAVE_NAME];
}

- (BOOL) requestIsForClientCredentials:(GroupMeRequest*)request {
	return [request.requestId isEqualToString:GROUP_ME_AUTH_CLIENT_CREDENTIALS];
}

- (BOOL) requestIsForAuthWithPIN:(GroupMeRequest*)request {
	return [request.requestId isEqualToString:GROUP_ME_AUTH_WITH_PIN];
}

- (void)request:(GroupMeRequest *)request didReceiveResponse:(NSURLResponse *)response {
	
	if ([(NSHTTPURLResponse*)response statusCode] == 401) {
		if ([self requestIsForClientCredentials:request]) {
			if ([_registrationDelegate respondsToSelector:@selector(groupMeRequiresPIN)]) {
				[_registrationDelegate groupMeRequiresPIN];
				_hasSentPIN = YES;
				if (_storeStateInDefaults) {
					[[NSUserDefaults standardUserDefaults] setBool:_hasSentPIN forKey:GROUP_ME_DEFAULT_HAS_SENT_PIN];
					[[NSUserDefaults standardUserDefaults] synchronize];
				}

			}
		} else if ([self requestIsForAuthWithPIN:request]) {
			if ([_registrationDelegate respondsToSelector:@selector(groupMeInvalidPIN)]) {
				[_registrationDelegate groupMeInvalidPIN];
			}
		} else if ([self requestIsForNameUpdate:request]) {
			if ([_registrationDelegate respondsToSelector:@selector(groupMeFailedUpdatingName)]) {
				[_registrationDelegate groupMeFailedUpdatingName];
			}
		}
		
		request.delegate = nil;
		[request cancel];
		
	}
}

- (void)request:(GroupMeRequest *)request didFailWithError:(NSError *)error {
	if ([self requestIsForNameUpdate:request]) {
		if ([_registrationDelegate respondsToSelector:@selector(groupMeFailedUpdatingName)]) {
			[_registrationDelegate groupMeFailedUpdatingName];
		}
	} else if ([_registrationDelegate respondsToSelector:@selector(groupMeDidNotRegister:)]) {
		[_registrationDelegate groupMeDidNotRegister:NO];
	}
	
}

- (void)request:(GroupMeRequest *)request didLoad:(id)result {
	
	if ([self requestIsForNameUpdate:request]) {
		if ([result isKindOfClass:[NSDictionary class]]
			&& [[(NSDictionary*)result objectForKey:@"user"] objectForKey:@"name"] != nil) {
			self.name = [[(NSDictionary*)result objectForKey:@"user"] objectForKey:@"name"];
			if (_storeStateInDefaults) {
				[[NSUserDefaults standardUserDefaults] setObject:_name forKey:GROUP_ME_DEFAULT_NAME];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
			if ([_registrationDelegate respondsToSelector:@selector(groupMeDidRegister)]) {
				[_registrationDelegate groupMeDidRegister];
			}
		} else {
			if ([_registrationDelegate respondsToSelector:@selector(groupMeFailedUpdatingName)]) {
				[_registrationDelegate groupMeFailedUpdatingName];
			}
		}
	} else if ([result isKindOfClass:[NSDictionary class]] 
		&& [(NSDictionary*)result objectForKey:@"access_token"] != nil
		&& [(NSDictionary*)result objectForKey:@"user_id"] != nil) {
		self.token = [(NSDictionary*)result objectForKey:@"access_token"];
		if ([[(NSDictionary*)result objectForKey:@"user_id"] isKindOfClass:[NSString class]]) {
			self.userId = [(NSDictionary*)result objectForKey:@"user_id"];
		} else {
			self.userId = [[(NSDictionary*)result objectForKey:@"user_id"] stringValue];
		}
		if ([(NSDictionary*)result objectForKey:@"user_name"] != nil 
			&& [[(NSDictionary*)result objectForKey:@"user_name"] isKindOfClass:[NSString class]]
			&& [(NSString*)[(NSDictionary*)result objectForKey:@"user_name"] length] > 0) {
			self.name = [(NSDictionary*)result objectForKey:@"user_name"];
		}

		if (_name == nil) {
			if ([_registrationDelegate respondsToSelector:@selector(groupMeRequiresName)]) {
				[_registrationDelegate groupMeRequiresName];
			}
		} else if ([_registrationDelegate respondsToSelector:@selector(groupMeDidRegister)]) {
			[_registrationDelegate groupMeDidRegister];
		}
		
		if (_storeStateInDefaults) {
			[[NSUserDefaults standardUserDefaults] setObject:_token forKey:GROUP_ME_DEFAULT_TOKEN];
			[[NSUserDefaults standardUserDefaults] setObject:_userId forKey:GROUP_ME_DEFAULT_USER_ID];
			if (_name != nil)
				[[NSUserDefaults standardUserDefaults] setObject:_name forKey:GROUP_ME_DEFAULT_NAME];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	} else {
		if ([_registrationDelegate respondsToSelector:@selector(groupMeDidNotRegister:)]) {
			[_registrationDelegate groupMeDidNotRegister:NO];
		}
	}
	
}

#pragma mark - Contact Validation

+ (NSString *)normalizePhoneNumber:(NSString*)input {
	NSMutableString *shortNumber = [NSMutableString string];
	
	for (int i = 0; i < [input length]; i++) {
		unichar ch = [input characterAtIndex:i];
		if (('0' <= ch && ch <= '9') || (ch == '+' && i == 0))
			[shortNumber appendFormat:@"%c", ch];
	}
	
	if ([shortNumber length] == 12 && [shortNumber hasPrefix:@"+1"])
		[shortNumber deleteCharactersInRange:NSMakeRange(0, 2)];

	if ([shortNumber length] == 11 && [shortNumber characterAtIndex:0] == '1')
		[shortNumber deleteCharactersInRange:NSMakeRange(0, 1)];
	
	return shortNumber;	
}

+ (NSString *)formatPhoneNumber:(NSString*)input {
	
	input = [self normalizePhoneNumber:input];
	
	if ([input length] == 10) {
		
		NSString *pretty = [NSString string];
		
		int i;
		for (i = 0; i < [input length]; i++) {
			switch (i) {
				case 0:
					pretty = [pretty stringByAppendingFormat:@"(%c", [input characterAtIndex:i]];
					break;
				case 2:
					pretty = [pretty stringByAppendingFormat:@"%c", [input characterAtIndex:i]];
					break;
				case 3:
					pretty = [pretty stringByAppendingFormat:@") %c", [input characterAtIndex:i]];
					break;
				case 6:
					pretty = [pretty stringByAppendingFormat:@"-%c", [input characterAtIndex:i]];
					break;
				default:
					pretty = [pretty stringByAppendingFormat:@"%c", [input characterAtIndex:i]];
					break;
			}
		}
		
		return pretty;
	} else {
		return input;
	}
}

+ (BOOL) validateEmail:(NSString*)input {

	NSString *emailRegEx =
    @"(?:[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-zA-Z0-9](?:[a-"
    @"zA-Z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
	
	NSPredicate *regExPredicate =
    [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
	
	return [regExPredicate evaluateWithObject:input]; 
	
}

+ (BOOL) validatePhone:(NSString*)input {
	
	NSString *normal = [self normalizePhoneNumber:input];
	
	//if not international, it has to be 10
	if (![normal hasPrefix:@"+"] && [normal length] == 10) {
		return YES;
	}
	
	//else it has to start with a +
	if ([normal hasPrefix:@"+"] && [normal length] >= 10) {
		return YES;
	}
	return NO;
	
}

#pragma mark - Alerts etc

+ (UIAlertView*) workingAlertViewWithTitle:(NSString*)title andMessage:(NSString*)message {

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
											message:message 
										   delegate:nil 
								  cancelButtonTitle:nil
								  otherButtonTitles:nil];
	
	[alertView sizeToFit];
	
	UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	[spinner sizeToFit];
	spinner.frame = CGRectMake(fabsf(280.0f/2 - spinner.frame.size.width/2), 
							   80.0f, 
							   spinner.frame.size.width, 
							   spinner.frame.size.height);
	[alertView addSubview:spinner];
	[spinner startAnimating];
	
	[alertView show];
	
	return [alertView autorelease];
}

+ (void) showError:(NSString*)errorMessage {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
													message:errorMessage 
												   delegate:nil 
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
}

@end
