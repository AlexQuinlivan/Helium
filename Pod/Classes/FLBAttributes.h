//
//  FLBAttributes.h
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FLBAttributeType) {
    ATTRIBUTE_TYPE_STRING,
    ATTRIBUTE_TYPE_NS_NUMBER,
    ATTRIBUTE_TYPE_NS_INTEGER,
    ATTRIBUTE_TYPE_NS_UNSIGNED_INTEGER,
    ATTRIBUTE_TYPE_BOOL,
    ATTRIBUTE_TYPE_INT,
    ATTRIBUTE_TYPE_CHAR,
    ATTRIBUTE_TYPE_LONG,
    ATTRIBUTE_TYPE_FLOAT,
    ATTRIBUTE_TYPE_DOUBLE,
    ATTRIBUTE_TYPE_CG_FLOAT,
    ATTRIBUTE_TYPE_CG_RECT,
    ATTRIBUTE_TYPE_CG_SIZE,
    ATTRIBUTE_TYPE_CG_POINT,
    ATTRIBUTE_TYPE_UI_EDGE_INSETS,
    ATTRIBUTE_TYPE_UI_COLOR,
    ATTRIBUTE_TYPE_STRING_HASH,
    ATTRIBUTE_TYPE_VIEW_ORIENTATION,
    ATTRIBUTE_TYPE_VIEW_LAYOUT_RULE,
    ATTRIBUTE_TYPE_VIEW_LAYOUT_MANAGER,
};

@interface FLBAttributes : NSObject

+(FLBAttributeType) attributeTypeForName:(NSString *) attributeName;
+(SEL) selectorAliasForAttributeType:(FLBAttributeType) attributeType;
+(SEL) selectorAliasForAttributeWithName:(NSString *) attributeName;

@end
