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


#import "GMRegisterDeviceViewController.h"

#import "GMButton.h"
#import "GMGroupDetailViewController.h"
#import "GMCreateGroupController.h"

@implementation GMRegisterDeviceViewController

@synthesize registrationDelegate = _registrationDelegate;
@synthesize externalGroupId = _externalGroupId;

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		
		_inputField = [[UITextField alloc] init];
		_inputField.autocorrectionType = UITextAutocorrectionTypeNo;
		_inputField.delegate = self;
		
		_actionButton = [[GMButton alloc] init];
		[_actionButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];

		[_actionButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
		
    }
    return self;
}

+ (void) showRegistrationInViewController:(UIViewController*)vc 
							  andDelegate:(id<GroupMeRegistrationDelegate>)regDelegate {
	

	[self showRegistrationInViewController:vc andExternalGroupId:nil andDelegate:regDelegate];
	
}

+ (void) showRegistrationInViewController:(UIViewController*)vc 
					   andExternalGroupId:(NSString*)externalId
							  andDelegate:(id<GroupMeRegistrationDelegate>)regDelegate {
	
	GMRegisterDeviceViewController *regVC = [[GMRegisterDeviceViewController alloc] init];
	regVC.registrationDelegate = regDelegate;
	regVC.externalGroupId = externalId;
	
	UINavigationController *regNav = [[UINavigationController alloc] initWithRootViewController:regVC];
	
	[vc presentModalViewController:regNav animated:YES];
	
	[regVC release];
	[regNav release];
	
}


