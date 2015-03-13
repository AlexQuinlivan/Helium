//
//  FLBAppDelegate.m
//  FlatBalloon
//
//  Created by CocoaPods on 03/13/2015.
//  Copyright (c) 2014 Alex Quinlivan. All rights reserved.
//

#import "FLBAppDelegate.h"
#import "FLBViewController.h"

@implementation FLBAppDelegate

-(BOOL)application:(UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [FLBViewController new];
    return YES;
}

@end
