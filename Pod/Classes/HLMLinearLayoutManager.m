//
//  HLMLinearLayoutManager.m
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "HLMLinearLayoutManager.h"

typedef NS_ENUM(int32_t, HLMLinearLayoutIndex) {
    HLMLinearLayoutIndexCenterVertical,
    HLMLinearLayoutIndexTop,
    HLMLinearLayoutIndexBottom,
    HLMLinearLayoutIndexFill,
};

@interface HLMLinearLayoutManager ()
@property (nonatomic) NSInteger baselineChildTop;
@property (nonatomic) int32_t totalLength;
@end

// todo: child baseline alignment

@implementation HLMLinearLayoutManager {
    int32_t maxAscent[4];
    int32_t maxDescent[4];
}

-(void) measure:(UIView *) view
      widthSpec:(HLMMeasureSpec) widthMeasureSpec
     heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    if (view.hlm_orientation == HLMLayoutOrientationVertical) {
        [self measureVertical:view
                    widthSpec:widthMeasureSpec
                   heightSpec:heightMeasureSpec];
    } else {
        [self measureHorizontal:view
                      widthSpec:widthMeasureSpec
                     heightSpec:heightMeasureSpec];
    }
}

-(void) measureVertical:(UIView *) view
              widthSpec:(HLMMeasureSpec) widthMeasureSpec
             heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    self.totalLength = 0;
    int32_t maxWidth = 0;
    int32_t alternativeMaxWidth = 0;
    int32_t weightedMaxWidth = 0;
    BOOL allFillParent = YES;
    CGFloat totalWeight = 0;
    HLMMeasureSpecMode widthMode = [HLMLayout measureSpecMode:widthMeasureSpec];
    HLMMeasureSpecMode heightMode = [HLMLayout measureSpecMode:heightMeasureSpec];
    BOOL matchWidth = NO;
    NSInteger baselineChildIndex = view.hlm_baselineAlignedChildIndex;
    NSArray* subviews = view.subviews;
    for (int i = 0; i < subviews.count; i++) {
        UIView* child = subviews[i];
        if (child.isHidden) {
            continue;
        }
        CGFloat childWeight = child.layoutWeight;
        CGFloat childLayoutHeight = child.layoutHeight;
        CGFloat childLayoutWidth = child.layoutWidth;
        totalWeight += childWeight;
        if (heightMode == HLMMeasureSpecExactly && childLayoutHeight == 0 && childWeight > 0) {
            self.totalLength += child.marginTop + child.marginBottom;
        } else {
            int32_t oldHeight = INT32_MIN;
            if (childLayoutHeight == 0 && childWeight > 0) {
                oldHeight = 0;
                childLayoutHeight = HLMLayoutParamWrap;
                child.layoutHeight = childLayoutHeight;
            }
            [HLMLayout measureChildWithMargins:child
                                      ofParent:view
                               parentWidthSpec:widthMeasureSpec
                                     widthUsed:0
                              parentHeightSpec:heightMeasureSpec
                                    heightUsed:totalWeight == 0 ? self.totalLength : 0];
            if (oldHeight != INT32_MIN) {
                childLayoutHeight = oldHeight;
                child.layoutHeight = childLayoutHeight;
            }
            self.totalLength += child.measuredHeight + child.marginTop + child.marginBottom;
        }
        if ((baselineChildIndex >= 0) && (baselineChildIndex == i + 1)) {
            self.baselineChildTop = self.totalLength;
        }
        if (i < baselineChildIndex && childWeight > 0) {
            @throw [NSException exceptionWithName:@"HLMLinearLayoutManagerMeasureException"
                                           reason:
                    @"A child of LinearLayout with index "
                    @"less than mBaselineAlignedChildIndex has weight > 0, which "
                    @"won't work.  Either remove the weight, or don't set "
                    @"mBaselineAlignedChildIndex."
                                         userInfo:nil];
        }
        BOOL matchWidthLocally = NO;
        if (widthMode != HLMMeasureSpecExactly && childLayoutWidth == HLMLayoutParamMatch) {
            matchWidth = true;
            matchWidthLocally = true;
        }
        CGFloat margin = child.marginLeft + child.marginRight;
        int32_t measuredWidth = child.measuredWidth + margin;
        maxWidth = MAX(maxWidth, measuredWidth);
        allFillParent = allFillParent && childLayoutWidth == HLMLayoutParamMatch;
        if (childWeight > 0) {
            weightedMaxWidth = MAX(weightedMaxWidth,
                                        matchWidthLocally ? margin : measuredWidth);
        } else {
            alternativeMaxWidth = MAX(alternativeMaxWidth,
                                           matchWidthLocally ? margin : measuredWidth);
        }
    }
    self.totalLength += view.paddingTop + view.paddingBottom;
    int32_t heightSize = self.totalLength;
    heightSize = MAX(heightSize, view.minHeight);
    heightSize = [HLMLayout resolveSize:heightSize spec:heightMeasureSpec];
    int32_t delta = heightSize - self.totalLength;
    if (delta != 0 && totalWeight > 0.0f) {
        CGFloat weightSum = view.hlm_weightSum > 0.0f ?: totalWeight;
        self.totalLength = 0;
        for (int i = 0; i < subviews.count; i++) {
            UIView* child = subviews[i];
            if (child.isHidden) {
                continue;
            }
            CGFloat childExtra = child.layoutWeight;
            CGFloat childLayoutHeight = child.layoutHeight;
            CGFloat childLayoutWidth = child.layoutWidth;
            if (childExtra > 0) {
                int32_t share = (int32_t) (childExtra * delta / weightSum);
                weightSum -= childExtra;
                delta -= share;
                HLMMeasureSpec childWidthMeasureSpec = [HLMLayout childMeasureSpec:widthMeasureSpec
                                                                           padding:child.paddingLeft + child.paddingRight + child.marginLeft + child.marginRight
                                                                         dimension:childLayoutWidth];
                if ((childLayoutHeight != 0) || (heightMode != HLMMeasureSpecExactly)) {
                    int childHeight = child.measuredHeight + share;
                    if (childHeight < 0) {
                        childHeight = 0;
                    }
                    [HLMLayout measureView:child
                                 widthSpec:childWidthMeasureSpec
                                heightSpec:[HLMLayout measureSpecWithSize:childHeight mode:HLMMeasureSpecExactly]];
                } else {
                    [HLMLayout measureView:child
                                 widthSpec:childWidthMeasureSpec
                                heightSpec:[HLMLayout measureSpecWithSize:(share > 0) ? share : 0 mode:HLMMeasureSpecExactly]];
                }
            }
            
            CGFloat margin = child.marginLeft + child.marginRight;
            int32_t measuredWidth = child.measuredWidth + margin;
            maxWidth = MAX(maxWidth, measuredWidth);
            BOOL matchWidthLocally = widthMode != HLMMeasureSpecExactly &&
            childLayoutWidth == HLMLayoutParamMatch;
            child.layoutWidth = childLayoutWidth;
            alternativeMaxWidth = MAX(alternativeMaxWidth, matchWidthLocally ? margin : measuredWidth);
            allFillParent = allFillParent && childLayoutWidth == HLMLayoutParamMatch;
            self.totalLength += child.measuredHeight + child.marginTop + child.marginBottom;
        }
        self.totalLength += view.paddingTop + view.paddingBottom;
    } else {
        alternativeMaxWidth = MAX(alternativeMaxWidth, weightedMaxWidth);
    }
    if (!allFillParent && widthMode != HLMMeasureSpecExactly) {
        maxWidth = alternativeMaxWidth;
    }
    maxWidth += view.paddingLeft + view.paddingRight;
    maxWidth = MAX(maxWidth, view.minWidth);
    view.measuredWidth = [HLMLayout resolveSize:maxWidth spec:widthMeasureSpec];
    view.measuredHeight = heightSize;
    if (matchWidth) {
        [self forceUniformWidth:view
                          count:subviews.count
              heightMeasureSpec:heightMeasureSpec];
    }
}

