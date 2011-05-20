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


#import "GMChatButton.h"
#import "GMGroupsTableViewController.h"

@implementation GMChatButton

- (id)initWithViewController:(UIViewController*)parentViewController
{
	
	self = [super init];
    if (self) {
		_parentViewController = [parentViewController retain];
		[self addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
		
		[self.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
		[self setTitle:@"GroupMe" forState:UIControlStateNormal];
		self.frame = CGRectMake(0.0f, 0.0f, 80.0f, 30.0f);

    }
    return self;
	
}

- (void) dealloc {
	[_parentViewController release];
	[super dealloc];
}

- (void) buttonPressed {
	
	[GMGroupsTableViewController showGroupsInViewController:_parentViewController];
	
}


@end
