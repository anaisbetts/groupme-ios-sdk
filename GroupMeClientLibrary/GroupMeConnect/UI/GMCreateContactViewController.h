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

@protocol GMCreateContactViewControllerDelegate;

@interface GMCreateContactViewController : UITableViewController <UITextFieldDelegate> {
    UITextField									*_nameField, *_infoField;
	NSArray										*_blacklistedNames;
	id<GMCreateContactViewControllerDelegate>	delegate;
}

@property (nonatomic, assign) id<GMCreateContactViewControllerDelegate>	delegate;

- (id)initWithContactName:(NSString*)contactName
		   andContactInfo:(NSString*)contactInfo
andBlacklistedContactNames:(NSArray*)blacklistedContactNames;

+ (void) showContactCreationInViewController:(UIViewController*)vc 
							 withContactName:(NSString*)contactName
							  andContactInfo:(NSString*)contactInfo
				  andBlacklistedContactNames:(NSArray*)blacklistedContactNames
								 andDelegate:(id<GMCreateContactViewControllerDelegate>)contactCreateDelegate;

@end


@protocol GMCreateContactViewControllerDelegate <NSObject>

@optional

- (void)createdContactWithEmail:(NSString *)email withName:(NSString*)name;
- (void)createdContactWithPhoneNumber:(NSString *)phoneNumber withName:(NSString*)name;

@end
