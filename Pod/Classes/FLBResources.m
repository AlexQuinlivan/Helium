//
//  FLBResources.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBResources.h"

static NSString* const FLBResourcesExceptionName = @"FLBResourcesException";

static NSString* const FLBResourceSeperator = @"/";
static NSString* const FLBResourceViewPrefix = @"@view";
static NSString* const FLBResourceStringPrefix = @"@string";
static NSString* const FLBResourceFloatPrefix = @"@float";
static NSString* const FLBResourceDoublePrefix = @"@double";
static NSString* const FLBResourceIntegerPrefix = @"@integer";
static NSString* const FLBResourceBoolPrefix = @"@bool";
static NSString* const FLBResourceColorPrefix = @"@color";

@interface FLBResourceTuple : NSObject
-(instancetype) initWithResourceId:(NSString *) resourceId;
@property (nonatomic, strong) NSString* resourceType;
@property (nonatomic, strong) NSString* resourceName;
@end

@implementation FLBResources

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
        return [NSString stringWithFormat:@"res.bundle/view/%@%@", tuple.resourceName, @".xml"];
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

