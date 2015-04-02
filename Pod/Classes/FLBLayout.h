//
//  FLBLayout.h
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FLBLayoutParam) {
    FLBLayoutParamWrap = -1, // Orientation size ignores previous values and wraps its layout out subviews
    FLBLayoutParamMatch = -2, // Orientation size matches parent's size at layout time
};

typedef NS_ENUM(NSInteger, FLBLayoutOrientation) {
    FLBLayoutOrientationVertical,
    FLBLayoutOrientationHorizontal,
};


#pragma mark - MeasureSpec

#define FLBMeasureSpecModeShift 30

typedef uint32_t FLBMeasureSpec;

typedef NS_ENUM(uint32_t, FLBMeasureSpecMode) {
    FLBMeasureSpecUnspecified = 0 << FLBMeasureSpecModeShift,
    FLBMeasureSpecExactly = 1 << FLBMeasureSpecModeShift,
    FLBMeasureSpecAtMost = 2 << FLBMeasureSpecModeShift,
};


#pragma mark - Gravity

#define FLBGravityAxisSpecified 0x1
#define FLBGravityAxisPullBefore 0x2
#define FLBGravityAxisPullAfter 0x4
#define FLBGravityAxisClip 0x8
#define FLBGravityAxisXShift 0
#define FLBGravityAxisYShift 4

typedef NS_ENUM(int32_t, FLBGravity) {
    FLBGravityTop = (FLBGravityAxisPullBefore | FLBGravityAxisSpecified) << FLBGravityAxisYShift,
    FLBGravityBottom = (FLBGravityAxisPullAfter | FLBGravityAxisSpecified) << FLBGravityAxisYShift,
    FLBGravityLeft = (FLBGravityAxisPullBefore | FLBGravityAxisSpecified) << FLBGravityAxisXShift,
    FLBGravityRight = (FLBGravityAxisPullAfter | FLBGravityAxisSpecified) << FLBGravityAxisXShift,
    FLBGravityCenterVertical = FLBGravityAxisSpecified << FLBGravityAxisYShift,
    FLBGravityCenterHorizontal = FLBGravityAxisSpecified << FLBGravityAxisXShift,
    FLBGravityFillVertical = FLBGravityTop | FLBGravityBottom,
    FLBGravityFillHorizontal = FLBGravityLeft | FLBGravityRight,
    FLBGravityCenter = FLBGravityCenterVertical | FLBGravityCenterHorizontal,
    FLBGravityFill = FLBGravityFillVertical | FLBGravityFillHorizontal,
    FLBGravityClipVertical = FLBGravityAxisClip << FLBGravityAxisYShift,
    FLBGravityClipHorizontal = FLBGravityAxisClip << FLBGravityAxisXShift,
};

#define FLBGravityHorizontalMask ((FLBGravityAxisSpecified | FLBGravityAxisPullBefore | FLBGravityAxisPullAfter) << FLBGravityAxisXShift)
#define FLBGravityVerticalMask ((FLBGravityAxisSpecified | FLBGravityAxisPullBefore | FLBGravityAxisPullAfter) << FLBGravityAxisYShift)


#pragma mark - UIView associated properties

@protocol FLBLayoutManager;

@interface UIView (FLBLayoutProperties)

@property (nonatomic) CGFloat marginLeft;
@property (nonatomic) CGFloat marginTop;
@property (nonatomic) CGFloat marginRight;
@property (nonatomic) CGFloat marginBottom;
@property (nonatomic) UIEdgeInsets flb_margins;
@property (nonatomic) CGFloat paddingLeft;
@property (nonatomic) CGFloat paddingTop;
@property (nonatomic) CGFloat paddingRight;
@property (nonatomic) CGFloat paddingBottom;
@property (nonatomic) UIEdgeInsets flb_padding;
@property (nonatomic) CGFloat translationX;
@property (nonatomic) CGFloat translationY;
@property (nonatomic) CGFloat layoutWidth;
@property (nonatomic) CGFloat layoutHeight;
@property (nonatomic) CGFloat layoutWeight;
@property (nonatomic) FLBGravity layoutGravity;
@property (nonatomic) CGFloat measuredWidth;
@property (nonatomic) CGFloat measuredHeight;
@property (nonatomic) CGFloat minWidth;
@property (nonatomic) CGFloat minHeight;
@property (nonatomic) id<FLBLayoutManager> flb_layoutManager;

@end


#pragma mark - LayoutManager

// linear / frame / relative
@protocol FLBLayoutManager <NSObject>
@required

-(void) measure:(UIView *) view
      widthSpec:(FLBMeasureSpec) widthMeasureSpec
     heightSpec:(FLBMeasureSpec) heightMeasureSpec;

-(void) layout:(UIView *) view
          left:(NSInteger) left
           top:(NSInteger) top
         right:(NSInteger) right
        bottom:(NSInteger) bottom;

@end


#pragma mark - Layout related implementations

@interface FLBLayout : NSObject

+(FLBMeasureSpec) measureSpecWithSize:(uint32_t) size mode:(FLBMeasureSpecMode) mode;
+(FLBMeasureSpecMode) measureSpecMode:(FLBMeasureSpec) measureSpec;
+(uint32_t) measureSpecSize:(FLBMeasureSpec) measureSpec;
+(FLBMeasureSpec) childMeasureSpec:(FLBMeasureSpec) spec
                           padding:(int32_t) padding
                         dimension:(FLBLayoutParam) childDimension;
+(uint32_t) defaultSize:(uint32_t) size spec:(FLBMeasureSpec) measureSpec;
+(uint32_t) resolveSize:(uint32_t) size spec:(FLBMeasureSpec) measureSpec;

+(void) measureChildWithMargins:(UIView *) childView
                       ofParent:(UIView *) parentView
                parentWidthSpec:(FLBMeasureSpec) parentWidthMeasureSpec
                      widthUsed:(NSInteger) widthUsed
               parentHeightSpec:(FLBMeasureSpec) parentHeightMeasureSpec
                     heightUsed:(NSInteger) heightUsed;

+(CGRect) applyGravity:(FLBGravity) gravity
           toContainer:(CGRect) container
                 width:(NSUInteger) width
                height:(NSUInteger) height;
+(CGRect) applyGravity:(FLBGravity) gravity
           toContainer:(CGRect) container
                 width:(NSUInteger) width
                height:(NSUInteger) height
               xAdjust:(NSInteger) xAdjust
               yAdjust:(NSInteger) yAdjust;

@end
