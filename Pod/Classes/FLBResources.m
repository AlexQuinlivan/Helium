//
//  FLBResources.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBResources.h"
#import "EDSemver.h"

static NSString* const FLBResourcesExceptionName = @"FLBResourcesException";

static NSString* const FLBResourceSeperator = @"/";
static NSString* const FLBResourceViewPrefix = @"@view";
static NSString* const FLBResourceStringPrefix = @"@string";
static NSString* const FLBResourceFloatPrefix = @"@float";
static NSString* const FLBResourceDoublePrefix = @"@double";
static NSString* const FLBResourceIntegerPrefix = @"@integer";
static NSString* const FLBResourceBoolPrefix = @"@bool";
static NSString* const FLBResourceColorPrefix = @"@color";

// language > uiidiom > sw > w > h > orientation > density > version
static uint8_t const FLBDeviceLanguagePriority = 0x80;
static uint8_t const FLBDeviceUIIdiomPriority = 0x40;
static uint8_t const FLBDeviceShortestWidthPriority = 0x20;
static uint8_t const FLBDeviceWidthPriority = 0x10;
static uint8_t const FLBDeviceHeightPriority = 0x08;
static uint8_t const FLBDeviceOrientationPriority = 0x04;
static uint8_t const FLBDeviceDensityPriority = 0x02;
static uint8_t const FLBDeviceVersionPriority = 0x01;


@interface FLBDeviceConfig : NSObject
-(instancetype) initWithQualifiers:(NSArray *) qualifiers;
-(BOOL) isSubconfigOfConfig:(FLBDeviceConfig *) config;
-(NSComparisonResult) compareQualifiers:(FLBDeviceConfig *) config;
@property (nonatomic, strong) NSString* orientation;
@property (nonatomic, strong) NSString* scale;
@property (nonatomic, strong) NSString* uiIdiom;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSNumber* width;
@property (nonatomic, strong) NSNumber* height;
@property (nonatomic, strong) EDSemver* systemVersion;
@property (nonatomic, readonly) NSNumber* shortestWidth;
@property (nonatomic) uint8_t priority;
+(FLBDeviceConfig *) currentDevice;
@end


@interface FLBBucketResource : NSObject
@property (nonatomic, strong) NSString* path;
@property (nonatomic, strong) FLBDeviceConfig* config;
@end


@interface FLBResourceTuple : NSObject
-(instancetype) initWithResourceId:(NSString *) resourceId;
@property (nonatomic, strong) NSString* resourceType;
@property (nonatomic, strong) NSString* resourceName;
@end


@implementation FLBResources

+(void) initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        (void) [self buckets];
    });
}

// @layout
// @view which one? They mean different things in this context
// Should this return a file/data?
+(NSString *) resolveResourcePath:(NSString *) resourceId {
    if (!resourceId) {
        return nil;
    }
    // TODO: Load resource with bucket qualifiers (disussion)
    FLBResourceTuple* tuple = [[FLBResourceTuple alloc] initWithResourceId:resourceId];
    if (!tuple) {
        @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected \"/\" in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
#ifdef DEBUG
    if (!tuple.resourceType.length) {
        @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected resource type in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
    if (!tuple.resourceName.length) {
        @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected resource name in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
#endif
    if ([FLBResourceViewPrefix isEqualToString:tuple.resourceType]) {
        FLBDeviceConfig* currentDevice = FLBDeviceConfig.currentDevice;
        NSArray* resources = self.buckets[resourceId];
        for (FLBBucketResource* resource in resources) {
            NSLog(@"%@", resource);
            if ([resource.config isSubconfigOfConfig:currentDevice]) {
                return resource.path;
            }
        }
        @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Failed to find resource (%@) that matches the current device config", resourceId]
                                     userInfo:@{@"current_device":currentDevice}];
    } else {
        @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Unexpected resource type \"%@\" in resourceId. resId: %@", tuple.resourceName, resourceId]
                                     userInfo:nil];
    }
}

