//
//  HLMLayoutManagers.m
//  Pods
//
//  Created by Alex Quinlivan on 16/06/15.
//
//

#import "HLMLayoutManagers.h"
#import "HLMResources.h"
#import "GDataXMLNode.h"

@interface HLMLayoutManager : NSObject

-(instancetype) initWithName:(NSString *) name
                       class:(NSString *) clazz
                    resource:(HLMBucketResource *) resource;

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* clazz;
@property (nonatomic, strong) HLMBucketResource* resource;

@end

@implementation HLMLayoutManagers

+(void) insertLayoutManager:(GDataXMLElement *) layoutManager fromResource:(HLMBucketResource *) resource {
    NSString* name = [layoutManager attributeForName:@"name"].stringValue;
    NSString* clazz = [layoutManager attributeForName:@"class"].stringValue;
    HLMLayoutManager* layoutManagerResource = [[HLMLayoutManager alloc] initWithName:name
                                                                               class:clazz
                                                                            resource:resource];
    NSMutableDictionary* layoutManagerMap = self.layoutManagerMap;
    NSMutableArray* layoutManagersWithName = layoutManagerMap[name];
    if (!layoutManagersWithName) {
        layoutManagersWithName = [NSMutableArray new];
        layoutManagerMap[name] = layoutManagersWithName;
    }
    NSUInteger newIndex = [layoutManagersWithName indexOfObject:layoutManagerResource
                                                  inSortedRange:NSMakeRange(0, layoutManagersWithName.count)
                                                        options:NSBinarySearchingInsertionIndex
                                                usingComparator:^NSComparisonResult(HLMLayoutManager* obj1, HLMLayoutManager* obj2) {
                                                    return HLMResources.bucketComparator(obj1.resource, obj2.resource);
                                                }];
    [layoutManagersWithName insertObject:layoutManagerResource atIndex:newIndex];
}

+(NSString *) layoutManagerClassStringWithName:(NSString *) name {
    HLMDeviceConfig* currentDevice = HLMDeviceConfig.currentDevice;
    NSArray* layoutManagerArray = self.layoutManagerMap[name];
    for (HLMLayoutManager* layoutManager in layoutManagerArray) {
        if ([layoutManager.resource.config isSubconfigOfConfig:currentDevice]) {
            return layoutManager.clazz;
        }
    }
    @throw [NSException exceptionWithName:@"HLMLayoutManagerException"
                                   reason:[NSString stringWithFormat:@"Failed to find a layoutManager matching the"
                                           @" current device config under the name `%@`", name]
                                 userInfo:nil];
}

+(NSMutableDictionary *) layoutManagerMap {
    static NSMutableDictionary* layoutManagerMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* [MAP STRUCTURE]:
         *
         * layoutManagerMap[@"{{layout_manager_name}}"] -> : @[HLMLayoutManager] (Ordered by -[HLMLayoutManager resource])}
         *
         */
        layoutManagerMap = [NSMutableDictionary new];
    });
    return layoutManagerMap;
}

@end

@implementation HLMLayoutManager

-(instancetype) initWithName:(NSString *) name
                       class:(NSString *) clazz
                    resource:(HLMBucketResource *) resource {
    if (self = [super init]) {
        self.name = name;
        self.clazz = clazz;
        self.resource = resource;
    }
    return self;
}

@end
