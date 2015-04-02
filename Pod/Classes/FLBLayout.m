//
//  FLBLayout.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBLayout.h"
#import "FLBAssociatedObjects.h"

#define ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(_type, _name, _camel, _nsvalueaccessor) \
ASSOCIATE_VALUE_NO_SETTER(_type, _name, _camel, _nsvalueaccessor)\
-(void) set##_camel:(_type) val {\
    objc_setAssociatedObject(self, &k##_camel##AssociationKey, @(val), OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
    [self setNeedsLayout];\
}\

static uint32_t const FLBMeasureSpecModeMask = 0x3 << FLBMeasureSpecModeShift;

@implementation UIView (FLBLayoutProperties)

ASSOCIATE_VALUE_NO_SETTER(UIEdgeInsets, flb_margins, Flb_margins, UIEdgeInsetsValue);
-(void) setMargins:(UIEdgeInsets) margins {
    objc_setAssociatedObject(self, &kFlb_marginsAssociationKey,
                             [NSValue valueWithUIEdgeInsets:margins], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsLayout];
}

-(void) setMarginLeft:(CGFloat) marginLeft {
    UIEdgeInsets margins = self.flb_margins;
    margins.left = marginLeft;
    self.margins = margins;
}

-(void) setMarginTop:(CGFloat) marginTop {
    UIEdgeInsets margins = self.flb_margins;
    margins.top = marginTop;
    self.margins = margins;
}

-(void) setMarginRight:(CGFloat) marginRight {
    UIEdgeInsets margins = self.flb_margins;
    margins.right = marginRight;
    self.margins = margins;
}

-(void) setMarginBottom:(CGFloat) marginBottom {
    UIEdgeInsets margins = self.flb_margins;
    margins.bottom = marginBottom;
    self.margins = margins;
}

-(CGFloat) marginLeft {
    return self.flb_margins.left;
}

-(CGFloat) marginTop {
    return self.flb_margins.top;
}

-(CGFloat) marginRight {
    return self.flb_margins.right;
}

-(CGFloat) marginBottom {
    return self.flb_margins.bottom;
}

ASSOCIATE_VALUE_NO_SETTER(UIEdgeInsets, flb_padding, Flb_padding, UIEdgeInsetsValue);
-(void) setFlb_padding:(UIEdgeInsets) flb_padding {
    objc_setAssociatedObject(self, &kFlb_paddingAssociationKey,
                             [NSValue valueWithUIEdgeInsets:flb_padding], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsLayout];
}

-(void) setPaddingLeft:(CGFloat) paddingLeft {
    UIEdgeInsets padding = self.flb_padding;
    padding.left = paddingLeft;
    self.flb_padding = padding;
}

-(void) setPaddingTop:(CGFloat) paddingTop {
    UIEdgeInsets padding = self.flb_padding;
    padding.top = paddingTop;
    self.flb_padding = padding;
}

-(void) setPaddingRight:(CGFloat) paddingRight {
    UIEdgeInsets padding = self.flb_padding;
    padding.right = paddingRight;
    self.flb_padding = padding;
}

-(void) setPaddingBottom:(CGFloat) paddingBottom {
    UIEdgeInsets padding = self.flb_padding;
    padding.bottom = paddingBottom;
    self.flb_padding = padding;
}

-(CGFloat) paddingLeft {
    return self.flb_padding.left;
}

-(CGFloat) paddingTop {
    return self.flb_padding.top;
}

-(CGFloat) paddingRight {
    return self.flb_padding.right;
}

-(CGFloat) paddingBottom {
    return self.flb_padding.bottom;
}

ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, translationX, TranslationX, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, translationY, TranslationY, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, minWidth, MinWidth, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, minHeight, MinHeight, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, layoutWidth, LayoutWidth, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, layoutHeight, LayoutHeight, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, layoutWeight, LayoutWeight, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(FLBGravity, layoutGravity, LayoutGravity, intValue);
ASSOCIATE_NUMBER(CGFloat, measuredWidth, MeasuredWidth, floatValue);
ASSOCIATE_NUMBER(CGFloat, measuredHeight, MeasuredHeight, floatValue);
ASSOCIATE_OBJECT(NSObject, flb_layoutManager, Flb_layoutManager);

@end

@implementation FLBLayout

#pragma mark - MeasureSpec impl

+(FLBMeasureSpec) measureSpecWithSize:(uint32_t) size mode:(FLBMeasureSpecMode) mode {
    return (size & ~FLBMeasureSpecModeMask) | (mode & FLBMeasureSpecModeMask);
}

+(FLBMeasureSpecMode) measureSpecMode:(FLBMeasureSpec) measureSpec {
    return measureSpec & FLBMeasureSpecModeMask;
}

