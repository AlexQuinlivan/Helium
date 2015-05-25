//
//  HLMRelativeLayoutManager.m
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "HLMRelativeLayoutManager.h"
#import "HLMAssociatedObjects.h"

@class HLMRelativeLayoutDependancyGraph;

typedef NS_ENUM(NSInteger, HLMRelativeLayoutVerb) {
    HLMRelativeLayoutVerbLeftOf,
    HLMRelativeLayoutVerbRightOf,
    HLMRelativeLayoutVerbAbove,
    HLMRelativeLayoutVerbBelow,
    HLMRelativeLayoutVerbAlignBaseline,
    HLMRelativeLayoutVerbAlignLeft,
    HLMRelativeLayoutVerbAlignTop,
    HLMRelativeLayoutVerbAlignRight,
    HLMRelativeLayoutVerbAlignBottom,
    HLMRelativeLayoutVerbAlignParentLeft,
    HLMRelativeLayoutVerbAlignParentTop,
    HLMRelativeLayoutVerbAlignParentRight,
    HLMRelativeLayoutVerbAlignParentBottom,
    HLMRelativeLayoutVerbCenterInParent,
    HLMRelativeLayoutVerbCenterHorizontal,
    HLMRelativeLayoutVerbCenterVertical,
    HLMRelativeLayoutVerbStartOf,
    HLMRelativeLayoutVerbEndOf,
    HLMRelativeLayoutVerbAlignStart,
    HLMRelativeLayoutVerbAlignEnd,
    HLMRelativeLayoutVerbAlignParentStart,
    HLMRelativeLayoutVerbAlignParentEnd,
    HLMRelativeLayoutVerbCount
};
static NSInteger const HLMRelativeLayoutVerbTrue = -1;
static NSArray* HLMRelativeLayoutRulesVertical;
static NSArray* HLMRelativeLayoutRulesHorizontal;

typedef struct HLMRelativeLayoutFrame {
    CGFloat top, left, bottom, right;
} HLMRelativeLayoutFrame;

static inline CGRect
CGRectFromHLMRelativeLayoutFrame(HLMRelativeLayoutFrame frame) {
    return CGRectMake(frame.left,
                      frame.top,
                      frame.right - frame.left,
                      frame.bottom - frame.top);
}

static inline HLMRelativeLayoutFrame
HLMRelativeLayoutFrameFromCGRect(CGRect frame) {
    HLMRelativeLayoutFrame outRect;
    outRect.left = frame.origin.x;
    outRect.top = frame.origin.y;
    outRect.right = outRect.left + frame.size.width;
    outRect.bottom = outRect.top + frame.size.height;
    return outRect;
}

@interface UIView (HLMRelativeLayoutManagerProperties)
@property (nonatomic) HLMRelativeLayoutFrame hlm_relativeLayoutSelfBounds;
@property (nonatomic) HLMRelativeLayoutFrame hlm_relativeLayoutContentBounds;
@property (nonatomic) HLMRelativeLayoutFrame hlm_relativeLayoutManagerFrame;
@property (nonatomic) BOOL hlm_relativeLayoutHasBaselineAlignedChild;
@property (nonatomic, strong) HLMRelativeLayoutDependancyGraph* hlm_relativeLayoutDependancyGraph;
@property (nonatomic, strong) NSArray* hlm_relativeLayoutSortedHorizontalChildren;
@property (nonatomic, strong) NSArray* hlm_relativeLayoutSortedVerticalChildren;
@property (nonatomic, strong) NSMutableArray* hlm_relativeLayoutRules;
@property (nonatomic, weak) UIView* hlm_relativeLayoutBaselineView;
@end

@interface NSMutableArray (HLMRelativeLayoutQueue)
-(id) pollLast;
@end

@interface HLMRelativeLayoutDependancyGraph : NSObject
-(void) clear;
-(void) addView:(UIView *) view;
-(NSArray *) sortedViewsForRules:(NSArray *) rules expectingSize:(NSUInteger) size;

@property (nonatomic, strong) NSMutableArray* nodes;
@property (nonatomic, strong) NSMutableDictionary* keyNodes;
@property (nonatomic, strong) NSMutableArray* roots;
@end

@interface HLMRelativeLayoutDependancyGraphNode : NSObject <NSCopying>
-(instancetype) initWithView:(UIView *) view;

@property (nonatomic, weak) UIView* view;
@property (nonatomic, strong) NSMutableDictionary* dependencies;
@property (nonatomic, strong) NSMutableDictionary* dependants;
@end

@implementation HLMRelativeLayoutManager

+(void) initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HLMRelativeLayoutRulesVertical = @[
            @(HLMRelativeLayoutVerbAbove),
            @(HLMRelativeLayoutVerbBelow),
            @(HLMRelativeLayoutVerbAlignBaseline),
            @(HLMRelativeLayoutVerbAlignTop),
            @(HLMRelativeLayoutVerbAlignBottom)
        ];
        HLMRelativeLayoutRulesVertical = @[
            @(HLMRelativeLayoutVerbLeftOf),
            @(HLMRelativeLayoutVerbRightOf),
            @(HLMRelativeLayoutVerbAlignLeft),
            @(HLMRelativeLayoutVerbAlignRight),
            @(HLMRelativeLayoutVerbStartOf),
            @(HLMRelativeLayoutVerbEndOf),
            @(HLMRelativeLayoutVerbAlignStart),
            @(HLMRelativeLayoutVerbAlignEnd)
        ];
    });
}

