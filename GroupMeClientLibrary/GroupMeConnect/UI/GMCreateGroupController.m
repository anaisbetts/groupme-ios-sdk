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


#import "GMCreateGroupController.h"
#import "GMButton.h"
#import <QuartzCore/QuartzCore.h>
#import "GMGroupDetailViewController.h"

@implementation GMCreateGroupController

@synthesize externalGroupId = _externalGroupId;
@synthesize groupCreateDelegate = _groupCreateDelegate;
@dynamic groupName;

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    
	if (self) {
		
		_groupName = [[UITextField alloc] init];
		_groupName.placeholder = @"Enter group name";
		_groupName.text = [GroupMeConnect defaultGroupName];
		_groupName.returnKeyType = UIReturnKeyDone;
		_groupName.delegate = self;
		_groupName.clearButtonMode = UITextFieldViewModeWhileEditing;
		_groupName.autoresizingMask = (UIViewAutoresizingFlexibleWidth);

		
		_addContactFromAddressBookButton = [[GMButton alloc] init];
		[_addContactFromAddressBookButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
		[_addContactFromAddressBookButton setTitle:@"From Contacts" forState:UIControlStateNormal];
		[_addContactFromAddressBookButton addTarget:self action:@selector(addContactFromAddressBook) forControlEvents:UIControlEventTouchUpInside];
		
		_enterNewContactButton = [[GMButton alloc] init];
		[_enterNewContactButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
		[_enterNewContactButton setTitle:@"Enter number/email" forState:UIControlStateNormal];
		[_enterNewContactButton addTarget:self action:@selector(enterNewContact) forControlEvents:UIControlEventTouchUpInside];
		
		_contacts = [[NSMutableArray arrayWithCapacity:2] retain];
		
    }

    return self;
}


+ (void) showGroupCreationInViewController:(UIViewController*)vc andDelegate:(id<GMCreateGroupControllerDelegate>)delegate
{
	
	[self showGroupCreationInViewController:vc withName:nil andDelegate:delegate];
	
}

+ (void) showGroupCreationInViewController:(UIViewController*)vc
								  withName:(NSString*)groupName
							   andDelegate:(id<GMCreateGroupControllerDelegate>)delegate
{
	
	[self showGroupCreationInViewController:vc withName:groupName andExternalGroupId:nil andDelegate:delegate];
}


+ (void) showGroupCreationInViewController:(UIViewController*)vc 
								  withName:(NSString*)groupName
						andExternalGroupId:(NSString*)externalId 
							   andDelegate:(id<GMCreateGroupControllerDelegate>)delegate
{
	
	GMCreateGroupController *createVC = [[GMCreateGroupController alloc] init];
	createVC.externalGroupId = externalId;
	createVC.groupCreateDelegate = delegate;
	if (groupName != nil)
		createVC.groupName = groupName;
	UINavigationController *createNav = [[UINavigationController alloc] initWithRootViewController:createVC];
	
	[vc presentModalViewController:createNav animated:YES];
	
	[createVC release];
	[createNav release];
	
}

- (void)dealloc
{
	[_externalGroupId release];
	[_contacts release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (NSString*) groupName {
	return _groupName.text;
}

- (void) setGroupName:(NSString *)groupName {
	_groupName.text = groupName;
}


#pragma mark - Actions

- (NSArray*)contactNames {
	
	NSMutableArray *contactNames = nil;
	
	if ([_contacts count] > 0) {
		contactNames = [NSMutableArray arrayWithCapacity:[_contacts count]];
		for (NSDictionary *contact in _contacts) {
			if ([contact objectForKey:@"name"]) {
				[contactNames addObject:[contact objectForKey:@"name"]];
			}
		}
	}
	
	return contactNames;
	
}

- (NSArray*)emailAddresses {
	
	NSMutableArray *emailAddresses = nil;
	
	if ([_contacts count] > 0) {
		emailAddresses = [NSMutableArray arrayWithCapacity:[_contacts count]];
		for (NSDictionary *contact in _contacts) {
			if ([contact objectForKey:@"email"]) {
				[emailAddresses addObject:[contact objectForKey:@"email"]];
			}
		}
	}
	
	return emailAddresses;
	
}

- (NSArray*)phoneNumbers {
	
	NSMutableArray *phoneNumbers = nil;
	
	if ([_contacts count] > 0) {
		phoneNumbers = [NSMutableArray arrayWithCapacity:[_contacts count]];
		for (NSDictionary *contact in _contacts) {
			if ([contact objectForKey:@"phone_number"]) {
				[phoneNumbers addObject:[contact objectForKey:@"phone_number"]];
			}
		}
	}
	
	return phoneNumbers;
	
}

- (void)cancel {
	if (_groupCreateDelegate != nil && [_groupCreateDelegate respondsToSelector:@selector(groupMeDismissedGroupCreate)]) {
		[_groupCreateDelegate groupMeDismissedGroupCreate];
	}

	[self dismissModalViewControllerAnimated:YES];
}

- (void)addContactFromAddressBook {
	
	if ([_groupName isFirstResponder]) {
		[_groupName resignFirstResponder];
	}

	ABPeoplePickerNavigationController *pp = [[ABPeoplePickerNavigationController alloc] init];
	pp.displayedProperties = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty], [NSNumber numberWithInt:kABPersonEmailProperty], nil];
	pp.peoplePickerDelegate = self;
	[self presentModalViewController:pp animated:YES];
	[pp release];
	
}

- (void)enterNewContact {
	
	if ([_groupName isFirstResponder]) {
		[_groupName resignFirstResponder];
	}

	[GMCreateContactViewController showContactCreationInViewController:self 
													   withContactName:nil 
														andContactInfo:nil 
											andBlacklistedContactNames:[self contactNames]
														   andDelegate:self];
	
}

- (void) done {
	if ([_groupName isFirstResponder]) {
		[_groupName resignFirstResponder];
		return;
	}
	
	if ([_groupName.text length] == 0) {
		[_groupName becomeFirstResponder];
		[GroupMeConnect showError:@"Please give this group a name."];
	} else  if ([_contacts count] == 0) {
		[GroupMeConnect showError:@"Please add some members to your group."];
	} else {
		[[GroupMeConnect sharedGroupMe] createGroupWithName:_groupName.text andMembers:_contacts andDelegate:self];
		
		_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Creating Group" andMessage:@"This will only take a moment"] retain];
		
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationItem.title = @"Create Group";
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
	
	self.tableView.backgroundColor = GROUP_ME_BRANDING_BACKGROUND;
	
	self.tableView.rowHeight = 60.0f;

	
	//Header View
	
	CGFloat xPadding = 10.0f;
	
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 50.0f)];
	
	headerView.backgroundColor = [UIColor whiteColor];
	
	UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPadding, 15.0f, 110.0f, 20.0f)];
	

	_groupName.frame = CGRectMake(headerLabel.frame.origin.x + headerLabel.frame.size.width, 
								  15.0f,
								  self.view.frame.size.width - headerLabel.frame.size.width - (xPadding*2), 
								  20.0f);
	
	_groupName.font = [UIFont systemFontOfSize:16.0f];
	
	headerLabel.font = [UIFont systemFontOfSize:16.0f];
	headerLabel.textColor = [UIColor lightGrayColor];
	headerLabel.text = @"Group Name:";
	
	[headerView addSubview:headerLabel];
	[headerView addSubview:_groupName];
	
	self.tableView.tableHeaderView = headerView;
	
	[headerLabel release];
	[headerView release];
	
	//Footer View
	
	UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 85.0f)];
	footerView.backgroundColor = [UIColor clearColor];
	footerView.opaque = NO;
	
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 11.0f, self.view.bounds.size.width - 30.0f, 20.0f)];
	
	
	label.font = [UIFont boldSystemFontOfSize:16.0f];
	label.textColor = [UIColor colorWithRed:122.0/255.0f green:122.0/255.0f blue:114.0f/255.0f alpha:1.0f];
	label.shadowColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor];
	label.opaque = NO;
	label.shadowOffset = CGSizeMake(0.0f, 1.0f);
	label.text = @"Add Member...";
	
	[footerView addSubview:label];
	
	[label release];
	
	CGFloat buttonY = 40.0f;
	CGFloat widthDifference = 20.0f;
	
	_addContactFromAddressBookButton.frame = CGRectMake(xPadding, 
														buttonY, 
														(self.view.frame.size.width - (xPadding*3))/2.0f - widthDifference, 
														40.0f);
	
	_enterNewContactButton.frame = CGRectMake(_addContactFromAddressBookButton.frame.origin.x + _addContactFromAddressBookButton.frame.size.width + xPadding, 
											  buttonY, 
											  (self.view.frame.size.width - (xPadding*3))/2.0f + widthDifference, 
											  40.0f);
	
	[footerView addSubview:_addContactFromAddressBookButton];
	[footerView addSubview:_enterNewContactButton];
	
	self.tableView.tableFooterView = footerView;
	
	[footerView release];

	

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	self.tableView.editing = YES;
	
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_contacts count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if ([_contacts count] > 0) {
		return 26.0f;
	} else {
		return 1.0f;
	}
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if ([_contacts count] > 0) {
		UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])] autorelease];
		view.backgroundColor = [UIColor colorWithRed:116.0f/255.0f green:128.0f/255.0f blue:130.0f/255.0f alpha:1.0f];
		CAGradientLayer *gradient = [CAGradientLayer layer];
		gradient.frame = CGRectMake(0.0f, 1.0f, view.bounds.size.width, view.bounds.size.height-2.0f);
		gradient.colors = [NSArray arrayWithObjects:
						   (id)[[UIColor colorWithRed:236.0f/255.0f green:238.0f/255.0f blue:240.0f/255.0f alpha:1.0f] CGColor], 
						   (id)[[UIColor colorWithRed:209.0f/255.0f green:212.0f/255.0f blue:218.0f/255.0f alpha:1.0f] CGColor], nil];
		[view.layer insertSublayer:gradient atIndex:0];
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 3.0f, view.bounds.size.width - 20.0f, 20.0f)];
		
		
		label.font = [UIFont boldSystemFontOfSize:14.0f];
		label.textColor = [UIColor colorWithRed:10.0f/255.0f green:37.0f/255.0f blue:50.0f/255.0f alpha:1.0f];
		label.shadowColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		label.opaque = NO;
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.text = @"Members";

		[view addSubview:label];
		
		[label release];
		
		return view;
	} else {
		UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1.0f)] autorelease];
		view.backgroundColor = [UIColor colorWithRed:116.0f/255.0f green:128.0f/255.0f blue:130.0f/255.0f alpha:1.0f];

		return view;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	
	NSDictionary *data = [_contacts objectAtIndex:indexPath.row];
	
	cell.textLabel.text = [data objectForKey:@"name"];
	
	if ([data objectForKey:@"email"]) {
		cell.detailTextLabel.text = [data objectForKey:@"email"];
	} else if ([data objectForKey:@"phone_number"]) {
		cell.detailTextLabel.text = [GroupMeConnect formatPhoneNumber:[data objectForKey:@"phone_number"]];
	}
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		[_contacts removeObjectAtIndex:indexPath.row];
		if ([_contacts count] > 0) {
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
		} else {
			[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
		}
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
	
	ABMultiValueRef contactProperty = ABRecordCopyValue(person,property);
	NSString *phoneOrEmail = (NSString *)ABMultiValueCopyValueAtIndex(contactProperty,identifier);
	
	NSString *firstName = (NSString *) ABRecordCopyValue(person, kABPersonFirstNameProperty);
	NSString *lastName = (NSString *) ABRecordCopyValue(person, kABPersonLastNameProperty);
	NSString *organization = (NSString *) ABRecordCopyValue(person, kABPersonOrganizationProperty);
	NSString *contactName = nil;
	
	if (firstName && lastName) {
		contactName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
	} else if (firstName) {
		contactName = firstName;
	} else if (lastName) {
		contactName = lastName;
	} else if (organization) {
		contactName = organization;
	}
	
	if (contactName) {
		
		BOOL nameExists = [[self contactNames] containsObject:contactName];
		BOOL phoneExists = [[self phoneNumbers] containsObject:phoneOrEmail];
		BOOL emailExists = [[self emailAddresses] containsObject:phoneOrEmail];

		if (nameExists && (phoneExists || emailExists)) { //perfect match, must've picked the same contact
			
			[peoplePicker dismissModalViewControllerAnimated:YES];
		
		} else if (nameExists) {
			
			[peoplePicker dismissModalViewControllerAnimated:NO];
			[GMCreateContactViewController showContactCreationInViewController:self 
															   withContactName:contactName 
																andContactInfo:phoneOrEmail 
													andBlacklistedContactNames:[self contactNames]
																   andDelegate:self];
			
			[GroupMeConnect showError:@"Someone already has that name, please enter a unique name for this contact."];
		
		} else if ([GroupMeConnect validateEmail:phoneOrEmail]) {
			
			if (!emailExists) {
				[_contacts addObject:[NSDictionary dictionaryWithObjectsAndKeys:phoneOrEmail, @"email", contactName, @"name", nil]];
			}
			[peoplePicker dismissModalViewControllerAnimated:YES];
			
		} else if ([GroupMeConnect validatePhone:phoneOrEmail]) {
			
			if (!phoneExists) {
				[_contacts addObject:[NSDictionary dictionaryWithObjectsAndKeys:phoneOrEmail, @"phone_number", contactName, @"name", nil]];
			}
			[peoplePicker dismissModalViewControllerAnimated:YES];
			
		} else {
			
			[peoplePicker dismissModalViewControllerAnimated:YES];
			
		}
	} else {

		[peoplePicker dismissModalViewControllerAnimated:NO];

		[GMCreateContactViewController showContactCreationInViewController:self 
														   withContactName:nil 
															andContactInfo:phoneOrEmail 
												andBlacklistedContactNames:[self contactNames]
															   andDelegate:self];
		
		[GroupMeConnect showError:@"Please enter a name for this contact."];

	}
	
	
	
	[organization release];
	[firstName release];
	[lastName release];
	
	
	[phoneOrEmail release];
	CFRelease(contactProperty);
	
	[self.tableView reloadData];
	
	return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
	[peoplePicker dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark UITextFieldDelegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField.text length] > 0)
		[textField resignFirstResponder];
	return NO; 
}

