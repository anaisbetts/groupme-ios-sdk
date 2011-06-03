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


#import "GMGroupDetailViewController.h"

#import "GMGroupPostLineViewController.h"
#import "GMButton.h"

#import "JSONKit.h"

#define DELETE_REQUEST @"removeMember"
#define ADD_REQUEST @"addMember"
#define CONFERENCE_REQUEST @"conferenceCall"
#define DELETE_GROUP_REQUEST @"deleteGroup"

@implementation GMGroupDetailViewController

@synthesize group = _group;

- (id)initWithGroup:(NSDictionary*)group
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		
		self.group = group;
		
		_membersRetryCount = 0;
		_loadingMembers = YES;
		_haveCheckedAddressBook = NO;
		_inAddressBook = NO;
		_indexPathToDelete = nil;
		
    }
    return self;
}

+ (void) showGroupDetailInViewController:(UIViewController*)vc 
								andGroup:(NSDictionary*)group {
	
	GMGroupDetailViewController *detailVC = [[GMGroupDetailViewController alloc] initWithGroup:group];
	
	UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:detailVC];
	
	[vc presentModalViewController:detailNav animated:YES];
	
	[detailVC release];
	[detailNav release];
	
}

- (void)dealloc
{
	
	if (_lastMembersRequest != nil) {
		_lastMembersRequest.delegate = nil;
		[_lastMembersRequest cancel];
		_lastMembersRequest = nil;
	}

	[_members release];
	[_group release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - API calls

- (void) loadMembers {
	
	//if already trying to get this, then don't repeat the work please
	if (_lastMembersRequest != nil)
		return;
	
	_lastMembersRequest = [[GroupMeConnect sharedGroupMe] requestWithMethodName:[NSString stringWithFormat:@"groups/%@/memberships", [_group objectForKey:@"id"]] 
																	  andParams:nil 
																  andHttpMethod:@"GET"
																   andRequestId:nil
																	andDelegate:self];
}

- (void) addMemberWithName:(NSString*)name andContactInfo:(NSString*)info andContactType:(NSString*)contactType {
	
	_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Adding Member" andMessage:@"This will only take a moment"] retain];
	
	NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithCapacity:1];
	NSMutableDictionary *membership = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[payload setObject:membership forKey:@"membership"];
	
	[membership setObject:name forKey:@"name"];
	[membership setObject:info forKey:contactType];
	
	NSData *jsonData = [payload JSONData];
	
	[[GroupMeConnect sharedGroupMe] requestWithMethodName:[NSString stringWithFormat:@"groups/%@/memberships", [_group objectForKey:@"id"]] 
												andParams:[NSMutableDictionary dictionaryWithObject:jsonData forKey:@"_body"] 
											andHttpMethod:@"POST"
											 andRequestId:ADD_REQUEST
											  andDelegate:self];
}

#pragma mark - Modal

- (void)close {
	if ([self.navigationController.viewControllers count] == 1 || self.navigationItem.hidesBackButton) {
		[self dismissModalViewControllerAnimated:YES];
	} else if ([self.navigationController.viewControllers count] > 1) {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void) deleteMember:(NSDictionary*)memberToDelete {
	[[GroupMeConnect sharedGroupMe] requestWithMethodName:[NSString stringWithFormat:@"groups/%@/memberships/%@", [_group objectForKey:@"id"], [memberToDelete objectForKey:@"id"]]
												andParams:nil
											andHttpMethod:@"DELETE"
											 andRequestId:DELETE_REQUEST
											  andDelegate:self];
}

- (void)removeCurrentUser {
	
	_indexPathToDelete = nil;
	
	if ([[_group objectForKey:@"creator_id"] isEqualToString:[GroupMeConnect sharedGroupMe].userId]) {
		[[GroupMeConnect sharedGroupMe] requestWithMethodName:[NSString stringWithFormat:@"groups/%@", [_group objectForKey:@"id"]]
													andParams:nil
												andHttpMethod:@"DELETE"
												 andRequestId:DELETE_GROUP_REQUEST
												  andDelegate:self];
		_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Deleting group" andMessage:@"This will only take a moment"] retain];
		
	} else {
		for (NSDictionary *member in _members) {
			if ([[GroupMeConnect sharedGroupMe].userId isEqualToString:[member objectForKey:@"user_id"]]) {
				[self deleteMember:member];
				_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Leaving group" andMessage:@"This will only take a moment"] retain];
			}
			
		}
	}

	
}

#pragma mark - Addressbook helpers

+ (BOOL)contactExistsForNumber:(NSString *)aNumber{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
	CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
	
	NSString *normNumber = [GroupMeConnect normalizePhoneNumber:aNumber];
	BOOL found = NO;
	
	for (int i = 0; i < nPeople; i++) {
		ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
		CFTypeRef phoneNumberMultiRef = ABRecordCopyValue(ref, kABPersonPhoneProperty);
		for (int j = 0; j < ABMultiValueGetCount(phoneNumberMultiRef); j++) {
			
			NSString *unnormalNumberInBook = (NSString *) ABMultiValueCopyValueAtIndex(phoneNumberMultiRef, j);
			NSString *numberInBook = [GroupMeConnect normalizePhoneNumber:unnormalNumberInBook];
			if ([normNumber isEqualToString:numberInBook]) {
				found = YES;
			}
			
			[unnormalNumberInBook release];
		}
		CFRelease(phoneNumberMultiRef);
	}
	
	CFRelease(allPeople);
	CFRelease(addressBook);
	
	return found;
}

+ (BOOL)addContactWithPhoneNumber:(NSString *)number andName:(NSString *)name{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	BOOL saved = YES;
	
	ABRecordRef contactRecord = ABPersonCreate();
	
	ABRecordSetValue(contactRecord, kABPersonFirstNameProperty, name, NULL);
	
	ABMultiValueRef contactNumber = ABMultiValueCreateMutable(kABPersonPhoneProperty);
	ABMultiValueAddValueAndLabel(contactNumber, [GroupMeConnect normalizePhoneNumber:number], kABPersonPhoneMobileLabel, NULL);
	
	ABRecordSetValue(contactRecord, kABPersonPhoneProperty, contactNumber, NULL);
	
	ABAddressBookAddRecord(addressBook, contactRecord, NULL);
	
	
	CFErrorRef error = NULL;
	
	if (ABAddressBookHasUnsavedChanges(addressBook)) {
		ABAddressBookSave(addressBook, &error);
	}
	
	if(error != NULL){
		saved = NO;
	}
	
	CFRelease(contactNumber);
	CFRelease(contactRecord);
	
	CFRelease(addressBook);
	
	return saved;
}

- (void)checkAddressBook {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	_inAddressBook = [GMGroupDetailViewController contactExistsForNumber:[_group objectForKey:@"phone_number"]];
	_haveCheckedAddressBook = YES;
	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	
	[pool release];
	
}


#pragma mark - Adding members

- (NSArray*) memberNames {
	NSMutableArray *names = [NSMutableArray arrayWithCapacity:1];
	for (NSDictionary *member in _members) {
		if ([[member objectForKey:@"name"] isKindOfClass:[NSString class]]) {
			[names addObject:[member objectForKey:@"name"]];
		}
	}
	return names;
}

- (void) addMember {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
															 delegate:self 
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil 
													otherButtonTitles:@"From Address Book", @"New Contact", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	UIView *view = self.view;
	
	if (self.navigationController.tabBarController) {
		view = self.navigationController.tabBarController.view;
	} else if (self.navigationController) {
		view = self.navigationController.view;
	}
	
	[actionSheet showInView:view];
	actionSheet.delegate = self;
	[actionSheet release];

}

#pragma mark - UIActionSheetDelegate


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	
	if (buttonIndex == actionSheet.cancelButtonIndex) {
		return;
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
		[GMCreateContactViewController showContactCreationInViewController:self 
														   withContactName:nil 
															andContactInfo:nil 
												andBlacklistedContactNames:[self memberNames]
															   andDelegate:self];

	} else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
		ABPeoplePickerNavigationController *pp = [[ABPeoplePickerNavigationController alloc] init];
		pp.displayedProperties = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty], [NSNumber numberWithInt:kABPersonEmailProperty], nil];
		pp.peoplePickerDelegate = self;
		[self presentModalViewController:pp animated:YES];
		[pp release];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 1) {
		
		if ([[_group objectForKey:@"creator_id"] isEqualToString:[GroupMeConnect sharedGroupMe].userId]) {
			
			[[GroupMeConnect sharedGroupMe] requestWithMethodName:[NSString stringWithFormat:@"groups/%@", [_group objectForKey:@"id"]]
														andParams:nil
													andHttpMethod:@"DELETE"
													 andRequestId:DELETE_GROUP_REQUEST
													  andDelegate:self];
			_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Deleting group" andMessage:@"This will only take a moment"] retain];
			
		} else {
			NSDictionary *memberToDelete = [_members objectAtIndex:_indexPathToDelete.row];
			[self deleteMember:memberToDelete];
			_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Leaving group" andMessage:@"This will only take a moment"] retain];
		}

	}

}

