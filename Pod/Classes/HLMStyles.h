//
//  HLMStyles.h
//  Pods
//
//  Created by Alex Quinlivan on 6/05/15.
//
//

#import <Foundation/Foundation.h>
@class HLMStyle;
@class HLMBucketResource;
@class GDataXMLElement;

@interface HLMStyles : NSObject

+(void) insertStyle:(GDataXMLElement *) element fromResource:(HLMBucketResource *) resource;

+(HLMStyle *) styleWithName:(NSString *) name;

@end

@interface HLMStyle : NSObject

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) HLMStyle* parent;
@property (nonatomic, readonly) NSMutableArray* entries;

@end

@interface HLMStyleEntry : NSObject

@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* value;

@end
