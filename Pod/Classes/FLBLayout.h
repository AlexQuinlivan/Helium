//
//  FLBLayout.h
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FLBLayoutRule) {
    FLBLayoutRuleWrap = -1, // Orientation size ignores previous values and wraps its layout out subviews
    FLBLayoutRuleFill = -2, // Orientation size matches parent's size at layout time
};

typedef NS_ENUM(NSInteger, FLBLayoutOrientation) {
    FLBLayoutOrientationVertical,
    FLBLayoutOrientationHorizontal,
};

@protocol FLBLayoutManager;

@interface UIView (FLBLayoutProperties)

@property (nonatomic) CGFloat marginLeft;
@property (nonatomic) CGFloat marginTop;
@property (nonatomic) CGFloat marginRight;
@property (nonatomic) CGFloat marginBottom;
@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) CGFloat translationX;
@property (nonatomic) CGFloat translationY;
@property (nonatomic) CGFloat layoutWidth;
@property (nonatomic) CGFloat layoutHeight;
@property (nonatomic) CGFloat layoutWeight;
@property (nonatomic) id<FLBLayoutManager> flb_layoutManager;

@end

// linear / frame / relative
@protocol FLBLayoutManager <NSObject>
@required

-(void) flb_measure:(UIView *) view;
-(void) flb_layout:(UIView *) view;

@end
