//
//  HLMColors.m
//  Pods
//
//  Created by Alex Quinlivan on 18/05/15.
//
//

#import "HLMColors.h"
#import "HLMResources.h"
#import "GDataXMLNode.h"

@interface HLMColor : NSObject

-(instancetype) initWithName:(NSString *) name
                       value:(NSString *) value
                    resource:(HLMBucketResource *) resource;

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* value;
@property (nonatomic, strong) HLMBucketResource* resource;

@end

@implementation HLMColors

+(void) insertColor:(GDataXMLElement *) color fromResource:(HLMBucketResource *) resource {
    NSString* name = [color attributeForName:@"name"].stringValue;
    NSString* value = color.stringValue;
    HLMColor* colorResource = [[HLMColor alloc] initWithName:name
                                                       value:value
                                                    resource:resource];
    NSMutableDictionary* colorMap = self.colorMap;
    NSMutableArray* colorsWithName = colorMap[name];
    if (!colorsWithName) {
        colorsWithName = [NSMutableArray new];
        colorMap[name] = colorsWithName;
    }
    NSUInteger newIndex = [colorsWithName indexOfObject:colorResource
                                          inSortedRange:NSMakeRange(0, colorsWithName.count)
                                                options:NSBinarySearchingInsertionIndex
                                        usingComparator:^NSComparisonResult(HLMColor* obj1, HLMColor* obj2) {
                                            return HLMResources.bucketComparator(obj1.resource, obj2.resource);
                                        }];
    [colorsWithName insertObject:colorResource atIndex:newIndex];
}

+(NSString *) colorStringWithName:(NSString *) name {
    HLMDeviceConfig* currentDevice = HLMDeviceConfig.currentDevice;
    NSArray* colorArray = self.colorMap[name];
    for (HLMColor* color in colorArray) {
        if ([color.resource.config isSubconfigOfConfig:currentDevice]) {
            return color.value;
        }
    }
    @throw [NSException exceptionWithName:@"HLMColorException"
                                   reason:[NSString stringWithFormat:@"Failed to find a color matching the"
                                           @" current device config under the name `%@`", name]
                                 userInfo:nil];
}

+(NSMutableDictionary *) colorMap {
    static NSMutableDictionary* colorMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* [MAP STRUCTURE]:
         *
         * colorMap[@"{{color_name}}"] -> : @[HLMColor] (Ordered by -[HLMColor resource])}
         *
         */
        colorMap = [NSMutableDictionary new];
    });
    return colorMap;
}

@end

@implementation HLMColor

-(instancetype) initWithName:(NSString *) name
                       value:(NSString *) value
                    resource:(HLMBucketResource *) resource {
    if (self = [super init]) {
        self.name = name;
        self.value = value;
        self.resource = resource;
    }
    return self;
}

@end
