//
//  FLBFrameLayoutManager.m
//  Pods
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "FLBFrameLayoutManager.h"

@implementation FLBFrameLayoutManager

-(void) measure:(UIView *) view
      widthSpec:(FLBMeasureSpec) widthMeasureSpec
     heightSpec:(FLBMeasureSpec) heightMeasureSpec {
    uint32_t maxHeight = 0;
    uint32_t maxWidth = 0;
    for (UIView* child in view.subviews) {
        if (child.isHidden) {
            continue;
        }
        [FLBLayout measureChildWithMargins:child
                                  ofParent:view
                           parentWidthSpec:widthMeasureSpec
                                 widthUsed:0
                          parentHeightSpec:heightMeasureSpec
                                heightUsed:0];
        maxWidth = MAX(maxWidth, child.measuredWidth);
        maxHeight = MAX(maxHeight, child.measuredHeight);
    }
    UIEdgeInsets padding = view.flb_padding;
    int32_t paddingLeft = padding.left;
    int32_t paddingRight = padding.right;
    int32_t paddingTop = padding.top;
    int32_t paddingBottom = padding.bottom;
    maxWidth += paddingLeft + paddingRight;
    maxHeight += paddingTop + paddingBottom;
    maxWidth = MAX(maxWidth, view.minWidth);
    maxHeight = MAX(maxHeight, view.minHeight);
    view.measuredWidth = [FLBLayout resolveSize:maxWidth spec:widthMeasureSpec];
    view.measuredHeight = [FLBLayout resolveSize:maxHeight spec:heightMeasureSpec];
}

-(void) layout:(UIView *) view
          left:(NSInteger) left
           top:(NSInteger) top
         right:(NSInteger) right
        bottom:(NSInteger) bottom {
    view.frame = CGRectMake(left, top, right - left, bottom - top);
    UIEdgeInsets padding = view.flb_padding;
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
        UIEdgeInsets margins = child.flb_margins;
        int32_t marginLeft = margins.left;
        int32_t marginRight = margins.right;
        int32_t marginTop = margins.top;
        int32_t marginBottom = margins.bottom;
        CGFloat width = child.measuredWidth;
        CGFloat height = child.measuredHeight;
        NSInteger childLeft = parentLeft;
        NSInteger childTop = parentTop;
        FLBGravity gravity = child.layoutGravity;
        if (gravity) {
            FLBGravity horizontalGravity = gravity & FLBGravityHorizontalMask;
            FLBGravity verticalGravity = gravity & FLBGravityVerticalMask;
            switch (horizontalGravity) {
                case FLBGravityLeft:
                    childLeft = parentLeft + marginLeft;
                    break;
                case FLBGravityCenterHorizontal:
                    childLeft = parentLeft + (parentRight - parentLeft + marginLeft + marginRight - width) / 2;
                    break;
                case FLBGravityRight:
                    childLeft = parentRight - width - marginRight;
                    break;
                default:
                    childLeft = parentLeft + marginLeft;
            }
            switch (verticalGravity) {
                case FLBGravityTop:
                    childTop = parentTop + marginTop;
                    break;
                case FLBGravityCenterVertical:
                    childTop = parentTop + (parentBottom - parentTop + marginTop + marginBottom - height) / 2;
                    break;
                case FLBGravityBottom:
                    childTop = parentBottom - height - marginBottom;
                    break;
                default:
                    childTop = parentTop + marginTop;
            }
        }
        [FLBLayout setChild:child frame:CGRectMake(childLeft, childTop, width, height)];
    }
}

@end