+(NSString *) resolveResourceValue:(NSString *) resourceId {
    return resourceId; // todo:
}

+(NSString *) stringValue:(NSString *) stringResource {
    FLBResourceTuple* tuple = [[FLBResourceTuple alloc] initWithResourceId:stringResource];
    NSString* value = nil;
    if (tuple) {
        if ([FLBResourceStringPrefix isEqualToString:tuple.resourceType]) {
            value = NSLocalizedString(tuple.resourceName, nil);
        } else {
            @throw [self unexpectedResourceExceptionParsing:@"NSString*" withResourceId:stringResource];
        }
    } else {
        value = stringResource;
    }
    return value;
}

+(NSNumber *) numberValue:(NSString *) numberResource {
    FLBResourceTuple* tuple = [[FLBResourceTuple alloc] initWithResourceId:numberResource];
    NSNumber* value = nil;
    if (tuple) {
        // todo
        if ([FLBResourceIntegerPrefix isEqualToString:tuple.resourceType]) {
        } else if ([FLBResourceFloatPrefix isEqualToString:tuple.resourceType]) {
        } else if ([FLBResourceDoublePrefix isEqualToString:tuple.resourceType]) {
        } else if ([FLBResourceBoolPrefix isEqualToString:tuple.resourceType]) {
        } else {
            @throw [self unexpectedResourceExceptionParsing:@"NSNumber*" withResourceId:numberResource];
        }
    } else {
        if ([numberResource containsString:@"."]) {
            value = @([numberResource floatValue]);
        } else if ([self.boolAliases containsObject:numberResource]) {
            value = @([numberResource boolValue]);
        } else {
            value = @([numberResource longLongValue]);
        }
    }
    return value;
}

+(NSInteger) integerValue:(NSString *) integerResource {
    return [[self numberValue:integerResource] integerValue];
}

+(NSUInteger) unsignedIntegerValue:(NSString *) unsignedIntegerResource {
    return (NSUInteger) [[self numberValue:unsignedIntegerResource] longLongValue];
}

+(BOOL) boolValue:(NSString *) boolResource {
    return [[self numberValue:boolResource] boolValue];
}

+(int) intValue:(NSString *) intResource {
    return [[self numberValue:intResource] intValue];
}

+(unichar) charValue:(NSString *) charResource {
    NSString* stringValue = [self stringValue:charResource];
    if (!stringValue.length) {
        @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                       reason:@"Loading charValue on an empty string"
                                     userInfo:nil];
    }
    unichar value = [stringValue characterAtIndex:0];
    return value;
}

+(long) longValue:(NSString *) longResource {
    return (long) [self integerValue:longResource];
}

+(float) floatValue:(NSString *) floatResource {
    return [[self numberValue:floatResource] floatValue];
}

+(double) doubleValue:(NSString *) doubleResource {
    return [[self numberValue:doubleResource] doubleValue];
}

+(CGFloat) cgFloatValue:(NSString *) cgFloatResource {
    return (CGFloat) [self floatValue:cgFloatResource];
}

+(CGRect) cgRectValue:(NSString *) cgRectResource {
    CGFloat floatValue = [self cgFloatValue:cgRectResource];
    return CGRectMake(floatValue, floatValue, floatValue, floatValue);
}

+(CGSize) cgSizeValue:(NSString *) cgSizeResource {
    CGFloat floatValue = [self cgFloatValue:cgSizeResource];
    return CGSizeMake(floatValue, floatValue);
}

+(CGPoint) cgPointValue:(NSString *) cgPointResource {
    CGFloat floatValue = [self cgFloatValue:cgPointResource];
    return CGPointMake(floatValue, floatValue);
}

+(UIEdgeInsets) uiEdgeInsetsValue:(NSString *) uiEdgeInsetsResource {
    CGFloat floatValue = [self cgFloatValue:uiEdgeInsetsResource];
    return UIEdgeInsetsMake(floatValue, floatValue, floatValue, floatValue);
}

