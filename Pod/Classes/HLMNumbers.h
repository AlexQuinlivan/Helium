//
//  HLMNumbers.h
//  Pods
//
//  Created by Alex Quinlivan on 18/05/15.
//
//

#import <Foundation/Foundation.h>
@class GDataXMLElement;
@class HLMBucketResource;

@interface HLMNumbers : NSObject

+(void) insertInteger:(GDataXMLElement *) integerData fromResource:(HLMBucketResource *) resource;
+(void) insertBool:(GDataXMLElement *) boolData fromResource:(HLMBucketResource *) resource;
+(void) insertFloat:(GDataXMLElement *) floatData fromResource:(HLMBucketResource *) resource;
+(void) insertDouble:(GDataXMLElement *) doubleData fromResource:(HLMBucketResource *) resource;

+(NSString *) numberStringWithName:(NSString *) name;

@end
