//
//  HLMStrings.m
//  Pods
//
//  Created by Alex Quinlivan on 18/05/15.
//
//

#import "HLMStrings.h"
#import "HLMResources.h"
#import "GDataXMLNode.h"

@interface HLMString : NSObject

-(instancetype) initWithName:(NSString *) name
                       value:(NSString *) value
                    resource:(HLMBucketResource *) resource;

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* value;
@property (nonatomic, strong) HLMBucketResource* resource;

@end

@interface HLMStringArray : HLMString

-(instancetype) initWithName:(NSString *) name
                      values:(NSArray *) values
                    resource:(HLMBucketResource *) resource;

@property (nonatomic, strong) NSArray* values;

@end

@implementation HLMStrings

+(void) insertString:(GDataXMLElement *) string fromResource:(HLMBucketResource *) resource {
    NSString* name = [string attributeForName:@"name"].stringValue;
    NSString* value = string.stringValue;
    HLMString* stringResource = [[HLMString alloc] initWithName:name
                                                          value:value
                                                       resource:resource];
    NSMutableDictionary* stringMap = self.stringMap;
    NSMutableArray* stringsWithName = stringMap[name];
    if (!stringsWithName) {
        stringsWithName = [NSMutableArray new];
        stringMap[name] = stringsWithName;
    }
    NSUInteger newIndex = [stringsWithName indexOfObject:stringResource
                                           inSortedRange:NSMakeRange(0, stringsWithName.count)
                                                 options:NSBinarySearchingInsertionIndex
                                         usingComparator:^NSComparisonResult(HLMString* obj1, HLMString* obj2) {
                                             return HLMResources.bucketComparator(obj1.resource, obj2.resource);
                                         }];
    [stringsWithName insertObject:stringResource atIndex:newIndex];
}

+(void) insertStringArray:(GDataXMLElement *) stringArray fromResource:(HLMBucketResource *) resource {
    NSLog(@"insertStringArray:fromResource: is a nop");
}

+(NSString *) stringWithName:(NSString *) name {
    HLMDeviceConfig* currentDevice = HLMDeviceConfig.currentDevice;
    NSArray* stringArray = self.stringMap[name];
    for (HLMString* string in stringArray) {
        if ([string.resource.config isSubconfigOfConfig:currentDevice]) {
            return string.value;
        }
    }
    @throw [NSException exceptionWithName:@"HLMStringException"
                                   reason:[NSString stringWithFormat:@"Failed to find a string matching the"
                                           @" current device config under the name `%@`", name]
                                 userInfo:nil];
}

+(NSMutableDictionary *) stringMap {
    static NSMutableDictionary* stringMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* [MAP STRUCTURE]:
         *
         * stringMap[@"{{string_name}}"] -> : @[HLMString] (Ordered by -[HLMString resource])}
         *
         */
        stringMap = [NSMutableDictionary new];
    });
    return stringMap;
}

@end

@implementation HLMString

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

@implementation HLMStringArray

-(instancetype) initWithName:(NSString *) name
                      values:(NSArray *) values
                    resource:(HLMBucketResource *) resource {
    if (self = [super init]) {
        self.name = name;
        self.values = values;
        self.resource = resource;
    }
    return self;
}

-(NSString *) value {
    return self.values.firstObject;
}

@end
