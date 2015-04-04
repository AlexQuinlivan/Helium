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
    static NSDictionary* aliasMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        aliasMap = @{
                     @"layout" : [NSValue valueWithPointer:@selector(setFlb_layoutManager:)],
                     @"padding" : [NSValue valueWithPointer:@selector(setFlb_padding:)],
                     @"margins" : [NSValue valueWithPointer:@selector(setFlb_margins:)],
                     @"orientation" : [NSValue valueWithPointer:@selector(setFlb_orientation:)],
                     @"baseline_child_index" : [NSValue valueWithPointer:@selector(setFlb_baselineChildIndex:)],
                     @"weight_sum" : [NSValue valueWithPointer:@selector(setFlb_weightSum:)],
                     @"gravity" : [NSValue valueWithPointer:@selector(setFlb_gravity:)],
                     };
    });
    return [aliasMap[attributeName] pointerValue];
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
                @"min_width" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"min_height" : @(ATTRIBUTE_TYPE_CG_FLOAT),
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
                @"alpha" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"hidden" : @(ATTRIBUTE_TYPE_BOOL),
                };
    });
    return map;
}

@end
