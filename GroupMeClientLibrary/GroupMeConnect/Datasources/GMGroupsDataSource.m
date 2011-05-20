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

#import "GMGroupsDataSource.h"

#define GM_TIMESTAMP_TAG 666
#define GM_GROUP_TOPIC_TAG 777
#define GM_DESCRIPTION_TAG 888

static NSDateFormatter *shortDateFormatter;


@implementation GMGroupsDataSource

@synthesize delegate;
@synthesize showDisclosure = _showDisclosure;

#pragma mark - Init/Destroy

- (id)init
{
    self = [super init];
    if (self) {
		_showDisclosure = YES;
    }
    return self;
}

- (void) dealloc {
	_lastRequest.delegate = nil;
	[_lastRequest cancel];
	[_lastRequest release];
	[super dealloc];
}

#pragma mark - Data

- (id) dataForIndexPath:(NSIndexPath*)indexPath {
	if ([[[GroupMeConnect sharedGroupMe] groups] count] > indexPath.row) 
		return [[[GroupMeConnect sharedGroupMe] groups] objectAtIndex:indexPath.row];
	return nil;
}

#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[GroupMeConnect sharedGroupMe] groups] count];
}

- (NSString*)formattedTimestampFromEpoch:(NSNumber*)epoch {
	
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[epoch intValue]];
	
	double ti = [[NSDate date] timeIntervalSince1970] - [date timeIntervalSince1970];
	
	if (ti < 60) {
        return @"just now";
    } else if (ti < 3600) {
        int diff = round(ti / 60);
		if (diff == 1) { 
			return[NSString stringWithFormat:@"%d min ago", diff];
		} else {
			return[NSString stringWithFormat:@"%d min ago", diff];
		}
    } else if (ti < 86400) {
        int diff = round(ti / 60 / 60);
		if (diff == 1) { 
			return[NSString stringWithFormat:@"%d hr ago", diff];
		} else {
			return[NSString stringWithFormat:@"%d hrs ago", diff];
		}
    } else if (ti < 2629743) {
        int diff = round(ti / 60 / 60 / 24);
		if (diff == 1) { 
			return[NSString stringWithFormat:@"%d day ago", diff];
		} else {
			return[NSString stringWithFormat:@"%d days ago", diff];
		}
    } else {
		if (shortDateFormatter == nil) {
			@synchronized (self) {
				shortDateFormatter = [[NSDateFormatter alloc] init];
				[shortDateFormatter setDateFormat:@"MMM dd, YYYY"];
			}
		}
		
		return [shortDateFormatter stringFromDate:date];
    }   
	
}

- (UILabel*)labelForTimestamp {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	
	
	label.font = [UIFont systemFontOfSize:12.0f];
	label.textColor = GROUP_ME_BRANDING_BLUE;
	label.textAlignment = UITextAlignmentRight;
	label.tag = GM_TIMESTAMP_TAG;
	label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin);
	
	return [label autorelease];
	
}

- (UILabel*)labelForTopic {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	
	
	label.font = [UIFont boldSystemFontOfSize:18.0f];
	label.textColor = [UIColor blackColor];
	label.textAlignment = UITextAlignmentLeft;
	label.tag = GM_GROUP_TOPIC_TAG;
	
	return [label autorelease];
	
}

