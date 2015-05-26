//
//  HLMAttributes.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMAttributes.h"
#import "HLMResources.h"
#import "NSString+Convert.h"
#import "GDataXMLNode.h"
#import <objc/runtime.h>

static NSString* const HLMAttributeFormatIdentifier = @"identifier";
static NSString* const HLMAttributeFormatInteger = @"integer";
static NSString* const HLMAttributeFormatInt = @"int";
static NSString* const HLMAttributeFormatFloat = @"float";
static NSString* const HLMAttributeFormatCGFloat = @"cgfloat";
static NSString* const HLMAttributeFormatBool = @"bool";
static NSString* const HLMAttributeFormatString = @"string";
static NSString* const HLMAttributeFormatGravity = @"gravity";
static NSString* const HLMAttributeFormatLayoutParam = @"layout_param";
static NSString* const HLMAttributeFormatLayoutManager = @"layout_manager";
static NSString* const HLMAttributeFormatLayoutOrientation = @"layout_orientation";
static NSString* const HLMAttributeFormatColor = @"color";
static NSString* const HLMAttributeFormatStringHash = @"string_hash";
static NSString* const HLMAttributeFormatEdgeInsets = @"edge_insets";
static NSString* const HLMAttributeFormatNumber = @"number";
static NSString* const HLMAttributeFormatUnsignedInteger = @"unsigned_integer";
static NSString* const HLMAttributeFormatChar = @"char";
static NSString* const HLMAttributeFormatLong = @"long";
static NSString* const HLMAttributeFormatDouble = @"double";
static NSString* const HLMAttributeFormatCGRect = @"cgrect";
static NSString* const HLMAttributeFormatCGSize = @"cgsize";
static NSString* const HLMAttributeFormatCGPoint = @"cgpoint";
static NSString* const HLMAttributeFormatFont = @"font";
static NSString* const HLMAttributeFormatImage = @"image";
static NSString* const HLMAttributeFormatImageRenderingMode = @"image_rendering_mode";
static NSString* const HLMAttributeFormatContentMode = @"content_mode";
static NSString* const HLMAttributeFormatTextAlignment = @"text_alignment";

static NSString* const HLMAttributesNamespaceDefault = @"default";
static NSString* const HLMAttributesNamespaceHelium = @"helium";
static NSString* const HLMAttributesNamespaceUser = @"user";

@interface HLMAttribute ()

-(instancetype) initWithName:(NSString *) name
                      format:(NSString *) format
               propertyAlias:(NSString *) propertyAlias
                    resource:(HLMBucketResource *) resource
                 styledClass:(Class) clazz;

@property (nonatomic, strong) HLMBucketResource* resource;
@property (nonatomic, strong) Class styledClass;

@end

@implementation HLMAttributes

+(void) insertStyleable:(GDataXMLElement *) styleable fromResource:(HLMBucketResource *) resource {
    NSDictionary* attributeMap = self.attributeMap;
    if (styleable.kind != GDataXMLElementKind) {
        return;
    }
    NSString* styledClassString = [styleable attributeForName:@"name"].stringValue; // @todo: Unused, use this to apply attrs to classes
    Class styledClass = NSClassFromString(styledClassString);
    if (!styledClass) {
        @throw [NSException exceptionWithName:@"HLMAttributesLoadException"
                                       reason:[NSString stringWithFormat:@"Failed to find class for styleable (%@)", styledClassString]
                                     userInfo:nil];
    }
    for (GDataXMLElement* attr in styleable.children) {
        if (attr.kind != GDataXMLElementKind) {
            continue;
        }
        NSString* name = [attr attributeForName:@"name"].stringValue;
        NSString* format = [attr attributeForName:@"format"].stringValue;
        NSString* propertyAlias = [attr attributeForName:@"property_alias"].stringValue;
        HLMAttribute* attribute = [[HLMAttribute alloc] initWithName:name
                                                              format:format
                                                       propertyAlias:propertyAlias
                                                            resource:resource
                                                         styledClass:styledClass];
        NSMutableArray* attributesWithNameAndNamespace = attributeMap[attribute.nmspace][attribute.name];
        if (!attributesWithNameAndNamespace) {
            attributesWithNameAndNamespace = [NSMutableArray new];
            attributeMap[attribute.nmspace][attribute.name] = attributesWithNameAndNamespace;
        }
        NSUInteger newIndex = [attributesWithNameAndNamespace indexOfObject:attribute
                                                              inSortedRange:NSMakeRange(0, attributesWithNameAndNamespace.count)
                                                                    options:NSBinarySearchingInsertionIndex
                                                            usingComparator:^NSComparisonResult(HLMAttribute* obj1, HLMAttribute* obj2) {
                                                                return HLMResources.bucketComparator(obj1.resource, obj2.resource);
                                                            }];
        [attributesWithNameAndNamespace insertObject:attribute atIndex:newIndex];
    }
}

