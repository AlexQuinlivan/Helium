//
//  HLMResources.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

@interface HLMResources : NSObject

+(NSString *) resolveResourcePath:(NSString *) resourceId;

// Attribute resolving

+(NSString *) stringValue:(NSString *) stringResource;
+(NSNumber *) numberValue:(NSString *) numberResource;
+(NSInteger) integerValue:(NSString *) integerResource;
+(NSUInteger) unsignedIntegerValue:(NSString *) unsignedIntegerResource;
+(BOOL) boolValue:(NSString *) boolResource;
+(int) intValue:(NSString *) intResource;
+(unichar) charValue:(NSString *) charResource;
+(long) longValue:(NSString *) longResource;
+(float) floatValue:(NSString *) floatResource;
+(double) doubleValue:(NSString *) doubleResource;
+(CGFloat) cgFloatValue:(NSString *) cgFloatResource;
+(CGRect) cgRectValue:(NSString *) cgRectResource;
+(CGSize) cgSizeValue:(NSString *) cgSizeResource;
+(CGPoint) cgPointValue:(NSString *) cgPointResource;
+(UIEdgeInsets) uiEdgeInsetsValue:(NSString *) uiEdgeInsetsResource;
+(UIColor *) uiColorValue:(NSString *) uiColorResource;

@end
