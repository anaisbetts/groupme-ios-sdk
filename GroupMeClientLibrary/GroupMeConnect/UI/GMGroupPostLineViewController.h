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


#import <UIKit/UIKit.h>
#import "GroupMeConnect.h"
#import <MessageUI/MessageUI.h>


@protocol GMGroupPostLineViewControllerDelegate;

@interface GMGroupPostLineViewController : UIViewController <UITextViewDelegate, GroupMeRequestDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate> {
	NSDictionary	*_group;
	UITextView		*_textView;
	UILabel			*_locationLabel;
	UIAlertView		*_alertView;
	NSNumber		*_latitude, *_longitude;
	NSString		*_locationName;
	id<GMGroupPostLineViewControllerDelegate>	_postLineDelegate;

}

@property (nonatomic, assign) id<GMGroupPostLineViewControllerDelegate>	postLineDelegate;

- (id) initWithGroup:(NSDictionary*)group;
- (void) setText:(NSString*)text;
- (void) setLocationName:(NSString*)locationName withLatitude:(NSNumber*)latitude andLongitude:(NSNumber*)longitude;


+ (void) showGroupPostLineInViewController:(UIViewController*)vc 
						withDefaultMessage:(NSString*)message
								  andGroup:(NSDictionary*)group
							   andDelegate:(id<GMGroupPostLineViewControllerDelegate>)plDelegate;

+ (void) showGroupPostLineInViewController:(UIViewController*)vc 
						withDefaultMessage:(NSString*)message
						   andLocationName:(NSString*)locationName
							   andLatitude:(NSNumber*)latitude
							  andLongitude:(NSNumber*)longitude
								  andGroup:(NSDictionary*)group
							   andDelegate:(id<GMGroupPostLineViewControllerDelegate>)plDelegate;

+ (void) showGroupPostLineInViewController:(UIViewController*)vc 
								  andGroup:(NSDictionary*)group
							   andDelegate:(id<GMGroupPostLineViewControllerDelegate>)plDelegate;


@end


@protocol GMGroupPostLineViewControllerDelegate <NSObject>

@optional

//Called when user picks a group
- (void)groupMePostedMessageToGroup:(NSDictionary*)group;

//Called if they cancel picking a group
- (void)groupMeDismissedGroupPostLine;

@end