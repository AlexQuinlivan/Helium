//
//  HLMLayout.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HLMLayoutParam) {
    HLMLayoutParamWrap = -1, // Orientation size ignores previous values and wraps its layout out subviews
    HLMLayoutParamMatch = -2, // Orientation size matches parent's size at layout time
};

typedef NS_ENUM(NSInteger, HLMLayoutOrientation) {
    HLMLayoutOrientationHorizontal,
    HLMLayoutOrientationVertical,
};


#pragma mark - MeasureSpec

#define HLMMeasureSpecModeShift 30

typedef uint32_t HLMMeasureSpec;

typedef NS_ENUM(uint32_t, HLMMeasureSpecMode) {
    HLMMeasureSpecUnspecified = 0 << HLMMeasureSpecModeShift,
    HLMMeasureSpecExactly = 1 << HLMMeasureSpecModeShift,
    HLMMeasureSpecAtMost = 2 << HLMMeasureSpecModeShift,
};


#pragma mark - Gravity

#define HLMGravityAxisSpecified 0x1
#define HLMGravityAxisPullBefore 0x2
#define HLMGravityAxisPullAfter 0x4
#define HLMGravityAxisClip 0x8
#define HLMGravityAxisXShift 0
#define HLMGravityAxisYShift 4

typedef NS_ENUM(int32_t, HLMGravity) {
    HLMGravityTop = (HLMGravityAxisPullBefore | HLMGravityAxisSpecified) << HLMGravityAxisYShift,
    HLMGravityBottom = (HLMGravityAxisPullAfter | HLMGravityAxisSpecified) << HLMGravityAxisYShift,
    HLMGravityLeft = (HLMGravityAxisPullBefore | HLMGravityAxisSpecified) << HLMGravityAxisXShift,
    HLMGravityRight = (HLMGravityAxisPullAfter | HLMGravityAxisSpecified) << HLMGravityAxisXShift,
    HLMGravityCenterVertical = HLMGravityAxisSpecified << HLMGravityAxisYShift,
    HLMGravityCenterHorizontal = HLMGravityAxisSpecified << HLMGravityAxisXShift,
    HLMGravityFillVertical = HLMGravityTop | HLMGravityBottom,
    HLMGravityFillHorizontal = HLMGravityLeft | HLMGravityRight,
    HLMGravityCenter = HLMGravityCenterVertical | HLMGravityCenterHorizontal,
    HLMGravityFill = HLMGravityFillVertical | HLMGravityFillHorizontal,
    HLMGravityClipVertical = HLMGravityAxisClip << HLMGravityAxisYShift,
    HLMGravityClipHorizontal = HLMGravityAxisClip << HLMGravityAxisXShift,
};

#define HLMGravityHorizontalMask ((HLMGravityAxisSpecified | HLMGravityAxisPullBefore | HLMGravityAxisPullAfter) << HLMGravityAxisXShift)
#define HLMGravityVerticalMask ((HLMGravityAxisSpecified | HLMGravityAxisPullBefore | HLMGravityAxisPullAfter) << HLMGravityAxisYShift)


#pragma mark - UIView associated properties

@protocol HLMLayoutManager;

@interface UIView (HLMLayoutProperties)

@property (nonatomic) NSUInteger hlm_id;
@property (nonatomic) CGFloat hlm_marginLeft;
@property (nonatomic) CGFloat hlm_marginTop;
@property (nonatomic) CGFloat hlm_marginRight;
@property (nonatomic) CGFloat hlm_marginBottom;
@property (nonatomic) UIEdgeInsets hlm_margins;
@property (nonatomic) CGFloat hlm_paddingLeft;
@property (nonatomic) CGFloat hlm_paddingTop;
@property (nonatomic) CGFloat hlm_paddingRight;
@property (nonatomic) CGFloat hlm_paddingBottom;
@property (nonatomic) UIEdgeInsets hlm_padding;
@property (nonatomic) CGFloat hlm_translationX;
@property (nonatomic) CGFloat hlm_translationY;
@property (nonatomic) CGFloat hlm_layoutWidth;
@property (nonatomic) CGFloat hlm_layoutHeight;
@property (nonatomic) HLMGravity hlm_layoutGravity;
@property (nonatomic) CGFloat hlm_measuredWidth;
@property (nonatomic) CGFloat hlm_measuredHeight;
@property (nonatomic) CGFloat hlm_minWidth;
@property (nonatomic) CGFloat hlm_minHeight;
@property (nonatomic) HLMGravity hlm_gravity;
@property (nonatomic, strong) id<HLMLayoutManager> hlm_layoutManager;
@property (nonatomic) BOOL hlm_overridesLayoutGuides;

-(UIView *) hlm_viewWithId:(NSUInteger) hlm_id;
-(void) hlm_requestLayout;

@end

@interface UIView (HLMLinearLayoutProperties)