-(void) measure:(UIView *) view
      widthSpec:(HLMMeasureSpec) widthMeasureSpec
     heightSpec:(HLMMeasureSpec) heightMeasureSpec {
    [self sortChildren:view];
    
    int32_t myWidth = -1;
    int32_t myHeight = -1;
    
    int32_t width = 0;
    int32_t height = 0;
    
    HLMMeasureSpecMode const widthMode = [HLMLayout measureSpecMode:widthMeasureSpec];
    HLMMeasureSpecMode const heightMode = [HLMLayout measureSpecMode:heightMeasureSpec];
    uint32_t const widthSize = [HLMLayout measureSpecSize:widthMeasureSpec];
    uint32_t const heightSize = [HLMLayout measureSpecSize:heightMeasureSpec];
    
    // Record our dimensions if they are known;
    if (widthMode != HLMMeasureSpecUnspecified) {
        myWidth = widthSize;
    }
    
    if (heightMode != HLMMeasureSpecUnspecified) {
        myHeight = heightSize;
    }
    
    if (widthMode == HLMMeasureSpecExactly) {
        width = myWidth;
    }
    
    if (heightMode == HLMMeasureSpecExactly) {
        height = myHeight;
    }
    
    view.hlm_relativeLayoutHasBaselineAlignedChild = NO;
    
    UIView* ignore;
    HLMGravity gravity = view.hlm_gravity & HLMGravityHorizontalMask;
    BOOL const horizontalGravity = gravity != HLMGravityLeft && gravity != 0;
    gravity = view.hlm_gravity & HLMGravityVerticalMask;
    BOOL const verticalGravity = gravity != HLMGravityTop && gravity != 0;
    
    int32_t left = INT32_MAX;
    int32_t top = INT32_MAX;
    int32_t right = INT32_MIN;
    int32_t bottom = INT32_MIN;
    
    BOOL offsetHorizontalAxis = NO;
    BOOL offsetVerticalAxis = NO;
    
    if ((horizontalGravity || verticalGravity) && view.hlm_ignoreGravity) {
        ignore = [view viewWithTag:view.hlm_ignoreGravity.integerValue];
    }
    
    BOOL const isWrapContentWidth = widthMode != HLMMeasureSpecExactly;
    BOOL const isWrapContentHeight = heightMode != HLMMeasureSpecExactly;
    
    NSArray* views = view.hlm_relativeLayoutSortedHorizontalChildren;
    
    for (UIView* child in views) {
        if (!child.isHidden) {
            NSMutableArray* rules = child.hlm_relativeLayoutRules;
            
            [self applyHorizontalSizeRulesWithView:view
                                             child:child
                                             witdh:myWidth
                                             rules:rules];
            [self measureChildHorizontal:child
                                    view:view
                                   width:myWidth
                                  height:myHeight];
            
            if ([self positionChildHorizontal:child
                                         view:view
                                        width:myWidth
                             wrapContentWidth:isWrapContentWidth]) {
                offsetHorizontalAxis = YES;
            }
        }
    }
    
    views = view.hlm_relativeLayoutSortedVerticalChildren;
    
    for (UIView* child in views) {
        if (!child.isHidden) {
            
            [self applyVerticalSizeRulesWithView:view
                                           child:child
                                          height:myHeight];
            [self measureChild:child
                          view:view
                         width:myWidth
                        height:myHeight];
            if ([self positionChildVertical:child
                                       view:view
                                     height:myHeight
                          wrapContentHeight:isWrapContentHeight]) {
                offsetVerticalAxis = YES;
            }
            
            if (isWrapContentWidth) {
                width = MAX(width, child.hlm_relativeLayoutManagerFrame.right + child.hlm_marginRight);
            }
            
            if (isWrapContentHeight) {
                height = MAX(height, child.hlm_relativeLayoutManagerFrame.bottom + child.hlm_marginBottom);
            }
            
            if (child != ignore || verticalGravity) {
                left = MIN(left, child.hlm_relativeLayoutManagerFrame.left - child.hlm_marginLeft);
                top = MIN(top, child.hlm_relativeLayoutManagerFrame.top - child.hlm_marginTop);
            }
            
            if (child != ignore || horizontalGravity) {
                right = MAX(right, child.hlm_relativeLayoutManagerFrame.right + child.hlm_marginRight);
                bottom = MAX(bottom, child.hlm_relativeLayoutManagerFrame.bottom + child.hlm_marginBottom);
            }
        }
    }
    
    if (view.hlm_relativeLayoutHasBaselineAlignedChild) {
        for (UIView* child in view.subviews) {
            if (!child.isHidden) {
                [self alignBaseline:child inView:view];
                
                if (child != ignore || verticalGravity) {
                    left = MIN(left, child.hlm_relativeLayoutManagerFrame.left - child.hlm_marginLeft);
                    top = MIN(top, child.hlm_relativeLayoutManagerFrame.top - child.hlm_marginTop);
                }
                
                if (child != ignore || horizontalGravity) {
                    right = MAX(right, child.hlm_relativeLayoutManagerFrame.right + child.hlm_marginRight);
                    bottom = MAX(bottom, child.hlm_relativeLayoutManagerFrame.bottom + child.hlm_marginBottom);
                }
            }
        }
    }
    
    if (isWrapContentWidth) {
        // Width already has left padding in it since it was calculated by looking at
        // the right of each child view
        width += view.hlm_paddingRight;
        
        if (view.hlm_layoutWidth >= 0) {
            width = MAX(width, view.hlm_layoutWidth);
        }
        
        width = MAX(width, view.hlm_minWidth);
        width = [HLMLayout resolveSize:width spec:widthMeasureSpec];
        
        if (offsetHorizontalAxis) {
            for (UIView* child in view.subviews) {
                if (!child.isHidden) {
                    NSMutableArray* const rules = child.hlm_relativeLayoutRules;
                    if ([rules[HLMRelativeLayoutVerbCenterInParent] integerValue] != 0
                        || [rules[HLMRelativeLayoutVerbCenterHorizontal] integerValue] != 0) {
                        [self centerHorizontal:child
                                          view:view
                                         width:width];
                    } else if ([rules[HLMRelativeLayoutVerbAlignParentRight] integerValue] != 0) {
                        CGFloat const childWidth = child.hlm_measuredWidth;
                        HLMRelativeLayoutFrame frame = child.hlm_relativeLayoutManagerFrame;
                        frame.left = width - view.hlm_paddingRight - childWidth;
                        frame.right = frame.left + childWidth;
                        child.hlm_relativeLayoutManagerFrame = frame;
                    }
                }
            }
        }
    }
    
    if (isWrapContentHeight) {
        // Height already has top padding in it since it was calculated by looking at
        // the bottom of each child view
        height += view.hlm_paddingBottom;
        
        if (view.hlm_layoutHeight >= 0) {
            height = MAX(height, view.hlm_layoutHeight);
        }
        
        height = MAX(height, view.hlm_minHeight);
        height = [HLMLayout resolveSize:height spec:heightMeasureSpec];
        
        if (offsetVerticalAxis) {
            for (UIView* child in view.subviews) {
                if (!child.isHidden) {
                    NSMutableArray* const rules = child.hlm_relativeLayoutRules;
                    if ([rules[HLMRelativeLayoutVerbCenterInParent] integerValue] != 0
                        || [rules[HLMRelativeLayoutVerbCenterVertical] integerValue] != 0) {
                        [self centerVertical:child
                                        view:view
                                      height:height];
                    } else if ([rules[HLMRelativeLayoutVerbAlignParentBottom] integerValue] != 0) {
                        CGFloat const childHeight = child.hlm_measuredHeight;
                        HLMRelativeLayoutFrame frame = child.hlm_relativeLayoutManagerFrame;
                        frame.top = height - view.hlm_paddingBottom - childHeight;
                        frame.bottom = frame.top + childHeight;
                        child.hlm_relativeLayoutManagerFrame = frame;
                    }
                }
            }
        }
    }
    
    if (horizontalGravity || verticalGravity) {
        HLMRelativeLayoutFrame selfBounds = view.hlm_relativeLayoutSelfBounds;
        selfBounds.left = view.hlm_paddingLeft;
        selfBounds.top = view.hlm_paddingTop;
        selfBounds.right = width - view.hlm_paddingRight;
        selfBounds.bottom = height - view.hlm_paddingBottom;
        view.hlm_relativeLayoutSelfBounds = selfBounds;
        
        CGRect contentRect = [HLMLayout applyGravity:view.hlm_gravity
                                         toContainer:CGRectFromHLMRelativeLayoutFrame(view.hlm_relativeLayoutContentBounds)
                                               width:right - left
                                              height:bottom - top];
        HLMRelativeLayoutFrame contentBounds = HLMRelativeLayoutFrameFromCGRect(contentRect);
        view.hlm_relativeLayoutContentBounds = contentBounds;
        
        int32_t const horizontalOffset = contentBounds.left - left;
        int32_t const verticalOffset = contentBounds.top - top;
        if (horizontalOffset != 0 || verticalOffset != 0) {
            for (UIView* child in view.subviews) {
                if (!child.isHidden && child != ignore) {
                    if (horizontalGravity) {
                        HLMRelativeLayoutFrame frame = child.hlm_relativeLayoutManagerFrame;
                        frame.left += horizontalOffset;
                        frame.right += horizontalOffset;
                        child.hlm_relativeLayoutManagerFrame = frame;
                    }
                    if (verticalGravity) {
                        HLMRelativeLayoutFrame frame = child.hlm_relativeLayoutManagerFrame;
                        frame.top += verticalOffset;
                        frame.bottom += verticalOffset;
                        child.hlm_relativeLayoutManagerFrame = frame;
                    }
                }
            }
        }
    }
    
    view.hlm_measuredWidth = width;
    view.hlm_measuredHeight = height;
}

