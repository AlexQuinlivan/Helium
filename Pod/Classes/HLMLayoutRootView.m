//
//  HLMLayoutRootView.m
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "HLMLayoutRootView.h"
#import "HLMLayout.h"

@implementation HLMLayoutRootView

-(void) layoutSubviews {
#ifdef LAYOUT_PERF
    NSDate* layoutStarted = NSDate.date;
#endif
    [super layoutSubviews];
    NSArray* subviews = self.subviews;
    NSUInteger subviewCount = subviews.count;
    if (subviewCount > 1) {
        @throw [NSException exceptionWithName:@"HLMLayoutException"
                                       reason:@"HLMLayoutRootView has > 1 subviews. Expected 0..1"
                                     userInfo:nil];
    } else if (subviewCount) {
        UIView* subview = subviews[0];
        if (!subview.hlm_layoutManager) {
            @throw [NSException exceptionWithName:@"HLMLayoutException"
                                           reason:[NSString stringWithFormat:@"View `(%@)` found in layout pass without layout manager", NSStringFromClass(subview.class)]
                                         userInfo:nil];
        }
        CGRect frame = self.frame;
        HLMMeasureSpec rootWidthMeasureSpec = [HLMLayout measureSpecWithSize:frame.size.width mode:HLMMeasureSpecExactly];
        HLMMeasureSpec rootHeightMeasureSpec = [HLMLayout measureSpecWithSize:frame.size.height mode:HLMMeasureSpecExactly];
        [subview.hlm_layoutManager measure:subview
                                 widthSpec:rootWidthMeasureSpec
                                heightSpec:rootHeightMeasureSpec];
        [subview.hlm_layoutManager layout:subview
                                     left:0
                                      top:0
                                    right:subview.hlm_measuredWidth
                                   bottom:subview.hlm_measuredHeight];
    }
#ifdef LAYOUT_PERF
    NSLog(@"[VERBOSE]: Layout took %.3fms", [NSDate.date timeIntervalSinceDate:layoutStarted]);
#endif
}

@end