+(NSDictionary *) attributeMap {
    static NSDictionary* attributesMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* [MAP STRUCTURE]:
         *
         * attributesMap[@"{{attribute_namespace}}"] -> 
         *     @{@"{{attribute_name}}" : @[HLMAttribute] (Ordered by -[HLMAttribute resource])}
         *
         */
        attributesMap = @{
            HLMAttributesNamespaceDefault : [NSMutableDictionary new],
            HLMAttributesNamespaceHelium : [NSMutableDictionary new],
            HLMAttributesNamespaceUser : [NSMutableDictionary new],
        };
    });
    return attributesMap;
}

+(HLMAttribute *) attributeWithName:(NSString *) name inNamespace:(NSString *) nmspace forView:(UIView *) view {
    NSParameterAssert(name);
    HLMDeviceConfig* currentDevice = HLMDeviceConfig.currentDevice;
    if (!nmspace || [@"" isEqualToString:nmspace]
        || [HLMAttributesNamespaceDefault isEqualToString:nmspace]) {
        nmspace = HLMAttributesNamespaceDefault;
    } else if (![HLMAttributesNamespaceHelium isEqualToString:nmspace]) {
        nmspace = HLMAttributesNamespaceUser;
    }
    NSArray* attributeArray = self.attributeMap[nmspace][name];
    for (HLMAttribute* attribute in attributeArray) {
        if ([attribute.resource.config isSubconfigOfConfig:currentDevice]
            && [self doesAttribute:attribute applyToView:view]) {
            return attribute;
        }
    }
    @throw [NSException exceptionWithName:@"HLMAttributeException"
                                   reason:[NSString stringWithFormat:@"Failed to find an attribute matching the"
                                           @" current device config under the name `%@%@` applied to a view with type `%@`",
                                           (nmspace) ? [nmspace stringByAppendingString:@":"] : @"", name, NSStringFromClass(view.class)]
                                 userInfo:nil];
}

+(BOOL) doesAttribute:(HLMAttribute *) attribute applyToView:(UIView *) view {
    Class attrClass = attribute.styledClass;
    Class viewClass = view.class;
    do {
        if (attrClass == viewClass) {
            return YES;
        }
        viewClass = class_getSuperclass(viewClass);
    } while (viewClass);
    return NO;
}

@end

@implementation HLMAttribute

-(instancetype) initWithName:(NSString *) name
                      format:(NSString *) format
               propertyAlias:(NSString *) propertyAlias
                    resource:(HLMBucketResource *) resource
                 styledClass:(Class) clazz {
    if (self = [super init]) {
        self.type = [HLMAttribute typeForFormat:format];
        [self extractNameAndNamespaceFromName:name];
        [self extractSelectorsWithName:name propertyAlias:propertyAlias];
        self.resource = resource;
        self.styledClass = clazz;
    }
    return self;
}

