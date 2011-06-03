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


#import "GMGroupsTableViewController.h"

#import "GMRegisterDeviceViewController.h"
#import "GMCreateGroupController.h"
#import "GMGroupDetailViewController.h"
#import "GMLearnMoreViewController.h"
#import "GMButton.h"

@implementation GMGroupsTableViewController

@synthesize noGroupsImage = _noGroupsImage;

@synthesize hideLogoutButton = _hideLogoutButton;
@synthesize hideNavigationCreateGroupButton = _hideNavigationCreateGroupButton;
@synthesize hideCloseButton = _hideCloseButton;
@synthesize messageToPost = _messageToPost;
@synthesize messageLocationName = _messageLocationName;
@synthesize messageLatitude = _messageLatitude;
@synthesize messageLongitude = _messageLongitude;
@synthesize loggedOutStartButtonText = _loggedOutStartButtonText;
@synthesize footerText = _footerText;
@synthesize defaultTitle = _defaultTitle;

@dynamic groupListDelegate;


- (void)sharedInit {
	_hideNavigationCreateGroupButton = NO;
	_hideLogoutButton = NO;
	_hideCloseButton = YES;
	self.loggedOutStartButtonText = @"Get Started";
	self.defaultTitle = @"GroupMe";
	self.navigationItem.title = self.defaultTitle;
}

- (id) initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
		[self sharedInit];
	}
	return self;
}

- (void) awakeFromNib {
	[super awakeFromNib];
	[self sharedInit];
}

+ (void) showGroupsInViewController:(UIViewController*)vc {
	
	[self showGroupsInViewController:vc withDelegate:nil];
}


+ (void) showGroupsInViewController:(UIViewController*)vc toPostMessage:(NSString*)message andLocationName:(NSString*)locationName andLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude {
	
	GMGroupsTableViewController *gvc = [[GMGroupsTableViewController alloc] init];
	gvc.hideLogoutButton = YES;
	gvc.hideCloseButton = NO;
	gvc.messageToPost = message;
	gvc.messageLocationName = locationName;
	gvc.messageLatitude = latitude;
	gvc.messageLongitude = longitude;
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gvc];
	
	[vc presentModalViewController:nav animated:YES];
	
	[gvc release];
	[nav release];
}


+ (void) showGroupsInViewController:(UIViewController*)vc withDelegate:(id<GMGroupsTableViewControllerDelegate>)delegate {
	
	
	GMGroupsTableViewController *gvc = [[GMGroupsTableViewController alloc] init];
	gvc.hideLogoutButton = YES;
	gvc.hideCloseButton = NO;
	gvc.groupListDelegate = delegate;
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gvc];
	
	[vc presentModalViewController:nav animated:YES];
	
	[gvc release];
	[nav release];
	
}

