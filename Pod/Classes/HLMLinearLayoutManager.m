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
    float totalWeight = 0;
    
    NSArray* const subviews = view.subviews;
    int32_t const count = subviews.count;
    
    HLMMeasureSpecMode const widthMode = [HLMLayout measureSpecMode:widthMeasureSpec];
    HLMMeasureSpecMode const heightMode = [HLMLayout measureSpecMode:heightMeasureSpec];
    
    BOOL matchWidth = NO;
    
    int32_t const baselineChildIndex = view.hlm_baselineAlignedChildIndex; // todo: baseline align child
    BOOL const useLargestChild = NO;// mUseLargestChild; // todo: measure with largest
    
    int32_t largestChildHeight = INT32_MIN;
    
    // See how tall everyone is. Also remember max width.
    for (int32_t i = 0; i < count; ++i) {
        UIView* const child = subviews[i];
        
        if (child.isHidden) {
            continue;
        }
        
        UIEdgeInsets const childMargins = child.hlm_margins;
        CGFloat const childLayoutWeight = child.hlm_layoutWeight;
        
        totalWeight += childLayoutWeight;
        
        if (heightMode == HLMMeasureSpecExactly && child.hlm_layoutHeight == 0 && childLayoutWeight > 0) {
            // Optimization: don't bother measuring children who are going to use
            // leftover space. These views will get measured again down below if
            // there is any leftover space.
            int32_t const totalLength = self.totalLength;
            self.totalLength = MAX(totalLength, totalLength + childMargins.top + childMargins.bottom);
        } else {
            int32_t oldHeight = INT32_MIN;
            
            if (child.hlm_layoutHeight == 0 && childLayoutWeight > 0) {
                // heightMode is either unspecified or `at most`, and this
                // child wanted to stretch to fill available space.
                // Translate that to wrap so that it does not end up
                // with a height of 0
                oldHeight = 0;
                child.hlm_layoutHeight = HLMLayoutParamWrap;
            }
            
            // Determine how big this child would like to be. If this or
            // previous children have given a weight, then we allow it to
            // use all available space (and we will shrink things later
            // if needed).
            [HLMLayout measureChildWithMargins:child
                                      ofParent:view
                               parentWidthSpec:widthMeasureSpec
                                     widthUsed:0
                              parentHeightSpec:heightMeasureSpec
                                    heightUsed:totalWeight == 0 ? self.totalLength : 0];
            
            if (oldHeight != INT32_MIN) {
                child.hlm_layoutHeight = oldHeight;
            }
            
            int32_t const childHeight = child.hlm_measuredHeight;
            int32_t const totalLength = self.totalLength;
            self.totalLength = MAX(totalLength, totalLength + childHeight + childMargins.top +
                                   childMargins.bottom);
            
            if (useLargestChild) {
                largestChildHeight = MAX(childHeight, largestChildHeight);
            }
        }
        
        // If applicable, compute the additional offset to the child's baseline
        // we'll need later when asked
        if ((baselineChildIndex >= 0) && (baselineChildIndex == i + 1)) {
            self.baselineChildTop = self.totalLength;
        }
        
        // if we are trying to use a child index for our baseline, the above
        // book keeping only works if there are no children above it with
        // weight.  fail fast to aid the developer.
        if (i < baselineChildIndex && childLayoutWeight > 0) {
            @throw [NSException exceptionWithName:@"HLMLinearLayoutManagerMeasureException"
                                           reason:
                    @"A child of a linearly laid out view with index "
                    @"less than mBaselineAlignedChildIndex has weight > 0, which "
                    @"won't work.  Either remove the weight, or don't set "
                    @"mBaselineAlignedChildIndex."
                                         userInfo:nil];
        }
        
        BOOL matchWidthLocally = NO;
        if (widthMode != HLMMeasureSpecExactly && child.hlm_layoutWidth == HLMLayoutParamMatch) {
            // The width of the linear layout will scale, and at least one
            // child said it wanted to match our width. Set a flag
            // indicating that we need to remeasure at least that view when
            // we know our width.
            matchWidth = YES;
            matchWidthLocally = YES;
        }
        
        int32_t const margin = childMargins.left + childMargins.right;
        int32_t const measuredWidth = child.hlm_measuredWidth + margin;
        maxWidth = MAX(maxWidth, measuredWidth);
        
        allFillParent = allFillParent && child.hlm_layoutWidth == HLMLayoutParamMatch;
        if (childLayoutWeight > 0) {
            // Widths of weighted Views are bogus if we end up
            // remeasuring, so keep them separate.
            weightedMaxWidth = MAX(weightedMaxWidth,
                                   matchWidthLocally ? margin : measuredWidth);
        } else {
            alternativeMaxWidth = MAX(alternativeMaxWidth,
                                      matchWidthLocally ? margin : measuredWidth);
        }
        
    }
    
    if (useLargestChild &&
        (heightMode == HLMMeasureSpecAtMost || heightMode == HLMMeasureSpecUnspecified)) {
        self.totalLength = 0;
        
        for (int32_t i = 0; i < count; ++i) {
            UIView* const child = subviews[i];
            
            if (child.isHidden) {
                continue;
            }
            
            // Account for negative margins
            UIEdgeInsets const childMargins = child.hlm_margins;
            int32_t const totalLength = self.totalLength;
            self.totalLength = MAX(totalLength, totalLength + largestChildHeight +
                                   childMargins.top + childMargins.bottom);
        }
    }
    
    // Add in our padding
    self.totalLength += view.hlm_paddingTop + view.hlm_paddingBottom;
    
    int32_t heightSize = self.totalLength;
    
    // Check against our minimum height
    heightSize = MAX(heightSize, view.hlm_minHeight);
    
    // Reconcile our calculated size with the heightMeasureSpec
    heightSize = [HLMLayout resolveSize:heightSize spec:heightMeasureSpec];
    
    // Either expand children with weight to take up available space or
    // shrink them if they extend beyond our current bounds
    int32_t delta = heightSize - self.totalLength;
    if (delta != 0 && totalWeight > 0.0f) {
        float weightSum = view.hlm_weightSum > 0.0f ? view.hlm_weightSum : totalWeight;
        
        self.totalLength = 0;
        
        for (int32_t i = 0; i < count; ++i) {
            UIView* const child = subviews[i];
            
            if (child.isHidden) {
                continue;
            }
            
            UIEdgeInsets const childMargins = child.hlm_margins;
            
            float childExtra = child.hlm_layoutWeight;
            if (childExtra > 0) {
                // Child said it could absorb extra space -- give him his share
                int32_t share = (int32_t) (childExtra * delta / weightSum);
                weightSum -= childExtra;
                delta -= share;
                
                HLMMeasureSpec const childWidthMeasureSpec = [HLMLayout childMeasureSpec:widthMeasureSpec
                                                                                 padding:view.hlm_paddingLeft + view.hlm_paddingRight + childMargins.left + childMargins.right
                                                                               dimension:child.hlm_layoutWidth];
                
                if ((child.hlm_layoutHeight != 0) || (heightMode != HLMMeasureSpecExactly)) {
                    // child was measured once already above...
                    // base new measurement on stored values
                    int32_t childHeight = child.hlm_measuredHeight + share;
                    if (childHeight < 0) {
                        childHeight = 0;
                    }
                    
                    [HLMLayout measureView:child
                                 widthSpec:childWidthMeasureSpec
                                heightSpec:[HLMLayout measureSpecWithSize:childHeight mode:HLMMeasureSpecExactly]];
                } else {
                    // child was skipped in the loop above.
                    // Measure for this first time here
                    [HLMLayout measureView:child
                                 widthSpec:childWidthMeasureSpec
                                heightSpec:[HLMLayout measureSpecWithSize:share > 0 ? share : 0 mode:HLMMeasureSpecExactly]];
                }
                
            }
            
            int32_t const margin =  childMargins.left + childMargins.right;
            int32_t const measuredWidth = child.hlm_measuredWidth + margin;
            maxWidth = MAX(maxWidth, measuredWidth);
            
            BOOL matchWidthLocally = widthMode != HLMMeasureSpecExactly && child.hlm_layoutWidth == HLMLayoutParamMatch;
            
            alternativeMaxWidth = MAX(alternativeMaxWidth,
                                      matchWidthLocally ? margin : measuredWidth);
            
            allFillParent = allFillParent && child.hlm_layoutWidth == HLMLayoutParamMatch;
            
            int32_t const totalLength = self.totalLength;
            self.totalLength = MAX(totalLength, totalLength + child.hlm_measuredHeight +
                                   childMargins.top + childMargins.bottom);
        }
        
        // Add in our padding
        self.totalLength += view.hlm_paddingTop + view.hlm_paddingBottom;
    } else {
        alternativeMaxWidth = MAX(alternativeMaxWidth,
                                  weightedMaxWidth);
        
        // We have no limit, so make all weighted views as tall as the largest child.
        // Children will have already been measured once.
        if (useLargestChild && heightMode != HLMMeasureSpecExactly) {
            for (int32_t i = 0; i < count; i++) {
                UIView* const child = subviews[i];
                
                if (child.isHidden) {
                    continue;
                }
                
                float childExtra = child.hlm_layoutWeight;
                if (childExtra > 0) {
                    [HLMLayout measureView:child
                                 widthSpec:[HLMLayout measureSpecWithSize:child.hlm_measuredWidth mode:HLMMeasureSpecExactly]
                                heightSpec:[HLMLayout measureSpecWithSize:largestChildHeight mode:HLMMeasureSpecExactly]];
                }
            }
        }
    }
    
    if (!allFillParent && widthMode != HLMMeasureSpecExactly) {
        maxWidth = alternativeMaxWidth;
    }
    
    maxWidth += view.hlm_paddingLeft + view.hlm_paddingRight;
    
    // Check against our minimum width
    maxWidth = MAX(maxWidth, view.hlm_minWidth);
    
    view.hlm_measuredWidth = [HLMLayout resolveSize:maxWidth spec:widthMeasureSpec];
    view.hlm_measuredHeight = heightSize;
    
    if (matchWidth) {
        [self forceUniformWidth:view
                          count:count
              heightMeasureSpec:heightMeasureSpec];
    }
}