@property (nonatomic) CGFloat hlm_layoutWeight;
@property (nonatomic) HLMLayoutOrientation hlm_orientation;
@property (nonatomic) BOOL hlm_baselineAligned;
@property (nonatomic) NSInteger hlm_baselineAlignedChildIndex;
@property (nonatomic) CGFloat hlm_weightSum;

@end

@interface UIView (HLMRelativeLayoutProperties)

@property (nonatomic) NSUInteger hlm_layoutAbove;
@property (nonatomic) NSUInteger hlm_layoutAlignBaseline;
@property (nonatomic) NSUInteger hlm_layoutAlignBottom;
@property (nonatomic) NSUInteger hlm_layoutAlignEnd;
@property (nonatomic) NSUInteger hlm_layoutAlignLeft;
@property (nonatomic) BOOL hlm_layoutAlignParentBottom;
@property (nonatomic) BOOL hlm_layoutAlignParentEnd;
@property (nonatomic) BOOL hlm_layoutAlignParentLeft;
@property (nonatomic) BOOL hlm_layoutAlignParentRight;
@property (nonatomic) BOOL hlm_layoutAlignParentStart;
@property (nonatomic) BOOL hlm_layoutAlignParentTop;
@property (nonatomic) NSUInteger hlm_layoutAlignRight;
@property (nonatomic) NSUInteger hlm_layoutAlignStart;
@property (nonatomic) NSUInteger hlm_layoutAlignTop;
@property (nonatomic) BOOL hlm_layoutAlignWithParentIfMissing;
@property (nonatomic) NSUInteger hlm_layoutBelow;
@property (nonatomic) BOOL hlm_layoutCenterHorizontal;
@property (nonatomic) BOOL hlm_layoutCenterInParent;
@property (nonatomic) BOOL hlm_layoutCenterVertical;
@property (nonatomic) NSUInteger hlm_layoutToEndOf;
@property (nonatomic) NSUInteger hlm_layoutToLeftOf;
@property (nonatomic) NSUInteger hlm_layoutToRightOf;
@property (nonatomic) NSUInteger hlm_layoutToStartOf;
@property (nonatomic) NSUInteger hlm_ignoreGravity;

@end

@interface UILabel (HLMLayoutProperties)

@property (nonatomic) CGFloat hlm_textSize;

@end

@interface UIImageView (HLMLayoutProperties)

@property (nonatomic) UIImageRenderingMode hlm_imageRenderingMode;
@property (nonatomic, strong) UIImage* hlm_image;
@property (nonatomic, strong) UIImage* hlm_highlightedImage;

@end

@interface UIButton (HLMLayoutProperties)

@property (nonatomic, strong) UIColor* hlm_highlightedBackgroundColor;

@end


#pragma mark - LayoutManager

// linear / frame / relative
@protocol HLMLayoutManager <NSObject>
@required

-(void) measure:(UIView *) view
      widthSpec:(HLMMeasureSpec) widthMeasureSpec
     heightSpec:(HLMMeasureSpec) heightMeasureSpec;

-(void) layout:(UIView *) view
          left:(NSInteger) left
           top:(NSInteger) top
         right:(NSInteger) right
        bottom:(NSInteger) bottom;

@end


#pragma mark - Layout related implementations

@interface HLMLayout : NSObject

+(HLMMeasureSpec) measureSpecWithSize:(uint32_t) size mode:(HLMMeasureSpecMode) mode;
+(HLMMeasureSpecMode) measureSpecMode:(HLMMeasureSpec) measureSpec;
+(uint32_t) measureSpecSize:(HLMMeasureSpec) measureSpec;
+(HLMMeasureSpec) childMeasureSpec:(HLMMeasureSpec) spec
                           padding:(int32_t) padding
                         dimension:(HLMLayoutParam) childDimension;
+(uint32_t) defaultSize:(uint32_t) size spec:(HLMMeasureSpec) measureSpec;
+(uint32_t) resolveSize:(uint32_t) size spec:(HLMMeasureSpec) measureSpec;

+(void) measureChildWithMargins:(UIView *) childView
                       ofParent:(UIView *) parentView
                parentWidthSpec:(HLMMeasureSpec) parentWidthMeasureSpec
                      widthUsed:(NSInteger) widthUsed
               parentHeightSpec:(HLMMeasureSpec) parentHeightMeasureSpec
                     heightUsed:(NSInteger) heightUsed;
+(void) measureView:(UIView *) view
          widthSpec:(HLMMeasureSpec) widthMeasureSpec
         heightSpec:(HLMMeasureSpec) heightMeasureSpec;
+(void) setChild:(UIView *) child frame:(CGRect) frame;

+(CGRect) applyGravity:(HLMGravity) gravity
           toContainer:(CGRect) container
                 width:(NSUInteger) width
                height:(NSUInteger) height;
+(CGRect) applyGravity:(HLMGravity) gravity
           toContainer:(CGRect) container
                 width:(NSUInteger) width
                height:(NSUInteger) height
               xAdjust:(NSInteger) xAdjust
               yAdjust:(NSInteger) yAdjust;

@end