-(void) sortChildren:(UIView *) view {
    HLMRelativeLayoutDependancyGraph* const graph = view.hlm_relativeLayoutDependancyGraph;
    [graph clear];
    
    for (UIView* child in view.subviews) {
        [graph addView:child];
    }
    
    NSUInteger const count = view.subviews.count;
    view.hlm_relativeLayoutSortedVerticalChildren = [graph sortedViewsForRules:HLMRelativeLayoutRulesVertical expectingSize:count];
    view.hlm_relativeLayoutSortedHorizontalChildren = [graph sortedViewsForRules:HLMRelativeLayoutRulesHorizontal expectingSize:count];
}

-(void) applyHorizontalSizeRulesWithView:(UIView *) view
                                   child:(UIView *) child
                                   witdh:(int32_t) myWidth
                                   rules:(NSMutableArray *) rules {
    // -1 indicated a "soft requirement" in that direction. For example:
    // left=10, right=-1 means the view must start at 10, but can go as far as it wants to the right
    // left =-1, right=10 means the view must end at 10, but can go as far as it wants to the left
    // left=10, right=20 means the left and right ends are both fixed
    HLMRelativeLayoutFrame childFrame = child.hlm_relativeLayoutManagerFrame;
    childFrame.left = -1;
    childFrame.right = -1;
    
    UIView* anchorView = [self relatedViewInView:view
                                           rules:rules
                                        relation:HLMRelativeLayoutVerbLeftOf];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.right = anchorFrame.left - (anchorView.hlm_marginLeft + child.hlm_marginRight);
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbLeftOf] integerValue] != 0) {
        if (myWidth >= 0) {
            childFrame.right = myWidth - view.hlm_paddingRight - child.hlm_marginRight;
        }
    }
    
    anchorView = [self relatedViewInView:view
                                   rules:rules
                                relation:HLMRelativeLayoutVerbRightOf];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.left = anchorFrame.right + (anchorView.hlm_marginRight + child.hlm_marginLeft);
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbRightOf] integerValue] != 0) {
        childFrame.left = view.hlm_paddingLeft + child.hlm_marginLeft;
    }
    
    anchorView = [self relatedViewInView:view
                                   rules:rules
                                relation:HLMRelativeLayoutVerbAlignLeft];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.left = anchorFrame.left + child.hlm_marginLeft;
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbAlignLeft] integerValue] != 0) {
        childFrame.left = view.hlm_paddingLeft + child.hlm_marginLeft;
    }
    
    anchorView = [self relatedViewInView:view
                                   rules:rules
                                relation:HLMRelativeLayoutVerbAlignRight];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.right = anchorFrame.right - child.hlm_marginRight;
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbAlignRight] integerValue] != 0) {
        if (myWidth >= 0) {
            childFrame.right = myWidth - view.hlm_paddingRight - child.hlm_marginRight;
        }
    }
    
    if (0 != [rules[HLMRelativeLayoutVerbAlignParentLeft] integerValue]) {
        childFrame.left = view.hlm_paddingLeft + child.hlm_marginLeft;
    }
    
    if (0 != [rules[HLMRelativeLayoutVerbAlignParentRight] integerValue]) {
        if (myWidth >= 0) {
            childFrame.right = myWidth - view.hlm_paddingRight - child.hlm_marginRight;
        }
    }
    
    child.hlm_relativeLayoutManagerFrame = childFrame;
}