// @discussion: Should formats be extensible?
+(HLMAttributeType) typeForFormat:(NSString *) format {
    if (!format) {
        @throw [NSException exceptionWithName:@"HLMAttributeException"
                                       reason:@"Attribute attempted to create without format type"
                                     userInfo:nil];
    }
    static NSDictionary* typeMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeMap = @{
                    HLMAttributeFormatIdentifier : @(ATTRIBUTE_TYPE_IDENTIFIER),
                    HLMAttributeFormatInteger : @(ATTRIBUTE_TYPE_NS_INTEGER),
                    HLMAttributeFormatInt : @(ATTRIBUTE_TYPE_INT),
                    HLMAttributeFormatFloat : @(ATTRIBUTE_TYPE_FLOAT),
                    HLMAttributeFormatCGFloat : @(ATTRIBUTE_TYPE_CG_FLOAT),
                    HLMAttributeFormatBool : @(ATTRIBUTE_TYPE_BOOL),
                    HLMAttributeFormatString : @(ATTRIBUTE_TYPE_STRING),
                    HLMAttributeFormatGravity : @(ATTRIBUTE_TYPE_VIEW_GRAVITY),
                    HLMAttributeFormatLayoutParam : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_PARAM),
                    HLMAttributeFormatLayoutManager : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_MANAGER),
                    HLMAttributeFormatLayoutOrientation : @(ATTRIBUTE_TYPE_VIEW_ORIENTATION),
                    HLMAttributeFormatColor : @(ATTRIBUTE_TYPE_UI_COLOR),
                    HLMAttributeFormatStringHash : @(ATTRIBUTE_TYPE_STRING_HASH),
                    HLMAttributeFormatEdgeInsets : @(ATTRIBUTE_TYPE_UI_EDGE_INSETS),
                    HLMAttributeFormatNumber : @(ATTRIBUTE_TYPE_NS_NUMBER),
                    HLMAttributeFormatUnsignedInteger : @(ATTRIBUTE_TYPE_NS_UNSIGNED_INTEGER),
                    HLMAttributeFormatChar : @(ATTRIBUTE_TYPE_CHAR),
                    HLMAttributeFormatLong : @(ATTRIBUTE_TYPE_LONG),
                    HLMAttributeFormatDouble : @(ATTRIBUTE_TYPE_DOUBLE),
                    HLMAttributeFormatCGRect : @(ATTRIBUTE_TYPE_CG_RECT),
                    HLMAttributeFormatCGSize : @(ATTRIBUTE_TYPE_CG_SIZE),
                    HLMAttributeFormatCGPoint : @(ATTRIBUTE_TYPE_CG_POINT),
                    HLMAttributeFormatFont : @(ATTRIBUTE_TYPE_UI_FONT),
                    HLMAttributeFormatImage : @(ATTRIBUTE_TYPE_UI_IMAGE),
                    HLMAttributeFormatImageRenderingMode : @(ATTRIBUTE_TYPE_UI_IMAGE_RENDERING_MODE),
                    HLMAttributeFormatContentMode : @(ATTRIBUTE_TYPE_UI_VIEW_CONTENT_MODE),
                    HLMAttributeFormatTextAlignment : @(ATTRIBUTE_TYPE_TEXT_ALIGNMENT),
                    };
    });
    NSNumber* type = typeMap[format];
    if (!type) {
        @throw [NSException exceptionWithName:@"HLMAttributeException"
                                       reason:[NSString stringWithFormat:@"Unknown attribute format `%@`", format]
                                     userInfo:nil];
    }
    return type.integerValue;
}

-(void) extractNameAndNamespaceFromName:(NSString *) name {
    NSRange rangeOfColon = [name rangeOfString:@":"];
    if (rangeOfColon.location == NSNotFound) {
        self.name = name;
        self.nmspace = HLMAttributesNamespaceDefault;
    } else {
        NSString* nmspace = [name substringToIndex:rangeOfColon.location];
        if (![nmspace isEqualToString:HLMAttributesNamespaceHelium]) {
            nmspace = HLMAttributesNamespaceUser;
        }
        self.name = [name substringFromIndex:rangeOfColon.location + rangeOfColon.length];
        self.nmspace = nmspace;
    }
}

-(void) extractSelectorsWithName:(NSString *) name propertyAlias:(NSString *) propertyAlias {
    NSString* propertyName = (propertyAlias) ?: name.toCamelCase;
    NSRange firstChar = NSMakeRange(0, 1);
    NSString* capitalizedName = [propertyName stringByReplacingCharactersInRange:firstChar
                                                                      withString:[propertyName substringWithRange:firstChar].capitalizedString];
    NSString* setterName = [NSString stringWithFormat:@"set%@:", capitalizedName];
    self.getter = NSSelectorFromString(propertyName);
    self.setter = NSSelectorFromString(setterName);
}

-(NSString *) description {
    return [NSString stringWithFormat:@"%@ (%@)", NSStringFromClass(self.styledClass), self.resource.description];
}

@end
