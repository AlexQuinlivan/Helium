//
//  HLMScrollView.m
//  Pods
//
//  Created by Alex Quinlivan on 11/05/15.
//
//

#import "HLMScrollView.h"
#import "HLMFrameLayoutManager.h"

@interface HLMScrollViewLayoutManager : HLMFrameLayoutManager
@property (nonatomic) CGRect keyboardFrame;
@end

@interface HLMScrollView ()
@property (nonatomic, weak) UIView* hlm_childView;
@end

@implementation HLMScrollView
@synthesize keyboardFrame = _keyboardFrame;

-(instancetype) initWithFrame:(CGRect) frame {
    if (self = [super initWithFrame:frame]) {
        self.hlm_layoutManager = [HLMScrollViewLayoutManager new];
    }
    return self;
}

-(void) didInflateChild:(UIView *) childView {
    if (self.hlm_childView && [self.subviews containsObject:self.hlm_childView]) {
        @throw [NSException exceptionWithName:@"HLMScrollViewException"
                                       reason:[NSString stringWithFormat:@"Reason: ScrollView's can only have"
                                               @" 1 child. Cause: trying to add a `%@` to a scrollView that "
                                               @"already has a `%@` child", NSStringFromClass(childView.class),
                                               NSStringFromClass(self.hlm_childView.class)]
                                     userInfo:nil];
    }
    self.hlm_childView = childView;
}

-(void) setKeyboardFrame:(CGRect) keyboardFrame {
    _keyboardFrame = keyboardFrame;
    ((HLMScrollViewLayoutManager *) self.hlm_layoutManager).keyboardFrame = keyboardFrame;
}

@end

@implementation HLMScrollViewLayoutManager

-(void) measure:(HLMScrollView *) view
      widthSpec:(HLMMeasureSpec) widthMeasureSpec
     heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    if (view.hlm_orientation == HLMLayoutOrientationVertical) {
        uint32_t heightSize = [HLMLayout measureSpecSize:heightMeasureSpec];
        heightSize += self.keyboardFrame.size.height;
        HLMMeasureSpecMode heightMode = [HLMLayout measureSpecMode:heightMeasureSpec];
        [super measure:view
             widthSpec:widthMeasureSpec
            heightSpec:[HLMLayout measureSpecWithSize:heightSize
                                                 mode:HLMMeasureSpecUnspecified]];
        switch (heightMode) {
            case HLMMeasureSpecUnspecified:
                heightSize = view.hlm_childView.hlm_measuredHeight;
                break;
            case HLMMeasureSpecAtMost:
                heightSize = MIN(heightSize, view.hlm_childView.hlm_measuredHeight);
                break;
            case HLMMeasureSpecExactly:
            default:
                break;
        }
        view.hlm_measuredHeight = heightSize;
    } else {
        uint32_t widthSize = [HLMLayout measureSpecSize:widthMeasureSpec];
        HLMMeasureSpecMode widthMode = [HLMLayout measureSpecMode:widthMeasureSpec];
        [super measure:view
             widthSpec:[HLMLayout measureSpecWithSize:widthSize
                                                 mode:HLMMeasureSpecUnspecified]
            heightSpec:heightMeasureSpec];
        switch (widthMode) {
            case HLMMeasureSpecUnspecified:
                widthSize = view.hlm_childView.hlm_measuredWidth;
                break;
            case HLMMeasureSpecAtMost:
                widthSize = MIN(widthSize, view.hlm_childView.hlm_measuredWidth);
                break;
            case HLMMeasureSpecExactly:
            default:
                break;
        }
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
    CGSize contentSize = view.hlm_childView.bounds.size;
    contentSize.height += self.keyboardFrame.size.height;
    view.contentSize = contentSize;
}

@end