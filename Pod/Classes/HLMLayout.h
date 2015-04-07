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

@property (nonatomic) CGFloat marginLeft;
@property (nonatomic) CGFloat marginTop;
@property (nonatomic) CGFloat marginRight;
@property (nonatomic) CGFloat marginBottom;
@property (nonatomic) UIEdgeInsets hlm_margins;
@property (nonatomic) CGFloat paddingLeft;
@property (nonatomic) CGFloat paddingTop;
@property (nonatomic) CGFloat paddingRight;
@property (nonatomic) CGFloat paddingBottom;
@property (nonatomic) UIEdgeInsets hlm_padding;
@property (nonatomic) CGFloat translationX;
@property (nonatomic) CGFloat translationY;
@property (nonatomic) CGFloat layoutWidth;
@property (nonatomic) CGFloat layoutHeight;
@property (nonatomic) CGFloat layoutWeight;
@property (nonatomic) HLMGravity layoutGravity;
@property (nonatomic) CGFloat measuredWidth;
@property (nonatomic) CGFloat measuredHeight;
@property (nonatomic) CGFloat minWidth;
@property (nonatomic) CGFloat minHeight;
@property (nonatomic) HLMLayoutOrientation hlm_orientation;
@property (nonatomic) BOOL hlm_baselineAligned;
@property (nonatomic) NSInteger hlm_baselineAlignedChildIndex;
@property (nonatomic) CGFloat hlm_weightSum;
@property (nonatomic) HLMGravity hlm_gravity;
@property (nonatomic, strong) id<HLMLayoutManager> hlm_layoutManager;

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
