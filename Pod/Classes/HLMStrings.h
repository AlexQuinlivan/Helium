//
//  HLMStrings.h
//  Pods
//
//  Created by Alex Quinlivan on 18/05/15.
//
//

#import <Foundation/Foundation.h>
@class GDataXMLElement;
@class HLMBucketResource;

@interface HLMStrings : NSObject

+(void) insertString:(GDataXMLElement *) string fromResource:(HLMBucketResource *) resource;
+(void) insertStringArray:(GDataXMLElement *) stringArray fromResource:(HLMBucketResource *) resource;

+(NSString *) stringWithName:(NSString *) name;

@end
