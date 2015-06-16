//
//  HLMResources.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMResources.h"
#import "HLMAttributes.h"
#import "HLMStrings.h"
#import "HLMStyles.h"
#import "HLMColors.h"
#import "HLMNumbers.h"
#import "HLMLayoutManagers.h"
#import "GDataXMLNode.h"
#import "EDSemver.h"

static NSString* const HLMResourcesExceptionName = @"HLMResourcesException";

static NSString* const HLMResourceViewPrefix = @"@view";
static NSString* const HLMResourceStringPrefix = @"@string";
static NSString* const HLMResourceFloatPrefix = @"@float";
static NSString* const HLMResourceDoublePrefix = @"@double";
static NSString* const HLMResourceIntegerPrefix = @"@integer";
static NSString* const HLMResourceBoolPrefix = @"@bool";
static NSString* const HLMResourceNumberPrefix = @"@number";
static NSString* const HLMResourceColorPrefix = @"@color";
static NSString* const HLMResourceLayoutManagerPrefix = @"@layout";

NSString* const HLMDeviceConfigDidChangeNotification = @"HLMDeviceConfigDidChangeNotification";

CFStringRef const HLMStringResourceTransformation = CFSTR("Any-Hex/Java");

// language > uiidiom > sw > w > h > orientation > density > version
static uint8_t const HLMDeviceLanguagePriority = 0x80;
static uint8_t const HLMDeviceUIIdiomPriority = 0x40;
static uint8_t const HLMDeviceShortestWidthPriority = 0x20;
static uint8_t const HLMDeviceWidthPriority = 0x10;
static uint8_t const HLMDeviceHeightPriority = 0x08;
static uint8_t const HLMDeviceOrientationPriority = 0x04;
static uint8_t const HLMDeviceDensityPriority = 0x02;
static uint8_t const HLMDeviceVersionPriority = 0x01;


@interface HLMDeviceConfig ()
-(instancetype) initWithQualifiers:(NSArray *) qualifiers;
@end


@interface HLMResourceTuple : NSObject
-(instancetype) initWithResourceId:(NSString *) resourceId;
@property (nonatomic, strong) NSString* resourceType;
@property (nonatomic, strong) NSString* resourceName;
@end


@implementation HLMResources

+(void) initialize {
    [super initialize];
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
    HLMResourceTuple* tuple = [[HLMResourceTuple alloc] initWithResourceId:resourceId];
    if (!tuple) {
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected \"/\" in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
    if (!tuple.resourceType.length) {
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected resource type in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
    if (!tuple.resourceName.length) {
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected resource name in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
    if ([HLMResourceViewPrefix isEqualToString:tuple.resourceType]) {
        HLMDeviceConfig* currentDevice = HLMDeviceConfig.currentDevice;
        NSArray* resources = self.buckets[resourceId];
        for (HLMBucketResource* resource in resources) {
            if ([resource.config isSubconfigOfConfig:currentDevice]) {
                return resource.path;
            }
        }
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Failed to find resource (%@) that matches the current device config", resourceId]
                                     userInfo:@{@"current_device":currentDevice}];
    } else {
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Unexpected resource type \"%@\" in resourceId. resId: %@", tuple.resourceName, resourceId]
                                     userInfo:nil];
    }
}

+(NSArray *) pathsForResource:(NSString *) resource {
    return self.buckets[resource];
}

+(NSString *) stringValue:(NSString *) stringResource {
    HLMResourceTuple* tuple = [[HLMResourceTuple alloc] initWithResourceId:stringResource];
    if (tuple) {
        if ([HLMResourceStringPrefix isEqualToString:tuple.resourceType]) {
            return [self stringValue:[HLMStrings stringWithName:tuple.resourceName]];
        } else {
            @throw [self unexpectedResourceExceptionParsing:@"NSString*" withResourceId:stringResource];
        }
    }
    NSMutableString* mutableStringResource = stringResource.mutableCopy;
    [mutableStringResource replaceOccurrencesOfString:@"\\n"
                                           withString:@"\n"
                                              options:0
                                                range:NSMakeRange(0, mutableStringResource.length)];
    [mutableStringResource replaceOccurrencesOfString:@"\\@"
                                           withString:@"@"
                                              options:0
                                                range:NSMakeRange(0, mutableStringResource.length)];
    CFStringTransform((__bridge CFMutableStringRef) mutableStringResource,
                      NULL, HLMStringResourceTransformation, YES);
    return mutableStringResource;
}

