//
//  HLMViewController.m
//  Helium
//
//  Created by Alex Quinlivan on 03/13/2015.
//  Copyright (c) 2014 Alex Quinlivan. All rights reserved.
//

#import "HLMViewController.h"
#import "HLMLayout.h"

@interface HLMViewController ()
@property (nonatomic, weak) UIView* blueView;
@end

@implementation HLMViewController
INJECT_VIEW(blueView, blue_square)

-(NSString *) layoutResource {
    return @"@view/example_view";
}

-(void) viewDidLoad {
    [super viewDidLoad];
    [self animate];
}

-(void) animate {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:1
                          delay:1
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         weakSelf.blueView.hlm_layoutHeight = 0;
                         weakSelf.blueView.hlm_layoutWeight = 0;
                         [weakSelf.view layoutSubviews];
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:1
                                               delay:1
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              weakSelf.blueView.hlm_layoutHeight = HLMLayoutParamMatch;
                                              weakSelf.blueView.hlm_layoutWeight = 1;
                                              [weakSelf.view layoutSubviews];
                                          }
                                          completion:^(BOOL finished) {
                                              [weakSelf animate];
                                          }];
                     }];
}

@end