+(uint32_t) measureSpecSize:(FLBMeasureSpec) measureSpec {
    return measureSpec & ~FLBMeasureSpecModeMask;
}

+(FLBMeasureSpec) childMeasureSpec:(FLBMeasureSpec) spec
                           padding:(int32_t) padding
                         dimension:(FLBLayoutParam) childDimension {
    uint32_t specMode = [FLBLayout measureSpecMode:spec];
    uint32_t specSize = [FLBLayout measureSpecSize:spec];
    uint32_t size = MAX(0, specSize - padding);
    uint32_t resultSize = 0;
    uint32_t resultMode = 0;
    switch (specMode) {
        case FLBMeasureSpecExactly: {
            if (childDimension >= 0) {
                resultSize = childDimension;
                resultMode = FLBMeasureSpecExactly;
            } else if (childDimension == FLBLayoutParamMatch) {
                resultSize = size;
                resultMode = FLBMeasureSpecExactly;
            } else if (childDimension == FLBLayoutParamWrap) {
                resultSize = size;
                resultMode = FLBMeasureSpecAtMost;
            }
            break;
        }
        case FLBMeasureSpecAtMost: {
            if (childDimension >= 0) {
                resultSize = childDimension;
                resultMode = FLBMeasureSpecExactly;
            } else if (childDimension == FLBLayoutParamMatch) {
                resultSize = size;
                resultMode = FLBMeasureSpecAtMost;
            } else if (childDimension == FLBLayoutParamWrap) {
                resultSize = size;
                resultMode = FLBMeasureSpecAtMost;
            }
            break;
        }
        case FLBMeasureSpecUnspecified: {
            if (childDimension >= 0) {
                resultSize = childDimension;
                resultMode = FLBMeasureSpecExactly;
            } else if (childDimension == FLBLayoutParamMatch) {
                resultSize = 0;
                resultMode = FLBMeasureSpecUnspecified;
            } else if (childDimension == FLBLayoutParamWrap) {
                resultSize = 0;
                resultMode = FLBMeasureSpecUnspecified;
            }
            break;
        }
    }
    return [FLBLayout measureSpecWithSize:resultSize mode:resultMode];
}

+(uint32_t) defaultSize:(uint32_t) size spec:(FLBMeasureSpec) measureSpec {
    FLBMeasureSpecMode specMode = [self measureSpecMode:measureSpec];
    switch (specMode) {
        case FLBMeasureSpecUnspecified:
            return size;
        default:
            return [self measureSpecSize:measureSpec];
    }
}

+(uint32_t) resolveSize:(uint32_t) size spec:(FLBMeasureSpec) measureSpec {
    uint32_t result = size;
    FLBMeasureSpecMode specMode = [FLBLayout measureSpecMode:measureSpec];
    switch (specMode) {
        case FLBMeasureSpecUnspecified:
            return size;
        case FLBMeasureSpecAtMost:
            return MIN(size, [FLBLayout measureSpecSize:measureSpec]);
        case FLBMeasureSpecExactly:
            return [FLBLayout measureSpecSize:measureSpec];
    }
    return result;
}

#pragma mark - Measure specific impl

+(void) measureChildWithMargins:(UIView *) childView
                       ofParent:(UIView *) parentView
                parentWidthSpec:(FLBMeasureSpec) parentWidthMeasureSpec
                      widthUsed:(NSInteger) widthUsed
               parentHeightSpec:(FLBMeasureSpec) parentHeightMeasureSpec
                     heightUsed:(NSInteger) heightUsed {
    UIEdgeInsets padding = parentView.flb_padding;
    int32_t paddingLeft = padding.left;
    int32_t paddingRight = padding.right;
    int32_t paddingTop = padding.top;
    int32_t paddingBottom = padding.bottom;
    UIEdgeInsets margins = childView.flb_margins;
    int32_t marginLeft = margins.left;
    int32_t marginRight = margins.right;
    int32_t marginTop = margins.top;
    int32_t marginBottom = margins.bottom;
    FLBMeasureSpec childWidthMeasureSpec = [self childMeasureSpec:parentWidthMeasureSpec
                                                          padding:paddingLeft + paddingRight + marginLeft + marginRight + ((int32_t) widthUsed)
                                                        dimension:childView.layoutWidth];
    FLBMeasureSpec childHeightMeasureSpec = [self childMeasureSpec:parentHeightMeasureSpec
                                                           padding:paddingTop + paddingBottom + marginTop + marginBottom + ((int32_t) heightUsed)
                                                         dimension:childView.layoutHeight];
    if (childView.flb_layoutManager) {
        [childView.flb_layoutManager measure:childView
                                   widthSpec:childWidthMeasureSpec
                                  heightSpec:childHeightMeasureSpec];
    } else {
        childView.measuredWidth = [self defaultSize:childView.minWidth spec:childWidthMeasureSpec];
        childView.measuredHeight = [self defaultSize:childView.minHeight spec:childHeightMeasureSpec];
    }
}