#pragma mark - GMCreateContactViewControllerDelegate

- (void)createdContactWithEmail:(NSString *)email withName:(NSString*)name {
	if (![[self emailAddresses] containsObject:email]) {
		[_contacts addObject:[NSDictionary dictionaryWithObjectsAndKeys:email, @"email", name, @"name", nil]];
		[self.tableView reloadData];
	}
}

- (void)createdContactWithPhoneNumber:(NSString *)phoneNumber withName:(NSString*)name {
	if (![[self phoneNumbers] containsObject:phoneNumber]) {
		[_contacts addObject:[NSDictionary dictionaryWithObjectsAndKeys:phoneNumber, @"phone_number", name, @"name", nil]];
		[self.tableView reloadData];
	}
}

#pragma mark -
#pragma mark GroupMeRequestDelegate


- (void)hideAlert {
	if (_alertView) {
		[_alertView dismissWithClickedButtonIndex:0 animated:YES];
		[_alertView release];
		_alertView = nil;
	}
}

- (void)request:(GroupMeRequest *)request didFailWithError:(NSError *)error {
	[self hideAlert];
	if ([request.errors count] > 0) {
		[GroupMeConnect showError:[request.errors objectAtIndex:0]];
	} else {
		[GroupMeConnect showError:@"Could not create group.\nPlease try again later."];
	}
}