-(void) applyVerticalSizeRulesWithView:(UIView *) view
                                 child:(UIView *) child
                                height:(int32_t) myHeight {
    NSArray* rules = child.hlm_relativeLayoutRules;
    
    HLMRelativeLayoutFrame childFrame = child.hlm_relativeLayoutManagerFrame;
    childFrame.top = -1;
    childFrame.bottom = -1;
    
    UIView* anchorView = [self relatedViewInView:view
                                           rules:rules
                                        relation:HLMRelativeLayoutVerbAbove];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.bottom = anchorFrame.top - (anchorView.hlm_marginTop + child.hlm_marginBottom);
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbAbove] integerValue] != 0) {
        if (myHeight >= 0) {
            childFrame.bottom = myHeight - view.hlm_paddingBottom - child.hlm_marginBottom;
        }
    }
    
    anchorView = [self relatedViewInView:view
                                   rules:rules
                                relation:HLMRelativeLayoutVerbBelow];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.top = anchorFrame.bottom + (anchorView.hlm_marginBottom + child.hlm_marginTop);
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbBelow] integerValue] != 0) {
        childFrame.top = view.hlm_paddingTop + child.hlm_marginTop;
    }
    
    anchorView = [self relatedViewInView:view
                                   rules:rules
                                relation:HLMRelativeLayoutVerbAlignTop];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.top = anchorFrame.top + child.hlm_marginTop;
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbAlignTop] integerValue] != 0) {
        childFrame.top = view.hlm_paddingTop + child.hlm_marginTop;
    }
    
    anchorView = [self relatedViewInView:view
                                   rules:rules
                                relation:HLMRelativeLayoutVerbAlignBottom];
    if (anchorView) {
        HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
        childFrame.bottom = anchorFrame.bottom - child.hlm_marginBottom;
    } else if (child.hlm_layoutAlignWithParentIfMissing
               && [rules[HLMRelativeLayoutVerbAlignBottom] integerValue] != 0) {
        if (myHeight >= 0) {
            childFrame.bottom = myHeight - view.hlm_paddingBottom - child.hlm_marginBottom;
        }
    }
    
    if (0 != [rules[HLMRelativeLayoutVerbAlignParentTop] integerValue]) {
        childFrame.top = view.hlm_paddingTop + child.hlm_marginTop;
    }
    
    if (0 != [rules[HLMRelativeLayoutVerbAlignParentBottom] integerValue]) {
        if (myHeight >= 0) {
            childFrame.bottom = myHeight - view.hlm_paddingBottom - child.hlm_marginBottom;
        }
    }
    
    if (0 != [rules[HLMRelativeLayoutVerbAlignBaseline] integerValue]) {
        view.hlm_relativeLayoutHasBaselineAlignedChild = YES;
    }
    
    child.hlm_relativeLayoutManagerFrame = childFrame;

}

-(void) measureChildHorizontal:(UIView *) child
                          view:(UIView *) view
                         width:(int32_t) myWidth
                        height:(int32_t) myHeight {
    HLMRelativeLayoutFrame childFrame = child.hlm_relativeLayoutManagerFrame;
    HLMMeasureSpec childWidthMeasureSpec = [self childMeasureSpecChildStart:childFrame.left
                                                                   childEnd:childFrame.right
                                                                  childSize:child.hlm_layoutWidth
                                                                startMargin:child.hlm_marginLeft
                                                                  endMargin:child.hlm_marginRight
                                                               startPadding:view.hlm_paddingLeft
                                                                 endPadding:view.hlm_paddingRight
                                                                     mySize:myWidth];
    int32_t maxHeight = MAX(0, myHeight - view.hlm_paddingTop - view.hlm_paddingBottom -
                                 child.hlm_marginTop - child.hlm_marginBottom);
    HLMMeasureSpec childHeightMeasureSpec;
    if (myHeight < 0) {
        if (child.hlm_layoutHeight >= 0) {
            childHeightMeasureSpec = [HLMLayout measureSpecWithSize:child.hlm_layoutHeight mode:HLMMeasureSpecExactly];
        } else {
            // Negative values in a mySize/myWidth/myWidth value in RelativeLayout measurement
            // is code for, "we got an unspecified mode in the RelativeLayout's measurespec."
            // Carry it forward.
            childHeightMeasureSpec = [HLMLayout measureSpecWithSize:0 mode:HLMMeasureSpecUnspecified];
        }
    } else if (child.hlm_layoutWidth == HLMLayoutParamMatch) {
        childHeightMeasureSpec = [HLMLayout measureSpecWithSize:maxHeight mode:HLMMeasureSpecExactly];
    } else {
        childHeightMeasureSpec = [HLMLayout measureSpecWithSize:maxHeight mode:HLMMeasureSpecAtMost];
    }
    [HLMLayout measureView:child
                 widthSpec:childWidthMeasureSpec
                heightSpec:childHeightMeasureSpec];
}

