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


#import "GMButton.h"

@implementation GMButton

@synthesize buttonStyle;

- (id)init
{
	
	self = [super init];
    if (self) {
		gradientLayer = [[CAGradientLayer alloc] init];
		
		[self setTitleShadowColor:[UIColor colorWithRed:30.0f/255.0f green:30.0f/255.0f blue:30.0f/255.0f alpha:0.5f] forState:UIControlStateNormal];
		self.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
		[[self layer] insertSublayer:gradientLayer atIndex:0];
		
		[[self layer] setCornerRadius:6.0f];
		[[self layer] setMasksToBounds:YES];
		[[self layer] setBorderWidth:1.0f];
		
		buttonStyle = GMButtonStyleGreen;
    }
    return self;
	
}

- (void) layoutSubviews {
	[super layoutSubviews];
	[gradientLayer setBounds:[self bounds]];
	[gradientLayer setPosition:
	 CGPointMake([self bounds].size.width/2,
				 [self bounds].size.height/2)];

}

- (void) setSelected:(BOOL)selected {
	[super setSelected:selected];
	[self setNeedsDisplay];
}

- (void) setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect {
	
	if (self.highlighted || self.selected) {
		if (buttonStyle == GMButtonStyleGreen) {
			[gradientLayer setColors:
			 [NSArray arrayWithObjects:
			  (id)[[UIColor colorWithRed:113.0f/255.0f green:178.0f/255.0f blue:0.0f/255.0f alpha:1.0f] CGColor], 
			  (id)[[UIColor colorWithRed:69.0f/255.0f green:107.0f/255.0f blue:5.0f/255.0f alpha:1.0f] CGColor], nil]];
			[[self layer] setBorderColor:[[UIColor colorWithRed:64.0f/255.0f green:92.0f/255.0f blue:12.0f/255.0f alpha:1.0f] CGColor]];

		} else {
			[gradientLayer setColors:
			 [NSArray arrayWithObjects:
			  (id)[[UIColor colorWithRed:255.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f] CGColor], 
			  (id)[[UIColor colorWithRed:120.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f] CGColor], nil]];
			[[self layer] setBorderColor:[[UIColor colorWithRed:92.0f/255.0f green:64.0f/255.0f blue:12.0f/255.0f alpha:1.0f] CGColor]];
			
		}

	} else {
		if (buttonStyle == GMButtonStyleGreen) {
			[gradientLayer setColors:
			 [NSArray arrayWithObjects:
			  (id)[[UIColor colorWithRed:133.0f/255.0f green:198.0f/255.0f blue:0.0f/255.0f alpha:1.0f] CGColor], 
			  (id)[[UIColor colorWithRed:79.0f/255.0f green:117.0f/255.0f blue:10.0f/255.0f alpha:1.0f] CGColor], nil]];
			[[self layer] setBorderColor:[[UIColor colorWithRed:64.0f/255.0f green:92.0f/255.0f blue:12.0f/255.0f alpha:1.0f] CGColor]];
		} else {
			[gradientLayer setColors:
			 [NSArray arrayWithObjects:
			  (id)[[UIColor colorWithRed:245.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f] CGColor], 
			  (id)[[UIColor colorWithRed:170.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f] CGColor], nil]];
			[[self layer] setBorderColor:[[UIColor colorWithRed:92.0f/255.0f green:64.0f/255.0f blue:12.0f/255.0f alpha:1.0f] CGColor]];
		}

	}
	
	[super drawRect:rect];
}

- (void) dealloc {
	[gradientLayer release];
	[super dealloc];
}

@end