-(void) measureHorizontal:(UIView *) view
                widthSpec:(HLMMeasureSpec) widthMeasureSpec
               heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    self.totalLength = 0;
    int32_t maxHeight = 0;
    int32_t alternativeMaxHeight = 0;
    int32_t weightedMaxHeight = 0;
    BOOL allFillParent = YES;
    CGFloat totalWeight = 0;
    HLMMeasureSpecMode widthMode = [HLMLayout measureSpecMode:widthMeasureSpec];
    HLMMeasureSpecMode heightMode = [HLMLayout measureSpecMode:heightMeasureSpec];
    BOOL matchHeight = NO;
    memset(maxAscent, -1, sizeof(maxAscent));
    memset(maxDescent, -1, sizeof(maxDescent));
    BOOL baselineAligned = view.hlm_baselineAligned;
    NSArray* subviews = view.subviews;
    for (int i = 0; i < subviews.count; i++) {
        UIView* child = subviews[i];
        if (child.isHidden) {
            continue;
        }
        CGFloat childWeight = child.layoutWeight;
        CGFloat childLayoutHeight = child.layoutHeight;
        CGFloat childLayoutWidth = child.layoutWidth;
        totalWeight += childWeight;
        if (widthMode == HLMMeasureSpecExactly && childLayoutWidth == 0 && childWeight > 0) {
            self.totalLength += child.marginLeft + child.marginRight;
            if (baselineAligned) {
                HLMMeasureSpec freeSpec = [HLMLayout measureSpecWithSize:0 mode:HLMMeasureSpecUnspecified];
                [HLMLayout measureView:child
                             widthSpec:freeSpec
                            heightSpec:freeSpec];
            }
        } else {
            int32_t oldWidth = INT32_MIN;
            if (childLayoutWidth == 0 && childWeight > 0) {
                oldWidth = 0;
                childLayoutWidth = HLMLayoutParamWrap;
                child.layoutWidth = childLayoutWidth;
            }
            [HLMLayout measureChildWithMargins:child
                                      ofParent:view
                               parentWidthSpec:widthMeasureSpec
                                     widthUsed:(totalWeight == 0) ? self.totalLength : 0
                              parentHeightSpec:heightMeasureSpec
                                    heightUsed:0];
            if (oldWidth != INT32_MIN) {
                childLayoutWidth = oldWidth;
                child.layoutWidth = childLayoutWidth;
            }
            self.totalLength += child.measuredWidth + child.marginLeft + child.marginRight;
        }
        BOOL matchHeightLocally = NO;
        if (heightMode != HLMMeasureSpecExactly && childLayoutHeight == HLMLayoutParamMatch) {
            matchHeight = YES;
            matchHeightLocally = YES;
        }
        CGFloat margin = child.marginTop + child.marginBottom;
        int32_t childHeight = child.measuredHeight + margin;
        if (baselineAligned) {
            int32_t childBaseline = -1; // todo: child baseline
            if (childBaseline != -1) {
                HLMGravity gravity = ((child.layoutGravity < 0) ? view.hlm_gravity : child.layoutGravity) & HLMGravityVerticalMask;
                int32_t index = ((gravity >> HLMGravityAxisYShift) & ~HLMGravityAxisSpecified) >> 1;
                maxAscent[index] = MAX(maxAscent[index], childBaseline);
                maxDescent[index] = MAX(maxDescent[index], childHeight - childBaseline);
            }
        }
        maxHeight = MAX(maxHeight, childHeight);
        allFillParent = allFillParent && childLayoutHeight == HLMLayoutParamMatch;
        if (childWeight > 0) {
            weightedMaxHeight = MAX(weightedMaxHeight,
                                    matchHeightLocally ? margin : childHeight);
        } else {
            alternativeMaxHeight = MAX(alternativeMaxHeight,
                                       matchHeightLocally ? margin : childHeight);
        }
    }
    if (maxAscent[HLMLinearLayoutIndexTop] != -1 ||
        maxAscent[HLMLinearLayoutIndexCenterVertical] != -1 ||
        maxAscent[HLMLinearLayoutIndexBottom] != -1 ||
        maxAscent[HLMLinearLayoutIndexFill] != -1) {
        int32_t ascent = MAX(maxAscent[HLMLinearLayoutIndexFill],
                             MAX(maxAscent[HLMLinearLayoutIndexCenterVertical],
                                 MAX(maxAscent[HLMLinearLayoutIndexTop], maxAscent[HLMLinearLayoutIndexBottom])));
        int32_t descent = MAX(maxDescent[HLMLinearLayoutIndexFill],
                              MAX(maxDescent[HLMLinearLayoutIndexCenterVertical],
                                  MAX(maxDescent[HLMLinearLayoutIndexTop], maxDescent[HLMLinearLayoutIndexBottom])));
        maxHeight = MAX(maxHeight, ascent + descent);
    }
    self.totalLength += view.paddingLeft + view.paddingRight;
    int32_t widthSize = self.totalLength;
    widthSize = MAX(widthSize, view.minWidth);
    widthSize = [HLMLayout resolveSize:widthSize spec:widthMeasureSpec];
    int32_t delta = widthSize - self.totalLength;
    if (delta != 0 && totalWeight > 0.0f) {
        CGFloat weightSum = view.hlm_weightSum > 0.0f ?: totalWeight;
        memset(maxAscent, -1, sizeof(maxAscent));
        memset(maxDescent, -1, sizeof(maxDescent));
        maxHeight = -1;
        self.totalLength = 0;
        for (int i = 0; i < subviews.count; i++) {
            UIView* child = subviews[i];
            if (child.isHidden) {
                continue;
            }
            CGFloat childExtra = child.layoutWeight;
            CGFloat childLayoutHeight = child.layoutHeight;
            CGFloat childLayoutWidth = child.layoutWidth;
            if (childExtra > 0) {
                int32_t share = (int32_t) (childExtra * delta / weightSum);
                weightSum -= childExtra;
                delta -= share;
                HLMMeasureSpec childHeightMeasureSpec = [HLMLayout childMeasureSpec:heightMeasureSpec
                                                                            padding:view.paddingTop + view.paddingBottom + child.marginTop + child.marginBottom
                                                                          dimension:childLayoutHeight];
                if ((childLayoutWidth != 0) || (widthMode != HLMMeasureSpecExactly)) {
                    int childWidth = child.measuredWidth + share;
                    if (childWidth < 0) {
                        childWidth = 0;
                    }
                    [HLMLayout measureView:child
                                 widthSpec:[HLMLayout measureSpecWithSize:childWidth mode:HLMMeasureSpecExactly]
                                heightSpec:childHeightMeasureSpec];
                } else {
                    [HLMLayout measureView:child
                                 widthSpec:[HLMLayout measureSpecWithSize:(share > 0) ? share : 0 mode:HLMMeasureSpecExactly]
                                heightSpec:childHeightMeasureSpec];
                }
            }
            self.totalLength += child.measuredWidth + child.marginLeft + child.marginRight;
            BOOL matchHeightLocally = heightMode != HLMMeasureSpecExactly && childLayoutHeight == HLMLayoutParamMatch;
            CGFloat margin = child.marginTop + child.marginBottom;
            int32_t childHeight = child.measuredHeight + margin;
            maxHeight = MAX(maxHeight, childHeight);
            alternativeMaxHeight = MAX(alternativeMaxHeight,
                                       matchHeightLocally ? margin : childHeight);
            allFillParent = allFillParent && childLayoutHeight == HLMMeasureSpecExactly;
            if (baselineAligned) {
                int32_t childBaseline = -1; // todo: child baseline
                if (childBaseline != -1) {
                    HLMGravity gravity = ((child.layoutGravity < 0) ? view.hlm_gravity : child.layoutGravity) & HLMGravityVerticalMask;
                    int32_t index = ((gravity >> HLMGravityAxisYShift) & ~HLMGravityAxisSpecified) >> 1;
                    maxAscent[index] = MAX(maxAscent[index], childBaseline);
                    maxDescent[index] = MAX(maxDescent[index], childHeight - childBaseline);
                }
            }
        }
        self.totalLength += view.paddingLeft + view.paddingRight;
        if (maxAscent[HLMLinearLayoutIndexTop] != -1 ||
            maxAscent[HLMLinearLayoutIndexCenterVertical] != -1 ||
            maxAscent[HLMLinearLayoutIndexBottom] != -1 ||
            maxAscent[HLMLinearLayoutIndexFill] != -1) {
            int32_t ascent = MAX(maxAscent[HLMLinearLayoutIndexFill],
                                 MAX(maxAscent[HLMLinearLayoutIndexCenterVertical],
                                     MAX(maxAscent[HLMLinearLayoutIndexTop], maxAscent[HLMLinearLayoutIndexBottom])));
            int32_t descent = MAX(maxDescent[HLMLinearLayoutIndexFill],
                                  MAX(maxDescent[HLMLinearLayoutIndexCenterVertical],
                                      MAX(maxDescent[HLMLinearLayoutIndexTop], maxDescent[HLMLinearLayoutIndexBottom])));
            maxHeight = MAX(maxHeight, ascent + descent);
        }
    } else {
        alternativeMaxHeight = MAX(alternativeMaxHeight, weightedMaxHeight);
    }
    if (!allFillParent && heightMode != HLMMeasureSpecExactly) {
        maxHeight = alternativeMaxHeight;
    }
    maxHeight += view.paddingTop + view.paddingBottom;
    maxHeight = MAX(maxHeight, view.minHeight);
    view.measuredWidth = widthSize;
    view.measuredHeight = [HLMLayout resolveSize:maxHeight spec:heightMeasureSpec];
    if (matchHeight) {
        [self forceUniformHeight:view
                           count:subviews.count
                widthMeasureSpec:widthMeasureSpec];
    }
}

