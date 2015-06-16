//
//  HLMLayoutManagers.h
//  Pods
//
//  Created by Alex Quinlivan on 16/06/15.
//
//

#import <Foundation/Foundation.h>
@class GDataXMLElement;
@class HLMBucketResource;

@interface HLMLayoutManagers : NSObject

+(void) insertLayoutManager:(GDataXMLElement *) layoutManager fromResource:(HLMBucketResource *) resource;

+(NSString *) layoutManagerClassStringWithName:(NSString *) name;

@end
