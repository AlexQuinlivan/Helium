//
//  FLBViewController.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 03/13/2015.
//  Copyright (c) 2014 Alex Quinlivan. All rights reserved.
//

#import "FLBViewController.h"

@interface FLBViewController ()
@property (nonatomic, weak) UIView* example;
@end

@implementation FLBViewController
INJECT_VIEW(example, example)

-(NSString *) layoutResource {
    return @"@view/example_view";
}

@end
