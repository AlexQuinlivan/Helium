//
//  AQLayout.m
//  Pods
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "AQLayout.h"
#import "AQAssociatedObjects.h"

#define ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(_type, _name, _camel, _nsvalueaccessor) \
ASSOCIATE_VALUE_NO_SETTER(_type, _name, _camel, _nsvalueaccessor)\
-(void) set##_camel:(_type) val {\
    objc_setAssociatedObject(self, &k##_camel##AssociationKey, @(val), OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
    [self setNeedsLayout];\
}\

@implementation UIView (AQLayoutProperties)

ASSOCIATE_VALUE_NO_SETTER(UIEdgeInsets, margins, Margins, UIEdgeInsetsValue);
-(void) setMargins:(UIEdgeInsets) margins {
    objc_setAssociatedObject(self, &kMarginsAssociationKey,
                             [NSValue valueWithUIEdgeInsets:margins], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsLayout];
}

-(void) setMarginLeft:(CGFloat) marginLeft {
    UIEdgeInsets margins = self.margins;
    margins.left = marginLeft;
    self.margins = margins;
}

-(void) setMarginTop:(CGFloat) marginTop {
    UIEdgeInsets margins = self.margins;
    margins.top = marginTop;
    self.margins = margins;
}

-(void) setMarginRight:(CGFloat) marginRight {
    UIEdgeInsets margins = self.margins;
    margins.right = marginRight;
    self.margins = margins;
}

-(void) setMarginBottom:(CGFloat) marginBottom {
    UIEdgeInsets margins = self.margins;
    margins.bottom = marginBottom;
    self.margins = margins;
}

-(CGFloat) marginLeft {
    return self.margins.left;
}

-(CGFloat) marginTop {
    return self.margins.top;
}

-(CGFloat) marginRight {
    return self.margins.right;
}

-(CGFloat) marginBottom {
    return self.margins.bottom;
}

ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, translationX, TranslationX, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, translationY, TranslationY, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, layoutWidth, LayoutWidth, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, layoutHeight, LayoutHeight, floatValue);
ASSOCIATE_NUMBER_SET_NEEDS_LAYOUT(CGFloat, layoutWeight, LayoutWeight, floatValue);

@end
