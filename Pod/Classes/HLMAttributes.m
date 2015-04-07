//
//  HLMAttributes.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMAttributes.h"

@implementation HLMAttributes

+(HLMAttributeType) attributeTypeForName:(NSString *) attributeName {
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
                     @"layout_width" : [NSValue valueWithPointer:@selector(setHlm_layoutWidth:)],
                     @"layout_height" : [NSValue valueWithPointer:@selector(setHlm_layoutHeight:)],
                     @"layout_gravity" : [NSValue valueWithPointer:@selector(setHlm_layoutGravity:)],
                     @"layout_weight" : [NSValue valueWithPointer:@selector(setHlm_layoutWeight:)],
                     @"layout" : [NSValue valueWithPointer:@selector(setHlm_layoutManager:)],
                     @"min_width" : [NSValue valueWithPointer:@selector(setHlm_minWidth:)],
                     @"min_height" : [NSValue valueWithPointer:@selector(setHlm_minHeight:)],
                     @"padding" : [NSValue valueWithPointer:@selector(setHlm_padding:)],
                     @"padding_left" : [NSValue valueWithPointer:@selector(setHlm_paddingLeft:)],
                     @"padding_top" : [NSValue valueWithPointer:@selector(setHlm_paddingTop:)],
                     @"padding_right" : [NSValue valueWithPointer:@selector(setHlm_paddingRight:)],
                     @"padding_bottom" : [NSValue valueWithPointer:@selector(setHlm_paddingBottom:)],
                     @"margins" : [NSValue valueWithPointer:@selector(setHlm_margins:)],
                     @"margin_left" : [NSValue valueWithPointer:@selector(setHlm_marginLeft:)],
                     @"margin_top" : [NSValue valueWithPointer:@selector(setHlm_marginTop:)],
                     @"margin_right" : [NSValue valueWithPointer:@selector(setHlm_marginRight:)],
                     @"margin_bottom" : [NSValue valueWithPointer:@selector(setHlm_marginBottom:)],
                     @"orientation" : [NSValue valueWithPointer:@selector(setHlm_orientation:)],
                     @"baseline_child_index" : [NSValue valueWithPointer:@selector(setHlm_baselineChildIndex:)],
                     @"weight_sum" : [NSValue valueWithPointer:@selector(setHlm_weightSum:)],
                     @"gravity" : [NSValue valueWithPointer:@selector(setHlm_gravity:)],
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
                @"layout_weight" : @(ATTRIBUTE_TYPE_CG_FLOAT),
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
                @"baseline_child_index" : @(ATTRIBUTE_TYPE_NS_INTEGER),
                @"weight_sum" : @(ATTRIBUTE_TYPE_CG_FLOAT),
                @"gravity" : @(ATTRIBUTE_TYPE_VIEW_GRAVITY),
                };
    });
    return map;
}

@end
