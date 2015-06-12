//
//  UIView+HLMCALayerBridge.h
//  Pods
//
//  Created by Alex Quinlivan on 12/06/15.
//
//

#import <UIKit/UIKit.h>

@interface UIView (HLMCALayerBridge)

@property (nonatomic) CGFloat hlm_layerZPosition;
@property (nonatomic) BOOL hlm_layerDoubleSided;
@property (nonatomic) BOOL hlm_layerGeometryFlipped;
@property (nonatomic) BOOL hlm_layerMasksToBounds;
@property (nonatomic) CGFloat hlm_layerContentsScale;
@property (nonatomic) float hlm_layerMinificationFilterBias;
@property (nonatomic) BOOL hlm_layerNeedsDisplayOnBoundsChange;
@property (nonatomic) BOOL hlm_layerDrawsAsynchronously;
@property (nonatomic) BOOL hlm_layerAllowsEdgeAntialiasing;
@property (nonatomic) CGFloat hlm_layerCornerRadius;
@property (nonatomic) CGFloat hlm_layerBorderWidth;
@property (nonatomic, strong) UIColor* hlm_layerBorderColor;
@property (nonatomic) float hlm_layerOpacity;
@property (nonatomic) BOOL hlm_layerAllowsGroupOpacity;
@property (nonatomic) BOOL hlm_layerShouldRasterize;
@property (nonatomic) CGFloat hlm_layerRasterizationScale;
@property (nonatomic, strong) UIColor* hlm_layerShadowColor;
@property (nonatomic) float hlm_layerShadowOpacity;
@property (nonatomic) CGSize hlm_layerShadowOffset;
@property (nonatomic) CGFloat hlm_layerShadowRadius;
@property (nonatomic, strong) NSString* hlm_layerName;

@end