#pragma mark - View lifecycle

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	
	if (editing) {
		UIView *wrapperView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 70.0f)] autorelease];
		
		GMButton *leaveOrDeleteGroup = [[[GMButton alloc] init] autorelease];
		[leaveOrDeleteGroup.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
		
		if ([[_group objectForKey:@"creator_id"] isEqualToString:[GroupMeConnect sharedGroupMe].userId]) {
			[leaveOrDeleteGroup setTitle:@"End Group" forState:UIControlStateNormal];
		} else {
			[leaveOrDeleteGroup setTitle:@"Leave Group" forState:UIControlStateNormal];
		}
		[leaveOrDeleteGroup addTarget:self action:@selector(removeCurrentUser) forControlEvents:UIControlEventTouchUpInside];
		
		leaveOrDeleteGroup.frame = CGRectInset(wrapperView.frame, 15.0f, 15.0f);
		leaveOrDeleteGroup.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
		leaveOrDeleteGroup.buttonStyle = GMButtonStyleRed;
		
		[wrapperView addSubview:leaveOrDeleteGroup];
		
		self.tableView.tableFooterView = wrapperView;

	} else {
		self.tableView.tableFooterView = nil;
	}
	
	[super setEditing:editing animated:YES];
	[self.tableView beginUpdates];
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	if ([GroupMeConnect sharedGroupMe].showGroupMeLinkOnBottomOfGroupView) {
		if (editing) {
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
		} else {
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	[self.tableView endUpdates];

}


- (void)viewDidLoad
{
    [super viewDidLoad];

	self.tableView.backgroundColor = GROUP_ME_BRANDING_BACKGROUND;
	self.navigationItem.title = @"Group";
	
	if ([self.navigationController.viewControllers count] == 1 || self.navigationItem.hidesBackButton) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
	}

}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	if (_members == nil || [_members count] == 0) {
		[self performSelector:@selector(loadMembers) withObject:nil afterDelay:0.5];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
	}
	
	if (!_haveCheckedAddressBook) {
		[self performSelectorInBackground:@selector(checkAddressBook) withObject:nil];
		
	}

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
    // Return the number of sections.
    return ([GroupMeConnect sharedGroupMe].showGroupMeLinkOnBottomOfGroupView && ! self.tableView.editing ? 3 : 2);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	if (section == 2) {
		return 1;
	} else if (section == 0) {
		return (tableView.editing ? 0 : (![GroupMeConnect sharedGroupMe].showGroupMeLinkOnBottomOfGroupView && ![GroupMeConnect sharedGroupMe].hideGroupMeLinkInGroupView ? 4 : 3));
	} else {
		if (_loadingMembers) {
			return 1;
		} else {
			return [_members count] + 1;
		}
	}
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 2) {
		return ([self tableView:tableView numberOfRowsInSection:section] ? @"GroupMe" : nil);
	} else if (section == 0) {
		return (tableView.editing ? [NSString stringWithFormat:@"Editing Group: %@", [_group objectForKey:@"topic"]] : [_group objectForKey:@"topic"]);
	} else {
		return ([self tableView:tableView numberOfRowsInSection:section] ? @"Members" : nil);
	}
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 2 && ![GroupMeConnect hasGroupMeAppInstalled]) {
		return @"You don't need to download the GroupMe app, but with it you can share photos and location and other cool stuff.";
	}
	return nil;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:14.0f];;
		cell.detailTextLabel.textColor = GROUP_ME_BRANDING_BLUE;
    }
	
	cell.accessoryView = nil;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.imageView.image = nil;
	cell.detailTextLabel.text = nil;
	
	if (indexPath.section == 2) {
		cell.textLabel.text = ([GroupMeConnect hasGroupMeAppInstalled] ? @"Open GroupMe App" : @"Download GroupMe App");
		cell.imageView.image = [UIImage imageNamed:@"GroupMeConnect.bundle/poundie.png"];
	} else if (indexPath.section == 0) {
		switch (indexPath.row) {
			case 0:
				cell.textLabel.text = @"Send text to group";
				cell.imageView.image = [UIImage imageNamed:@"GroupMeConnect.bundle/chat.png"];
				break;
			case 1:
				cell.textLabel.text = @"Start conference call";
				cell.imageView.image = [UIImage imageNamed:@"GroupMeConnect.bundle/phone.png"];
				break;
			case 2:
				cell.textLabel.text = (_haveCheckedAddressBook ? (_inAddressBook ? @"In Address Book" : @"Add to Address Book") : @"Checking Address Book");
				if (_haveCheckedAddressBook && _inAddressBook)
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.imageView.image = [UIImage imageNamed:@"GroupMeConnect.bundle/book.png"];
				break;
			case 3:
				cell.textLabel.text = ([GroupMeConnect hasGroupMeAppInstalled] ? @"Open GroupMe App" : @"Download GroupMe App");
				cell.imageView.image = [UIImage imageNamed:@"GroupMeConnect.bundle/poundie.png"];
				break;
				
			default:
				break;
		}
	} else {
		if ([_members count] > indexPath.row) {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.text = ([[[_members objectAtIndex:indexPath.row] objectForKey:@"name"] isKindOfClass:[NSString class]] ? [[_members objectAtIndex:indexPath.row] objectForKey:@"name"] : @"Pending member");
			
			if ([[[_members objectAtIndex:indexPath.row] objectForKey:@"state"] isKindOfClass:[NSString class]]) {
				if (![[[_members objectAtIndex:indexPath.row] objectForKey:@"state"] isEqualToString:@"active"]) {
					cell.detailTextLabel.text = [[_members objectAtIndex:indexPath.row] objectForKey:@"state"];
				}
			}
			
		} else {
			if (indexPath.row == 0 && _loadingMembers) {
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.textLabel.text = @"Loading members...";
				UIActivityIndicatorView *spins = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
				[spins startAnimating];
				cell.accessoryView = spins;
			} else {
				cell.textLabel.text = @"Add member";
				UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
				addButton.userInteractionEnabled = NO;
				cell.accessoryView = addButton;
			}
		}
	}
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	if (indexPath.section == 1 && indexPath.row < [_members count])
		return UITableViewCellEditingStyleDelete;

	if (indexPath.section == 1 && !_loadingMembers)
		return UITableViewCellEditingStyleInsert;

	return UITableViewCellEditingStyleNone;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.editing && indexPath.section == 1 && !_loadingMembers)
		return YES;
	
    return NO;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		_indexPathToDelete = [indexPath copy];
		
		NSDictionary *memberToDelete = [_members objectAtIndex:indexPath.row];
		
		if ([[GroupMeConnect sharedGroupMe].userId isEqualToString:[memberToDelete objectForKey:@"user_id"]]) {
			
			if ([[_group objectForKey:@"creator_id"] isEqualToString:[GroupMeConnect sharedGroupMe].userId]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"End group?"
																message:@"Since you created this group, leaving the group will end the group for everyone. Continue?" 
															   delegate:self 
													  cancelButtonTitle:@"Cancel"
													  otherButtonTitles:@"End Group", nil];
				[alert show];
				[alert release];
				
			} else {
			
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Leave group?"
																message:@"This is you, are you sure you want to leave this group?" 
															   delegate:self 
													  cancelButtonTitle:@"Cancel"
													  otherButtonTitles:@"Leave", nil];
				[alert show];
				[alert release];
			}
		} else {
		
			_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Removing Member" andMessage:@"This will only take a moment"] retain];
			
			[self deleteMember:memberToDelete];
			
		}
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self addMember];
		[self setEditing:NO animated:YES];
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	
	//Open GroupMe
	if ((indexPath.section == 0 && indexPath.row == 3) || indexPath.section == 2) {
		if ([GroupMeConnect hasGroupMeAppInstalled]) {
			[GroupMeConnect openGroupMeAppForGroup:_group];
		} else {
			[GroupMeConnect downloadGroupMeApp];
		}
	} else if (indexPath.section == 0) {
		
		//Text Group
		if (indexPath.row == 0) {
			
			Class messageComposeViewControllerClass = NSClassFromString(@"MFMessageComposeViewController");
			
			if ([GroupMeConnect sharedGroupMe].sendSMSAsDefaultWhenAvailable &&  messageComposeViewControllerClass && [messageComposeViewControllerClass canSendText]) {
				id controller = [[messageComposeViewControllerClass alloc] initWithNibName:nil bundle:nil];
				[controller setRecipients:[NSArray arrayWithObject:[_group objectForKey:@"phone_number"]]];
				[controller setMessageComposeDelegate:self];
				[self.navigationController presentModalViewController:controller animated:YES];
				[controller release];
			} else {
				[GMGroupPostLineViewController showGroupPostLineInViewController:self andGroup:_group andDelegate:nil];
			}
		}

		//Conference Call
		if (indexPath.row == 1) {
			
			NSURL *phoneUrl = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", [GroupMeConnect normalizePhoneNumber:[_group objectForKey:@"phone_number"]]]];
			if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
				[[UIApplication sharedApplication] openURL:phoneUrl];
			} else {
				
				_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Starting Call" andMessage:@"This will only take a moment"] retain];
				
				[[GroupMeConnect sharedGroupMe] requestWithMethodName:[NSString stringWithFormat:@"groups/%@/conferences", [_group objectForKey:@"id"]]
															andParams:nil
														andHttpMethod:@"POST"
														 andRequestId:CONFERENCE_REQUEST
														  andDelegate:self];
				
			}
		}
		//Address book
		if (indexPath.row == 2 && _haveCheckedAddressBook && !_inAddressBook) {
			[GMGroupDetailViewController addContactWithPhoneNumber:[GroupMeConnect normalizePhoneNumber:[_group objectForKey:@"phone_number"]]
														   andName:[NSString stringWithFormat:@"%@: %@", [GroupMeConnect defaultAddressBookPrefix], [_group objectForKey:@"topic"]]];
			_inAddressBook = YES;
			[self.tableView reloadData];
		}
		
	} else {
		if (!_loadingMembers && indexPath.row == ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)) {
			[self addMember];
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	
}

