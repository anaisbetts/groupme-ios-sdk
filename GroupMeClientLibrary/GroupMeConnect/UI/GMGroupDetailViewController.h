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



@interface GMGroupDetailViewController : UITableViewController <GroupMeRequestDelegate, ABPeoplePickerNavigationControllerDelegate, UIActionSheetDelegate, GMCreateContactViewControllerDelegate, UIAlertViewDelegate> {
	NSDictionary	*_group;
	NSArray			*_members;
	NSInteger		_membersRetryCount;
	GroupMeRequest	*_lastMembersRequest;
	BOOL			_loadingMembers;
	UIAlertView		*_alertView;
	NSIndexPath		*_indexPathToDelete;
}

@property (nonatomic, retain) NSDictionary *group;


- (id)initWithGroup:(NSDictionary*)group;

+ (void) showGroupDetailInViewController:(UIViewController*)vc 
								andGroup:(NSDictionary*)group;

@end
