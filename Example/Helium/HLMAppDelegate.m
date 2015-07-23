//
//  HLMAppDelegate.m
//  Helium
//
//  Created by CocoaPods on 03/13/2015.
//  Copyright (c) 2014 Alex Quinlivan. All rights reserved.
//

#import "HLMAppDelegate.h"
#import "HLMInflatedViewController.h"

@implementation HLMAppDelegate

-(BOOL)application:(UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [HLMInflatedViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
