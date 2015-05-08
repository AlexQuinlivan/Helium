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
    NSArray* subviews = self.subviews;
    if (subviews.count) {
        UIView* subview = subviews[0];
        if (!subview.hlm_layoutManager) {
            @throw [NSException exceptionWithName:@"HLMLayoutException"
                                           reason:[NSString stringWithFormat:@"View `(%@)` found in layout pass without layout manager", NSStringFromClass(subview.class)]
                                         userInfo:nil];
        }
        CGRect frame = self.frame;
        CGFloat width = frame.size.width;
        CGFloat height = frame.size.height;
        BOOL overridesLayoutGuides = subview.hlm_overridesLayoutGuides;
        CGFloat topGuideLength = self.topLayoutGuide.length;
        CGFloat bottomGuideLength = self.bottomLayoutGuide.length;
        CGFloat const previousPaddingTop = subview.hlm_paddingTop;
        CGFloat const previousPaddingBottom = subview.hlm_paddingBottom;
        if (!overridesLayoutGuides) {
            subview.hlm_paddingTop += topGuideLength;
            subview.hlm_paddingBottom += bottomGuideLength;
        }
        HLMMeasureSpec rootWidthMeasureSpec = [HLMLayout measureSpecWithSize:width mode:HLMMeasureSpecExactly];
        HLMMeasureSpec rootHeightMeasureSpec = [HLMLayout measureSpecWithSize:height mode:HLMMeasureSpecExactly];
        [subview.hlm_layoutManager measure:subview
                                 widthSpec:rootWidthMeasureSpec
                                heightSpec:rootHeightMeasureSpec];
        [subview.hlm_layoutManager layout:subview
                                     left:0
                                      top:0
                                    right:subview.hlm_measuredWidth
                                   bottom:subview.hlm_measuredHeight];
        subview.hlm_paddingTop = previousPaddingTop;
        subview.hlm_paddingBottom = previousPaddingBottom;
    }
#ifdef LAYOUT_PERF
    NSLog(@"[VERBOSE]: Layout took %.1fms", [NSDate.date timeIntervalSinceDate:layoutStarted] * 100.f);
#endif
}

@end