+(UIColor *) uiColorValue:(NSString *) uiColorResource {
    NSString* colorString = [self resolveResourceValue:uiColorResource];
    NSUInteger length = colorString.length;
    if (!(length == 4 || length == 5 || length == 7 || length == 9)
        || [colorString characterAtIndex:0] != '#') {
        @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                       reason:@"Unexpected color format `%@`. Colors should be in the form #rgb, #argb, #rrggbb or #aarrggbb"
                                     userInfo:nil];
    }
    unsigned short a = 255, r, g, b;
    NSScanner* scanner = [NSScanner scannerWithString:colorString];
    [scanner setScanLocation:1];
    if (length == 4 || length == 5) {
        unsigned hex;
        [scanner scanHexInt:&hex];
        a = (length == 5) ? ((hex & 0xF000) >> 12) * 0x11 : a;
        r = ((hex & 0xF00) >> 8) * 0x11;
        g = ((hex & 0xF0) >> 4) * 0x11;
        b = (hex & 0xF) * 0x11;
    } else {
        unsigned hex;
        [scanner scanHexInt:&hex];
        a = (length == 9) ? (hex & 0xFF000000) >> 24 : a;
        r = (hex & 0xFF0000) >> 16;
        g = (hex & 0xFF00) >> 8;
        b = (hex & 0xFF);
    }
    UIColor* colorValue = [UIColor colorWithRed:r / 255.0f
                                          green:g / 255.0f
                                           blue:b / 255.0f
                                          alpha:a / 255.0f];
    return colorValue;
}

+(NSException *) unexpectedResourceExceptionParsing:(NSString *) parsing
                                     withResourceId:(NSString *) resourceId {
    return [NSException exceptionWithName:FLBResourcesExceptionName
                                   reason:[NSString stringWithFormat:@"Unexpected resource type when parsing %@ found: \"%@\"", parsing, resourceId]
                                 userInfo:nil];
}

+(NSSet *) boolAliases {
    static NSSet* aliases;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        aliases = [NSSet setWithObjects:@"YES", @"yes", @"TRUE", @"true",
                   @"NO", @"no", @"FALSE", @"false", nil];
    });
    return aliases;
}

+(NSDictionary *) buckets {
    static NSDictionary* buckets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* mutBuckets = [NSMutableDictionary new];
        NSString* resPath = [NSString stringWithFormat:@"%@/res.bundle", [NSBundle mainBundle].bundlePath];
        NSBundle* resBundle = [NSBundle bundleWithPath:resPath];
        NSArray* bucketDirs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[resBundle bundleURL]
                                                             includingPropertiesForKeys:@[]
                                                                                options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                                  error:nil];
        for (NSString* bucketFullPath in bucketDirs) {
            NSString* bucketPath = bucketFullPath.lastPathComponent;
            NSArray* bucketQualifiers = [bucketPath componentsSeparatedByString:@"-"];
            NSString* bucketString = bucketQualifiers[0];
            if (bucketQualifiers.count) {
                bucketQualifiers = [bucketQualifiers subarrayWithRange:NSMakeRange(1, bucketQualifiers.count-1)];
            }
            FLBDeviceConfig* bucketDeviceConfig = [[FLBDeviceConfig alloc] initWithQualifiers:bucketQualifiers];
            NSArray* bucketContents = [resBundle pathsForResourcesOfType:@"xml" inDirectory:bucketPath];
            for (NSString* filePath in bucketContents) {
                NSString* fileName = filePath.lastPathComponent;
                fileName = [fileName substringToIndex:fileName.length - 4]; // - ".xml"
                NSString* resourceId = [NSString stringWithFormat:@"@%@/%@", bucketString, fileName];
                NSMutableArray* resource = mutBuckets[resourceId];
                if (!resource) {
                    resource = [NSMutableArray new];
                    mutBuckets[resourceId] = resource;
                }
                FLBBucketResource* bucketResource = [FLBBucketResource new];
                bucketResource.path = [filePath stringByReplacingOccurrencesOfString:resPath withString:@"res.bundle"];
                bucketResource.config = bucketDeviceConfig;
                NSUInteger newIndex = [resource indexOfObject:bucketResource
                                                inSortedRange:NSMakeRange(0, resource.count)
                                                      options:NSBinarySearchingInsertionIndex
                                              usingComparator:^NSComparisonResult(FLBBucketResource* obj1, FLBBucketResource* obj2) {
                                                  FLBDeviceConfig* config1 = obj1.config;
                                                  FLBDeviceConfig* config2 = obj2.config;
                                                  NSInteger obj1Priority = (NSInteger) config1.priority;
                                                  NSInteger obj2Priority = (NSInteger) config2.priority;
                                                  NSInteger result = obj1Priority - obj2Priority;
                                                  if (!result) {
                                                      return [config1 compareQualifiers:config2];
                                                  } else if (result > 0) {
                                                      return NSOrderedAscending;
                                                  } else {
                                                      return NSOrderedDescending;
                                                  }
                                              }];
                [resource insertObject:bucketResource atIndex:newIndex];
            }
        }
        buckets = mutBuckets;
        NSLog(@"buckets: %@", buckets);
    });
    return buckets;
}

