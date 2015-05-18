//
//  HLMNumbers.m
//  Pods
//
//  Created by Alex Quinlivan on 18/05/15.
//
//

#import "HLMNumbers.h"
#import "HLMResources.h"
#import "GDataXMLNode.h"

@interface HLMNumber : NSObject

-(instancetype) initWithName:(NSString *) name
                       value:(NSString *) value
                    resource:(HLMBucketResource *) resource;

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* value;
@property (nonatomic, strong) HLMBucketResource* resource;

@end

@implementation HLMNumbers

+(void) insertInteger:(GDataXMLElement *) integerData fromResource:(HLMBucketResource *) resource {
    [self insertNumber:integerData fromResource:resource];
}

+(void) insertBool:(GDataXMLElement *) boolData fromResource:(HLMBucketResource *) resource {
    [self insertNumber:boolData fromResource:resource];
}

+(void) insertFloat:(GDataXMLElement *) floatData fromResource:(HLMBucketResource *) resource {
    [self insertNumber:floatData fromResource:resource];
}

+(void) insertDouble:(GDataXMLElement *) doubleData fromResource:(HLMBucketResource *) resource {
    [self insertNumber:doubleData fromResource:resource];
}

+(void) insertNumber:(GDataXMLElement *) number fromResource:(HLMBucketResource *) resource {
    NSString* name = [number attributeForName:@"name"].stringValue;
    NSString* value = number.stringValue;
    HLMNumber* numberResource = [[HLMNumber alloc] initWithName:name
                                                       value:value
                                                    resource:resource];
    NSMutableDictionary* numberMap = self.numberMap;
    NSMutableArray* numbersWithName = numberMap[name];
    if (!numbersWithName) {
        numbersWithName = [NSMutableArray new];
        numberMap[name] = numbersWithName;
    }
    NSUInteger newIndex = [numbersWithName indexOfObject:numberResource
                                          inSortedRange:NSMakeRange(0, numbersWithName.count)
                                                options:NSBinarySearchingInsertionIndex
                                        usingComparator:^NSComparisonResult(HLMNumber* obj1, HLMNumber* obj2) {
                                            return HLMResources.bucketComparator(obj1.resource, obj2.resource);
                                        }];
    [numbersWithName insertObject:numberResource atIndex:newIndex];
}

+(NSString *) numberStringWithName:(NSString *) name {
    HLMDeviceConfig* currentDevice = HLMDeviceConfig.currentDevice;
    NSArray* numberArray = self.numberMap[name];
    for (HLMNumber* number in numberArray) {
        if ([number.resource.config isSubconfigOfConfig:currentDevice]) {
            return number.value;
        }
    }
    @throw [NSException exceptionWithName:@"HLMNumberException"
                                   reason:[NSString stringWithFormat:@"Failed to find a number matching the"
                                           @" current device config under the name `%@`", name]
                                 userInfo:nil];
}

+(NSMutableDictionary *) numberMap {
    static NSMutableDictionary* numberMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* [MAP STRUCTURE]:
         *
         * numberMap[@"{{number_name}}"] -> : @[HLMNumber] (Ordered by -[HLMNumber resource])}
         *
         */
        numberMap = [NSMutableDictionary new];
    });
    return numberMap;
}

@end

@implementation HLMNumber

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
