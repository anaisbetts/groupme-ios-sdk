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

#pragma mark - Constants

#define GROUP_ME_CONNECT_SDK_TYPE @"ios"
#define GROUP_ME_CONNECT_VERSION @"1.0"
#define GROUP_ME_PROTOCOL @"groupme://"
#define GROUP_ME_CALLBACK_PROTOCOL @"groupmecb://"
#define GROUP_ME_DOWNLOAD_URL @"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=392796698"
#define GROUP_ME_BASE_API_URL @"https://api.groupme.com"

#pragma mark - Colors

#define GROUP_ME_BRANDING_DARK_BLUE [UIColor colorWithRed:0.102 green:0.376 blue:0.502 alpha:1.000]
#define GROUP_ME_BRANDING_BLUE [UIColor colorWithRed:0.165 green:0.533 blue:0.686 alpha:1.000]
#define GROUP_ME_BRANDING_BACKGROUND [UIColor colorWithRed:0.925 green:0.922 blue:0.906 alpha:1.000]


#import "GroupMeRequest.h"

#pragma mark - Protocols/Interfaces 

@protocol GroupMeRegistrationDelegate;

@interface GroupMeConnect : NSObject <GroupMeRequestDelegate> {
    NSString						*_token;
    NSString						*_userId;
    NSString						*_name;
	NSString						*_lastPhoneNumber;
	BOOL							_hasSentPIN;
	id<GroupMeRegistrationDelegate> _registrationDelegate;
	NSArray							*_groups;
}

#pragma mark - Properties

@property (nonatomic, retain) NSString	*token;
@property (nonatomic, retain) NSString	*name;
@property (nonatomic, retain) NSString	*userId;
@property (nonatomic, retain) NSArray	*groups;
@property (nonatomic, assign) id<GroupMeRegistrationDelegate> registrationDelegate;


#pragma mark - Singleton

+ (GroupMeConnect*)sharedGroupMe;

#pragma mark - Configuration
//Sets whether the token should be stored in the NSUserDefaults.
//This isn't the most secure thing, you should really store it in your keychain.
+ (void) storeStateInUserDefaults:(BOOL)storeIt; 

+ (void) setClientId:(NSString*)clientId andClientSecret:(NSString*)clientSecret;

+ (void) setDefaultGroupName:(NSString*)groupName;
+ (NSString*)defaultGroupName;

+ (void) setDefaultCallbackUrl:(NSString*)url andTitle:(NSString*)title;

+ (NSString*) version;
+ (NSString*) sdkType;

#pragma mark - Inter-app stuff

+ (BOOL) hasGroupMeAppInstalled;
+ (void) openGroupMeAppForGroup:(NSDictionary*)group;
+ (void) openGroupMeAppForGroup:(NSDictionary*)group withCallBackUrl:(NSString*)url andCallbackTitle:(NSString*)title;
+ (void) downloadGroupMeApp;

#pragma mark - Initialization

- (BOOL) isSessionValid;
- (void) clearSession;

#pragma mark - Generic Requests

// if you pass a value in the params with the key _body, it won't create a query stream, but rather serialize that value as JSON and send it as the body.
// see the createGroupWithName implementation for an example

- (GroupMeRequest*)requestWithMethodName:(NSString *)methodName
							   andParams:(NSMutableDictionary *)params
						   andHttpMethod:(NSString *)httpMethod
							andRequestId:(NSString *)requestId
							 andDelegate:(id <GroupMeRequestDelegate>)delegate;

#pragma mark - Registration Requests

- (void) authorizeForPhoneNumber:(NSString*)phoneNumber andDelegate:(id<GroupMeRegistrationDelegate>)delegate;
- (void) validatePin:(NSString*)pin andDelegate:(id<GroupMeRegistrationDelegate>)delegate;
- (void) saveName:(NSString*)name andDelegate:(id<GroupMeRegistrationDelegate>)delegate;

#pragma mark - Group Related Request

- (GroupMeRequest*) createGroupWithName:(NSString*)groupName andMembers:(NSArray*)members andDelegate:(id<GroupMeRequestDelegate>)delegate;
- (GroupMeRequest*) refreshGroupsWithDelegate:(id<GroupMeRequestDelegate>)delegate;
- (GroupMeRequest*) postMessage:(NSString*) message toGroup:(NSDictionary*)group andDelegate:(id<GroupMeRequestDelegate>)delegate;
- (GroupMeRequest*) postMessage:(NSString*) message toGroup:(NSDictionary*)group withLocationName:(NSString*)locationName atLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude andDelegate:(id<GroupMeRequestDelegate>)delegate;

#pragma mark - Helpers

- (NSString*) lastPhoneNumberAttempted;
- (BOOL) hasSentPIN;
- (BOOL) userMissingName;

+ (NSString *) normalizePhoneNumber:(NSString*)input;
+ (NSString *)formatPhoneNumber:(NSString*)input;
+ (BOOL) validateEmail:(NSString*)input;
+ (BOOL) validatePhone:(NSString*)input;

- (void) addGroupToGroups:(NSDictionary*)group;
- (void) removeGroupFromGroups:(NSDictionary*)group;

- (NSDictionary*) groupForExternalId:(NSString*)externalId;

#pragma mark - Alerts etc

+ (UIAlertView*) workingAlertViewWithTitle:(NSString*)title andMessage:(NSString*)message;
+ (void) showError:(NSString*)errorMessage;

@end

#pragma mark - Delegate Protocol

//This is the delegate protocol to implement if you are handling login requests on your own.

@protocol GroupMeRegistrationDelegate <NSObject>

@optional

//Called when user successfulling logs in
- (void)groupMeDidRegister;

//Called when user needs to submit a PIN to verify number, it will be sent via SMS
- (void)groupMeRequiresPIN;

//Called when user needs to submit a PIN to verify number, it will be sent via SMS
- (void)groupMeRequiresName;

//Called when user needs to submit a PIN to verify number, it will be sent via SMS
- (void)groupMeInvalidPIN;

//Called when user needs to submit a PIN to verify number, it will be sent via SMS
- (void)groupMeFailedUpdatingName;

//Called when user does not log in
- (void)groupMeDidNotRegister:(BOOL)cancelled;

@end