-(void) layout:(UIView *) view
          left:(NSInteger) left
           top:(NSInteger) top
         right:(NSInteger) right
        bottom:(NSInteger) bottom {
    view.frame = CGRectMake(left, top, right - left, bottom - top);
    if (view.hlm_orientation == HLMLayoutOrientationVertical) {
        [self layoutVertical:view
                        left:left
                         top:top
                       right:right
                      bottom:bottom];
    } else {
        [self layoutHorizontal:view
                          left:left
                           top:top
                         right:right
                        bottom:bottom];
    }
}

-(void) layoutVertical:(UIView *) view
                  left:(NSInteger) left
                   top:(NSInteger) top
                 right:(NSInteger) right
                bottom:(NSInteger) bottom {
    UIEdgeInsets padding = view.hlm_padding;
    int32_t paddingLeft = padding.left;
    int32_t paddingRight = padding.right;
    int32_t paddingTop = padding.top;
    int32_t childTop = paddingTop;
    int32_t childLeft = paddingLeft;
    int32_t width = (int32_t) (right - left);
    int32_t childRight = width - paddingRight;
    int32_t childSpace = width - paddingLeft - paddingRight;
    HLMGravity gravity = view.layoutGravity;
    HLMGravity minorGravity = gravity & HLMGravityHorizontalMask;
    HLMGravity majorGravity = gravity & HLMGravityVerticalMask;
    if (majorGravity != HLMGravityTop) {
        switch (majorGravity) {
            case HLMGravityBottom:
                childTop = (int32_t) (bottom - top + paddingTop - self.totalLength);
                break;
            case HLMGravityCenterVertical:
                childTop += ((bottom - top)  - self.totalLength) / 2;
                break;
            default:
                break;
        }
    }
    NSArray* subviews = view.subviews;
    for (int i = 0; i < subviews.count; i++) {
        UIView* child = subviews[i];
        if (child.isHidden) {
            continue;
        }
        int32_t childWidth = child.measuredWidth;
        int32_t childHeight = child.measuredHeight;
        HLMGravity gravity = child.layoutGravity;
        if (gravity < 0) {
            gravity = minorGravity;
        }
        switch (gravity & HLMGravityHorizontalMask) {
            case HLMGravityLeft:
                childLeft = paddingLeft + child.marginLeft;
                break;
            case HLMGravityCenterHorizontal:
                childLeft = paddingLeft + ((childSpace - childWidth) / 2) + child.marginLeft - child.marginRight;
                break;
            case HLMGravityRight:
                childLeft = childRight - childWidth - child.marginRight;
                break;
            default:
                break;
        }
        childTop += child.marginTop;
        [HLMLayout setChild:child frame:CGRectMake(childLeft, childTop, childWidth, childHeight)];
        childTop += childHeight + child.marginBottom;
    }
}

