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
@property (nonatomic, strong) NSArray* squares;
@end

@implementation HLMViewController
BIND_VIEW_OPTIONAL(blueView, blue_square)
BIND_VIEWS_4(squares, square_0, square_1, square_2, square_3)

-(NSString *) layoutResource {
    return @"@view/example_view";
}

-(void) viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
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
                         [self changeGravity];
                         for (UIView* square in self.squares) {
                             square.transform = CGAffineTransformRotate(square.transform, M_PI_2);
                         }
                         [weakSelf.view layoutSubviews];
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:1
                                               delay:1
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              weakSelf.blueView.hlm_layoutHeight = HLMLayoutParamMatch;
                                              weakSelf.blueView.hlm_layoutWeight = 1;
                                              [self changeGravity];
                                              for (UIView* square in self.squares) {
                                                  square.transform = CGAffineTransformRotate(square.transform, M_PI_2);
                                              }
                                              [weakSelf.view layoutSubviews];
                                          }
                                          completion:^(BOOL finished) {
                                              [weakSelf animate];
                                          }];
                     }];
}

-(void) changeGravity {
    for (UIView* square in self.squares) {
        HLMGravity horizontalGravity = square.hlm_layoutGravity & HLMGravityHorizontalMask;
        HLMGravity verticalGravity = square.hlm_layoutGravity & HLMGravityVerticalMask;
        HLMGravity newGravity = 0;
        if (horizontalGravity == HLMGravityLeft) {
            if (verticalGravity == HLMGravityBottom) {
                newGravity = HLMGravityRight | verticalGravity;
            } else {
                newGravity = horizontalGravity | HLMGravityBottom;
            }
        } else {
            if (verticalGravity == HLMGravityBottom) {
                newGravity = horizontalGravity | HLMGravityTop;
            } else {
                newGravity = HLMGravityLeft | verticalGravity;
            }
        }
        square.hlm_layoutGravity = newGravity;
    }
}

@end