+(NSNumber *) numberValue:(NSString *) numberResource {
    HLMResourceTuple* tuple = [[HLMResourceTuple alloc] initWithResourceId:numberResource];
    NSNumber* value = nil;
    if (tuple) {
        NSString* resourceType = tuple.resourceType;
        if ([HLMResourceNumberPrefix isEqualToString:resourceType]
            || [HLMResourceIntegerPrefix isEqualToString:resourceType]
            || [HLMResourceFloatPrefix isEqualToString:resourceType]
            || [HLMResourceDoublePrefix isEqualToString:resourceType]
            || [HLMResourceBoolPrefix isEqualToString:resourceType]) {
            return [self numberValue:[HLMNumbers numberStringWithName:tuple.resourceName]];
        } else {
            @throw [self unexpectedResourceExceptionParsing:@"NSNumber*" withResourceId:numberResource];
        }
    } else {
        if ([numberResource rangeOfString:@"."].location != NSNotFound) {
            value = @([numberResource doubleValue]);
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
    return [[self numberValue:unsignedIntegerResource] unsignedIntegerValue];
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
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:@"Loading charValue on an empty string"
                                     userInfo:nil];
    }
    unichar value = [stringValue characterAtIndex:0];
    return value;
}

+(long) longValue:(NSString *) longResource {
    return [[self numberValue:longResource] longValue];
}

+(float) floatValue:(NSString *) floatResource {
    return [[self numberValue:floatResource] floatValue];
}

+(double) doubleValue:(NSString *) doubleResource {
    return [[self numberValue:doubleResource] doubleValue];
}

+(CGFloat) cgFloatValue:(NSString *) cgFloatResource {
#if CGFLOAT_IS_DOUBLE
    return [self doubleValue:cgFloatResource];
#else
    return [self floatValue:cgFloatResource];
#endif
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
    HLMResourceTuple* tuple = [[HLMResourceTuple alloc] initWithResourceId:uiColorResource];
    if (tuple) {
        if ([HLMResourceColorPrefix isEqualToString:tuple.resourceType]) {
            return [self uiColorValue:[HLMColors colorStringWithName:tuple.resourceName]];
        } else {
            @throw [self unexpectedResourceExceptionParsing:@"UIColor*" withResourceId:uiColorResource];
        }
    }
    NSString* colorString = uiColorResource;
    NSUInteger length = colorString.length;
    if (!(length == 4 || length == 5 || length == 7 || length == 9)
        || [colorString characterAtIndex:0] != '#') {
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Unexpected color format `%@`. Colors should be in the form #rgb, #argb, #rrggbb or #aarrggbb", uiColorResource]
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

+(id <HLMLayoutManager>) layoutManagerValue:(NSString *) layoutManagerResource {
    HLMResourceTuple* tuple = [[HLMResourceTuple alloc] initWithResourceId:layoutManagerResource];
    if (tuple) {
        if ([HLMResourceLayoutManagerPrefix isEqualToString:tuple.resourceType]) {
            return [self layoutManagerValue:[HLMLayoutManagers layoutManagerClassStringWithName:tuple.resourceName]];
        } else {
            @throw [self unexpectedResourceExceptionParsing:@"id <HLMLayoutManager>" withResourceId:layoutManagerResource];
        }
    }
    return [NSClassFromString(layoutManagerResource) new];
}

+(NSException *) unexpectedResourceExceptionParsing:(NSString *) parsing
                                     withResourceId:(NSString *) resourceId {
    return [NSException exceptionWithName:HLMResourcesExceptionName
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
        [self addBundleWithName:@"res" toBuckets:mutBuckets];
        [self addBundleWithName:@"helium_res" toBuckets:mutBuckets];
        buckets = mutBuckets;
    });
    return buckets;
}

+(void) addBundleWithName:(NSString *) bundleName toBuckets:(NSMutableDictionary *) mutBuckets {
    NSString* resPath = [NSBundle.mainBundle pathForResource:bundleName ofType:@"bundle"];
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
        HLMDeviceConfig* bucketDeviceConfig = [[HLMDeviceConfig alloc] initWithQualifiers:bucketQualifiers];
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
            HLMBucketResource* bucketResource = [HLMBucketResource new];
            NSRange rangeOfResBundle = [filePath rangeOfString:[NSString stringWithFormat:@"%@.bundle", bundleName]];
            bucketResource.path = [filePath substringFromIndex:rangeOfResBundle.location];
            bucketResource.config = bucketDeviceConfig;
            NSUInteger newIndex = [resource indexOfObject:bucketResource
                                            inSortedRange:NSMakeRange(0, resource.count)
                                                  options:NSBinarySearchingInsertionIndex
                                          usingComparator:self.bucketComparator];
            [resource insertObject:bucketResource atIndex:newIndex];
            if ([@"values" isEqualToString:bucketString]) {
                [self loadResources:bucketResource];
            }
        }
    }
}

