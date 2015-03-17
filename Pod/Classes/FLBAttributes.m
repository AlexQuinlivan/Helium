//
//  FLBAttributes.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBAttributes.h"

@implementation FLBAttributes

+(FLBAttributeType) attributeTypeForName:(NSString *) attributeName {
    NSNumber* type = self.typeMap[attributeName];
    if (type) {
        return [type integerValue];
    } else {
        NSLog(@"[WARNING]: Unkown attribute type, defaulting to NSString: %@", attributeName);
        return ATTRIBUTE_TYPE_STRING;
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

+(SEL) selectorAliasForAttributeType:(FLBAttributeType) attributeType {
    switch (attributeType) {
        case ATTRIBUTE_TYPE_VIEW_LAYOUT_MANAGER:
            return @selector(setFlb_layoutManager:);
        default:
            return nil;
    }
}

#pragma clang diagnostic pop

+(SEL) selectorAliasForAttributeWithName:(NSString *) attributeName {
    return [self selectorAliasForAttributeType:[self attributeTypeForName:attributeName]];
}

//todo: build from values/attrs
+(NSDictionary *) typeMap {
    static NSDictionary* map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
                @"layout_width" : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_RULE),
                @"layout_height" : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_RULE),
                @"layout" : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_MANAGER),
                @"padding_left" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"margins" : @(ATTRIBUTE_TYPE_UI_EDGE_INSETS),
                @"margin_left" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"margin_top" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"margin_right" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"margin_bottom" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"background_color" : @(ATTRIBUTE_TYPE_UI_COLOR),
                @"tag" : @(ATTRIBUTE_TYPE_STRING_HASH),
                @"orientation" : @(ATTRIBUTE_TYPE_VIEW_ORIENTATION),
                };
    });
    return map;
}

@end
