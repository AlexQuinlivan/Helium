//
//  HLMScrollView.m
//  Pods
//
//  Created by Alex Quinlivan on 11/05/15.
//
//

#import "HLMScrollView.h"
#import "HLMFrameLayoutManager.h"

@interface HLMScrollViewLayoutManager : HLMFrameLayoutManager @end

@interface HLMScrollView ()
@property (nonatomic, weak) UIView* hlm_childView;
@end

@implementation HLMScrollView

-(instancetype) initWithFrame:(CGRect) frame {
    if (self = [super initWithFrame:frame]) {
        self.hlm_layoutManager = [HLMScrollViewLayoutManager new];
    }
    return self;
}

-(void) didInflate {
    self.hlm_childView = self.subviews.lastObject;
}

@end

@implementation HLMScrollViewLayoutManager

-(void) measure:(HLMScrollView *) view
      widthSpec:(HLMMeasureSpec) widthMeasureSpec
     heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    if (view.hlm_orientation == HLMLayoutOrientationVertical) {
        uint32_t heightSize = [HLMLayout measureSpecSize:heightMeasureSpec];
        [super measure:view
             widthSpec:widthMeasureSpec
            heightSpec:[HLMLayout measureSpecWithSize:heightSize
                                                 mode:HLMMeasureSpecUnspecified]];
        view.hlm_measuredHeight = heightSize;
    } else {
        uint32_t widthSize = [HLMLayout measureSpecSize:widthMeasureSpec];
        [super measure:view
             widthSpec:[HLMLayout measureSpecWithSize:widthSize
                                                 mode:HLMMeasureSpecUnspecified]
            heightSpec:heightMeasureSpec];
        view.hlm_measuredWidth = widthSize;
    }
    // @todo: implement a viewport filling scrollview
}

-(void) layout:(HLMScrollView *) view
          left:(NSInteger) left
           top:(NSInteger) top
         right:(NSInteger) right
        bottom:(NSInteger) bottom {
    [super layout:view
             left:left
              top:top
            right:right
           bottom:bottom];
    view.contentSize = view.hlm_childView.bounds.size;
}

@end