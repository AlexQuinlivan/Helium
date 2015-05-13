//
//  HLMStyles.m
//  Pods
//
//  Created by Alex Quinlivan on 6/05/15.
//
//

#import "HLMStyles.h"
#import "HLMResources.h"
#import "GDataXMLNode.h"

@interface HLMStyle ()

@property (nonatomic, strong) NSString* parentStyleName;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) HLMBucketResource* resource;
@property (nonatomic, strong) NSMutableArray* entries;

-(instancetype) initWithName:(NSString *) name
                 parentStyle:(NSString *) parentName
                    resource:(HLMBucketResource *) resource;
-(void) addItem:(NSString *) name value:(NSString *) value;

@end

@interface HLMStyleEntry ()

+(instancetype) entryWithName:(NSString *) name value:(NSString *) value;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* value;

@end


@implementation HLMStyles

+(void) initialize {
    [super initialize];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self loadStylesFromResources];
    });
}

+(void) loadStylesFromResources {
    NSArray* paths = [HLMResources pathsForResource:@"@values/styles"];
    for (HLMBucketResource* stylePath in paths) {
        NSString* fullPath = [NSString stringWithFormat:@"%@/%@", NSBundle.mainBundle.bundlePath, stylePath.path];
        NSError* error;
        NSData* data = [[NSFileManager defaultManager] contentsAtPath:fullPath];
        GDataXMLDocument* document = [[GDataXMLDocument alloc] initWithData:data
                                                                    options:0
                                                                      error:&error];
        NSArray* styles = [document.rootElement elementsForName:@"style"];
        for (GDataXMLElement* styleData in styles) {
            if (styleData.kind != GDataXMLElementKind) {
                continue;
            }
            NSString* styleName = [styleData attributeForName:@"name"].stringValue;
            NSString* styleParentName = [styleData attributeForName:@"parent"].stringValue;
            if (!styleName.length) {
                @throw [NSException exceptionWithName:@"HLMStyleLoadException"
                                               reason:@"Unexpected style with no name. Styles MUST have a"
                                                      @" name attribute."
                                             userInfo:nil];
            }
            if (!styleParentName.length) {
                styleParentName = nil;
            }
            HLMStyle* style = [[HLMStyle alloc] initWithName:styleName
                                                 parentStyle:styleParentName
                                                    resource:stylePath];
            for (GDataXMLElement* item in styleData.children) {
                if (item.kind != GDataXMLElementKind) {
                    continue;
                }
                NSString* name = [item attributeForName:@"name"].stringValue;
                NSString* value = item.stringValue;
                if (!name.length) {
                    @throw [NSException exceptionWithName:@"HLMStyleLoadException"
                                                   reason:@"Unexpected style item with no name. Style "
                                                          @"items MUST have a name attribute."
                                                 userInfo:nil];
                }
                if (!value.length) {
                    @throw [NSException exceptionWithName:@"HLMStyleLoadException"
                                                   reason:@"Unexpected style item with no value. Style "
                                                          @"items MUST have a value associated with them."
                                                 userInfo:nil];
                }
                [style addItem:name value:value];
            }
            NSMutableArray* stylesWithName = HLMStyles.styleMap[style.name];
            if (!stylesWithName) {
                stylesWithName = [NSMutableArray new];
                HLMStyles.styleMap[style.name] = stylesWithName;
            }
            NSUInteger newIndex = [stylesWithName indexOfObject:style
                                                  inSortedRange:NSMakeRange(0, stylesWithName.count)
                                                        options:NSBinarySearchingInsertionIndex
                                                usingComparator:^NSComparisonResult(HLMStyle* obj1, HLMStyle* obj2) {
                                                    HLMBucketResource* obj1Resource = obj1.resource;
                                                    HLMBucketResource* obj2Resource = obj2.resource;
                                                    return HLMResources.bucketComparator(obj1Resource, obj2Resource);
                                                }];
            [stylesWithName insertObject:style atIndex:newIndex];
        }
    }
}

+(HLMStyle *) styleWithName:(NSString *) name {
    NSParameterAssert(name);
    HLMDeviceConfig* currentDevice = HLMDeviceConfig.currentDevice;
    NSArray* styles = self.styleMap[name];
    for (HLMStyle* style in styles) {
        if ([style.resource.config isSubconfigOfConfig:currentDevice]) {
            return style;
        }
    }
    @throw [NSException exceptionWithName:@"HLMStyleApplyException"
                                   reason:[NSString stringWithFormat:@"Failed to find a style matching the"
                                           @" current device config under the name `%@`. Is there a default"
                                           @" implemenation of this style? (config : %@)", name, HLMDeviceConfig.currentDevice]
                                 userInfo:nil];
}

+(NSMutableDictionary *) styleMap {
    static NSMutableDictionary* styleMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* [MAP STRUCTURE]:
         *
         * styleMap[@"@style/{{style_name}}"] -> @[HLMStyle] (Ordered by -[HLMStyle resource])
         *
         */
        styleMap = [NSMutableDictionary new];
    });
    return styleMap;
}

@end


@implementation HLMStyle

-(instancetype) initWithName:(NSString *) name
                 parentStyle:(NSString *) parentName
                    resource:(HLMBucketResource *) resource {
    if (self = [super init]) {
        self.name = name;
        self.parentStyleName = parentName;
        self.resource = resource;
        self.entries = [NSMutableArray new];
    }
    return self;
}

-(void) addItem:(NSString *) name value:(NSString *) value {
    [self.entries addObject:[HLMStyleEntry entryWithName:name value:value]];
}

-(HLMStyle *) parent {
    if (!self.parentStyleName) {
        return nil;
    } else {
        return [HLMStyles styleWithName:self.parentStyleName];
    }
}

-(NSString *) description {
    return [NSString stringWithFormat:@"<style name=\"%@\"%@>%@</style> (%@)", self.name, (self.parentStyleName) ? [NSString stringWithFormat:@" parent=\"%@\"", self.parentStyleName] : @"", self.entries, self.resource.config];
}

@end


@implementation HLMStyleEntry

+(instancetype) entryWithName:(NSString *) name value:(NSString *) value {
    HLMStyleEntry* entry = [HLMStyleEntry new];
    entry.name = name;
    entry.value = value;
    return entry;
}

-(NSString *) description {
    return [NSString stringWithFormat:@"<item name=\"%@\">%@</item>", self.name, self.value];
}

@end