//
//  HLMResources.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>
@class EDSemver;

@interface HLMResources : NSObject

+(NSString *) resolveResourcePath:(NSString *) resourceId;
+(NSArray *) pathsForResource:(NSString *) resource;
+(NSComparator) bucketComparator;

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


@interface HLMDeviceConfig : NSObject
-(BOOL) isSubconfigOfConfig:(HLMDeviceConfig *) config;
-(NSComparisonResult) compareQualifiers:(HLMDeviceConfig *) config;
@property (nonatomic, strong) NSString* orientation;
@property (nonatomic, strong) NSString* scale;
@property (nonatomic, strong) NSString* uiIdiom;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSNumber* width;
@property (nonatomic, strong) NSNumber* height;
@property (nonatomic, strong) EDSemver* systemVersion;
@property (nonatomic, readonly) NSNumber* shortestWidth;
@property (nonatomic) uint8_t priority;
+(HLMDeviceConfig *) currentDevice;
@end


@interface HLMBucketResource : NSObject
@property (nonatomic, strong) NSString* path;
@property (nonatomic, strong) HLMDeviceConfig* config;
@end

