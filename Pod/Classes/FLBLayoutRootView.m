//
//  FLBLayoutRootView.m
//  Pods
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "FLBLayoutRootView.h"
#import "FLBLayout.h"

@implementation FLBLayoutRootView

-(void) layoutSubviews {
    [super layoutSubviews];
    NSArray* subviews = self.subviews;
    NSUInteger subviewCount = subviews.count;
    if (subviewCount > 1) {
        @throw [NSException exceptionWithName:@"FLBLayoutException"
                                       reason:@"FLBLayoutRootView has > 1 subviews. Expected 0..1"
                                     userInfo:nil];
    } else if (subviewCount) {
        UIView* subview = subviews[0];
        if (!subview.flb_layoutManager) {
            @throw [NSException exceptionWithName:@"FLBLayoutException"
                                           reason:[NSString stringWithFormat:@"View `(%@)` found in layout pass without layout manager", NSStringFromClass(subview.class)]
                                         userInfo:nil];
        }
        CGRect frame = self.frame;
        FLBMeasureSpec rootWidthMeasureSpec = [FLBLayout measureSpecWithSize:frame.size.width mode:FLBMeasureSpecExactly];
        FLBMeasureSpec rootHeightMeasureSpec = [FLBLayout measureSpecWithSize:frame.size.height mode:FLBMeasureSpecExactly];
        [subview.flb_layoutManager measure:subview
                                 widthSpec:rootWidthMeasureSpec
                                heightSpec:rootHeightMeasureSpec];
        [subview.flb_layoutManager layout:subview
                                     left:0
                                      top:0
                                    right:subview.measuredWidth
                                   bottom:subview.measuredHeight];
    }
}

@end
