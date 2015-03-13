//
//  AQResources.m
//  Pods
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "AQResources.h"

static NSString* const AQResourcesExceptionName = @"AQResourcesException";

static NSString* const AQResourceSeperator = @"/";
static NSString* const AQResourceViewPrefix = @"@view";
static NSString* const AQResourceStringPrefix = @"@string";
static NSString* const AQResourceFloatPrefix = @"@float";
static NSString* const AQResourceDoublePrefix = @"@double";
static NSString* const AQResourceIntegerPrefix = @"@integer";
static NSString* const AQResourceBoolPrefix = @"@bool";
static NSString* const AQResourceColorPrefix = @"@color";

@interface AQResourceTuple : NSObject
-(instancetype) initWithResourceId:(NSString *) resourceId;
@property (nonatomic, strong) NSString* resourceType;
@property (nonatomic, strong) NSString* resourceName;
@end

@implementation AQResources
AQ_INSTANTIATION_ERROR

// @layout
// @view which one? They mean different things in this context
// Should this return a file/data?
+(NSString *) resolveResourcePath:(NSString *) resourceId {
    if (!resourceId) {
        return nil;
    }
    // TODO: Load resource with bucket qualifiers (disussion)
    AQResourceTuple* tuple = [[AQResourceTuple alloc] initWithResourceId:resourceId];
    if (!tuple) {
        @throw [NSException exceptionWithName:AQResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected \"/\" in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
#ifdef DEBUG
    if (!tuple.resourceType.length) {
        @throw [NSException exceptionWithName:AQResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected resource type in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
    if (!tuple.resourceName.length) {
        @throw [NSException exceptionWithName:AQResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Expected resource name in resourceId. resId: %@", resourceId]
                                     userInfo:nil];
    }
#endif
    if ([AQResourceViewPrefix isEqualToString:tuple.resourceType]) {
        return [NSString stringWithFormat:@"%@%@", tuple.resourceName, @".xml"];
    } else {
        @throw [NSException exceptionWithName:AQResourcesExceptionName
                                       reason:[NSString stringWithFormat:@"Unexpected resource type \"%@\" in resourceId. resId: %@", tuple.resourceName, resourceId]
                                     userInfo:nil];
    }
}

+(NSString *) resolveResourceValue:(NSString *) resourceId {
    return resourceId; // todo:
}

+(NSString *) stringValue:(NSString *) stringResource {
    AQResourceTuple* tuple = [[AQResourceTuple alloc] initWithResourceId:stringResource];
    NSString* value = nil;
    if (tuple) {
        if ([AQResourceStringPrefix isEqualToString:tuple.resourceType]) {
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
    AQResourceTuple* tuple = [[AQResourceTuple alloc] initWithResourceId:numberResource];
    NSNumber* value = nil;
    if (tuple) {
        // todo
        if ([AQResourceIntegerPrefix isEqualToString:tuple.resourceType]) {
        } else if ([AQResourceFloatPrefix isEqualToString:tuple.resourceType]) {
        } else if ([AQResourceDoublePrefix isEqualToString:tuple.resourceType]) {
        } else if ([AQResourceBoolPrefix isEqualToString:tuple.resourceType]) {
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
        @throw [NSException exceptionWithName:AQResourcesExceptionName
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
        @throw [NSException exceptionWithName:AQResourcesExceptionName
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
    return [NSException exceptionWithName:AQResourcesExceptionName
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

@end


@implementation AQResourceTuple

-(instancetype) initWithResourceId:(NSString *) resourceId {
    if (self = [super init]) {
        NSRange range = [resourceId rangeOfString:AQResourceSeperator];
        if (range.location == NSNotFound) {
            return nil;
        }
        self.resourceType = [resourceId substringToIndex:range.location];
        self.resourceName = [resourceId substringFromIndex:range.location+1];
    }
    return self;
}

@end

