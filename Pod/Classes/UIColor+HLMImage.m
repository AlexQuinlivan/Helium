//
//  UIColor+HLMImage.m
//  Pods
//
//  Created by Alex Quinlivan on 5/05/15.
//
//

#import "UIColor+HLMImage.h"

@implementation UIColor (HLMImage)

-(UIImage *) hlm_asImage {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.CGColor);
    CGContextFillRect(context, rect);
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