@end


@implementation FLBResourceTuple

-(instancetype) initWithResourceId:(NSString *) resourceId {
    if (self = [super init]) {
        NSRange range = [resourceId rangeOfString:FLBResourceSeperator];
        if (range.location == NSNotFound) {
            return nil;
        }
        self.resourceType = [resourceId substringToIndex:range.location];
        self.resourceName = [resourceId substringFromIndex:range.location+1];
    }
    return self;
}

@end


@implementation FLBDeviceConfig {
    NSNumber* qualifiedShortestWidth;
}

+(FLBDeviceConfig *) currentDevice {
    static FLBDeviceConfig* currentDevice;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentDevice = [FLBDeviceConfig new];
        [currentDevice registerDeviceConfigs];
    });
    return currentDevice;
}

+(NSNumber *) shortestWidthNaN {
    static NSNumber* shortestWidthNaN;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shortestWidthNaN = @-1;
    });
    return shortestWidthNaN;
}

-(instancetype) initWithQualifiers:(NSArray *) qualifiers {
    if (self = [super init]) {
        self->qualifiedShortestWidth = FLBDeviceConfig.shortestWidthNaN;
        uint8_t priority = 0;
        for (NSString* qualifier in qualifiers) {
            uint8_t qualifierPriority = 0;
            if ([@"land" isEqualToString:qualifier]
                || [@"port" isEqualToString:qualifier]) {
                self.orientation = qualifier;
                qualifierPriority = FLBDeviceOrientationPriority;
            } else if ([@"ipad" isEqualToString:qualifier]
                       || [@"iphone" isEqualToString:qualifier]) {
                self.uiIdiom = qualifier;
                qualifierPriority = FLBDeviceUIIdiomPriority;
            } else if ([qualifier hasPrefix:@"sw"]) {
                NSInteger val = [[qualifier substringFromIndex:2] integerValue];
                self->qualifiedShortestWidth = @(val);
                qualifierPriority = FLBDeviceShortestWidthPriority;
            } else if ([qualifier hasPrefix:@"w"]) {
                NSInteger val = [[qualifier substringFromIndex:1] integerValue];
                self.width = @(val);
                qualifierPriority = FLBDeviceWidthPriority;
            } else if ([qualifier hasPrefix:@"h"]) {
                NSInteger val = [[qualifier substringFromIndex:1] integerValue];
                self.height = @(val);
                qualifierPriority = FLBDeviceHeightPriority;
            } else if ([qualifier hasPrefix:@"@"]) {
                self.scale = qualifier;
                qualifierPriority = FLBDeviceDensityPriority;
            } else if ([qualifier hasPrefix:@"v"]) {
                self.systemVersion = [EDSemver semverWithString:qualifier];
                qualifierPriority = FLBDeviceVersionPriority;
            } else if ([NSLocale.ISOLanguageCodes containsObject:qualifier]) {
                self.language = qualifier;
                qualifierPriority = FLBDeviceLanguagePriority;
            } else {
                @throw [NSException exceptionWithName:FLBResourcesExceptionName
                                               reason:[NSString stringWithFormat:@"Unexpected resource qualifier (%@)", qualifier]
                                             userInfo:nil];
            }
            priority |= qualifierPriority;
        }
        self.priority = priority;
    }
    return self;
}

