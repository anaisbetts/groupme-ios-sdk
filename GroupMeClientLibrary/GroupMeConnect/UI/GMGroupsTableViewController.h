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
#import "GMGroupsDataSource.h"
#import "GMCreateGroupController.h"
#import "GMGroupPostLineViewController.h"


@protocol GMGroupsTableViewControllerDelegate;

@interface GMGroupsTableViewController : UITableViewController <GroupMeRegistrationDelegate, GMGroupsDataSourceDelegate, GMCreateGroupControllerDelegate, GMGroupPostLineViewControllerDelegate> {
    
	GMGroupsDataSource	*_groupsDatasource;
	UIImage				*_noGroupsImage;
	NSString			*_messageToPost, *_messageLocationName, *_loggedOutStartButtonText, *_footerText, *_defaultTitle;
	NSNumber			*_messageLatitude, *_messageLongitude;
	
	BOOL				_addGroupOnDidAppearUnlessFoundGroups;
	BOOL				_hideLogoutButton, _hideNavigationCreateGroupButton, _hideCloseButton;
	
	id<GMGroupsTableViewControllerDelegate>		_groupListDelegate;
}

@property (nonatomic, retain) NSString			*messageToPost, *messageLocationName, *loggedOutStartButtonText, *footerText, *defaultTitle;
@property (nonatomic, retain) NSNumber			*messageLatitude, *messageLongitude;
@property (nonatomic, retain) UIImage			*noGroupsImage;
@property (nonatomic, assign) BOOL				hideLogoutButton, hideNavigationCreateGroupButton, hideCloseButton;
@property (nonatomic, assign) id<GMGroupsTableViewControllerDelegate> groupListDelegate;

+ (void) showGroupsInViewController:(UIViewController*)vc;
+ (void) showGroupsInViewController:(UIViewController*)vc toPostMessage:(NSString*)message andLocationName:(NSString*)locationName andLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude;
+ (void) showGroupsInViewController:(UIViewController*)vc withDelegate:(id<GMGroupsTableViewControllerDelegate>)delegate;



@end


@protocol GMGroupsTableViewControllerDelegate <NSObject>

@optional

//Called when user picks a group
- (void)groupMePickedGroup:(NSDictionary*)group;

//Called if they cancel picking a group
- (void)groupMeDismissedGroupsList;

@end