//
//  UIView+HLMCALayerBridge.h
//  Pods
//
//  Created by Alex Quinlivan on 12/06/15.
//
//

#import <UIKit/UIKit.h>

@interface UIView (HLMCALayerBridge)

@property (nonatomic) CGFloat hlm_layerCornerRadius;
@property (nonatomic) CGFloat hlm_layerBorderWidth;
@property (nonatomic, strong) UIColor* hlm_layerBorderColor;

@end
