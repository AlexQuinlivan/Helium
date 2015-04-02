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

+(SEL) selectorAliasForAttributeWithName:(NSString *) attributeName {
    if ([@"layout" isEqualToString:attributeName]) {
        return @selector(setFlb_layoutManager:);
    } else if ([@"padding" isEqualToString:attributeName]) {
        return @selector(setFlb_padding:);
    } else if ([@"margins" isEqualToString:attributeName]) {
        return @selector(setFlb_margins:);
    }
    return nil;
}

#pragma clang diagnostic pop

//todo: build from values/attrs
+(NSDictionary *) typeMap {
    static NSDictionary* map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
                @"layout_width" : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_PARAM),
                @"layout_height" : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_PARAM),
                @"layout_gravity" : @(ATTRIBUTE_TYPE_VIEW_GRAVITY),
                @"layout" : @(ATTRIBUTE_TYPE_VIEW_LAYOUT_MANAGER),
                @"padding" : @(ATTRIBUTE_TYPE_UI_EDGE_INSETS),
                @"padding_left" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"padding_top" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"padding_right" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"padding_bottom" : @(ATTRIBUTE_TYPE_CG_FLOAT),
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
