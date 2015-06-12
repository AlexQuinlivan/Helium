//
//  UIView+HLMCALayerBridge.m
//  Pods
//
//  Created by Alex Quinlivan on 12/06/15.
//
//

#import "UIView+HLMCALayerBridge.h"

@implementation UIView (HLMCALayerBridge)

-(BOOL) hlm_layerDoubleSided {
    return self.layer.isDoubleSided;
}

-(void) setHlm_layerDoubleSided:(BOOL) hlm_layerDoubleSided {
    self.layer.doubleSided = hlm_layerDoubleSided;
}

-(BOOL) hlm_layerGeometryFlipped {
    return self.layer.isGeometryFlipped;
}

-(void) setHlm_layerGeometryFlipped:(BOOL) hlm_layerGeometryFlipped {
    self.layer.geometryFlipped = hlm_layerGeometryFlipped;
}

-(BOOL) hlm_layerMasksToBounds {
    return self.layer.masksToBounds;
}

-(void) setHlm_layerMasksToBounds:(BOOL) hlm_layerMasksToBounds {
    self.layer.masksToBounds = hlm_layerMasksToBounds;
}

-(CGFloat) hlm_layerContentsScale {
    return self.layer.contentsScale;
}

-(void) setHlm_layerContentsScale:(CGFloat) hlm_layerContentsScale {
    self.layer.contentsScale = hlm_layerContentsScale;
}

-(float) hlm_layerMinificationFilterBias {
    return self.layer.minificationFilterBias;
}

-(void) setHlm_layerMinificationFilterBias:(float) hlm_layerMinificationFilterBias {
    self.layer.minificationFilterBias = hlm_layerMinificationFilterBias;
}

-(BOOL) hlm_layerNeedsDisplayOnBoundsChange {
    return self.layer.needsDisplayOnBoundsChange;
}

-(void) setHlm_layerNeedsDisplayOnBoundsChange:(BOOL) hlm_layerNeedsDisplayOnBoundsChange {
    self.layer.needsDisplayOnBoundsChange = hlm_layerNeedsDisplayOnBoundsChange;
}

-(BOOL) hlm_layerDrawsAsynchronously {
    return self.layer.drawsAsynchronously;
}

-(void) setHlm_layerDrawsAsynchronously:(BOOL) hlm_layerDrawsAsynchronously {
    self.layer.drawsAsynchronously = hlm_layerDrawsAsynchronously;
}

-(BOOL) hlm_layerAllowsEdgeAntialiasing {
    return self.layer.allowsEdgeAntialiasing;
}

-(void) setHlm_layerAllowsEdgeAntialiasing:(BOOL) hlm_layerAllowsEdgeAntialiasing {
    self.layer.allowsEdgeAntialiasing = hlm_layerAllowsEdgeAntialiasing;
}

-(CGFloat) hlm_layerCornerRadius {
    return self.layer.cornerRadius;
}

-(void) setHlm_layerCornerRadius:(CGFloat) hlm_layerCornerRadius {
    self.layer.cornerRadius = hlm_layerCornerRadius;
}

-(CGFloat) hlm_layerBorderWidth {
    return self.layer.borderWidth;
}

-(void) setHlm_layerBorderWidth:(CGFloat) hlm_layerBorderWidth {
    self.layer.borderWidth = hlm_layerBorderWidth;
}

-(UIColor *) hlm_layerBorderColor {
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

-(void) setHlm_layerBorderColor:(UIColor *) hlm_layerBorderColor {
    self.layer.borderColor = hlm_layerBorderColor.CGColor;
}

-(float) hlm_layerOpacity {
    return self.layer.opacity;
}

-(void) setHlm_layerOpacity:(float) hlm_layerOpacity {
    self.layer.opacity = hlm_layerOpacity;
}

-(BOOL) hlm_layerAllowsGroupOpacity {
    return self.layer.allowsGroupOpacity;
}

-(void) setHlm_layerAllowsGroupOpacity:(BOOL) hlm_layerAllowsGroupOpacity {
    self.layer.allowsGroupOpacity = hlm_layerAllowsGroupOpacity;
}

-(BOOL) hlm_layerShouldRasterize {
    return self.layer.shouldRasterize;
}

-(void) setHlm_layerShouldRasterize:(BOOL) hlm_layerShouldRasterize {
    self.layer.shouldRasterize = hlm_layerShouldRasterize;
}

-(CGFloat) hlm_layerRasterizationScale {
    return self.layer.rasterizationScale;
}

-(void) setHlm_layerRasterizationScale:(CGFloat) hlm_layerRasterizationScale {
    self.layer.rasterizationScale = hlm_layerRasterizationScale;
}

-(UIColor *) hlm_layerShadowColor {
    return [UIColor colorWithCGColor:self.layer.shadowColor];
}

-(void) setHlm_layerShadowColor:(UIColor *) hlm_layerShadowColor {
    self.layer.shadowColor = hlm_layerShadowColor.CGColor;
}

-(float) hlm_layerShadowOpacity {
    return self.layer.shadowOpacity;
}

-(void) setHlm_layerShadowOpacity:(float) hlm_layerShadowOpacity {
    self.layer.shadowOpacity = hlm_layerShadowOpacity;
}

-(CGSize) hlm_layerShadowOffset {
    return self.layer.shadowOffset;
}

-(void) setHlm_layerShadowOffset:(CGSize) hlm_layerShadowOffset {
    self.layer.shadowOffset = hlm_layerShadowOffset;
}

-(CGFloat) hlm_layerShadowRadius {
    return self.layer.shadowRadius;
}

-(void) setHlm_layerShadowRadius:(CGFloat) hlm_layerShadowRadius {
    self.layer.shadowRadius = hlm_layerShadowRadius;
}

-(NSString *) hlm_layerName {
    return self.layer.name;
}

-(void) setHlm_layerName:(NSString *) hlm_layerName {
    self.layer.name = hlm_layerName;
}

@end