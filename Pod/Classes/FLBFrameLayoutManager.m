//
//  FLBFrameLayoutManager.m
//  Pods
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "FLBFrameLayoutManager.h"

@implementation FLBFrameLayoutManager

-(void) flb_measure:(UIView *) view {
    CGRect frame = CGRectMake(0, 0, 0, 0);
    if (view.layoutHeight == FLBLayoutRuleFill) {
        frame.size.height = view.superview.bounds.size.height;
    } else if (view.layoutHeight == FLBLayoutRuleWrap) {
        //TOOD:
    } else {
        frame.size.height = view.layoutHeight;
    }
    if (view.layoutWidth == FLBLayoutRuleFill) {
        frame.size.width = view.superview.bounds.size.height;
    } else if (view.layoutWidth == FLBLayoutRuleWrap) {
        //TODO:
    } else {
        frame.size.width = view.layoutWidth;
    }
    view.frame = frame;
    for (UIView* subview in view.subviews) {
        [subview.flb_layoutManager flb_measure:subview];
        [subview.flb_layoutManager flb_layout:subview];
    }
}

-(void) flb_layout:(UIView *) view {
    
}

@end
