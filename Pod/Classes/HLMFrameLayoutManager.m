//
//  HLMFrameLayoutManager.m
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "HLMFrameLayoutManager.h"

@implementation HLMFrameLayoutManager

-(void) measure:(UIView *) view
      widthSpec:(HLMMeasureSpec) widthMeasureSpec
     heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    uint32_t maxHeight = 0;
    uint32_t maxWidth = 0;
    for (UIView* child in view.subviews) {
        if (child.isHidden) {
            continue;
        }
        [HLMLayout measureChildWithMargins:child
                                  ofParent:view
                           parentWidthSpec:widthMeasureSpec
                                 widthUsed:0
                          parentHeightSpec:heightMeasureSpec
                                heightUsed:0];
        maxWidth = MAX(maxWidth, child.hlm_measuredWidth);
        maxHeight = MAX(maxHeight, child.hlm_measuredHeight);
    }
    UIEdgeInsets padding = view.hlm_padding;
    int32_t paddingLeft = padding.left;
    int32_t paddingRight = padding.right;
    int32_t paddingTop = padding.top;
    int32_t paddingBottom = padding.bottom;
    maxWidth += paddingLeft + paddingRight;
    maxHeight += paddingTop + paddingBottom;
    maxWidth = MAX(maxWidth, view.hlm_minWidth);
    maxHeight = MAX(maxHeight, view.hlm_minHeight);
    view.hlm_measuredWidth = [HLMLayout resolveSize:maxWidth spec:widthMeasureSpec];
    view.hlm_measuredHeight = [HLMLayout resolveSize:maxHeight spec:heightMeasureSpec];
}

-(void) layout:(UIView *) view
          left:(NSInteger) left
           top:(NSInteger) top
         right:(NSInteger) right
        bottom:(NSInteger) bottom {
    view.frame = CGRectMake(left, top, right - left, bottom - top);
    UIEdgeInsets padding = view.hlm_padding;
    int32_t paddingLeft = padding.left;
    int32_t paddingRight = padding.right;
    int32_t paddingTop = padding.top;
    int32_t paddingBottom = padding.bottom;
    NSInteger parentLeft = paddingLeft;
    NSInteger parentRight = right - left - paddingRight;
    NSInteger parentTop = paddingTop;
    NSInteger parentBottom = bottom - top - paddingBottom;
    for (UIView* child in view.subviews) {
        if (child.isHidden) {
            continue;
        }
        UIEdgeInsets margins = child.hlm_margins;
        int32_t marginLeft = margins.left;
        int32_t marginRight = margins.right;
        int32_t marginTop = margins.top;
        int32_t marginBottom = margins.bottom;
        CGFloat width = child.hlm_measuredWidth;
        CGFloat height = child.hlm_measuredHeight;
        NSInteger childLeft = parentLeft;
        NSInteger childTop = parentTop;
        HLMGravity gravity = child.hlm_layoutGravity;
        if (gravity) {
            HLMGravity horizontalGravity = gravity & HLMGravityHorizontalMask;
            HLMGravity verticalGravity = gravity & HLMGravityVerticalMask;
            switch (horizontalGravity) {
                case HLMGravityLeft:
                    childLeft = parentLeft + marginLeft;
                    break;
                case HLMGravityCenterHorizontal:
                    childLeft = parentLeft + (parentRight - parentLeft + marginLeft + marginRight - width) / 2;
                    break;
                case HLMGravityRight:
                    childLeft = parentRight - width - marginRight;
                    break;
                default:
                    childLeft = parentLeft + marginLeft;
            }
            switch (verticalGravity) {
                case HLMGravityTop:
                    childTop = parentTop + marginTop;
                    break;
                case HLMGravityCenterVertical:
                    childTop = parentTop + (parentBottom - parentTop + marginTop + marginBottom - height) / 2;
                    break;
                case HLMGravityBottom:
                    childTop = parentBottom - height - marginBottom;
                    break;
                default:
                    childTop = parentTop + marginTop;
            }
        }
        [HLMLayout setChild:child frame:CGRectMake(childLeft, childTop, width, height)];
    }
}

@end