#pragma mark - Gravity impl

typedef struct {
    NSInteger left;
    NSInteger right;
    NSInteger top;
    NSInteger bottom;
} FLBGravityRect;

+(CGRect) applyGravity:(FLBGravity) gravity
           toContainer:(CGRect) container
                 width:(NSUInteger) width
                height:(NSUInteger) height {
    return [self applyGravity:gravity
                  toContainer:container
                        width:width
                       height:height
                      xAdjust:0
                      yAdjust:0];
}

+(CGRect) applyGravity:(FLBGravity) gravity
           toContainer:(CGRect) containerSource
                 width:(NSUInteger) width
                height:(NSUInteger) height
               xAdjust:(NSInteger) xAdjust
               yAdjust:(NSInteger) yAdjust {
    FLBGravityRect outRect = (FLBGravityRect) {0, 0, 0, 0};
    FLBGravityRect container = (FLBGravityRect) {containerSource.origin.x, containerSource.origin.y,
        containerSource.origin.y + containerSource.size.width, containerSource.origin.y + containerSource.size.height};
    switch (gravity & ((FLBGravityAxisPullBefore | FLBGravityAxisPullAfter) << FLBGravityAxisXShift)) {
        case 0:
            outRect.left = container.left
            + ((container.right - container.left - width)/2) + xAdjust;
            outRect.right = outRect.left + width;
            if ((gravity & (FLBGravityAxisClip << FLBGravityAxisXShift))
                == (FLBGravityAxisClip << FLBGravityAxisXShift)) {
                if (outRect.left < container.left) {
                    outRect.left = container.left;
                }
                if (outRect.right > container.right) {
                    outRect.right = container.right;
                }
            }
            break;
        case FLBGravityAxisPullBefore << FLBGravityAxisXShift:
            outRect.left = container.left + xAdjust;
            outRect.right = outRect.left + width;
            if ((gravity & (FLBGravityAxisClip << FLBGravityAxisXShift))
                == (FLBGravityAxisClip << FLBGravityAxisXShift)) {
                if (outRect.right > container.right) {
                    outRect.right = container.right;
                }
            }
            break;
        case FLBGravityAxisPullAfter << FLBGravityAxisXShift:
            outRect.right = container.right - xAdjust;
            outRect.left = outRect.right - width;
            if ((gravity & (FLBGravityAxisClip << FLBGravityAxisXShift))
                == (FLBGravityAxisClip << FLBGravityAxisXShift)) {
                if (outRect.left < container.left) {
                    outRect.left = container.left;
                }
            }
            break;
        default:
            outRect.left = container.left + xAdjust;
            outRect.right = container.right + xAdjust;
            break;
    }
    
    switch (gravity & ((FLBGravityAxisPullBefore | FLBGravityAxisPullAfter) << FLBGravityAxisYShift)) {
        case 0:
            outRect.top = container.top
            + ((container.bottom - container.top - height)/2) + yAdjust;
            outRect.bottom = outRect.top + height;
            if ((gravity & (FLBGravityAxisClip << FLBGravityAxisYShift))
                == (FLBGravityAxisClip << FLBGravityAxisYShift)) {
                if (outRect.top < container.top) {
                    outRect.top = container.top;
                }
                if (outRect.bottom > container.bottom) {
                    outRect.bottom = container.bottom;
                }
            }
            break;
        case FLBGravityAxisPullBefore << FLBGravityAxisYShift:
            outRect.top = container.top + yAdjust;
            outRect.bottom = outRect.top + height;
            if ((gravity & (FLBGravityAxisClip << FLBGravityAxisYShift))
                == (FLBGravityAxisClip << FLBGravityAxisYShift)) {
                if (outRect.bottom > container.bottom) {
                    outRect.bottom = container.bottom;
                }
            }
            break;
        case FLBGravityAxisPullAfter << FLBGravityAxisYShift:
            outRect.bottom = container.bottom - yAdjust;
            outRect.top = outRect.bottom - height;
            if ((gravity & (FLBGravityAxisClip << FLBGravityAxisYShift))
                == (FLBGravityAxisClip << FLBGravityAxisYShift)) {
                if (outRect.top < container.top) {
                    outRect.top = container.top;
                }
            }
            break;
        default:
            outRect.top = container.top + yAdjust;
            outRect.bottom = container.bottom + yAdjust;
            break;
    }
    CGRect outCGRect = (CGRect) {outRect.left, outRect.top,
        outRect.right - outRect.left, outRect.bottom - outRect.top};
    return outCGRect;
}

@end
