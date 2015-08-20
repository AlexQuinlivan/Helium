//
//  HLMLayoutStandaloneView.m
//  Pods
//
//  Created by Alex Quinlivan on 20/08/15.
//
//

#import "HLMLayoutStandaloneView.h"

@interface HLMLayoutStandaloneView ()
@property (nonatomic, getter=isInLayout) BOOL inLayout;
@end

@implementation HLMLayoutStandaloneView
@synthesize dirty = _dirty;

-(void) layoutSubviews {
    if (!self.isDirty) {
        return;
    }
#ifdef LAYOUT_PERF
    NSDate* layoutStarted = NSDate.date;
#endif
    UIView* contentView = self.contentView;
    if (contentView) {
        if (!contentView.hlm_layoutManager) {
            @throw [NSException exceptionWithName:@"HLMLayoutException"
                                           reason:[NSString stringWithFormat:@"View `(%@)` found in layout pass without layout manager", NSStringFromClass(contentView.class)]
                                         userInfo:nil];
        }
        self.inLayout = YES;
        CGRect  const frame = self.frame;
        CGFloat const width = frame.size.width;
        CGFloat const height = frame.size.height;
        CGFloat const childLayoutHeight = contentView.hlm_layoutHeight;
        HLMMeasureSpec contentWidthMeasureSpec = [HLMLayout measureSpecWithSize:width mode:HLMMeasureSpecExactly];
        HLMMeasureSpec contentHeightMeasureSpec;
        if (childLayoutHeight > 0) {
            contentHeightMeasureSpec = [HLMLayout measureSpecWithSize:childLayoutHeight mode:HLMMeasureSpecExactly];
        } else if (childLayoutHeight == HLMLayoutParamWrap) {
            contentHeightMeasureSpec = [HLMLayout measureSpecWithSize:0 mode:HLMMeasureSpecUnspecified];
        } else {
            contentHeightMeasureSpec = [HLMLayout measureSpecWithSize:height mode:HLMMeasureSpecExactly];
        }
        [contentView.hlm_layoutManager measure:contentView
                                     widthSpec:contentWidthMeasureSpec
                                    heightSpec:contentHeightMeasureSpec];
        [contentView.hlm_layoutManager layout:contentView
                                         left:0
                                          top:0
                                        right:contentView.hlm_measuredWidth
                                       bottom:contentView.hlm_measuredHeight];
        self.bounds = contentView.bounds;
        self.inLayout = NO;
        self.dirty = NO;
    }
#ifdef LAYOUT_PERF
    NSLog(@"[VERBOSE]: Layout took %.1fms", [NSDate.date timeIntervalSinceDate:layoutStarted] * 1000.f);
#endif
}

-(void) setFrame:(CGRect) frame {
    if (!CGRectEqualToRect(self.frame, frame)) {
        self.dirty = YES;
    }
    [super setFrame:frame];
}

-(void) setContentView:(UIView *) contentView {
    _contentView = contentView;
    [self addSubview:contentView];
    self.dirty = YES;
}

@end
