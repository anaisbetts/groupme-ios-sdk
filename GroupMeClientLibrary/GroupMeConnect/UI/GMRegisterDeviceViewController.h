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


#import <UIKit/UIKit.h>

#import "GroupMeConnect.h"

@interface GMRegisterDeviceViewController : UITableViewController <GroupMeRegistrationDelegate, GroupMeRequestDelegate, UITextFieldDelegate> {
    
	NSString							*_externalGroupId;
	id<GroupMeRegistrationDelegate>		_registrationDelegate;
	
	UITextField							*_inputField;
	UIButton							*_actionButton;
	UIAlertView							*_alertView;

}

@property (nonatomic, assign) 	id<GroupMeRegistrationDelegate> registrationDelegate;
@property (nonatomic, retain) 	NSString						*externalGroupId;



+ (void) showRegistrationInViewController:(UIViewController*)vc 
							  andDelegate:(id<GroupMeRegistrationDelegate>)regDelegate;

+ (void) showRegistrationInViewController:(UIViewController*)vc 
					   andExternalGroupId:(NSString*)externalId
							  andDelegate:(id<GroupMeRegistrationDelegate>)regDelegate;

@end