- (void)dealloc
{
	[_externalGroupId release];
	[_inputField release];
	[_actionButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Actions

- (void)buttonPressed {
	if ([[GroupMeConnect sharedGroupMe] userMissingName]) {
		
		NSString *trimmed = [_inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([trimmed length] > 0) {
			_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Saving Name" andMessage:@"This will only take a moment"] retain];
			[[GroupMeConnect sharedGroupMe] saveName:trimmed andDelegate:self];
		} else {
			[GroupMeConnect showError:@"Please enter your name."];
		}
	} else if (![[GroupMeConnect sharedGroupMe] hasSentPIN]) {
		if ([GroupMeConnect validatePhone:_inputField.text]) {
			_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Authorizing Phone" andMessage:@"This will only take a moment"] retain];
			[[GroupMeConnect sharedGroupMe] authorizeForPhoneNumber:_inputField.text andDelegate:self];
		} else {
			[GroupMeConnect showError:@"Sorry, that is not a valid phone number"];
		}
	} else {
		_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Validating PIN" andMessage:@"This will only take a moment"] retain];
		[[GroupMeConnect sharedGroupMe] validatePin:_inputField.text andDelegate:self];
	}
	
	[_inputField becomeFirstResponder];
}

- (void) wrongNumber {
	[[GroupMeConnect sharedGroupMe] clearSession];
	[self.tableView reloadData];
	[_inputField becomeFirstResponder];
}

- (void) resendPIN {
	if ([[GroupMeConnect sharedGroupMe] lastPhoneNumberAttempted]) {
		_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Resending PIN" andMessage:@"This will only take a moment"] retain];
		[[GroupMeConnect sharedGroupMe] authorizeForPhoneNumber:[[GroupMeConnect sharedGroupMe] lastPhoneNumberAttempted] andDelegate:self];
	}
}

- (void)close {
	[self dismissModalViewControllerAnimated:YES];
	
}

- (void)cancel {
	[self close];
	if ([_registrationDelegate respondsToSelector:@selector(groupMeDidNotRegister:)]) {
		[_registrationDelegate groupMeDidNotRegister:YES];
	}

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationItem.title = @"Register";
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
	
	self.tableView.rowHeight = 70.0f;
	
	self.tableView.backgroundColor = GROUP_ME_BRANDING_BACKGROUND;

}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[_inputField becomeFirstResponder];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}


- (UIButton*)textButtonWithText:(NSString*)text {
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[[button titleLabel] setFont:[UIFont systemFontOfSize:14.0f]];
	
	[button setTitle:text forState:UIControlStateNormal];
	[button setTitleColor:GROUP_ME_BRANDING_BLUE forState:UIControlStateNormal];
	
	[button setTitleColor:GROUP_ME_BRANDING_DARK_BLUE forState:UIControlStateHighlighted];
	
	[[button titleLabel] setTextAlignment:UITextAlignmentCenter];
	
	[button sizeToFit];
	
	return button;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 60.0f;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])] autorelease];
	
	
	if ([[GroupMeConnect sharedGroupMe] userMissingName]) {
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 5.0f, self.view.bounds.size.width - 30.0f, 50.0f)];
		
		
		label.font = [UIFont boldSystemFontOfSize:13.0f];
		label.textColor = [UIColor colorWithRed:122.0/255.0f green:122.0/255.0f blue:114.0f/255.0f alpha:1.0f];
		label.shadowColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		label.opaque = NO;
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.textAlignment = UITextAlignmentCenter;
		label.numberOfLines = 2;
		label.text = @"You look new to GroupMe.\nPlease specify your name to continue.";
		
		[view addSubview:label];
		
		[label release];

	} else if ([[GroupMeConnect sharedGroupMe] hasSentPIN]) {
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 9.0f, self.view.bounds.size.width - 30.0f, 20.0f)];
		
		
		label.font = [UIFont systemFontOfSize:15.0f];
		label.textColor = [UIColor colorWithRed:122.0/255.0f green:122.0/255.0f blue:114.0f/255.0f alpha:1.0f];
		label.shadowColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		label.opaque = NO;
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.textAlignment = UITextAlignmentCenter;
		label.text = [NSString stringWithFormat:@"Enter the PIN we texted to %@", [GroupMeConnect formatPhoneNumber:[[GroupMeConnect sharedGroupMe] lastPhoneNumberAttempted]]];
		
		[view addSubview:label];
		
		[label release];
		
		UIButton *wrongNumberButton = [self textButtonWithText:@"Not your number?"];
		[wrongNumberButton addTarget:self action:@selector(wrongNumber) forControlEvents:UIControlEventTouchUpInside];

		UIButton *resendPINButton = [self textButtonWithText:@"Resend PIN"];
		[resendPINButton addTarget:self action:@selector(resendPIN) forControlEvents:UIControlEventTouchUpInside];
		
		CGFloat buttonY = 34.0f;
		
		wrongNumberButton.frame = CGRectMake(15.0f, buttonY, wrongNumberButton.frame.size.width, wrongNumberButton.frame.size.height);
		resendPINButton.frame = CGRectMake(self.view.bounds.size.width - wrongNumberButton.frame.size.width, buttonY, wrongNumberButton.frame.size.width, wrongNumberButton.frame.size.height);
		
		[view addSubview:wrongNumberButton];
		[view addSubview:resendPINButton];
		
		
		
	} else {
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 5.0f, self.view.bounds.size.width - 30.0f, 50.0f)];
		
		
		label.font = [UIFont boldSystemFontOfSize:13.0f];
		label.textColor = [UIColor colorWithRed:122.0/255.0f green:122.0/255.0f blue:114.0f/255.0f alpha:1.0f];
		label.shadowColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		label.opaque = NO;
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.textAlignment = UITextAlignmentCenter;
		label.numberOfLines = 2;
		label.text = @"New and existing GroupMe users must\nverify their phone number to create groups.";
		
		[view addSubview:label];
		
		[label release];
		
	}
	
	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 60.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	UIView *wrapper = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 60.0f)] autorelease];
	
	_actionButton.frame = CGRectMake(10.0f, 10.0f, 300.0f, 40.0);
	
	if ([[GroupMeConnect sharedGroupMe] userMissingName]) {
		[_actionButton setTitle:@"Set your name" forState:UIControlStateNormal];
	} else if ([[GroupMeConnect sharedGroupMe] hasSentPIN]) {
		[_actionButton setTitle:@"Validate PIN" forState:UIControlStateNormal];
	} else {
		[_actionButton setTitle:@"Register Phone Number" forState:UIControlStateNormal];
	}
	
	[wrapper addSubview:_actionButton];
	
	return wrapper;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		_inputField.frame = CGRectMake(20.0f, 12.0f, 280.0f, 44.0f);
		_inputField.font = [UIFont systemFontOfSize:36.0f];
		[cell addSubview:_inputField];
		cell.selectionStyle = UITableViewCellEditingStyleNone;
    }
	
	if ([[GroupMeConnect sharedGroupMe] userMissingName]) {
		_inputField.placeholder = @"Name";
		_inputField.keyboardType = UIKeyboardTypeDefault;
		_inputField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	} else if ([[GroupMeConnect sharedGroupMe] hasSentPIN]) {
		_inputField.placeholder = @"PIN Number";
		_inputField.keyboardType = UIKeyboardTypeDefault;
		_inputField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
	} else {
		_inputField.placeholder = @"(###) ###-####";
		_inputField.keyboardType = UIKeyboardTypePhonePad;
		if ([[GroupMeConnect sharedGroupMe] lastPhoneNumberAttempted]) {
			_inputField.text = [GroupMeConnect formatPhoneNumber:[[GroupMeConnect sharedGroupMe] lastPhoneNumberAttempted]];
		}
	}
    
    return cell;
}


#pragma mark - Phone number formatter

