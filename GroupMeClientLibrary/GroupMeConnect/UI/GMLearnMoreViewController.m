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

#import "GMLearnMoreViewController.h"


@implementation GMLearnMoreViewController

@synthesize url = _url;

+ (void) showLearnMoreInViewController:(UIViewController*)vc {
	
	GMLearnMoreViewController *lvc = [[GMLearnMoreViewController alloc] init];
	lvc.url = @"http://groupme.com/client_library_help";
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:lvc];
	
	[vc presentModalViewController:nav animated:YES];
	
	[lvc release];
	[nav release];

	
}

+ (void) showTermsInViewController:(UIViewController*)vc {
	GMLearnMoreViewController *lvc = [[GMLearnMoreViewController alloc] init];
	lvc.url = @"http://groupme.com/terms";
	
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:lvc];
	
	[vc presentModalViewController:nav animated:YES];
	
	[lvc release];
	[nav release];
	
}


- (void) dealloc {
	[_url release];
	[_spinner release];
	[_webView release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)close {
	[self dismissModalViewControllerAnimated:YES];
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	_webView = [[UIWebView alloc] init];
	[_webView setScalesPageToFit:YES];
	[self setView:_webView];
	
	_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[_spinner sizeToFit];

	
	self.navigationItem.title = @"GroupMe";
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:_spinner] autorelease];

	

}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	//Set up the spinner

	//load the help page
	_webView.delegate = self;
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[_spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
	[_spinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
	[_spinner stopAnimating];
	[webView loadHTMLString:[NSString stringWithFormat:@"<html><head><body><div style=\"font-family: Helvetica;font-size:30pt;font-weight:bold;padding:80px 20px\">Could not load help page.<br/><br/><a style=\"color:#1A789E;text-decoration:none;\" href=\"%@\">Try to reload.</a></div></body></html>", _url] baseURL:nil];
	
}
@end
