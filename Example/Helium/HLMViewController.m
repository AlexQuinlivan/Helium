//
//  HLMViewController.m
//  Helium
//
//  Created by Alex Quinlivan on 03/13/2015.
//  Copyright (c) 2014 Alex Quinlivan. All rights reserved.
//

#import "HLMViewController.h"
#import "HLMResources.h"
#import "HLMLayout.h"

@interface HLMViewController ()
@property (nonatomic, weak) UIView* blueView;
@property (nonatomic, weak) UIView* topSquare;
@property (nonatomic, weak) UIView* hello;
@property (nonatomic, strong) NSArray* squares;
@end

@implementation HLMViewController
BIND_VIEW_OPTIONAL(blueView, blue_square)
BIND_VIEW(topSquare, top_square)
BIND_VIEW(hello, red_square)
BIND_VIEWS_4(squares, square_0, square_1, square_2, square_3)

-(NSString *) layoutResource {
    return @"@view/example_view";
}

-(void) viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    [self.view layoutSubviews];
    NSLog(@"%lu", self.topSquare.hlm_id);
    NSLog(@"%lu", self.hello.hlm_layoutToRightOf);
    NSLog(@"%@", self.squares);
}

@end