#pragma mark -  GroupMeRequestDelegate

- (void)hideAlert {
	if (_alertView) {
		[_alertView dismissWithClickedButtonIndex:0 animated:YES];
		[_alertView release];
		_alertView = nil;
	}
}

- (void)request:(GroupMeRequest *)request didFailWithError:(NSError *)error {
	
	if ([CONFERENCE_REQUEST isEqualToString:request.requestId]) {
		
		[self hideAlert];
		if ([request.errors count] > 0) {
			[GroupMeConnect showError:[request.errors objectAtIndex:0]];
		} else {
			[GroupMeConnect showError:@"Could not start conference call.\nPlease try again later."];
		}
		
	} else if([DELETE_GROUP_REQUEST isEqualToString:request.requestId]) {
		
		[self hideAlert];
		if ([request.errors count] > 0) {
			[GroupMeConnect showError:[request.errors objectAtIndex:0]];
		} else {
			[GroupMeConnect showError:@"Could not delete group.\nPlease try again later."];
		}

		
	} else if ([ADD_REQUEST isEqualToString:request.requestId]) {

		[self hideAlert];
		if ([request.errors count] > 0) {
			[GroupMeConnect showError:[request.errors objectAtIndex:0]];
		} else {
			[GroupMeConnect showError:@"Could not add user.\nPlease try again later."];
		}

		
	} else if ([DELETE_REQUEST isEqualToString:request.requestId]) {
		
		[self hideAlert];
		if ([request.errors count] > 0) {
			[GroupMeConnect showError:[request.errors objectAtIndex:0]];
		} else {
			[GroupMeConnect showError:@"Could not remove user.\nPlease try again later."];
		}
		[_indexPathToDelete release];
		_indexPathToDelete = nil;
		
	} else {
	
		//must be members
		_lastMembersRequest.delegate = nil;
		_lastMembersRequest = nil;
		if (_membersRetryCount < 2) {
			_membersRetryCount++;
			[self loadMembers];
		} else {
			_loadingMembers = NO;
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
}

- (void)request:(GroupMeRequest *)request didLoad:(id)result {


	if ([CONFERENCE_REQUEST isEqualToString:request.requestId]) {
		
		[self hideAlert];
		if (request.statusCode == 201) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Call Started"
															message:@"The conference call has started. Everyone's phones should ring in a moment." 
														   delegate:self 
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
			[alert release];
		} else {
			[GroupMeConnect showError:@"Could not start conference call.\nPlease try again later."];
		}
		
	} else if([DELETE_GROUP_REQUEST isEqualToString:request.requestId]) {
		[self hideAlert];
		if (request.statusCode == 200) {
			[[GroupMeConnect sharedGroupMe] removeGroupFromGroups:_group];
			[self close];
		} else {
			if ([request.errors count] > 0) {
				[GroupMeConnect showError:[request.errors objectAtIndex:0]];
			} else {
				[GroupMeConnect showError:@"Could not delete group.\nPlease try again later."];
			}
		}
		
	} else if ([ADD_REQUEST isEqualToString:request.requestId]) {
		[self hideAlert];

		if (request.statusCode == 201) {
			
			NSDictionary *member = [result objectForKey:@"membership"];
			
			NSArray *newMembers = (_members != nil ? [_members arrayByAddingObject:member] : [NSArray arrayWithObject:member]);
			
			[_members release];
			_members = [newMembers retain];
			
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
			
		} else {
			
			if ([request.errors count] > 0) {
				[GroupMeConnect showError:[request.errors objectAtIndex:0]];
			} else {
				[GroupMeConnect showError:@"Could not add user.\nPlease try again later."];
			}
		}

	} else if ([DELETE_REQUEST isEqualToString:request.requestId]) {
		
		[self hideAlert];
		if (request.statusCode == 200) {
			
			NSDictionary *memberToDelete = (_indexPathToDelete != nil ? [_members objectAtIndex:_indexPathToDelete.row] : nil);
			
			if (memberToDelete == nil || [[GroupMeConnect sharedGroupMe].userId isEqualToString:[memberToDelete objectForKey:@"user_id"]]) {
				[[GroupMeConnect sharedGroupMe] removeGroupFromGroups:_group];
				[self close];

			} else {
			
				NSMutableArray *newMembers = [_members mutableCopy];
				[newMembers removeObjectAtIndex:_indexPathToDelete.row];
				[_members release];
				_members = newMembers;
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:_indexPathToDelete] withRowAnimation:UITableViewRowAnimationBottom];
				
			}
			
		} else {
			
			if ([request.errors count] > 0) {
				[GroupMeConnect showError:[request.errors objectAtIndex:0]];
			} else {
				[GroupMeConnect showError:@"Could not remove user.\nPlease try again later."];
			}
		}
		
		[_indexPathToDelete release];
		_indexPathToDelete = nil;
		
	} else {

		//must be members

		_lastMembersRequest.delegate = nil;
		_lastMembersRequest = nil;
		_loadingMembers = NO;
		if ([result isKindOfClass:[NSDictionary class]] && [(NSDictionary*)result objectForKey:@"memberships"] != nil) {
			
			NSMutableArray *newMembers = [NSMutableArray arrayWithCapacity:1];
			
			for (NSDictionary *member in [(NSDictionary*)result objectForKey:@"memberships"]) {
				NSString *state = [member objectForKey:@"state"];
				if ([state isEqualToString:@"active"] || [state isEqualToString:@"muted"] || [state isEqualToString:@"pending"] || [state isEqualToString:@"invited"]) {
					[newMembers addObject:member];
				}
			}
			_members = [newMembers retain];
			
		}
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];

	}
	
	if ([_members count] > 0) {
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}

	
}