- (void)request:(GroupMeRequest *)request didLoad:(id)result {
	[self hideAlert];
	if ([result isKindOfClass:[NSDictionary class]] && [(NSDictionary*)result objectForKey:@"group"] != nil) {
		
		NSDictionary *newGroup =  [(NSDictionary*)result objectForKey:@"group"];
		
		[[GroupMeConnect sharedGroupMe] addGroupToGroups:newGroup];
		
		if (_externalGroupId != nil) {
			GMGroupDetailViewController *detailVC = [[GMGroupDetailViewController alloc] initWithGroup:newGroup];
			detailVC.navigationItem.hidesBackButton = YES;
			[self.navigationController pushViewController:detailVC animated:YES];
			[detailVC release];
		} else {
			if (_groupCreateDelegate != nil && [_groupCreateDelegate respondsToSelector:@selector(groupMeCreatedGroup:)]) {
				[self dismissModalViewControllerAnimated:NO];
				[_groupCreateDelegate groupMeCreatedGroup:newGroup];
			} else {
				[self dismissModalViewControllerAnimated:YES];
			}

		}
	} else {
		if ([request.errors count] > 0) {
			[GroupMeConnect showError:[request.errors objectAtIndex:0]];
		} else {
			[GroupMeConnect showError:@"Could not create group.\nPlease try again later."];
		}
	}
	
}

@end