-(void) layoutHorizontal:(UIView *) view
                    left:(NSInteger) left
                     top:(NSInteger) top
                   right:(NSInteger) right
                  bottom:(NSInteger) bottom {
    UIEdgeInsets padding = view.hlm_padding;
    int32_t paddingLeft = padding.left;
    int32_t paddingBottom = padding.bottom;
    int32_t paddingTop = padding.top;
    int32_t childTop = paddingTop;
    int32_t childLeft = paddingLeft;
    int32_t height = (int32_t) (bottom - top);
    int32_t childBottom = height - paddingBottom;
    int32_t childSpace = height - paddingTop - paddingBottom;
    HLMGravity gravity = view.layoutGravity;
    HLMGravity majorGravity = gravity & HLMGravityHorizontalMask;
    HLMGravity minorGravity = gravity & HLMGravityVerticalMask;
    BOOL baselineAligned = view.hlm_baselineAligned;
    if (majorGravity != HLMGravityLeft) {
        switch (majorGravity) {
            case HLMGravityRight:
                childLeft = (int32_t) (right - left + paddingLeft - self.totalLength);
                break;
            case HLMGravityCenterHorizontal:
                childLeft += ((right - left) - self.totalLength) / 2;
                break;
            default:
                break;
        }
    }
    NSArray* subviews = view.subviews;
    for (int i = 0; i < subviews.count; i++) {
        UIView* child = subviews[i];
        if (child.isHidden) {
            continue;
        }
        int32_t childWidth = child.measuredWidth;
        int32_t childHeight = child.measuredHeight;
        HLMGravity gravity = child.layoutGravity;
        int32_t childBaseline = -1;
        if (baselineAligned && child.layoutHeight != HLMLayoutParamMatch) {
            childBaseline = -1; // todo: child baseline
        }
        if (gravity < 0) {
            gravity = minorGravity;
        }
        switch (gravity & HLMGravityVerticalMask) {
            case HLMGravityTop: {
                childTop = paddingTop + child.marginTop;
                if (childBaseline != -1) {
                    childTop += maxAscent[HLMLinearLayoutIndexTop] - childBaseline;
                }
                break;
            }
            case HLMGravityCenterVertical:
                childTop = paddingTop + ((childSpace - childHeight) / 2) + child.marginTop - child.marginBottom;
                break;
            case HLMGravityBottom: {
                childTop = childBottom - childHeight - child.marginBottom;
                if (childBaseline != -1) {
                    int32_t descent = child.measuredHeight - childBaseline;
                    childTop -= (maxDescent[HLMLinearLayoutIndexBottom] - descent);
                }
                break;
            }
            default:
                break;
        }
        childLeft += child.marginLeft;
        [HLMLayout setChild:child frame:CGRectMake(childLeft, childTop, childWidth, childHeight)];
        childLeft += childWidth + child.marginRight;
    }
}

