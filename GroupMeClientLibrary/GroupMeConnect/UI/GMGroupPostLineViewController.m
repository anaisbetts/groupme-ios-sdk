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


#import "GMGroupPostLineViewController.h"


@implementation GMGroupPostLineViewController

@synthesize postLineDelegate = _postLineDelegate;

- (id)initWithGroup:(NSDictionary*)group
{
    self = [super init];
    if (self) {
		
		_group = [group retain];
		_textView = [[UITextView alloc] initWithFrame:CGRectZero];
		_textView.delegate = self;
		_locationLabel = [[UILabel alloc] init];
		
    }
    return self;
}

+ (void) showGroupPostLineInViewController:(UIViewController*)vc 
								  andGroup:(NSDictionary*)group
							   andDelegate:(id<GMGroupPostLineViewControllerDelegate>)plDelegate {
	[self showGroupPostLineInViewController:vc withDefaultMessage:nil andGroup:group andDelegate:plDelegate];
	
}

+ (void) showGroupPostLineInViewController:(UIViewController*)vc 
						withDefaultMessage:(NSString*)message
								  andGroup:(NSDictionary*)group 
							   andDelegate:(id<GMGroupPostLineViewControllerDelegate>)plDelegate {

	[self showGroupPostLineInViewController:vc 
						 withDefaultMessage:message
							andLocationName:nil 
								andLatitude:nil 
							   andLongitude:nil 
								   andGroup:group 
								andDelegate:plDelegate];
	
}

+ (void) showGroupPostLineInViewController:(UIViewController*)vc 
						withDefaultMessage:(NSString*)message
						   andLocationName:(NSString*)locationName
							   andLatitude:(NSNumber*)latitude
							  andLongitude:(NSNumber*)longitude
								  andGroup:(NSDictionary*)group 
							   andDelegate:(id<GMGroupPostLineViewControllerDelegate>)plDelegate {
	
	GMGroupPostLineViewController *pvc = [[GMGroupPostLineViewController alloc] initWithGroup:group];
	
	if (message != nil) 
		[pvc setText:message];
	
	if (locationName != nil && latitude != nil && longitude != nil) {
		[pvc setLocationName:locationName withLatitude:latitude andLongitude:longitude];
	}
	
	pvc.postLineDelegate = plDelegate;
	
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pvc];
	
	[vc presentModalViewController:nav animated:YES];
	
	[pvc release];
	[nav release];
	
}