- (UILabel*)labelForDescription {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	
	
	label.font = [UIFont systemFontOfSize:14.0f];
	label.textColor = [UIColor grayColor];
	label.textAlignment = UITextAlignmentLeft;
	label.tag = GM_DESCRIPTION_TAG;
	
	return [label autorelease];
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		if (_showDisclosure)
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		else
			cell.accessoryType = UITableViewCellAccessoryNone;
		[cell layoutSubviews];
    }


    // Configure the cell...
	
	NSDictionary *group = [self dataForIndexPath:indexPath];
    
	//topic
	UILabel *topicLabel = (UILabel*)[cell.contentView viewWithTag:GM_GROUP_TOPIC_TAG];
	if (topicLabel == nil) {
		topicLabel = [self labelForTopic];
		[cell.contentView addSubview:topicLabel];
	}
	
	topicLabel.text = [group objectForKey:@"topic"];
	
	//description
	
	UILabel *descriptionLabel = (UILabel*)[cell.contentView viewWithTag:GM_DESCRIPTION_TAG];
	if (descriptionLabel == nil) {
		descriptionLabel = [self labelForDescription];
		[cell.contentView addSubview:descriptionLabel];
	}
	
	if ([group objectForKey:@"description"] != nil && [[group objectForKey:@"description"] isKindOfClass:[NSString class]]) {
		descriptionLabel.text = [group objectForKey:@"description"];
	} else if ([group objectForKey:@"phone_number"] != nil && [[group objectForKey:@"phone_number"] isKindOfClass:[NSString class]]) {
		descriptionLabel.text = [GroupMeConnect formatPhoneNumber:[group objectForKey:@"phone_number"]];
	} else {
		descriptionLabel.text = @"The description will go here...";
	}
	
	//timestamp
	UILabel *timestampLabel = (UILabel*)[cell.contentView viewWithTag:GM_TIMESTAMP_TAG];
	if (timestampLabel == nil) {
		timestampLabel = [self labelForTimestamp];
		[cell.contentView addSubview:timestampLabel];
	}
	
	if ([[group objectForKey:@"updated_at"] isKindOfClass:[NSNumber class]]) {
		timestampLabel.text = [self formattedTimestampFromEpoch:[group objectForKey:@"updated_at"]];
	} else {
		timestampLabel.text = @"";
	}
	
	//layout
	[timestampLabel sizeToFit];
	
	CGFloat disclosureOffset = (_showDisclosure ? 15.0f : 0.0f);
	
	timestampLabel.frame = CGRectMake(tableView.frame.size.width - timestampLabel.frame.size.width - 10.0f - disclosureOffset,
									  5.0f, 
									  timestampLabel.frame.size.width, 
									  timestampLabel.frame.size.height);
	
	topicLabel.frame = CGRectMake(10.0f, 
								  5.0f, 
								  tableView.frame.size.width - timestampLabel.frame.size.width - 30.0f - disclosureOffset, 
								  24.0f);
	
	descriptionLabel.frame = CGRectMake(10.0f, 
										28.0f, 
										tableView.frame.size.width - 30.0f - disclosureOffset, 
										17.0f);
    return cell;
}

#pragma mark - Refresh Groups

- (void) refreshGroups {
	if ([[GroupMeConnect sharedGroupMe] isSessionValid])
		_lastRequest = [[[GroupMeConnect sharedGroupMe] refreshGroupsWithDelegate:self] retain];
}

#pragma mark - GroupMeRequestDelegate

- (void)request:(GroupMeRequest *)request didReceiveResponse:(NSURLResponse *)response {

	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	
	if ([httpResponse statusCode] == 401) {
		[[GroupMeConnect sharedGroupMe] clearSession];
		if ([delegate respondsToSelector:@selector(refreshedGroups)]) {
			[delegate refreshedGroups];
		}
		_lastRequest.delegate = nil;
		[_lastRequest release];
		_lastRequest = nil;
	}
}

- (void)request:(GroupMeRequest *)request didFailWithError:(NSError *)error {
	[_lastRequest release];
	_lastRequest = nil;
}

- (void)request:(GroupMeRequest *)request didLoad:(id)result {
	

	[_lastRequest release];
	_lastRequest = nil;
	
	if ([[GroupMeConnect sharedGroupMe] isSessionValid] //just in case they logged out in between request start and finish
		&& [result isKindOfClass:[NSDictionary class]] 
		&& [(NSDictionary*)result objectForKey:@"groups"] != nil) {
		[[GroupMeConnect sharedGroupMe] setGroups:[(NSDictionary*)result objectForKey:@"groups"]];
		
		if ([delegate respondsToSelector:@selector(refreshedGroups)]) {
			[delegate refreshedGroups];
		}
	}
	
}

@end
