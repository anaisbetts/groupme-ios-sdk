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


#import "GMCreateContactViewController.h"


@implementation GMCreateContactViewController

@synthesize delegate;

- (id)initWithContactName:(NSString*)contactName
		   andContactInfo:(NSString*)contactInfo
andBlacklistedContactNames:(NSArray*)blacklistedContactNames {
	
	self = [super initWithStyle:UITableViewStyleGrouped];

	
	if (self) {
		
		_nameField = [[UITextField alloc] init];
		_nameField.returnKeyType = UIReturnKeyNext;
		_nameField.delegate = self;
		_nameField.autocorrectionType = UITextAutocorrectionTypeNo;

		if (contactName)
			_nameField.text = contactName;
		
		_infoField = [[UITextField alloc] init];
		_infoField.returnKeyType = UIReturnKeyDone;
		_infoField.delegate = self;
		_infoField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_infoField.autocorrectionType = UITextAutocorrectionTypeNo;

		if (contactInfo)
			_infoField.text = contactInfo;
		
		if (blacklistedContactNames) {
			_blacklistedNames = [blacklistedContactNames copy];
		} else {
			_blacklistedNames = [[NSArray alloc] init];
		}
		
    }
	
    return self;
	
	

}

+ (void) showContactCreationInViewController:(UIViewController*)vc 
							 withContactName:(NSString*)contactName
							  andContactInfo:(NSString*)contactInfo
				  andBlacklistedContactNames:(NSArray*)blacklistedContactNames
								 andDelegate:(id<GMCreateContactViewControllerDelegate>)contactCreateDelegate {
	
	GMCreateContactViewController *createVC = [[GMCreateContactViewController alloc] initWithContactName:contactName 
																						  andContactInfo:contactInfo 
																			  andBlacklistedContactNames:blacklistedContactNames];
	createVC.delegate = contactCreateDelegate;
	
	UINavigationController *createNav = [[UINavigationController alloc] initWithRootViewController:createVC];
	
	[vc presentModalViewController:createNav animated:YES];
	
	[createVC release];
	[createNav release];
	
}


- (void)dealloc
{
	[_nameField release];
	[_infoField release];
	[_blacklistedNames release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)cancel {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)done {
	
	NSString *nameText = [_nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString *contactText = [_infoField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([nameText length] == 0) {
		[_nameField becomeFirstResponder];
		[GroupMeConnect showError:@"Name cannot be empty"];
		return;
	}

	if ([contactText length] == 0) {
		[_infoField becomeFirstResponder];
		[GroupMeConnect showError:@"Please enter a phone number or email address"];
		return;
	}
	
	if (![GroupMeConnect validateEmail:contactText] && ![GroupMeConnect validatePhone:contactText]) {
		[_infoField becomeFirstResponder];
		[GroupMeConnect showError:@"Please enter a valid phone number or email address"];
		return;
	}
	
	if ([_blacklistedNames containsObject:nameText]) {
		[_nameField becomeFirstResponder];
		[GroupMeConnect showError:@"You already have a contact with that name, please give this contact a unique nickname"];
		return;
	}
	
	if ([GroupMeConnect validateEmail:contactText] && [delegate respondsToSelector:@selector(createdContactWithEmail:withName:)]) {
		[delegate createdContactWithEmail:contactText withName:nameText];
	}
	
	if ([GroupMeConnect validatePhone:contactText] && [delegate respondsToSelector:@selector(createdContactWithPhoneNumber:withName:)]) {
		[delegate createdContactWithPhoneNumber:contactText withName:nameText];
	}
	
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationItem.title = @"New Contact";
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
	
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	self.tableView.backgroundColor = GROUP_ME_BRANDING_BACKGROUND;

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
	
	[_nameField becomeFirstResponder];
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	if (section == 0) {
		return @"Contact Name";
	} else {
		return @"Email or Phone Number";
	}
	
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	if (indexPath.section == 0) {
		static NSString *CellIdentifier = @"NameCell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			_nameField.frame = CGRectMake(20.0f, 12.0f, 280.0f, 40.0f);
			_nameField.font = [UIFont systemFontOfSize:18.0f];
			[cell addSubview:_nameField];
			cell.selectionStyle = UITableViewCellEditingStyleNone;
		}
		
		return cell;
	} else {
		static NSString *CellIdentifier = @"InfoCell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			_infoField.frame = CGRectMake(20.0f, 12.0f, 280.0f, 40.0f);
			_infoField.font = [UIFont systemFontOfSize:18.0f];
			[cell addSubview:_infoField];
			cell.selectionStyle = UITableViewCellEditingStyleNone;
		}
		
		return cell;

	}
}

#pragma mark -
#pragma mark UITextFieldDelegate


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

	NSString *nameText = _nameField.text;
	NSString *infoText = _infoField.text;
	
	if (textField == _nameField) {
		nameText = [[textField text] stringByReplacingCharactersInRange:range withString:string];
	}
	if (textField == _infoField) {
		infoText = [[textField text] stringByReplacingCharactersInRange:range withString:string];
	}
	
	if ([infoText length] > 0 && [nameText length] > 0) {
		self.navigationItem.rightBarButtonItem.enabled = YES;
	} else {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == _nameField) {
		[_infoField becomeFirstResponder];
	}
	
	if (textField == _infoField) {
		[self done];
	}
	return NO;
}



@end