- (void)dealloc
{
	[_locationLabel release];
	[_locationName release];
	[_latitude release];
	[_longitude release];
	[_textView release];
	[_group release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Actions

- (void)cancel {
	if (_postLineDelegate != nil && [_postLineDelegate respondsToSelector:@selector(groupMeDismissedGroupPostLine)]) {
		[self dismissModalViewControllerAnimated:NO];
		[_postLineDelegate groupMeDismissedGroupPostLine];
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (void) setText:(NSString*)text {
	[_textView setText:text];
}

- (void) setLocationName:(NSString*)locationName withLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude {
	if (locationName != nil && latitude != nil && longitude != nil) {
		[_locationName release];
		_locationName = [locationName retain];
		[_latitude release];
		_latitude = [latitude retain];
		[_longitude release];
		_longitude = [longitude retain];
		[_locationLabel setText:[NSString stringWithFormat:@"Location: %@", _locationName]];
	}
}

- (void)post {
	
	if ([_textView.text length] > 0) {
		
		_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Posting Message" andMessage:@"This will only take a moment"] retain];
		
		[_textView resignFirstResponder];
		[_textView becomeFirstResponder];
		
		[[GroupMeConnect sharedGroupMe] postMessage:_textView.text toGroup:_group withLocationName:_locationName atLatitude:_latitude andLongitude:_longitude andDelegate:self];

	}
	
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	
	self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.view.backgroundColor = [UIColor whiteColor];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationItem.title = @"Post Message";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(post)];

	
	CGFloat padding = 10.0f;
	
	_textView.frame = CGRectMake(padding, padding, self.view.frame.size.width - (padding*2), 160.0f);
	_textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
	_textView.backgroundColor = [UIColor whiteColor];
	_textView.font = [UIFont systemFontOfSize:18.0f];
	[self.view addSubview:_textView];
	
	padding = 15.0f;
	
	_locationLabel.frame = CGRectMake(padding, _textView.frame.origin.y + _textView.frame.size.height, self.view.frame.size.width - (padding*2), 20.0f);
	
	_locationLabel.font = [UIFont boldSystemFontOfSize:13.0f];
	
	_locationLabel.textColor = [UIColor lightGrayColor];
	
	[self.view addSubview:_locationLabel];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	[self.view release];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_textView becomeFirstResponder];
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
	NSInteger limit = 160;
	
	if(![text canBeConvertedToEncoding:NSUTF8StringEncoding]){
		return NO;
	}
	if(![text canBeConvertedToEncoding:NSASCIIStringEncoding]){
		limit = 140;
	}
	
	NSString *newString = [[textView text] stringByReplacingCharactersInRange:range withString:text];
	
	
	//if it can't be ascii, has to be 8bit, so 140, not 160.. and some chars are 2 bytes (emoji), so we need to convert it to data to see how long it is
	if ([[newString dataUsingEncoding:NSUTF8StringEncoding] length] >= limit)
		return NO;
	
	if([newString length] == 0 && [[textView text] length] == 0 && range.location == 0 && range.length == 0) return NO;
	
	return YES;
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

- (void)handleErrorForRequest:(GroupMeRequest*)request {
	Class messageComposeViewControllerClass = NSClassFromString(@"MFMessageComposeViewController");
	
	if (messageComposeViewControllerClass && [messageComposeViewControllerClass canSendText]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Try over SMS?"
														message:@"We couldn't send the message over your data connection. Would you like to try over SMS?" 
													   delegate:self 
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"SMS", nil];
		[alert show];
		[alert release];

	} else {
		if ([request.errors count] > 0) {
			[GroupMeConnect showError:[request.errors objectAtIndex:0]];
		} else {
			[GroupMeConnect showError:@"Could not post message.\nPlease try again later."];
		}
	}

}

- (void)request:(GroupMeRequest *)request didFailWithError:(NSError *)error {
	[self hideAlert];
	[self handleErrorForRequest:request];
}

- (void)request:(GroupMeRequest *)request didLoad:(id)result {
	[self hideAlert];
	if ([result isKindOfClass:[NSDictionary class]] && [(NSDictionary*)result objectForKey:@"line"] != nil) {
		if (_postLineDelegate != nil && [_postLineDelegate respondsToSelector:@selector(groupMePostedMessageToGroup:)]) {
			[self dismissModalViewControllerAnimated:NO];
			[_postLineDelegate groupMePostedMessageToGroup:_group];
		} else {
			[self dismissModalViewControllerAnimated:YES];
		}

	} else {
		if ([request.errors count] > 0) {
			[GroupMeConnect showError:[request.errors objectAtIndex:0]];
		} else {
			[GroupMeConnect showError:@"Could not post message.\nPlease try again later."];
		}
	}
	
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 1) {
		
		//show SMS thing.
		
		Class messageComposeViewControllerClass = NSClassFromString(@"MFMessageComposeViewController");
		
		if (messageComposeViewControllerClass && [messageComposeViewControllerClass canSendText]) {
			id controller = [[messageComposeViewControllerClass alloc] initWithNibName:nil bundle:nil];
			[controller setRecipients:[NSArray arrayWithObject:[_group objectForKey:@"phone_number"]]];
			[controller setBody:_textView.text];
			[controller setMessageComposeDelegate:self];
			[self.navigationController presentModalViewController:controller animated:YES];
			[controller release];
		}
		
	}
	
}

#pragma mark  - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {

	if (result == MessageComposeResultSent) {
		if (_postLineDelegate != nil && [_postLineDelegate respondsToSelector:@selector(groupMePostedMessageToGroup:)]) {
			[controller dismissModalViewControllerAnimated:NO];
			[self dismissModalViewControllerAnimated:NO];
			[_postLineDelegate groupMePostedMessageToGroup:_group];
		} else {
			[controller dismissModalViewControllerAnimated:NO];
			[self dismissModalViewControllerAnimated:YES];
		}
	} else {
		if (_postLineDelegate != nil && [_postLineDelegate respondsToSelector:@selector(groupMeDismissedGroupPostLine)]) {
			[controller dismissModalViewControllerAnimated:NO];
			[self dismissModalViewControllerAnimated:NO];
			[_postLineDelegate groupMeDismissedGroupPostLine];
		} else {
			[controller dismissModalViewControllerAnimated:NO];
			[self dismissModalViewControllerAnimated:YES];
		}
	}
}

@end