+(void) loadResources:(HLMBucketResource *) resource {
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@", NSBundle.mainBundle.bundlePath, resource.path];
    NSError* error;
    NSData* data = [[NSFileManager defaultManager] contentsAtPath:fullPath];
    GDataXMLDocument* document = [[GDataXMLDocument alloc] initWithData:data
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&error];
#if DEBUG
    if (![document.rootElement.name isEqualToString:@"resources"]) {
        @throw [NSException exceptionWithName:HLMResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Unexpected root element of a resource file `%@`", document.rootElement.name]
                                     userInfo:nil];
    }
#else
    return;
#endif
    NSArray* resources = document.rootElement.children;
    for (GDataXMLElement* element in resources) {
        if (element.kind != GDataXMLElementKind) {
            continue;
        }
        NSString* elementName = element.name;
        if ([elementName isEqualToString:@"styleable"]) {
            [HLMAttributes insertStyleable:element fromResource:resource];
        } else if ([elementName isEqualToString:@"layout"]) {
            [HLMLayoutManagers insertLayoutManager:element fromResource:resource];
        } else if ([elementName isEqualToString:@"string"]) {
            [HLMStrings insertString:element fromResource:resource];
        } else if ([elementName isEqualToString:@"string-array"]) {
            [HLMStrings insertStringArray:element fromResource:resource];
        } else if ([elementName isEqualToString:@"style"]) {
            [HLMStyles insertStyle:element fromResource:resource];
        } else if ([elementName isEqualToString:@"color"]) {
            [HLMColors insertColor:element fromResource:resource];
        } else if ([elementName isEqualToString:@"number"]) {
            [HLMNumbers insertDouble:element fromResource:resource];
        } else if ([elementName isEqualToString:@"integer"]) {
            [HLMNumbers insertInteger:element fromResource:resource];
        } else if ([elementName isEqualToString:@"bool"]) {
            [HLMNumbers insertBool:element fromResource:resource];
        } else if ([elementName isEqualToString:@"float"]) {
            [HLMNumbers insertFloat:element fromResource:resource];
        } else if ([elementName isEqualToString:@"double"]) {
            [HLMNumbers insertDouble:element fromResource:resource];
        } else {
            NSLog(@"Unsupported: %@", element.name);
        }
    }
}

+(NSComparator) bucketComparator {
    return ^NSComparisonResult(HLMBucketResource* obj1, HLMBucketResource* obj2) {
        BOOL obj1HlmRes = [obj1.path hasPrefix:@"helium_res"];
        BOOL obj2HlmRes = [obj2.path hasPrefix:@"helium_res"];
        if (obj1HlmRes != obj2HlmRes) {
            if (obj1HlmRes) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }
        HLMDeviceConfig* config1 = obj1.config;
        HLMDeviceConfig* config2 = obj2.config;
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
    };
}

@end


@implementation HLMResourceTuple