-(void) measureChild:(UIView *) child
                view:(UIView *) view
               width:(int32_t) myWidth
              height:(int32_t) myHeight {
    HLMRelativeLayoutFrame const childFrame = child.hlm_relativeLayoutManagerFrame;
    HLMMeasureSpec const childWidthMeasureSpec = [self childMeasureSpecChildStart:childFrame.left
                                                                         childEnd:childFrame.right
                                                                        childSize:child.hlm_layoutWidth
                                                                      startMargin:child.hlm_marginLeft
                                                                        endMargin:child.hlm_marginRight
                                                                     startPadding:view.hlm_paddingLeft
                                                                       endPadding:view.hlm_paddingRight
                                                                           mySize:myWidth];
    HLMMeasureSpec const childHeightMeasureSpec = [self childMeasureSpecChildStart:childFrame.top
                                                                          childEnd:childFrame.bottom
                                                                         childSize:child.hlm_layoutHeight
                                                                       startMargin:child.hlm_marginTop
                                                                         endMargin:child.hlm_marginBottom
                                                                      startPadding:view.hlm_paddingTop
                                                                        endPadding:view.hlm_paddingBottom
                                                                            mySize:myHeight];
    [HLMLayout measureView:child
                 widthSpec:childWidthMeasureSpec
                heightSpec:childHeightMeasureSpec];
}

-(HLMMeasureSpec) childMeasureSpecChildStart:(int32_t) childStart
                                    childEnd:(int32_t) childEnd
                                   childSize:(int32_t) childSize
                                 startMargin:(int32_t) startMargin
                                   endMargin:(int32_t) endMargin
                                startPadding:(int32_t) startPadding
                                  endPadding:(int32_t) endPadding
                                      mySize:(int32_t) mySize {
    if (mySize < 0) {
        if (childSize >= 0) {
            return [HLMLayout measureSpecWithSize:childSize mode:HLMMeasureSpecExactly];
        }
        // Negative values in a mySize/myWidth/myWidth value in RelativeLayout measurement
        // is code for, "we got an unspecified mode in the RelativeLayout's measurespec."
        // Carry it forward.
        return [HLMLayout measureSpecWithSize:0 mode:HLMMeasureSpecUnspecified];
    }
    
    HLMMeasureSpecMode childSpecMode = 0;
    int32_t childSpecSize = 0;
    
    // Figure out start and end bounds.
    int32_t tempStart = childStart;
    int32_t tempEnd = childEnd;
    
    // If the view did not express a layout constraint for an edge, use
    // view's margins and our padding
    if (tempStart < 0) {
        tempStart = startPadding + startMargin;
    }
    if (tempEnd < 0) {
        tempEnd = mySize - endPadding - endMargin;
    }
    
    // Figure out maximum size available to this view
    int32_t maxAvailable = tempEnd - tempStart;
    
    if (childStart >= 0 && childEnd >= 0) {
        // Constraints fixed both edges, so child must be an exact size
        childSpecMode = HLMMeasureSpecExactly;
        childSpecSize = maxAvailable;
    } else {
        if (childSize >= 0) {
            // Child wanted an exact size. Give as much as possible
            childSpecMode = HLMMeasureSpecExactly;
            
            if (maxAvailable >= 0) {
                // We have a maxmum size in this dimension.
                childSpecSize = MIN(maxAvailable, childSize);
            } else {
                // We can grow in this dimension.
                childSpecSize = childSize;
            }
        } else if (childSize == HLMLayoutParamMatch) {
            // Child wanted to be as big as possible. Give all available
            // space
            childSpecMode = HLMMeasureSpecExactly;
            childSpecSize = maxAvailable;
        } else if (childSize == HLMLayoutParamWrap) {
            // Child wants to wrap content. Use AT_MOST
            // to communicate available space if we know
            // our max size
            if (maxAvailable >= 0) {
                // We have a maximum size in this dimension.
                childSpecMode = HLMMeasureSpecAtMost;
                childSpecSize = maxAvailable;
            } else {
                // We can grow in this dimension. Child can be as big as it
                // wants
                childSpecMode = HLMMeasureSpecUnspecified;
                childSpecSize = 0;
            }
        }
    }
    
    return [HLMLayout measureSpecWithSize:childSpecSize mode:childSpecMode];
}

-(BOOL) positionChildHorizontal:(UIView *) child
                           view:(UIView *) view
                          width:(int32_t) myWidth
               wrapContentWidth:(BOOL) wrapContent {
    NSArray* rules = child.hlm_relativeLayoutRules;
    HLMRelativeLayoutFrame childFrame = child.hlm_relativeLayoutManagerFrame;
    
    if (childFrame.left < 0 && childFrame.right >= 0) {
        // Right is fixed, but left varies
        childFrame.left = childFrame.right - child.hlm_measuredWidth;
    } else if (childFrame.left >= 0 && childFrame.right < 0) {
        // Left is fixed, but right varies
        childFrame.right = childFrame.left + child.hlm_measuredWidth;
    } else if (childFrame.left < 0 && childFrame.right < 0) {
        // Both left and right vary
        if ([rules[HLMRelativeLayoutVerbCenterInParent] integerValue] != 0
            || [rules[HLMGravityCenterHorizontal] integerValue] != 0) {
            if (!wrapContent) {
                [self centerHorizontal:child
                                  view:view
                                 width:myWidth];
            } else {
                childFrame.left = view.hlm_paddingLeft + child.hlm_marginLeft;
                childFrame.right = childFrame.left + child.hlm_measuredWidth;
                child.hlm_relativeLayoutManagerFrame = childFrame;
            }
            return YES;
        } else {
            // This is the default case.
            childFrame.left = view.hlm_paddingLeft + child.hlm_marginLeft;
            childFrame.right = childFrame.left + child.hlm_measuredWidth;
        }
    }
    child.hlm_relativeLayoutManagerFrame = childFrame;
    return [rules[HLMRelativeLayoutVerbAlignParentEnd] integerValue] != 0;
}

