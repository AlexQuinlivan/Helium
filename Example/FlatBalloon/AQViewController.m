//
//  AQViewController.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 03/13/2015.
//  Copyright (c) 2014 Alex Quinlivan. All rights reserved.
//

#import "AQViewController.h"

@interface AQViewController ()
@property (nonatomic, weak) UIView* example;
@end

@implementation AQViewController
INJECT_VIEW(example, example)

-(NSString *) layoutResource {
    return @"@view/example_view";
}

@end