-(instancetype) initWithResourceId:(NSString *) resourceId {
    if (self = [super init]) {
        if (![resourceId hasPrefix:@"@"]) {
            return nil;
        }
        NSRange range = [resourceId rangeOfString:@"/"];
        if (range.location == NSNotFound) {
            return nil;
        }
        self.resourceType = [resourceId substringToIndex:range.location];
        self.resourceName = [resourceId substringFromIndex:range.location+1];
    }
    return self;
}

@end


@implementation HLMDeviceConfig {
    NSNumber* qualifiedShortestWidth;
}

+(HLMDeviceConfig *) currentDevice {
    static HLMDeviceConfig* currentDevice;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentDevice = [HLMDeviceConfig new];
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
        self->qualifiedShortestWidth = HLMDeviceConfig.shortestWidthNaN;
        uint8_t priority = 0;
        for (NSString* qualifier in qualifiers) {
            uint8_t qualifierPriority = 0;
            if ([@"land" isEqualToString:qualifier]
                || [@"port" isEqualToString:qualifier]) {
                self.orientation = qualifier;
                qualifierPriority = HLMDeviceOrientationPriority;
            } else if ([@"ipad" isEqualToString:qualifier]
                       || [@"iphone" isEqualToString:qualifier]) {
                self.uiIdiom = qualifier;
                qualifierPriority = HLMDeviceUIIdiomPriority;
            } else if ([qualifier hasPrefix:@"sw"]) {
                NSInteger val = [[qualifier substringFromIndex:2] integerValue];
                self->qualifiedShortestWidth = @(val);
                qualifierPriority = HLMDeviceShortestWidthPriority;
            } else if ([qualifier hasPrefix:@"w"]) {
                NSInteger val = [[qualifier substringFromIndex:1] integerValue];
                self.width = @(val);
                qualifierPriority = HLMDeviceWidthPriority;
            } else if ([qualifier hasPrefix:@"h"]) {
                NSInteger val = [[qualifier substringFromIndex:1] integerValue];
                self.height = @(val);
                qualifierPriority = HLMDeviceHeightPriority;
            } else if ([qualifier hasPrefix:@"@"]) {
                self.scale = qualifier;
                qualifierPriority = HLMDeviceDensityPriority;
            } else if ([qualifier hasPrefix:@"v"]) {
                self.systemVersion = [EDSemver semverWithString:qualifier];
                qualifierPriority = HLMDeviceVersionPriority;
            } else if ([NSLocale.ISOLanguageCodes containsObject:qualifier]) {
                self.language = qualifier;
                qualifierPriority = HLMDeviceLanguagePriority;
            } else {
                @throw [NSException exceptionWithName:HLMResourcesExceptionName
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
    self.priority = 0xFF;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChangeInViewController:)
                                                 name:HLMDeviceConfigDidChangeNotification
                                               object:nil];
    [self orientationDidChange:nil];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) orientationDidChange:(NSNotification *) notification {
    [self deviceOrientationChanged:[UIApplication sharedApplication].statusBarOrientation];
}

-(void) orientationDidChangeInViewController:(NSNotification *) notification {
    NSNumber* orientation = notification.object;
    [self deviceOrientationChanged:orientation.integerValue];
    NSNumber* temp = self.width;
    self.width = self.height;
    self.height = temp;
}

-(void) deviceOrientationChanged:(UIInterfaceOrientation) orientation {
    switch (orientation) {
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
        return (self->qualifiedShortestWidth != HLMDeviceConfig.shortestWidthNaN) ? self->qualifiedShortestWidth : nil;
    } else {
        return @(MIN(self.width.integerValue, self.height.integerValue));
    }
}

-(NSString *) description {
    return [NSString stringWithFormat:@"(orientation=%@, scale=%@, width=%@, height=%@, shortestWidth=%@, uiIdiom=%@, language=%@)", self.orientation, self.scale, self.width, self.height, self.shortestWidth, self.uiIdiom, self.language];
}

-(BOOL) isSubconfigOfConfig:(HLMDeviceConfig *) config {
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

-(NSComparisonResult) compareQualifiers:(HLMDeviceConfig *) config {
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

@implementation HLMBucketResource

-(NSString *) description {
    return self.path;
}

@end