-(BOOL) positionChildVertical:(UIView *) child
                         view:(UIView *) view
                       height:(int32_t) myHeight
            wrapContentHeight:(BOOL) wrapContent {
    NSArray* rules = child.hlm_relativeLayoutRules;
    HLMRelativeLayoutFrame childFrame = child.hlm_relativeLayoutManagerFrame;

    if (childFrame.top < 0 && childFrame.bottom >= 0) {
        // Bottom is fixed, but top varies
        childFrame.top = childFrame.bottom - child.hlm_measuredHeight;
    } else if (childFrame.top >= 0 && childFrame.bottom < 0) {
        // Top is fixed, but bottom varies
        childFrame.bottom = childFrame.top + child.hlm_measuredHeight;
    } else if (childFrame.top < 0 && childFrame.bottom < 0) {
        // Both top and bottom vary
        if ([rules[HLMRelativeLayoutVerbCenterInParent] integerValue] != 0
            || [rules[HLMGravityCenterVertical] integerValue] != 0) {
            if (!wrapContent) {
                [self centerHorizontal:child
                                  view:view
                                 width:myHeight];
            } else {
                childFrame.top = view.hlm_paddingTop + child.hlm_marginTop;
                childFrame.bottom = childFrame.top + child.hlm_measuredHeight;
            }
            return YES;
        } else {
            childFrame.top = view.hlm_paddingTop + child.hlm_marginTop;
            childFrame.bottom = childFrame.top + child.hlm_measuredHeight;
        }
    }
    child.hlm_relativeLayoutManagerFrame = childFrame;
    return [rules[HLMRelativeLayoutVerbAlignParentBottom] integerValue] != 0;
}

-(void) alignBaseline:(UIView *) child inView:(UIView *) view {
    NSArray* const rules = child.hlm_relativeLayoutRules;
    HLMRelativeLayoutFrame childFrame = child.hlm_relativeLayoutManagerFrame;
    int32_t const anchorBaseline = [self relatedViewBaselineInView:view
                                                             rules:rules
                                                          relation:HLMRelativeLayoutVerbAlignBaseline];
    
    if (anchorBaseline != -1 /* && false @todo: not this */) {
        UIView* const anchorView = [self relatedViewInView:view
                                                     rules:rules
                                                  relation:HLMRelativeLayoutVerbAlignBaseline];
        if (anchorView) {
            HLMRelativeLayoutFrame const anchorFrame = anchorView.hlm_relativeLayoutManagerFrame;
            int32_t offset = anchorFrame.top + anchorBaseline;
            int32_t const baseline = -1/* @todo: child.hlm_baseline */;
            if (baseline != -1) {
                offset -= baseline;
            }
            int32_t const height = childFrame.bottom - childFrame.top;
            childFrame.top = offset;
            childFrame.bottom = childFrame.top + height;
            child.hlm_relativeLayoutManagerFrame = childFrame;
        }
    }
    
    if (!view.hlm_relativeLayoutBaselineView) {
        view.hlm_relativeLayoutBaselineView = child;
    } else {
        HLMRelativeLayoutFrame baselineFrame = view.hlm_relativeLayoutBaselineView.hlm_relativeLayoutManagerFrame;
        if (childFrame.top < baselineFrame.top
            || (childFrame.top == baselineFrame.top && childFrame.left < baselineFrame.left)) {
            view.hlm_relativeLayoutBaselineView = child;
        }
    }
}

-(UIView *) relatedViewInView:(UIView *) view rules:(NSArray *) rules relation:(HLMRelativeLayoutVerb) relation {
    HLMRelativeLayoutDependancyGraph* const graph = view.hlm_relativeLayoutDependancyGraph;
    NSNumber* const tag = rules[relation];
    if (tag.integerValue != 0) {
        HLMRelativeLayoutDependancyGraphNode* node = graph.keyNodes[tag];
        if (!node) {
            return nil;
        }
        UIView* v = node.view;
        
        // Find the first non-hidden view up the chain
        while (v.isHidden) {
            rules = v.hlm_relativeLayoutRules;
            node = graph.keyNodes[rules[relation]];
            if (!node) {
                return nil;
            }
            v = node.view;
        }
        
        return v;
    }
    
    return nil;
}

-(int32_t) relatedViewBaselineInView:(UIView *) view rules:(NSArray *) rules relation:(HLMRelativeLayoutVerb) relation {
    UIView* related = [self relatedViewInView:view
                                        rules:rules
                                     relation:relation];
    if (related) {
        // @todo: implement baseline
        // return related.hlm_baseline;
    }
    return -1;
}

-(void) centerHorizontal:(UIView *) child view:(UIView *) view width:(int32_t) myWidth {
    CGFloat const childWidth = child.hlm_measuredWidth;
    int32_t const left = (myWidth - childWidth) / 2;
    
    HLMRelativeLayoutFrame frame = child.hlm_relativeLayoutManagerFrame;
    frame.left = left;
    frame.right = left + childWidth;
    child.hlm_relativeLayoutManagerFrame = frame;
}

-(void) centerVertical:(UIView *) child view:(UIView *) view height:(int32_t) myHeight {
    CGFloat const childHeight = child.hlm_measuredHeight;
    int32_t const top = (myHeight - childHeight) / 2;
    
    HLMRelativeLayoutFrame frame = child.hlm_relativeLayoutManagerFrame;
    frame.top = top;
    frame.bottom = top + childHeight;
    child.hlm_relativeLayoutManagerFrame = frame;
}

-(void) layout:(UIView *) view
          left:(NSInteger) left
           top:(NSInteger) top
         right:(NSInteger) right
        bottom:(NSInteger) bottom {
    view.frame = CGRectMake(left, top, right - left, bottom - top);
    //  The layout has actually already been performed and the positions
    //  cached.  Apply the cached values to the children.
    for (UIView* child in view.subviews) {
        if (!child.isHidden) {
            HLMRelativeLayoutFrame layoutFrame = child.hlm_relativeLayoutManagerFrame;
            CGRect frame = CGRectIntegral(CGRectFromHLMRelativeLayoutFrame(layoutFrame));
            [HLMLayout setChild:child frame:frame];
        }
    }
}

@end

@implementation UIView (HLMRelativeLayoutManagerProperties)

