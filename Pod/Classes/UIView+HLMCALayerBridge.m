//
//  UIView+HLMCALayerBridge.m
//  Pods
//
//  Created by Alex Quinlivan on 12/06/15.
//
//

#import "UIView+HLMCALayerBridge.h"

@implementation UIView (HLMCALayerBridge)

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

@end