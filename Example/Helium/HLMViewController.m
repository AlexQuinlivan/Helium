//
//  HLMViewController.m
//  Helium
//
//  Created by Alex Quinlivan on 03/13/2015.
//  Copyright (c) 2014 Alex Quinlivan. All rights reserved.
//

#import "HLMViewController.h"

@interface HLMViewController ()
@property (nonatomic, weak) UIView* example;
@end

@implementation HLMViewController
INJECT_VIEW(example, example)

-(NSString *) layoutResource {
    return @"@view/example_view";
}

@end