ASSOCIATED_PROPERTY(hlm_relativeLayoutManagerFrame, Hlm_relativeLayoutManagerFrame);
-(void) setHlm_relativeLayoutManagerFrame:(HLMRelativeLayoutFrame) hlm_relativeLayoutManagerFrame {
    NSValue* value = [NSValue valueWithBytes:&hlm_relativeLayoutManagerFrame objCType:@encode(HLMRelativeLayoutFrame)];
    objc_setAssociatedObject(self, &kHlm_relativeLayoutManagerFrameAssociationKey,
                             value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(HLMRelativeLayoutFrame) hlm_relativeLayoutManagerFrame {
    HLMRelativeLayoutFrame frame;
    NSValue* value = objc_getAssociatedObject(self, &kHlm_relativeLayoutManagerFrameAssociationKey);
    [value getValue:&frame];
    return frame;
}

ASSOCIATED_PROPERTY(hlm_relativeLayoutSelfBounds, Hlm_relativeLayoutSelfBounds);
-(void) setHlm_relativeLayoutSelfBounds:(HLMRelativeLayoutFrame) hlm_relativeLayoutSelfBounds {
    NSValue* value = [NSValue valueWithBytes:&hlm_relativeLayoutSelfBounds objCType:@encode(HLMRelativeLayoutFrame)];
    objc_setAssociatedObject(self, &kHlm_relativeLayoutSelfBoundsAssociationKey,
                             value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(HLMRelativeLayoutFrame) hlm_relativeLayoutSelfBounds {
    HLMRelativeLayoutFrame frame;
    NSValue* value = objc_getAssociatedObject(self, &kHlm_relativeLayoutSelfBoundsAssociationKey);
    [value getValue:&frame];
    return frame;
}

ASSOCIATED_PROPERTY(hlm_relativeLayoutContentBounds, Hlm_relativeLayoutContentBounds);
-(void) setHlm_relativeLayoutContentBounds:(HLMRelativeLayoutFrame) hlm_relativeLayoutContentBounds {
    NSValue* value = [NSValue valueWithBytes:&hlm_relativeLayoutContentBounds objCType:@encode(HLMRelativeLayoutFrame)];
    objc_setAssociatedObject(self, &kHlm_relativeLayoutContentBoundsAssociationKey,
                             value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(HLMRelativeLayoutFrame) hlm_relativeLayoutContentBounds {
    HLMRelativeLayoutFrame frame;
    NSValue* value = objc_getAssociatedObject(self, &kHlm_relativeLayoutContentBoundsAssociationKey);
    [value getValue:&frame];
    return frame;
}

ASSOCIATED_PROPERTY(hlm_relativeLayoutDependancyGraph, Hlm_relativeLayoutDependancyGraph);
-(void) setHlm_relativeLayoutDependancyGraph:(HLMRelativeLayoutDependancyGraph *) hlm_relativeLayoutDependancyGraph {
    objc_setAssociatedObject(self, &kHlm_relativeLayoutDependancyGraphAssociationKey,
                             hlm_relativeLayoutDependancyGraph, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(HLMRelativeLayoutDependancyGraph *) hlm_relativeLayoutDependancyGraph {
    HLMRelativeLayoutDependancyGraph* graph = objc_getAssociatedObject(self, &kHlm_relativeLayoutDependancyGraphAssociationKey);
    if (!graph) {
        graph = [HLMRelativeLayoutDependancyGraph new];
        self.hlm_relativeLayoutDependancyGraph = graph;
    }
    return graph;
}

ASSOCIATED_PROPERTY(hlm_relativeLayoutRules, Hlm_relativeLayoutRules);
-(void) setHlm_relativeLayoutRules:(NSMutableArray *) hlm_relativeLayoutRules {
    objc_setAssociatedObject(self, &kHlm_relativeLayoutRulesAssociationKey,
                             hlm_relativeLayoutRules, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSMutableArray *) hlm_relativeLayoutRules {
    NSMutableArray* rules = objc_getAssociatedObject(self, &kHlm_relativeLayoutRulesAssociationKey);
    if (!rules) {
        rules = [NSMutableArray arrayWithCapacity:HLMRelativeLayoutVerbCount];
        rules[HLMRelativeLayoutVerbLeftOf] = @(self.hlm_layoutToLeftOf);
        rules[HLMRelativeLayoutVerbRightOf] = @(self.hlm_layoutToRightOf);
        rules[HLMRelativeLayoutVerbAbove] = @(self.hlm_layoutAbove);
        rules[HLMRelativeLayoutVerbBelow] = @(self.hlm_layoutBelow);
        rules[HLMRelativeLayoutVerbAlignBaseline] = @(self.hlm_layoutAlignBaseline);
        rules[HLMRelativeLayoutVerbAlignLeft] = @(self.hlm_layoutAlignLeft);
        rules[HLMRelativeLayoutVerbAlignTop] = @(self.hlm_layoutAlignTop);
        rules[HLMRelativeLayoutVerbAlignRight] = @(self.hlm_layoutAlignRight);
        rules[HLMRelativeLayoutVerbAlignBottom] = @(self.hlm_layoutAlignBottom);
        rules[HLMRelativeLayoutVerbAlignParentLeft] = @(self.hlm_layoutAlignParentLeft ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbAlignParentTop] = @(self.hlm_layoutAlignParentTop ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbAlignParentRight] = @(self.hlm_layoutAlignParentRight ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbAlignParentBottom] = @(self.hlm_layoutAlignParentBottom ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbCenterInParent] = @(self.hlm_layoutCenterInParent ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbCenterHorizontal] = @(self.hlm_layoutCenterHorizontal ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbCenterVertical] = @(self.hlm_layoutCenterVertical ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbStartOf] = @(self.hlm_layoutToStartOf);
        rules[HLMRelativeLayoutVerbEndOf] = @(self.hlm_layoutToEndOf);
        rules[HLMRelativeLayoutVerbAlignStart] = @(self.hlm_layoutAlignStart);
        rules[HLMRelativeLayoutVerbAlignEnd] = @(self.hlm_layoutAlignEnd);
        rules[HLMRelativeLayoutVerbAlignParentStart] = @(self.hlm_layoutAlignParentStart ? HLMRelativeLayoutVerbTrue : 0);
        rules[HLMRelativeLayoutVerbAlignParentEnd] = @(self.hlm_layoutAlignParentEnd ? HLMRelativeLayoutVerbTrue : 0);
        self.hlm_relativeLayoutRules = rules;
    }
    return rules;
}


ASSOCIATED_PROPERTY(hlm_relativeLayoutBaselineView, Hlm_relativeLayoutBaselineView);
ASSOCIATED_ACCESSOR(UIView*, hlm_relativeLayoutBaselineView, self, &kHlm_relativeLayoutBaselineViewAssociationKey);
-(void) setHlm_relativeLayoutBaselineView:(UIView *) hlm_relativeLayoutBaselineView {
    objc_setAssociatedObject(self, &kHlm_relativeLayoutBaselineViewAssociationKey,
                             hlm_relativeLayoutBaselineView, OBJC_ASSOCIATION_ASSIGN);
}

ASSOCIATE_OBJECT(NSArray, hlm_relativeLayoutSortedHorizontalChildren, Hlm_relativeLayoutSortedHorizontalChildren);
ASSOCIATE_OBJECT(NSArray, hlm_relativeLayoutSortedVerticalChildren, Hlm_relativeLayoutSortedVerticalChildren);
ASSOCIATE_NUMBER(BOOL, hlm_relativeLayoutHasBaselineAlignedChild, Hlm_relativeLayoutHasBaselineAlignedChild, boolValue);

@end

@implementation HLMRelativeLayoutDependancyGraph

-(instancetype) init {
    if (self = [super init]) {
        self.nodes = [NSMutableArray new];
        self.keyNodes = [NSMutableDictionary new];
        self.roots = [NSMutableArray new];
    }
    return self;
}

-(void) clear {
    [self.nodes removeAllObjects];
    [self.keyNodes removeAllObjects];
    [self.roots removeAllObjects];
}

-(void) addView:(UIView *) view {
    NSUInteger const tag = view.tag;
    HLMRelativeLayoutDependancyGraphNode* node = [[HLMRelativeLayoutDependancyGraphNode alloc] initWithView:view];
    
    if (tag != 0) {
        self.keyNodes[@(tag)] = node;
    }
    
    [self.nodes addObject:node];
}

-(NSArray *) sortedViewsForRules:(NSArray *) rules expectingSize:(NSUInteger) size {
    NSMutableArray* roots = [self findRoots:rules];
    NSMutableArray* sorted = [NSMutableArray new];
    NSUInteger index = 0;
    
    HLMRelativeLayoutDependancyGraphNode* node;
    while ((node = roots.pollLast)) {
        UIView* const view = node.view;
        NSUInteger key = view.tag;
        
        [sorted addObject:view];
        index++;
        
        NSMutableDictionary* const dependents = node.dependants;
        NSUInteger const count = dependents.count;
        for (NSUInteger i = 0; i < count; i++) {
            HLMRelativeLayoutDependancyGraphNode* const dependent = dependents.allKeys[i];
            NSMutableDictionary* dependencies = dependent.dependencies;
            
            [dependencies removeObjectForKey:@(key)];
            if (!dependencies.count) {
                [roots addObject:dependent];
            }
        }
    }
    
    if (index < size) {
        @throw [NSException exceptionWithName:@"HLMRelativeLayoutIllegalStateException"
                                       reason:@"Circular dependencies cannot exist in RelativeLayout"
                                     userInfo:nil];
    }
    
    return sorted;
}

-(NSMutableArray *) findRoots:(NSArray *) rulesFilter {
    NSMutableArray* const nodes = self.nodes;
    NSUInteger const count = nodes.count;
    
    // Find roots can be invoked several times, so make sure to clear
    // all dependents and dependencies before running the algorithm
    for (NSUInteger i = 0; i < count; i++) {
        HLMRelativeLayoutDependancyGraphNode* const node = nodes[i];
        [node.dependants removeAllObjects];
        [node.dependencies removeAllObjects];
    }
    
    // Builds up the dependents and dependencies for each node of the graph
    for (NSUInteger i = 0; i < count; i++) {
        HLMRelativeLayoutDependancyGraphNode* const node = nodes[i];
        
        NSMutableArray* const rules = node.view.hlm_relativeLayoutRules;
        NSUInteger const rulesCount = rulesFilter.count;
        
        // Look only the the rules passed in parameter, this way we build only the
        // dependencies for a specific set of rules
        for (NSUInteger j = 0; j < rulesCount; j++) {
            NSNumber* const filterRule = rulesFilter[j];
            NSNumber* const rule = rules[filterRule.integerValue];
            if (rule.integerValue > 0) {
                // The node this node depends on
                HLMRelativeLayoutDependancyGraphNode* const dependency = self.keyNodes[rule];
                // Skip unknowns and self dependencies
                if (!dependency || dependency == node) {
                    continue;
                }
                // Add the current node as a dependent
                dependency.dependants[node] = self;
                // Add a dependency to the current node
                node.dependencies[rule] = dependency;
            }
        }
    }
    
    NSMutableArray* const roots = self.roots;
    [roots removeAllObjects];
    
    // Finds all the roots in the graph: all nodes with no dependencies
    for (NSUInteger i = 0; i < count; i++) {
        HLMRelativeLayoutDependancyGraphNode* const node = nodes[i];
        if (!node.dependencies.count) {
            [roots addObject:node];
        }
    }
    
    return roots;
}

@end

@implementation HLMRelativeLayoutDependancyGraphNode

-(instancetype) initWithView:(UIView *) view {
    if (self = [super init]) {
        self.view = view;
        self.dependants = [NSMutableDictionary new];
        self.dependencies = [NSMutableDictionary new];
    }
    return self;
}

-(id) copyWithZone:(NSZone *) zone {
    return self;
}

@end

@implementation NSMutableArray (HLMRelativeLayoutQueue)

-(id) pollLast {
    if (self.count) {
        id lastObject = self.lastObject;
        [self removeLastObject];
        return lastObject;
    }
    return nil;
}

@end