- (NSString *)prettyPhoneNumber:(NSString *)phoneN{
	
	NSString *pretty = [NSString string];
	
	int i;
	for (i = 0; i < [phoneN length]; i++) {
		switch (i) {
			case 0:
				pretty = [pretty stringByAppendingFormat:@"(%c", [phoneN characterAtIndex:i]];
				break;
			case 2:
				pretty = [pretty stringByAppendingFormat:@"%c", [phoneN characterAtIndex:i]];
				break;
			case 3:
				pretty = [pretty stringByAppendingFormat:@") %c", [phoneN characterAtIndex:i]];
				break;
			case 6:
				pretty = [pretty stringByAppendingFormat:@"-%c", [phoneN characterAtIndex:i]];
				break;
			default:
				pretty = [pretty stringByAppendingFormat:@"%c", [phoneN characterAtIndex:i]];
				break;
		}
	}
	
	return pretty;
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	
	NSString *testString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
	
	if(![[GroupMeConnect sharedGroupMe] userMissingName] && ![[GroupMeConnect sharedGroupMe] hasSentPIN]){
		NSString *newPhoneNumberString = [[testString componentsSeparatedByCharactersInSet:
										   [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
		
		if (![testString hasPrefix:@"+"] && [newPhoneNumberString length] <= 10) {
			[textField setText:[self prettyPhoneNumber:newPhoneNumberString]];
			return NO;
		} else if (![testString hasPrefix:@"+"] && [newPhoneNumberString length] >= 10) {
			return NO;
		}
	}
	
	if ([[GroupMeConnect sharedGroupMe] userMissingName] && [testString length] > 100) {
		return NO;
	}
	
	return YES;
}

#pragma mark - GroupMeRegistrationDelegate

- (void)hideAlert {
	if (_alertView) {
		[_alertView dismissWithClickedButtonIndex:0 animated:YES];
		[_alertView release];
		_alertView = nil;
	}
}

//Called when user successfulling logs in
- (void)groupMeDidRegister {
	
	[[GroupMeConnect sharedGroupMe] refreshGroupsWithDelegate:self];
	
	if ([_registrationDelegate respondsToSelector:@selector(groupMeDidRegister)]) {
		[_registrationDelegate groupMeDidRegister];
	}

}

//Called when user needs to submit a PIN to verify number, it will be sent via SMS
- (void)groupMeRequiresPIN {
	[self hideAlert];
	_inputField.text = @"";
	[self.tableView reloadData];
	[_inputField becomeFirstResponder];
	
	//don't pass this on to the delegate because PIN handling is taken care of in this VC.
	
}

//Called when user needs to set a name for the account, this will be for first time users
- (void)groupMeRequiresName {
	[self hideAlert];
	_inputField.text = @"";
	[self.tableView reloadData];
	[_inputField becomeFirstResponder];
	
	//don't pass this on to the delegate because PIN handling is taken care of in this VC.
	
}

- (void)groupMeFailedUpdatingName {
	[self hideAlert];
	[_inputField becomeFirstResponder];
	[GroupMeConnect showError:@"Sorry, could not complete operation right now."];
}

//Called when user needs to submit a PIN to verify number, it will be sent via SMS
- (void)groupMeInvalidPIN {
	[self hideAlert];
	[self.tableView reloadData];
	[GroupMeConnect showError:@"Invalid PIN"];
	[_inputField becomeFirstResponder];

	//don't pass this on to the delegate because PIN handling is taken care of in this VC.
}

//Called when user does not log in
- (void)groupMeDidNotRegister:(BOOL)cancelled {
	[self hideAlert];
	if (!cancelled) {
		[GroupMeConnect showError:@"Failed Registration."];
	}
	
	//don't pass this on to the delegate, because they may try again
}

#pragma mark -
#pragma mark GroupMeRequestDelegate


- (void)request:(GroupMeRequest *)request didFailWithError:(NSError *)error {
	[self hideAlert];
	
	if (_externalGroupId != nil) {
		GMCreateGroupController *createVC = [[GMCreateGroupController alloc] init];
		createVC.externalGroupId = _externalGroupId;
		[self.navigationController pushViewController:createVC animated:YES];
		[createVC release];
		return;
	}

	[self close];
}

- (void)request:(GroupMeRequest *)request didLoad:(id)result {
	[self hideAlert];
	
	if ([result isKindOfClass:[NSDictionary class]] && [(NSDictionary*)result objectForKey:@"groups"] != nil) {
		[[GroupMeConnect sharedGroupMe] setGroups:[(NSDictionary*)result objectForKey:@"groups"]];
		
		if (_externalGroupId != nil) {
			
			if ([[GroupMeConnect sharedGroupMe] groupForExternalId:_externalGroupId] != nil) {
				GMGroupDetailViewController *detailVC = [[GMGroupDetailViewController alloc] initWithGroup:[[GroupMeConnect sharedGroupMe] groupForExternalId:_externalGroupId]];
				detailVC.navigationItem.hidesBackButton = YES;
				[self.navigationController pushViewController:detailVC animated:YES];
				[detailVC release];
				return;
			}
			
		}
		
	}
	
	//in case this group wasn't found in the preloading.
	if (_externalGroupId != nil) {
		GMCreateGroupController *createVC = [[GMCreateGroupController alloc] init];
		createVC.externalGroupId = _externalGroupId;
		[self.navigationController pushViewController:createVC animated:YES];
		[createVC release];
		return;
	}

	[self close];

}
@end