-(void) forceUniformWidth:(UIView *) view
                    count:(NSUInteger) count
        heightMeasureSpec:(HLMMeasureSpec) heightMeasureSpec {
    HLMMeasureSpec uniformMeasureSpec = [HLMLayout measureSpecWithSize:view.measuredWidth mode:HLMMeasureSpecExactly];
    NSArray* subviews = view.subviews;
    for (int i = 0; i < count; i++) {
        UIView* child = subviews[i];
        if (!child.isHidden) {
            if (child.layoutWidth == HLMLayoutParamMatch) {
                int32_t oldHeight = child.layoutHeight;
                child.layoutHeight = child.measuredHeight;
                [HLMLayout measureChildWithMargins:child
                                          ofParent:view
                                   parentWidthSpec:uniformMeasureSpec
                                         widthUsed:0
                                  parentHeightSpec:heightMeasureSpec
                                        heightUsed:0];
                child.layoutHeight = oldHeight;
            }
        }
    }
}

-(void) forceUniformHeight:(UIView *) view
                     count:(NSUInteger) count
          widthMeasureSpec:(HLMMeasureSpec) widthMeasureSpec {
    HLMMeasureSpec uniformMeasureSpec = [HLMLayout measureSpecWithSize:view.measuredHeight mode:HLMMeasureSpecExactly];
    NSArray* subviews = view.subviews;
    for (int i = 0; i < count; i++) {
        UIView* child = subviews[i];
        if (!child.isHidden) {
            if (child.layoutHeight == HLMLayoutParamMatch) {
                int32_t oldWidth = child.layoutWidth;
                child.layoutWidth = child.measuredWidth;
                [HLMLayout measureChildWithMargins:child
                                          ofParent:view
                                   parentWidthSpec:widthMeasureSpec
                                         widthUsed:0
                                  parentHeightSpec:uniformMeasureSpec
                                        heightUsed:0];
                child.layoutWidth = oldWidth;
            }
        }
    }
}

@end