- (void)dealloc
{
	[_defaultTitle release];
	[_footerText release];
	[_loggedOutStartButtonText release];
	[_messageToPost release];
	[_messageLocationName release];
	[_messageLatitude release];
	[_messageLongitude release];
	[_noGroupsImage release];
	[_groupsDatasource release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Actions

- (void)close {
	if ([self.navigationController.viewControllers count] == 1 || self.navigationItem.hidesBackButton) {
		if (_groupListDelegate != nil && [_groupListDelegate respondsToSelector:@selector(groupMeDismissedGroupsList)]) {
			[_groupListDelegate groupMeDismissedGroupsList];
		}
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (void) updateDatasourceForDelegate {
	if ((_groupListDelegate != nil && [_groupListDelegate respondsToSelector:@selector(groupMePickedGroup:)]) || _messageToPost != nil) {
		_groupsDatasource.showDisclosure = NO;
		self.navigationItem.title = @"Pick a Group";
	} else {
		_groupsDatasource.showDisclosure = YES;
		self.navigationItem.title = self.defaultTitle;
	}
}

- (void) updateLoginLogoutButton {
	
	if (_hideLogoutButton)
		return;
	
	if ([[GroupMeConnect sharedGroupMe] isSessionValid]) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logout)];
	} else {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log in" style:UIBarButtonItemStyleBordered target:self action:@selector(login)];
	}
}

- (void)refreshFooterView {
	
	UIView *wrapperView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 70.0f)] autorelease];
	
	GMButton *newGroup = [[[GMButton alloc] init] autorelease];
	[newGroup.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
	if ([[GroupMeConnect sharedGroupMe] isSessionValid]) {
		[newGroup setTitle:@"Start a group" forState:UIControlStateNormal];
	} else {
		[newGroup setTitle:self.loggedOutStartButtonText forState:UIControlStateNormal];
	}
	[newGroup addTarget:self action:@selector(addGroup) forControlEvents:UIControlEventTouchUpInside];
	
	newGroup.frame = CGRectInset(wrapperView.frame, 15.0f, 15.0f);
	newGroup.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
	
	[wrapperView addSubview:newGroup];
	
	wrapperView.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 110.0f);
	
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[infoButton.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
	[infoButton setTitle:@"Learn more about GroupMe." forState:UIControlStateNormal];
	[infoButton setTitleColor:GROUP_ME_BRANDING_BLUE forState:UIControlStateNormal];
	[infoButton setTitleColor:GROUP_ME_BRANDING_DARK_BLUE forState:UIControlStateHighlighted];
	[infoButton.titleLabel setTextAlignment:UITextAlignmentCenter];
	[infoButton sizeToFit];
	
	[infoButton addTarget:self action:@selector(tappedInfoButton) forControlEvents:UIControlEventTouchUpInside];
	
	infoButton.frame = CGRectMake(self.view.frame.size.width/2 - infoButton.frame.size.width/2, 75.0f, infoButton.frame.size.width, infoButton.frame.size.height);
	
	[wrapperView addSubview:infoButton];
	
	if (_footerText) {
		
		CGFloat footerWidth = self.view.frame.size.width - 40.0f;
		
		UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		footerLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		footerLabel.textColor = [UIColor colorWithRed:122.0/255.0f green:122.0/255.0f blue:114.0f/255.0f alpha:1.0f];
		footerLabel.shadowColor = [UIColor whiteColor];
		footerLabel.backgroundColor = [UIColor clearColor];
		footerLabel.opaque = NO;
		footerLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		footerLabel.textAlignment = UITextAlignmentLeft;
		footerLabel.numberOfLines = 100;
		footerLabel.text = _footerText;
		
		CGSize size = [_footerText sizeWithFont:footerLabel.font constrainedToSize:CGSizeMake(footerWidth, 10000.0f)];
		
		footerLabel.frame = CGRectMake(20.0f, 110.0f, footerWidth, size.height);
		
		wrapperView.frame = CGRectMake(wrapperView.frame.origin.x,
									   wrapperView.frame.origin.y,
									   wrapperView.frame.size.width,
									   wrapperView.frame.size.height + size.height + 20.0f);
		
		[wrapperView addSubview:footerLabel];
		[footerLabel release];

		
		
	}
	
	self.tableView.tableFooterView = wrapperView;
	
}


- (void) addGroup {
	
	if (![[GroupMeConnect sharedGroupMe] isSessionValid]) {
		[GMRegisterDeviceViewController showRegistrationInViewController:self andDelegate:self];
		_addGroupOnDidAppearUnlessFoundGroups = YES;
	} else {
		[GMCreateGroupController showGroupCreationInViewController:self andDelegate:self];
	}
	
}

- (void) logout {
	[[GroupMeConnect sharedGroupMe] clearSession];
	[self.tableView reloadData];
	[self updateLoginLogoutButton];
	[self refreshFooterView];
	
}

- (void) tappedInfoButton {
	[GMLearnMoreViewController showLearnMoreInViewController:self];
	
}

- (void) login {
	[GMRegisterDeviceViewController showRegistrationInViewController:self andDelegate:self];
}

#pragma mark - Properties

- (id<GMGroupsTableViewControllerDelegate>)groupListDelegate {
	return _groupListDelegate;
}

