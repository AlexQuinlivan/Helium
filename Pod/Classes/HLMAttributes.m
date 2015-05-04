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
#import <libxml/tree.h>

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

static NSString* const HLMAttributesNamespaceDefault = @"default";
static NSString* const HLMAttributesNamespaceHelium = @"helium";
static NSString* const HLMAttributesNamespaceUser = @"user";

// @todo: This does not listen to device config changes
@implementation HLMAttributes

+(void) initialize {
    [super initialize];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self loadAttributesFromResources];
    });
}

+(void) loadAttributesFromResources {
    NSDictionary* attributeMap = self.attributeMap;
    NSArray* paths = [HLMResources pathsForResource:@"@values/attrs"];
    for (NSString* attrPath in paths) {
        NSString* fullPath = [NSString stringWithFormat:@"%@/%@", NSBundle.mainBundle.bundlePath, attrPath];
        NSError* error;
        NSData* data = [[NSFileManager defaultManager] contentsAtPath:fullPath];
        GDataXMLDocument* document = [[GDataXMLDocument alloc] initWithData:data
                                                                    options:0
                                                                      error:&error];
        NSArray* styleables = [document.rootElement elementsForName:@"styleable"];
        for (GDataXMLElement* styleable in styleables) {
            if (styleable.XMLNode->type == XML_TEXT_NODE) {
                continue;
            }
            NSString* styledClass = [styleable attributeForName:@"name"].stringValue; // @todo: Unused, use this to apply attrs to classes
            for (GDataXMLElement* attr in styleable.children) {
                if (attr.XMLNode->type == XML_TEXT_NODE) {
                    continue;
                }
                NSString* name = [attr attributeForName:@"name"].stringValue;
                NSString* format = [attr attributeForName:@"format"].stringValue;
                NSString* propertyAlias = [attr attributeForName:@"property_alias"].stringValue;
                HLMAttribute* attribute = [[HLMAttribute alloc] initWithName:name
                                                                      format:format
                                                               propertyAlias:propertyAlias];
                attributeMap[attribute.nmspace][attribute.name] = attribute;
            }
        }
    }
}

+(NSDictionary *) attributeMap {
    static NSDictionary* attributesMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        attributesMap = @{
                          HLMAttributesNamespaceDefault : [NSMutableDictionary new],
                          HLMAttributesNamespaceHelium : [NSMutableDictionary new],
                          HLMAttributesNamespaceUser : [NSMutableDictionary new],
                          };
    });
    return attributesMap;
}

+(HLMAttribute *) attributeForName:(NSString *) name inNamespace:(NSString *) nmspace {
    if (!nmspace || [@"" isEqualToString:nmspace]
        || [HLMAttributesNamespaceDefault isEqualToString:nmspace]) {
        nmspace = HLMAttributesNamespaceDefault;
    } else if (![HLMAttributesNamespaceHelium isEqualToString:nmspace]) {
        nmspace = HLMAttributesNamespaceUser;
    }
    return self.attributeMap[nmspace][name];
}

@end

@implementation HLMAttribute

-(instancetype) initWithName:(NSString *) name
                      format:(NSString *) format
               propertyAlias:(NSString *) propertyAlias {
    if (self = [super init]) {
        self.type = [HLMAttribute typeForFormat:format];
        [self extractNameAndNamespaceFromName:name];
        [self extractSelectorsWithName:name propertyAlias:propertyAlias];
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

@end
