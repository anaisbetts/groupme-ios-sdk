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
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "GroupMeConnect.h"
#import "GMCreateContactViewController.h"

@protocol GMCreateGroupControllerDelegate;

@interface GMCreateGroupController : UITableViewController <ABPeoplePickerNavigationControllerDelegate, GMCreateContactViewControllerDelegate, GroupMeRequestDelegate, UITextFieldDelegate> {
	UITextField							*_groupName;
	UIButton							*_addContactFromAddressBookButton;
	UIButton							*_enterNewContactButton;
	NSMutableArray						*_contacts;
	UIAlertView							*_alertView;
	NSString							*_externalGroupId;
	id<GMCreateGroupControllerDelegate>	_groupCreateDelegate;

}

@property (nonatomic, retain)	NSString *externalGroupId;
@property (nonatomic, assign)	NSString *groupName;
@property (nonatomic, assign)	id<GMCreateGroupControllerDelegate>	groupCreateDelegate;
@property (nonatomic, retain) NSMutableArray* contacts;

+ (void) showGroupCreationInViewController:(UIViewController*)vc
							   andDelegate:(id<GMCreateGroupControllerDelegate>)delegate;

+ (void) showGroupCreationInViewController:(UIViewController*)vc
								  withName:(NSString*)groupName
							   andDelegate:(id<GMCreateGroupControllerDelegate>)delegate;

+ (void) showGroupCreationInViewController:(UIViewController*)vc 
								  withName:(NSString*)groupName
						andExternalGroupId:(NSString*)externalId
							   andDelegate:(id<GMCreateGroupControllerDelegate>)delegate;

@end


@protocol GMCreateGroupControllerDelegate <NSObject>

@optional

//Called when user picks a group
- (void)groupMeCreatedGroup:(NSDictionary*)group;

//Called if they cancel picking a group
- (void)groupMeDismissedGroupCreate;

@end
