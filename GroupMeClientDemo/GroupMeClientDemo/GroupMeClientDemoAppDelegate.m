//
//  GroupMeClientDemoAppDelegate.m
//  GroupMeClientDemo
//
//  Created by Jeremy Schoenherr on 4/8/11.
//  Copyright 2011 Mindless Dribble, Inc. All rights reserved.
//

#import "GroupMeClientDemoAppDelegate.h"

#import "DemoCustomTableViewController.h"

#import "GroupMeConnect.h"
#import "GMGroupsTableViewController.h"
#import "DemoTabBarController.h"


@implementation GroupMeClientDemoAppDelegate


@synthesize window=_window;

@synthesize tabBarController=_tabBarController;

void uncaughtExceptionHandler(NSException *exception) {
	NSLog(@"exception: %@", exception);
} 


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

	///// GroupMe Configuration
	////////////////////////////////////////////////////////////////////////////////////
	//Required for GroupMe, always call this before you do any interaction with GroupMe.
	
	[GroupMeConnect setClientId:@"client id" andClientSecret:@"client secret"];
	
	//Optional
	[GroupMeConnect storeStateInUserDefaults:YES];

	[GroupMeConnect setDefaultGroupName:@"Buddies"];
	[GroupMeConnect setDefaultCallbackUrl:@"groupmedemo://comebacktome" andTitle:@"GroupMe Client Demo"];
	[GroupMeConnect setDefaultAddressBookPrefix:@"GroupMe Demo"];

	
	//[[GroupMeConnect sharedGroupMe] setSendSMSAsDefaultWhenAvailable:YES];
	//[[GroupMeConnect sharedGroupMe] setShowGroupMeLinkOnBottomOfGroupView:YES];
	//[[GroupMeConnect sharedGroupMe] setHideGroupMeLinkInGroupView:YES];
	
	
	//You can always clear the session if you like
	//[[GroupMeConnect sharedGroupMe] clearSession];


	///// The GroupMe Groups Table
	////////////////////////////////////////////////////////////////////////////////////
	//This is the drop in GroupMe View Controller that handles Authentication, Group creating and browsing
	
	GMGroupsTableViewController *groupsVC = [[GMGroupsTableViewController alloc] init];
	//Optional configuration:
	//groupsVC.hideLogoutButton = YES;
	//groupsVC.hideNavigationCreateGroupButton = YES;
	groupsVC.loggedOutStartButtonText = @"Start or Manage Groups";
	//groupsVC.footerText = @"- Works with any phone that can send\n  and receive text messages\n- View messages wherever you normally\n  do your texting\n- Normal text messaging rates apply\n- Get the GroupMe app for even more\n  group texting functionality";
	//groupsVC.noGroupsImage = [UIImage imageNamed:@"someOtherSplashScreenThatYouLikeMore.png"];


	
	///// The Chat Button View
	////////////////////////////////////////////////////////////////////////////////////
	//This is an example of how to just use the GMChatButton to launch GroupMe. See the implementation of DemoCustomTableViewController
	DemoCustomTableViewController *chatButtonVC = [[DemoCustomTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	chatButtonVC.navigationItem.title = @"Extras";

	
	///// ETC
	////////////////////////////////////////////////////////////////////////////////////
	//Set up root views
	self.tabBarController = [[[DemoTabBarController alloc] init] autorelease];
	self.tabBarController.delegate = self;

	UINavigationController *chatNav = [[UINavigationController alloc] initWithRootViewController:chatButtonVC];
	UINavigationController *groupsNav = [[UINavigationController alloc] initWithRootViewController:groupsVC];
	
	chatNav.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Extras" image:[UIImage imageNamed:@"GroupMeConnect.bundle/chat.png"] tag:1] autorelease];
	groupsNav.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"GroupMe" image:[UIImage imageNamed:@"GroupMeConnect.bundle/poundie.png"] tag:2] autorelease];
	
	[self.tabBarController setViewControllers:[NSArray arrayWithObjects:groupsNav, chatNav, nil]];
	
	[chatNav release];
	[groupsNav release];
	
	[chatButtonVC release];
	[groupsVC release];
	
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	[self.window addSubview:[self.tabBarController view]];
	[self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)dealloc
{
	[_window release];
	[_tabBarController release];
    [super dealloc];
}


@end