#pragma mark - GMCreateContactViewControllerDelegate

- (void)createdContactWithEmail:(NSString *)email withName:(NSString*)name {
	[self addMemberWithName:name andContactInfo:email andContactType:@"email"];
}

- (void)createdContactWithPhoneNumber:(NSString *)phoneNumber withName:(NSString*)name {
	[self addMemberWithName:name andContactInfo:phoneNumber andContactType:@"phone_number"];
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
		
		BOOL nameExists = [[self memberNames] containsObject:contactName];
		
		if (nameExists) {
			
			[peoplePicker dismissModalViewControllerAnimated:NO];
			[GMCreateContactViewController showContactCreationInViewController:self 
															   withContactName:contactName 
																andContactInfo:phoneOrEmail 
													andBlacklistedContactNames:[self memberNames]
																   andDelegate:self];
			
			[GroupMeConnect showError:@"Someone already has that name, please enter a unique name for this contact."];
			
		} else if ([GroupMeConnect validateEmail:phoneOrEmail]) {
			
			[self addMemberWithName:contactName andContactInfo:phoneOrEmail andContactType:@"email"];
			
			[peoplePicker dismissModalViewControllerAnimated:YES];
			
		} else if ([GroupMeConnect validatePhone:phoneOrEmail]) {
			
			[self addMemberWithName:contactName andContactInfo:phoneOrEmail andContactType:@"phone_number"];
			[peoplePicker dismissModalViewControllerAnimated:YES];
			
		} else {
			
			[peoplePicker dismissModalViewControllerAnimated:YES];
			
		}
	} else {
		
		[peoplePicker dismissModalViewControllerAnimated:NO];
		
		[GMCreateContactViewController showContactCreationInViewController:self 
														   withContactName:nil 
															andContactInfo:phoneOrEmail 
												andBlacklistedContactNames:[self memberNames]
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
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark  - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {

	[controller dismissModalViewControllerAnimated:NO];

}

@end