-(void) measureHorizontal:(UIView *) view
                widthSpec:(HLMMeasureSpec) widthMeasureSpec
               heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    self.totalLength = 0;
    int32_t maxHeight = 0;
    int32_t childState = 0;
    int32_t alternativeMaxHeight = 0;
    int32_t weightedMaxHeight = 0;
    BOOL allFillParent = YES;
    float totalWeight = 0;
    
    NSArray* const subviews = view.subviews;
    int32_t const count = subviews.count;
    
    HLMMeasureSpecMode const widthMode = [HLMLayout measureSpecMode:widthMeasureSpec];
    HLMMeasureSpecMode const heightMode = [HLMLayout measureSpecMode:heightMeasureSpec];
    
    BOOL matchHeight = NO;
    
    memset(maxAscent, -1, sizeof(maxAscent));
    memset(maxDescent, -1, sizeof(maxDescent));
    
    BOOL const baselineAligned = view.hlm_baselineAligned; // todo: baseline aligned
    BOOL const useLargestChild = NO; // todo: largest child
    
    BOOL const isExactly = widthMode == HLMMeasureSpecExactly;
    
    int32_t largestChildWidth = INT32_MIN;
    
    // See how wide everyone is. Also remember max height.
    for (int32_t i = 0; i < count; i++) {
        UIView* const child = subviews[i];
        
        if (child.isHidden) {
            continue;
        }
        
        UIEdgeInsets const childMargins = child.hlm_margins;
        CGFloat const childLayoutWeight = child.hlm_layoutWeight;
        
        totalWeight += childLayoutWeight;
        
        if (widthMode == HLMMeasureSpecExactly && child.hlm_layoutWidth == 0 && childLayoutWeight > 0) {
            // Optimization: don't bother measuring children who are going to use
            // leftover space. These views will get measured again down below if
            // there is any leftover space.
            if (isExactly) {
                self.totalLength += childMargins.left + childMargins.right;
            } else {
                int32_t const totalLength = self.totalLength;
                self.totalLength = MAX(totalLength, totalLength +
                                       childMargins.left + childMargins.right);
            }
            
            // Baseline alignment requires to measure widgets to obtain the
            // baseline offset (in particular for TextViews). The following
            // defeats the optimization mentioned above. Allow the child to
            // use as much space as it wants because we can shrink things
            // later (and re-measure).
            if (baselineAligned) {
                HLMMeasureSpec const freeSpec = [HLMLayout measureSpecWithSize:0 mode:HLMMeasureSpecUnspecified];
                [HLMLayout measureView:child
                             widthSpec:freeSpec
                            heightSpec:freeSpec];
            }
        } else {
            int32_t oldWidth = INT32_MIN;
            
            if (child.hlm_layoutWidth == 0 && childLayoutWeight > 0) {
                // widthMode is either unspecified or `at most`, and this child
                // wanted to stretch to fill available space. Translate that to
                // wrap so that it does not end up with a width of 0
                oldWidth = 0;
                child.hlm_layoutWidth = HLMLayoutParamWrap;
            }
            
            // Determine how big this child would like to be. If this or
            // previous children have given a weight, then we allow it to
            // use all available space (and we will shrink things later
            // if needed).
            [HLMLayout measureChildWithMargins:child
                                      ofParent:view
                               parentWidthSpec:widthMeasureSpec
                                     widthUsed:totalWeight == 0 ? self.totalLength : 0
                              parentHeightSpec:heightMeasureSpec
                                    heightUsed:0];
            
            if (oldWidth != INT32_MIN) {
                child.hlm_layoutWidth = oldWidth;
            }
            
            int32_t const childWidth = child.hlm_measuredWidth;
            if (isExactly) {
                self.totalLength += childWidth + childMargins.left + childMargins.right;
            } else {
                int32_t const totalLength = self.totalLength;
                self.totalLength = MAX(totalLength, totalLength + childWidth + childMargins.left + childMargins.right);
            }
            
            if (useLargestChild) {
                largestChildWidth = MAX(childWidth, largestChildWidth);
            }
        }
        
        BOOL matchHeightLocally = NO;
        if (heightMode != HLMMeasureSpecExactly && child.hlm_layoutHeight == HLMLayoutParamMatch) {
            // The height of the linear layout will scale, and at least one
            // child said it wanted to match our height. Set a flag indicating that
            // we need to remeasure at least that view when we know our height.
            matchHeight = YES;
            matchHeightLocally = YES;
        }
        
        int32_t const margin = childMargins.top + childMargins.bottom;
        int32_t const childHeight = child.hlm_measuredHeight + margin;
        
        if (baselineAligned) {
            //            int32_t const childBaseline = child.hlm_baseline;
            //            if (childBaseline != -1) {
            //                // Translates the child's vertical gravity into an index
            //                // in the range 0..VERTICAL_GRAVITY_COUNT
            //                HLMGravity const gravity = (child.hlm_layoutGravity >= 0 ? child.hlm_layoutGravity : view.hlm_gravity) & HLMGravityVerticalMask;
            //                int32_t const index = ((gravity >> HLMGravityAxisYShift) & ~HLMGravityAxisSpecified) >> 1;
            //
            //                maxAscent[index] = MAX(maxAscent[index], childBaseline);
            //                maxDescent[index] = MAX(maxDescent[index], childHeight - childBaseline);
            //            }
        }
        
        maxHeight = MAX(maxHeight, childHeight);
        
        allFillParent = allFillParent && child.hlm_layoutHeight == HLMLayoutParamMatch;
        if (childLayoutWeight > 0) {
            // Heights of weighted Views are bogus if we end up
            // remeasuring, so keep them separate.
            weightedMaxHeight = MAX(weightedMaxHeight, matchHeightLocally ? margin : childHeight);
        } else {
            alternativeMaxHeight = MAX(alternativeMaxHeight, matchHeightLocally ? margin : childHeight);
        }
        
    }
    
    // Check maxAscent[HLMLinearLayoutIndexTop] first because it maps to HLMGravityTop,
    // the most common case
    if (maxAscent[HLMLinearLayoutIndexTop] != -1 ||
        maxAscent[HLMLinearLayoutIndexCenterVertical] != -1 ||
        maxAscent[HLMLinearLayoutIndexBottom] != -1 ||
        maxAscent[HLMLinearLayoutIndexFill] != -1) {
        int32_t const ascent = MAX(maxAscent[HLMLinearLayoutIndexFill],
                                   MAX(maxAscent[HLMLinearLayoutIndexCenterVertical],
                                       MAX(maxAscent[HLMLinearLayoutIndexTop], maxAscent[HLMLinearLayoutIndexBottom])));
        int32_t const descent = MAX(maxDescent[HLMLinearLayoutIndexFill],
                                    MAX(maxDescent[HLMLinearLayoutIndexCenterVertical],
                                        MAX(maxDescent[HLMLinearLayoutIndexTop], maxDescent[HLMLinearLayoutIndexBottom])));
        maxHeight = MAX(maxHeight, ascent + descent);
    }
    
    if (useLargestChild && (widthMode == HLMMeasureSpecAtMost || widthMode == HLMMeasureSpecUnspecified)) {
        self.totalLength = 0;
        
        for (int32_t i = 0; i < count; i++) {
            UIView* const child = subviews[i];
            
            if (child.isHidden) {
                continue;
            }
            
            if (isExactly) {
                self.totalLength += largestChildWidth + child.hlm_marginLeft + child.hlm_marginRight;
            } else {
                int32_t const totalLength = self.totalLength;
                self.totalLength = MAX(totalLength, totalLength + largestChildWidth + child.hlm_marginLeft + child.hlm_marginRight);
            }
        }
    }
    
    // Add in our padding
    self.totalLength += view.hlm_paddingLeft + view.hlm_paddingRight;
    
    int32_t widthSize = self.totalLength;
    
    // Check against our minimum width
    widthSize = MAX(widthSize, view.hlm_minWidth);
    
    // Reconcile our calculated size with the widthMeasureSpec
    widthSize = [HLMLayout resolveSize:widthSize spec:widthMeasureSpec];
    
    // Either expand children with weight to take up available space or
    // shrink them if they extend beyond our current bounds
    int32_t delta = widthSize - self.totalLength;
    if (delta != 0 && totalWeight > 0.0f) {
        float weightSum = view.hlm_weightSum > 0.0f ? view.hlm_weightSum : totalWeight;
        
        memset(maxAscent, -1, sizeof(maxAscent));
        memset(maxDescent, -1, sizeof(maxDescent));
        maxHeight = -1;
        
        self.totalLength = 0;
        
        for (int32_t i = 0; i < count; i++) {
            UIView* child = subviews[i];
            
            if (child.isHidden) {
                continue;
            }
            
            float childExtra = child.hlm_layoutWeight;
            if (childExtra > 0) {
                // Child said it could absorb extra space -- give him his share
                int32_t share = (int32_t) (childExtra * delta / weightSum);
                weightSum -= childExtra;
                delta -= share;
                
                HLMMeasureSpec const childHeightMeasureSpec = [HLMLayout childMeasureSpec:heightMeasureSpec
                                                                                  padding:view.hlm_paddingTop + view.hlm_paddingBottom + child.hlm_marginTop + child.hlm_marginBottom
                                                                                dimension:child.hlm_layoutHeight];
                
                if ((child.hlm_layoutWidth != 0) || (widthMode != HLMMeasureSpecExactly)) {
                    // child was measured once already above ... base new measurement
                    // on stored values
                    int32_t childWidth = child.hlm_measuredWidth + share;
                    if (childWidth < 0) {
                        childWidth = 0;
                    }
                    
                    [HLMLayout measureView:child
                                 widthSpec:[HLMLayout measureSpecWithSize:childWidth mode:HLMMeasureSpecExactly]
                                heightSpec:childHeightMeasureSpec];
                } else {
                    // child was skipped in the loop above. Measure for this first time here
                    [HLMLayout measureView:child
                                 widthSpec:[HLMLayout measureSpecWithSize:share > 0 ? share : 0 mode:HLMMeasureSpecExactly]
                                heightSpec:childHeightMeasureSpec];
                }
                
            }
            
            if (isExactly) {
                self.totalLength += child.hlm_measuredWidth + child.hlm_marginLeft + child.hlm_marginRight;
            } else {
                int32_t const totalLength = self.totalLength;
                self.totalLength = MAX(totalLength, totalLength + child.hlm_measuredWidth + child.hlm_marginLeft + child.hlm_marginRight);
            }
            
            BOOL matchHeightLocally = heightMode != HLMMeasureSpecExactly && child.hlm_layoutHeight == HLMLayoutParamMatch;
            
            int32_t const margin = child.hlm_marginTop + child.hlm_marginBottom;
            int32_t const childHeight = child.hlm_measuredHeight + margin;
            maxHeight = MAX(maxHeight, childHeight);
            alternativeMaxHeight = MAX(alternativeMaxHeight, matchHeightLocally ? margin : childHeight);
            
            allFillParent = allFillParent && child.hlm_layoutHeight == HLMLayoutParamMatch;
            
            if (baselineAligned) {
                //                int32_t const childBaseline = child.hlm_baseline;
                //                if (childBaseline != -1) {
                //                    // Translates the child's vertical gravity into an index in the range 0..2
                //                    HLMGravity const gravity = (child.hlm_layoutGravity < 0 ? view.hlm_gravity : child.hlm_layoutGravity) & HLMGravityVerticalMask;
                //                    int32_t const index = ((gravity >> HLMGravityAxisYShift) & ~HLMGravityAxisSpecified) >> 1;
                //
                //                    maxAscent[index] = MAX(maxAscent[index], childBaseline);
                //                    maxDescent[index] = MAX(maxDescent[index], childHeight - childBaseline);
                //                }
            }
        }
        
        // Add in our padding
        self.totalLength += view.hlm_paddingLeft + view.hlm_paddingRight;
        
        // Check maxAscent[HLMLinearLayoutIndexTop] first because it maps to HLMGravityTop,
        // the most common case
        if (maxAscent[HLMLinearLayoutIndexTop] != -1 ||
            maxAscent[HLMLinearLayoutIndexCenterVertical] != -1 ||
            maxAscent[HLMLinearLayoutIndexBottom] != -1 ||
            maxAscent[HLMLinearLayoutIndexFill] != -1) {
            int32_t const ascent = MAX(maxAscent[HLMLinearLayoutIndexFill],
                                       MAX(maxAscent[HLMLinearLayoutIndexCenterVertical],
                                           MAX(maxAscent[HLMLinearLayoutIndexTop], maxAscent[HLMLinearLayoutIndexBottom])));
            int32_t const descent = MAX(maxDescent[HLMLinearLayoutIndexFill],
                                        MAX(maxDescent[HLMLinearLayoutIndexCenterVertical],
                                            MAX(maxDescent[HLMLinearLayoutIndexTop], maxDescent[HLMLinearLayoutIndexBottom])));
            maxHeight = MAX(maxHeight, ascent + descent);
        }
    } else {
        alternativeMaxHeight = MAX(alternativeMaxHeight, weightedMaxHeight);
        
        // We have no limit, so make all weighted views as wide as the largest child.
        // Children will have already been measured once.
        if (useLargestChild && widthMode != HLMMeasureSpecExactly) {
            for (int32_t i = 0; i < count; i++) {
                UIView* child = subviews[i];
                
                if (child.isHidden) {
                    continue;
                }
                
                float childExtra = child.hlm_layoutWeight;
                if (childExtra > 0) {
                    [HLMLayout measureView:child
                                 widthSpec:[HLMLayout measureSpecWithSize:largestChildWidth mode:HLMMeasureSpecExactly]
                                heightSpec:[HLMLayout measureSpecWithSize:child.hlm_measuredHeight mode:HLMMeasureSpecExactly]];
                }
            }
        }
    }
    
    if (!allFillParent && heightMode != HLMMeasureSpecExactly) {
        maxHeight = alternativeMaxHeight;
    }
    
    maxHeight += view.hlm_paddingTop + view.hlm_paddingBottom;
    
    // Check against our minimum height
    maxHeight = MAX(maxHeight, view.hlm_minHeight);
    
    view.hlm_measuredWidth = widthSize;
    view.hlm_measuredHeight = [HLMLayout resolveSize:maxHeight spec:heightMeasureSpec];
    
    if (matchHeight) {
        [self forceUniformHeight:view
                           count:count
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
    int32_t paddingLeft = view.hlm_paddingLeft;
    
    int32_t childTop;
    int32_t childLeft;
    
    // Where right end of child should go
    int32_t const width = right - left;
    int32_t childRight = width - view.hlm_paddingRight;
    
    // Space available for child
    int32_t childSpace = width - paddingLeft - view.hlm_paddingRight;
    
    NSArray* const subviews = view.subviews;
    int32_t const count = subviews.count;
    
    HLMGravity const majorGravity = view.hlm_gravity & HLMGravityVerticalMask;
    HLMGravity const minorGravity = view.hlm_gravity & HLMGravityHorizontalMask;
    
    switch (majorGravity) {
        case HLMGravityBottom:
            // self.totalLength contains the padding already
            childTop = view.hlm_paddingTop + bottom - top - self.totalLength;
            break;
            
            // self.totalLength contains the padding already
        case HLMGravityCenterVertical:
            childTop = view.hlm_paddingTop + (bottom - top - self.totalLength) / 2;
            break;
            
        case HLMGravityTop:
        default:
            childTop = view.hlm_paddingTop;
            break;
    }
    
    for (int32_t i = 0; i < count; i++) {
        UIView* const child = subviews[i];
        if (!child.isHidden) {
            int32_t const childWidth = child.hlm_measuredWidth;
            int32_t const childHeight = child.hlm_measuredHeight;
            
            HLMGravity gravity = child.hlm_layoutGravity;
            if (gravity < 0) {
                gravity = minorGravity;
            }
            switch (gravity & HLMGravityHorizontalMask) {
                case HLMGravityCenterHorizontal:
                    childLeft = paddingLeft + ((childSpace - childWidth) / 2) + child.hlm_marginLeft - child.hlm_marginRight;
                    break;
                    
                case HLMGravityRight:
                    childLeft = childRight - childWidth - child.hlm_marginRight;
                    break;
                    
                case HLMGravityLeft:
                default:
                    childLeft = paddingLeft + child.hlm_marginLeft;
                    break;
            }
            
            childTop += child.hlm_marginTop;
            [HLMLayout setChild:child frame:CGRectMake(childLeft, childTop, childWidth, childHeight)];
            childTop += childHeight + child.hlm_marginBottom;
        }
    }
}

-(void) layoutHorizontal:(UIView *) view
                    left:(NSInteger) left
                     top:(NSInteger) top
                   right:(NSInteger) right
                  bottom:(NSInteger) bottom {
    int32_t const paddingTop = view.hlm_paddingTop;
    
    int32_t childTop;
    int32_t childLeft;
    
    // Where bottom of child should go
    int32_t const height = bottom - top;
    int32_t childBottom = height - view.hlm_paddingBottom;
    
    // Space available for child
    int32_t childSpace = height - paddingTop - view.hlm_paddingBottom;
    
    NSArray* const subviews = view.subviews;
    int32_t const count = subviews.count;
    
    HLMGravity const majorGravity = view.hlm_gravity & HLMGravityHorizontalMask;
    HLMGravity const minorGravity = view.hlm_gravity & HLMGravityVerticalMask;
    
    BOOL const baselineAligned = view.hlm_baselineAligned;
    
    switch (majorGravity) {
        case HLMGravityRight:
            // self.totalLength contains the padding already
            childLeft = view.hlm_paddingLeft + right - left - self.totalLength;
            break;
            
        case HLMGravityCenterHorizontal:
            // mTotalLength contains the padding already
            childLeft = view.hlm_paddingLeft + (right - left - self.totalLength) / 2;
            break;
            
        case HLMGravityLeft:
        default:
            childLeft = view.hlm_paddingLeft;
            break;
    }
    
    for (int32_t i = 0; i < count; i++) {
        UIView* const child = subviews[i];
        
        if (!child.isHidden) {
            int32_t const childWidth = child.hlm_measuredWidth;
            int32_t const childHeight = child.hlm_measuredHeight;
            int32_t childBaseline = -1;
            
            if (baselineAligned && child.hlm_layoutHeight != HLMLayoutParamMatch) {
                //                childBaseline = child.hlm_baseline;
            }
            
            HLMGravity gravity = child.hlm_layoutGravity;
            if (gravity < 0) {
                gravity = minorGravity;
            }
            
            switch (gravity & HLMGravityVerticalMask) {
                case HLMGravityTop: {
                    childTop = paddingTop + child.hlm_marginTop;
                    if (childBaseline != -1) {
                        childTop += maxAscent[HLMLinearLayoutIndexTop] - childBaseline;
                    }
                    break;
                }
                    
                case HLMGravityCenterVertical:
                    childTop = paddingTop + ((childSpace - childHeight) / 2) + child.hlm_marginTop - child.hlm_marginBottom;
                    break;
                    
                case HLMGravityBottom: {
                    childTop = childBottom - childHeight - child.hlm_marginBottom;
                    if (childBaseline != -1) {
                        int32_t descent = child.hlm_measuredHeight - childBaseline;
                        childTop -= (maxDescent[HLMLinearLayoutIndexBottom] - descent);
                    }
                    break;
                }
                    
                default:
                    childTop = paddingTop;
                    break;
            }
            
            childLeft += child.hlm_marginLeft;
            [HLMLayout setChild:child frame:CGRectMake(childLeft, childTop, childWidth, childHeight)];
            childLeft += childWidth + child.hlm_marginRight;
            
        }
    }
}

-(void) forceUniformWidth:(UIView *) view
                    count:(NSUInteger) count
        heightMeasureSpec:(HLMMeasureSpec) heightMeasureSpec {
    NSArray* const subviews = view.subviews;
    // Pretend that the linear layout has an exact size.
    int32_t const uniformMeasureSpec = [HLMLayout measureSpecWithSize:view.hlm_measuredWidth mode:HLMMeasureSpecExactly];
    for (int32_t i = 0; i < count; i++) {
        UIView* child = subviews[i];
        if (!child.isHidden) {
            
            if (child.hlm_layoutWidth == HLMLayoutParamMatch) {
                // Temporarily force children to reuse their old measured height
                int32_t const oldHeight = child.hlm_layoutHeight;
                child.hlm_layoutHeight = child.hlm_measuredHeight;
                
                // Remeasue with new dimensions
                [HLMLayout measureChildWithMargins:child
                                          ofParent:view
                                   parentWidthSpec:uniformMeasureSpec
                                         widthUsed:0
                                  parentHeightSpec:heightMeasureSpec
                                        heightUsed:0];
                child.hlm_layoutHeight = oldHeight;
            }
        }
    }
}

-(void) forceUniformHeight:(UIView *) view
                     count:(NSUInteger) count
          widthMeasureSpec:(HLMMeasureSpec) widthMeasureSpec {
    NSArray* const subviews = view.subviews;
    // Pretend that the linear layout has an exact size. This is the measured height of
    // ourselves. The measured height should be the max height of the children, changed
    // to accommodate the heightMeasureSpec from the parent
    int32_t const uniformMeasureSpec = [HLMLayout measureSpecWithSize:view.hlm_measuredHeight mode:HLMMeasureSpecExactly];
    for (int32_t i = 0; i < count; i++) {
        UIView* child = subviews[i];
        if (!child.isHidden) {
            if (child.hlm_layoutHeight == HLMLayoutParamMatch) {
                // Temporarily force children to reuse their old measured width
                int32_t const oldWidth = child.hlm_layoutWidth;
                child.hlm_layoutWidth = child.hlm_measuredWidth;
                
                // Remeasure with new dimensions
                [HLMLayout measureChildWithMargins:child
                                          ofParent:view
                                   parentWidthSpec:widthMeasureSpec
                                         widthUsed:0
                                  parentHeightSpec:uniformMeasureSpec
                                        heightUsed:0];
                child.hlm_layoutWidth = oldWidth;
            }
        }
    }
}

@end
