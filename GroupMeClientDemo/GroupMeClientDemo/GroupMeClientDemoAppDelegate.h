//
//  GroupMeClientDemoAppDelegate.h
//  GroupMeClientDemo
//
//  Created by Jeremy Schoenherr on 4/8/11.
//  Copyright 2011 Mindless Dribble, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupMeClientDemoAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {

}

@property (nonatomic, retain) UIWindow *window;

@property (nonatomic, retain) UITabBarController *tabBarController;

@end