- (void) setGroupListDelegate:(id<GMGroupsTableViewControllerDelegate>)groupListDelegate {
	_groupListDelegate = groupListDelegate;
	
	[self updateDatasourceForDelegate];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (_groupsDatasource == nil) {
		
		_groupsDatasource = [[GMGroupsDataSource alloc] init];
		_groupsDatasource.delegate = self;
		
		[self updateDatasourceForDelegate];
	}
	
	if (!_hideCloseButton) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
	} 
	
	if (!_hideNavigationCreateGroupButton) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGroup)];
	}
	
	self.tableView.rowHeight = 50.0f;
	
	self.tableView.dataSource = _groupsDatasource;
	[self refreshFooterView];
	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	NSIndexPath *ip = [self.tableView indexPathForSelectedRow];
	
	if (ip != nil) {
		[self.tableView deselectRowAtIndexPath:ip animated:animated];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	if (_addGroupOnDidAppearUnlessFoundGroups) {
		_addGroupOnDidAppearUnlessFoundGroups = NO;
		if ([[GroupMeConnect sharedGroupMe] isSessionValid] && [[[GroupMeConnect sharedGroupMe] groups] count] == 0) {
			[self addGroup];
		}
	} else {
		[_groupsDatasource refreshGroups];
	}
	[self.tableView reloadData];
	[self updateLoginLogoutButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.tableView reloadData];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	
	if ([[GroupMeConnect sharedGroupMe].groups count] > 0) {
		return 0.0f;
	}
	
	if (_noGroupsImage == nil) {
		self.noGroupsImage = [UIImage imageNamed:@"GroupMeConnect.bundle/no_groups.png"];
	}
	
	return _noGroupsImage.size.height;
	
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if ([[GroupMeConnect sharedGroupMe].groups count] > 0) {
		return nil;
	}
	
	UIImageView *iv = [[[UIImageView alloc] initWithImage:_noGroupsImage] autorelease];
	iv.contentMode = UIViewContentModeCenter;
	
	return iv;
	
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *group = [_groupsDatasource dataForIndexPath:indexPath];
	if (group) {
		if (_messageToPost != nil) {
			[GMGroupPostLineViewController showGroupPostLineInViewController:self.navigationController 
														  withDefaultMessage:_messageToPost 
															 andLocationName:_messageLocationName 
																 andLatitude:_messageLatitude 
																andLongitude:_messageLongitude 
																	andGroup:group 
																 andDelegate:self];
			return;
		} else if (_groupListDelegate != nil && [_groupListDelegate respondsToSelector:@selector(groupMePickedGroup:)]) {
			[_groupListDelegate groupMePickedGroup:group];
			
			//this should almost always be the case, but check anyway.
			if (!_hideCloseButton)
				[self dismissModalViewControllerAnimated:YES];
		} else {
			GMGroupDetailViewController *vc = [[GMGroupDetailViewController alloc] initWithGroup:group];
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
			return;
		}
		
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - GMGroupsDataSourceDelegate

- (void)refreshedGroups {
	[self.tableView reloadData];
	[self updateLoginLogoutButton];
}

#pragma mark - GroupMeRegistrationDelegate

//Called when user successfully logs in
- (void)groupMeDidRegister {
	[self updateLoginLogoutButton];
	[self refreshFooterView];
}


//Called when user does not log in
- (void)groupMeDidNotRegister:(BOOL)cancelled {
	_addGroupOnDidAppearUnlessFoundGroups = NO;
}

#pragma mark -  GMCreateGroupControllerDelegate

//Called when user picks a group
- (void)groupMeCreatedGroup:(NSDictionary*)group {
	
	if (_messageToPost != nil) {
		[GMGroupPostLineViewController showGroupPostLineInViewController:self.navigationController 
													  withDefaultMessage:_messageToPost 
														 andLocationName:_messageLocationName 
															 andLatitude:_messageLatitude 
															andLongitude:_messageLongitude 
																andGroup:group 
															 andDelegate:self];
		return;
	} else if (_groupListDelegate != nil && [_groupListDelegate respondsToSelector:@selector(groupMePickedGroup:)]) {
		[_groupListDelegate groupMePickedGroup:group];
		
		//this should almost always be the case, but check anyway.
		if (!_hideCloseButton)
			[self dismissModalViewControllerAnimated:YES];
	} else {
		GMGroupDetailViewController *vc = [[GMGroupDetailViewController alloc] initWithGroup:group];
		[self.navigationController pushViewController:vc animated:NO];
		[vc release];
	}
}

//Called if they cancel picking a group
- (void)groupMeDismissedGroupCreate {
	
}

#pragma mark -  GMGroupPostLineViewControllerDelegate

//Called when user picks a group
- (void)groupMePostedMessageToGroup:(NSDictionary*)group {
	[self dismissModalViewControllerAnimated:YES];
}

//Called if they cancel picking a group
- (void)groupMeDismissedGroupPostLine {
	[self dismissModalViewControllerAnimated:YES];
	
}


@end
