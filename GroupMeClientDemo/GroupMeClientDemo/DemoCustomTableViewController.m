//
//  DemoCustomTableViewController.m
//  GroupMeClientDemo
//
//  Created by Jeremy Schoenherr on 4/8/11.
//  Copyright 2011 Mindless Dribble, Inc. All rights reserved.
//

#import "DemoCustomTableViewController.h"

#import "GroupMeConnect.h"
#import "GMChatButton.h"

@implementation DemoCustomTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.tabBarItem.title = @"Demo";
	self.tableView.rowHeight = 52.0f;

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
    return 3;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 0)
		return @"Use the GMChatButton to pop up a modal of the group list anywhere.";
	else if (section == 1)
		return @"Tap the above cell to select a group to post a message to.";
	else
		return @"Tap the above cell to select a group to post a message to and be able to edit the default text.";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		static NSString *CellIdentifier = @"ChatCell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			
			GMChatButton *chatButton = [[GMChatButton alloc] initWithViewController:self];
			
			cell.accessoryView = chatButton;
			
			[chatButton release];
			
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		// Configure the cell...
		
		cell.textLabel.text = @"Chat button";
		
		return cell;
	} else if (indexPath.section == 1) {
		static NSString *CellIdentifier = @"PostCell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
			
			
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		
		// Configure the cell...
		
		cell.textLabel.text = @"Post \"Test\" to a group..";
		cell.detailTextLabel.text = @"Also attaches a location (Brooklyn)";
		
		return cell;
		
	} else {
		static NSString *CellIdentifier = @"PostAndConfirmCell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
			
			
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		
		// Configure the cell...
		
		cell.textLabel.text = @"Compose a message";
		cell.detailTextLabel.text = @"Pick a group and edit text";
		
		return cell;
		
	}
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

	if (indexPath.section == 1) {
		[GMGroupsTableViewController showGroupsInViewController:self 
												   withDelegate:self];
	}
	if (indexPath.section == 2) {
		[GMGroupsTableViewController showGroupsInViewController:self 
												  toPostMessage:@"This is the default" 
												andLocationName:@"Brooklyn" 
													andLatitude:[NSNumber numberWithFloat:40.695f] 
												   andLongitude:[NSNumber numberWithFloat:-73.981f]];
	}
}



#pragma mark -  GMGroupsTableViewControllerDelegate

//Called when user picks a group
- (void)groupMePickedGroup:(NSDictionary*)group {
	if (group != nil) {
		_alertView = [[GroupMeConnect workingAlertViewWithTitle:@"Posting Message" andMessage:@"This will only take a moment"] retain];
		
		[[GroupMeConnect sharedGroupMe] postMessage:@"Test" 
											toGroup:group 
								   withLocationName:@"Brooklyn" 
										 atLatitude:[NSNumber numberWithFloat:40.695f] 
									   andLongitude:[NSNumber numberWithFloat:-73.981f]
										andDelegate:self];
	}
}

//Called if they cancel picking a group
- (void)groupMeDismissedGroupsList {
	
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
	[self hideAlert];
	if ([request.errors count] > 0) {
		[GroupMeConnect showError:[request.errors objectAtIndex:0]];
	} else {
		[GroupMeConnect showError:@"Could not post message.\nPlease try again later."];
	}
}

- (void)request:(GroupMeRequest *)request didLoad:(id)result {
	[self hideAlert];
	
}


@end
