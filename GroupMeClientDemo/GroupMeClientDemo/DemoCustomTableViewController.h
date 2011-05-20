//
//  DemoCustomTableViewController.h
//  GroupMeClientDemo
//
//  Created by Jeremy Schoenherr on 4/8/11.
//  Copyright 2011 Mindless Dribble, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupMeConnect.h"
#import "GMGroupsTableViewController.h"

@interface DemoCustomTableViewController : UITableViewController <GroupMeRequestDelegate, GMGroupsTableViewControllerDelegate> {
	
	UIAlertView	*_alertView;
}

@end
