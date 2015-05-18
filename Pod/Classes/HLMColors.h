//
//  HLMColors.h
//  Pods
//
//  Created by Alex Quinlivan on 18/05/15.
//
//

#import <Foundation/Foundation.h>
@class GDataXMLElement;
@class HLMBucketResource;

@interface HLMColors : NSObject

+(void) insertColor:(GDataXMLElement *) color fromResource:(HLMBucketResource *) resource;

+(NSString *) colorStringWithName:(NSString *) name;

@end
