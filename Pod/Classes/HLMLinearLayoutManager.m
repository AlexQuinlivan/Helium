//
//  HLMLinearLayoutManager.m
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "HLMLinearLayoutManager.h"

@interface HLMLinearLayoutManager ()
@property (nonatomic) NSInteger baselineChildTop;
@property (nonatomic) int32_t totalLength;
@end

@implementation HLMLinearLayoutManager

-(void) measure:(UIView *) view
      widthSpec:(HLMMeasureSpec) widthMeasureSpec
     heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    if (view.hlm_orientation == HLMLayoutOrientationVertical) {
        [self measureVertical:view
                    widthSpec:widthMeasureSpec
                   heightSpec:heightMeasureSpec];
    } else {
//        [self measureHorizontal:view
//                      widthSpec:widthMeasureSpec
//                     heightSpec:heightMeasureSpec];
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

//-(void) measureHorizontal:(UIView *) view
//                widthSpec:(HLMMeasureSpec) widthMeasureSpec
//               heightSpec:(HLMMeasureSpec) heightMeasureSpec {
//    mTotalLength = 0;
//    int maxHeight = 0;
//    int alternativeMaxHeight = 0;
//    int weightedMaxHeight = 0;
//    boolean allFillParent = true;
//    float totalWeight = 0;
//    
//    final int count = getVirtualChildCount();
//    
//    final int widthMode = MeasureSpec.getMode(widthMeasureSpec);
//    final int heightMode = MeasureSpec.getMode(heightMeasureSpec);
//    
//    boolean matchHeight = false;
//    
//    if (mMaxAscent == null || mMaxDescent == null) {
//        mMaxAscent = new int[VERTICAL_GRAVITY_COUNT];
//        mMaxDescent = new int[VERTICAL_GRAVITY_COUNT];
//    }
//    
//    final int[] maxAscent = mMaxAscent;
//    final int[] maxDescent = mMaxDescent;
//    
//    maxAscent[0] = maxAscent[1] = maxAscent[2] = maxAscent[3] = -1;
//    maxDescent[0] = maxDescent[1] = maxDescent[2] = maxDescent[3] = -1;
//    
//    final boolean baselineAligned = mBaselineAligned;
//    
//    // See how wide everyone is. Also remember max height.
//    for (int i = 0; i < count; ++i) {
//        final View child = getVirtualChildAt(i);
//        
//        if (child == null) {
//            mTotalLength += measureNullChild(i);
//            continue;
//        }
//        
//        if (child.getVisibility() == GONE) {
//            i += getChildrenSkipCount(child, i);
//            continue;
//        }
//        
//        final LinearLayout.LayoutParams lp = (LinearLayout.LayoutParams) child.getLayoutParams();
//        
//        totalWeight += lp.weight;
//        
//        if (widthMode == MeasureSpec.EXACTLY && lp.width == 0 && lp.weight > 0) {
//            // Optimization: don't bother measuring children who are going to use
//            // leftover space. These views will get measured again down below if
//            // there is any leftover space.
//            mTotalLength += lp.leftMargin + lp.rightMargin;
//            
//            // Baseline alignment requires to measure widgets to obtain the
//            // baseline offset (in particular for TextViews).
//            // The following defeats the optimization mentioned above.
//            // Allow the child to use as much space as it wants because we
//            // can shrink things later (and re-measure).
//            if (baselineAligned) {
//                final int freeSpec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED);
//                child.measure(freeSpec, freeSpec);
//            }
//        } else {
//            int oldWidth = Integer.MIN_VALUE;
//            
//            if (lp.width == 0 && lp.weight > 0) {
//                // widthMode is either UNSPECIFIED OR AT_MOST, and this child
//                // wanted to stretch to fill available space. Translate that to
//                // WRAP_CONTENT so that it does not end up with a width of 0
//                oldWidth = 0;
//                lp.width = LayoutParams.WRAP_CONTENT;
//            }
//            
//            // Determine how big this child would like to be. If this or
//            // previous children have given a weight, then we allow it to
//            // use all available space (and we will shrink things later
//            // if needed).
//            measureChildBeforeLayout(child, i, widthMeasureSpec,
//                                     totalWeight == 0 ? mTotalLength : 0,
//                                     heightMeasureSpec, 0);
//            
//            if (oldWidth != Integer.MIN_VALUE) {
//                lp.width = oldWidth;
//            }
//            
//            mTotalLength += child.getMeasuredWidth() + lp.leftMargin +
//            lp.rightMargin + getNextLocationOffset(child);
//        }
//        
//        boolean matchHeightLocally = false;
//        if (heightMode != MeasureSpec.EXACTLY && lp.height == LayoutParams.FILL_PARENT) {
//            // The height of the linear layout will scale, and at least one
//            // child said it wanted to match our height. Set a flag indicating that
//            // we need to remeasure at least that view when we know our height.
//            matchHeight = true;
//            matchHeightLocally = true;
//        }
//        
//        final int margin = lp.topMargin + lp.bottomMargin;
//        final int childHeight = child.getMeasuredHeight() + margin;
//        
//        if (baselineAligned) {
//            final int childBaseline = child.getBaseline();
//            if (childBaseline != -1) {
//                // Translates the child's vertical gravity into an index
//                // in the range 0..VERTICAL_GRAVITY_COUNT
//                final int gravity = (lp.gravity < 0 ? mGravity : lp.gravity)
//                & Gravity.VERTICAL_GRAVITY_MASK;
//                final int index = ((gravity >> Gravity.AXIS_Y_SHIFT)
//                                   & ~Gravity.AXIS_SPECIFIED) >> 1;
//                
//                maxAscent[index] = Math.max(maxAscent[index], childBaseline);
//                maxDescent[index] = Math.max(maxDescent[index], childHeight - childBaseline);
//            }
//        }
//        
//        maxHeight = Math.max(maxHeight, childHeight);
//        
//        allFillParent = allFillParent && lp.height == LayoutParams.FILL_PARENT;
//        if (lp.weight > 0) {
//            /*
//             * Heights of weighted Views are bogus if we end up
//             * remeasuring, so keep them separate.
//             */
//            weightedMaxHeight = Math.max(weightedMaxHeight,
//                                         matchHeightLocally ? margin : childHeight);
//        } else {
//            alternativeMaxHeight = Math.max(alternativeMaxHeight,
//                                            matchHeightLocally ? margin : childHeight);
//        }
//        
//        i += getChildrenSkipCount(child, i);
//    }
//    
//    // Check mMaxAscent[INDEX_TOP] first because it maps to Gravity.TOP,
//    // the most common case
//    if (maxAscent[INDEX_TOP] != -1 ||
//        maxAscent[INDEX_CENTER_VERTICAL] != -1 ||
//        maxAscent[INDEX_BOTTOM] != -1 ||
//        maxAscent[INDEX_FILL] != -1) {
//        final int ascent = Math.max(maxAscent[INDEX_FILL],
//                                    Math.max(maxAscent[INDEX_CENTER_VERTICAL],
//                                             Math.max(maxAscent[INDEX_TOP], maxAscent[INDEX_BOTTOM])));
//        final int descent = Math.max(maxDescent[INDEX_FILL],
//                                     Math.max(maxDescent[INDEX_CENTER_VERTICAL],
//                                              Math.max(maxDescent[INDEX_TOP], maxDescent[INDEX_BOTTOM])));
//        maxHeight = Math.max(maxHeight, ascent + descent);
//    }
//    
//    // Add in our padding
//    mTotalLength += mPaddingLeft + mPaddingRight;
//    
//    int widthSize = mTotalLength;
//    
//    // Check against our minimum width
//    widthSize = Math.max(widthSize, getSuggestedMinimumWidth());
//    
//    // Reconcile our calculated size with the widthMeasureSpec
//    widthSize = resolveSize(widthSize, widthMeasureSpec);
//    
//    // Either expand children with weight to take up available space or
//    // shrink them if they extend beyond our current bounds
//    int delta = widthSize - mTotalLength;
//    if (delta != 0 && totalWeight > 0.0f) {
//        float weightSum = mWeightSum > 0.0f ? mWeightSum : totalWeight;
//        
//        maxAscent[0] = maxAscent[1] = maxAscent[2] = maxAscent[3] = -1;
//        maxDescent[0] = maxDescent[1] = maxDescent[2] = maxDescent[3] = -1;
//        maxHeight = -1;
//        
//        mTotalLength = 0;
//        
//        for (int i = 0; i < count; ++i) {
//            final View child = getVirtualChildAt(i);
//            
//            if (child == null || child.getVisibility() == View.GONE) {
//                continue;
//            }
//            
//            final LinearLayout.LayoutParams lp =
//            (LinearLayout.LayoutParams) child.getLayoutParams();
//            
//            float childExtra = lp.weight;
//            if (childExtra > 0) {
//                // Child said it could absorb extra space -- give him his share
//                int share = (int) (childExtra * delta / weightSum);
//                weightSum -= childExtra;
//                delta -= share;
//                
//                final int childHeightMeasureSpec = getChildMeasureSpec(
//                                                                       heightMeasureSpec,
//                                                                       mPaddingTop + mPaddingBottom + lp.topMargin + lp.bottomMargin,
//                                                                       lp.height);
//                
//                // TODO: Use a field like lp.isMeasured to figure out if this
//                // child has been previously measured
//                if ((lp.width != 0) || (widthMode != MeasureSpec.EXACTLY)) {
//                    // child was measured once already above ... base new measurement
//                    // on stored values
//                    int childWidth = child.getMeasuredWidth() + share;
//                    if (childWidth < 0) {
//                        childWidth = 0;
//                    }
//                    
//                    child.measure(
//                                  MeasureSpec.makeMeasureSpec(childWidth, MeasureSpec.EXACTLY),
//                                  childHeightMeasureSpec);
//                } else {
//                    // child was skipped in the loop above. Measure for this first time here
//                    child.measure(MeasureSpec.makeMeasureSpec(
//                                                              share > 0 ? share : 0, MeasureSpec.EXACTLY),
//                                  childHeightMeasureSpec);
//                }
//            }
//            
//            mTotalLength += child.getMeasuredWidth() + lp.leftMargin +
//            lp.rightMargin + getNextLocationOffset(child);
//            
//            boolean matchHeightLocally = heightMode != MeasureSpec.EXACTLY &&
//            lp.height == LayoutParams.FILL_PARENT;
//            
//            final int margin = lp.topMargin + lp .bottomMargin;
//            int childHeight = child.getMeasuredHeight() + margin;
//            maxHeight = Math.max(maxHeight, childHeight);
//            alternativeMaxHeight = Math.max(alternativeMaxHeight,
//                                            matchHeightLocally ? margin : childHeight);
//            
//            allFillParent = allFillParent && lp.height == LayoutParams.FILL_PARENT;
//            
//            if (baselineAligned) {
//                final int childBaseline = child.getBaseline();
//                if (childBaseline != -1) {
//                    // Translates the child's vertical gravity into an index in the range 0..2
//                    final int gravity = (lp.gravity < 0 ? mGravity : lp.gravity)
//                    & Gravity.VERTICAL_GRAVITY_MASK;
//                    final int index = ((gravity >> Gravity.AXIS_Y_SHIFT)
//                                       & ~Gravity.AXIS_SPECIFIED) >> 1;
//                    
//                    maxAscent[index] = Math.max(maxAscent[index], childBaseline);
//                    maxDescent[index] = Math.max(maxDescent[index],
//                                                 childHeight - childBaseline);
//                }
//            }
//        }
//        
//        // Add in our padding
//        mTotalLength += mPaddingLeft + mPaddingRight;
//        
//        // Check mMaxAscent[INDEX_TOP] first because it maps to Gravity.TOP,
//        // the most common case
//        if (maxAscent[INDEX_TOP] != -1 ||
//            maxAscent[INDEX_CENTER_VERTICAL] != -1 ||
//            maxAscent[INDEX_BOTTOM] != -1 ||
//            maxAscent[INDEX_FILL] != -1) {
//            final int ascent = Math.max(maxAscent[INDEX_FILL],
//                                        Math.max(maxAscent[INDEX_CENTER_VERTICAL],
//                                                 Math.max(maxAscent[INDEX_TOP], maxAscent[INDEX_BOTTOM])));
//            final int descent = Math.max(maxDescent[INDEX_FILL],
//                                         Math.max(maxDescent[INDEX_CENTER_VERTICAL],
//                                                  Math.max(maxDescent[INDEX_TOP], maxDescent[INDEX_BOTTOM])));
//            maxHeight = Math.max(maxHeight, ascent + descent);
//        }
//    } else {
//        alternativeMaxHeight = Math.max(alternativeMaxHeight, weightedMaxHeight);
//    }
//    
//    if (!allFillParent && heightMode != MeasureSpec.EXACTLY) {
//        maxHeight = alternativeMaxHeight;
//    }
//    
//    maxHeight += mPaddingTop + mPaddingBottom;
//    
//    // Check against our minimum height
//    maxHeight = Math.max(maxHeight, getSuggestedMinimumHeight());
//    
//    setMeasuredDimension(widthSize, resolveSize(maxHeight, heightMeasureSpec));
//    
//    if (matchHeight) {
//        forceUniformHeight(count, widthMeasureSpec);
//    }
//}

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
//        [self layoutHorizontal:view];
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
    int32_t paddingBottom = padding.bottom;
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
//
//-(void) layoutHorizontal:(UIView *) view {
//    final int paddingTop = mPaddingTop;
//
//    int childTop = paddingTop;
//    int childLeft = mPaddingLeft;
//    
//    // Where bottom of child should go
//    final int height = mBottom - mTop;
//    int childBottom = height - mPaddingBottom;
//    
//    // Space available for child
//    int childSpace = height - paddingTop - mPaddingBottom;
//    
//    final int count = getVirtualChildCount();
//    
//    final int majorGravity = mGravity & Gravity.HORIZONTAL_GRAVITY_MASK;
//    final int minorGravity = mGravity & Gravity.VERTICAL_GRAVITY_MASK;
//    
//    final boolean baselineAligned = mBaselineAligned;
//    
//    final int[] maxAscent = mMaxAscent;
//    final int[] maxDescent = mMaxDescent;
//    
//    if (majorGravity != Gravity.LEFT) {
//        switch (majorGravity) {
//            case Gravity.RIGHT:
//                // mTotalLength contains the padding already, we add the left
//                // padding to compensate
//                childLeft = mRight - mLeft + mPaddingLeft - mTotalLength;
//                break;
//                
//            case Gravity.CENTER_HORIZONTAL:
//                childLeft += ((mRight - mLeft) - mTotalLength) / 2;
//                break;
//        }
//    }
//    
//    for (int i = 0; i < count; i++) {
//        final View child = getVirtualChildAt(i);
//        
//        if (child == null) {
//            childLeft += measureNullChild(i);
//        } else if (child.getVisibility() != GONE) {
//            final int childWidth = child.getMeasuredWidth();
//            final int childHeight = child.getMeasuredHeight();
//            int childBaseline = -1;
//            
//            final LinearLayout.LayoutParams lp =
//            (LinearLayout.LayoutParams) child.getLayoutParams();
//            
//            if (baselineAligned && lp.height != LayoutParams.FILL_PARENT) {
//                childBaseline = child.getBaseline();
//            }
//            
//            int gravity = lp.gravity;
//            if (gravity < 0) {
//                gravity = minorGravity;
//            }
//            
//            switch (gravity & Gravity.VERTICAL_GRAVITY_MASK) {
//                case Gravity.TOP:
//                    childTop = paddingTop + lp.topMargin;
//                    if (childBaseline != -1) {
//                        childTop += maxAscent[INDEX_TOP] - childBaseline;
//                    }
//                    break;
//                    
//                case Gravity.CENTER_VERTICAL:
//                    // Removed support for baselign alignment when layout_gravity or
//                    // gravity == center_vertical. See bug #1038483.
//                    // Keep the code around if we need to re-enable this feature
//                    // if (childBaseline != -1) {
//                    //     // Align baselines vertically only if the child is smaller than us
//                    //     if (childSpace - childHeight > 0) {
//                    //         childTop = paddingTop + (childSpace / 2) - childBaseline;
//                    //     } else {
//                    //         childTop = paddingTop + (childSpace - childHeight) / 2;
//                    //     }
//                    // } else {
//                    childTop = paddingTop + ((childSpace - childHeight) / 2)
//                    + lp.topMargin - lp.bottomMargin;
//                    break;
//                    
//                case Gravity.BOTTOM:
//                    childTop = childBottom - childHeight - lp.bottomMargin;
//                    if (childBaseline != -1) {
//                        int descent = child.getMeasuredHeight() - childBaseline;
//                        childTop -= (maxDescent[INDEX_BOTTOM] - descent);
//                    }
//                    break;
//            }
//            
//            childLeft += lp.leftMargin;
//            setChildFrame(child, childLeft + getLocationOffset(child), childTop,
//                          childWidth, childHeight);
//            childLeft += childWidth + lp.rightMargin +
//            getNextLocationOffset(child);
//            
//            i += getChildrenSkipCount(child, i);
//        }
//    }
//}

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
@end
