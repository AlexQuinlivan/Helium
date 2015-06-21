//
//  HLMLayoutRootView.m
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "HLMLayoutRootView.h"
#import "HLMLayout.h"

@interface HLMLayoutRootView ()
@property (nonatomic, getter=isInLayout) BOOL inLayout;
@end

@implementation HLMLayoutRootView

-(void) setRootView:(UIView *) rootView {
    [self addSubview:rootView];
    _rootView = rootView;
}

-(void) layoutSubviews {
#ifdef LAYOUT_PERF
    NSDate* layoutStarted = NSDate.date;
#endif
    UIView* rootView = self.rootView;
    if (rootView) {
        if (!rootView.hlm_layoutManager) {
            @throw [NSException exceptionWithName:@"HLMLayoutException"
                                           reason:[NSString stringWithFormat:@"View `(%@)` found in layout pass without layout manager", NSStringFromClass(rootView.class)]
                                         userInfo:nil];
        }
        self.inLayout = YES;
        CGRect frame = self.frame;
        CGFloat width = frame.size.width;
        CGFloat height = frame.size.height;
        BOOL overridesLayoutGuides = rootView.hlm_overridesLayoutGuides;
        CGFloat topGuideLength = self.topLayoutGuide.length;
        CGFloat bottomGuideLength = self.bottomLayoutGuide.length;
        CGFloat const previousPaddingTop = rootView.hlm_paddingTop;
        CGFloat const previousPaddingBottom = rootView.hlm_paddingBottom;
        if (!overridesLayoutGuides) {
            rootView.hlm_paddingTop += topGuideLength;
            rootView.hlm_paddingBottom += bottomGuideLength;
        }
        HLMMeasureSpec rootWidthMeasureSpec = [HLMLayout measureSpecWithSize:width mode:HLMMeasureSpecExactly];
        HLMMeasureSpec rootHeightMeasureSpec = [HLMLayout measureSpecWithSize:height mode:HLMMeasureSpecExactly];
        [rootView.hlm_layoutManager measure:rootView
                                  widthSpec:rootWidthMeasureSpec
                                 heightSpec:rootHeightMeasureSpec];
        [rootView.hlm_layoutManager layout:rootView
                                      left:0
                                       top:0
                                     right:rootView.hlm_measuredWidth
                                    bottom:rootView.hlm_measuredHeight];
        rootView.hlm_paddingTop = previousPaddingTop;
        rootView.hlm_paddingBottom = previousPaddingBottom;
        self.inLayout = NO;
    }
#ifdef LAYOUT_PERF
    NSLog(@"[VERBOSE]: Layout took %.1fms", [NSDate.date timeIntervalSinceDate:layoutStarted] * 1000.f);
#endif
}

@end