-(void) registerDeviceConfigs {
    self.scale = [NSString stringWithFormat:@"@%gx", [UIScreen mainScreen].scale];
    self.uiIdiom = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"ipad" : @"iphone";
    self.language = [NSBundle mainBundle].preferredLocalizations[0];
    self.systemVersion = [EDSemver semverWithString:[UIDevice currentDevice].systemVersion];
    self.priority = 0xFFFF;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [self orientationDidChange:nil];
}

-(void) orientationDidChange:(NSNotification *) notification {
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            self.orientation = @"land";
            break;
        default:
            self.orientation = @"port";
            break;
    }
    UIScreen* mainScreen = [UIScreen mainScreen];
    self.width = @(mainScreen.bounds.size.width);
    self.height = @(mainScreen.bounds.size.height);
}

-(NSNumber *) shortestWidth {
    if (self->qualifiedShortestWidth) {
        return (self->qualifiedShortestWidth != FLBDeviceConfig.shortestWidthNaN) ? self->qualifiedShortestWidth : nil;
    } else {
        return @(MIN(self.width.integerValue, self.height.integerValue));
    }
}

-(NSString *) description {
    return [NSString stringWithFormat:@"(orientation=%@, scale=%@, width=%@, height=%@, shortestWidth=%@, uiIdiom=%@, language=%@)", self.orientation, self.scale, self.width, self.height, self.shortestWidth, self.uiIdiom, self.language];
}

-(BOOL) isSubconfigOfConfig:(FLBDeviceConfig *) config {
    if (self.orientation && ![self.orientation isEqualToString:config.orientation]) {
        return NO;
    } else if (self.uiIdiom && ![self.uiIdiom isEqualToString:config.uiIdiom]) {
        return NO;
    } else if (self.language && ![self.language isEqualToString:config.language]) {
        return NO;
    } else if ([self compareQualifiers:config] == NSOrderedAscending) {
        return NO;
    }
    return YES;
}

-(NSComparisonResult) compareQualifiers:(FLBDeviceConfig *) config {
    if (self.shortestWidth) {
        NSComparisonResult result = NSOrderedSame;
        result = [config.shortestWidth compare:self.shortestWidth];
        if (result != NSOrderedSame) {
            return result;
        }
    }
    if (self.width) {
        NSComparisonResult result = NSOrderedSame;
        result = [config.width compare:self.width];
        if (result != NSOrderedSame) {
            return result;
        }
    }
    if (self.height) {
        NSComparisonResult result = NSOrderedSame;
        result = [config.height compare:self.height];
        if (result != NSOrderedSame) {
            return result;
        }
    }
    if (self.scale) {
        NSComparisonResult result = NSOrderedSame;
        NSNumber* selfScale = @([[self.scale substringWithRange:NSMakeRange(1, self.scale.length-2)] integerValue]);
        NSNumber* configScale = @([[config.scale substringWithRange:NSMakeRange(1, config.scale.length-2)] integerValue]);
        result = [configScale compare:selfScale];
        if (result != NSOrderedSame) {
            return result;
        }
    }
    if (self.systemVersion) {
        NSComparisonResult result = NSOrderedSame;
        result = [config.systemVersion compare:self.systemVersion];
        if (result != NSOrderedSame) {
            return result;
        }
    }
    return NSOrderedSame;
}

@end

@implementation FLBBucketResource

-(NSString *) description {
    return self.path;
}

@end
