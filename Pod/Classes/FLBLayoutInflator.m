//
//  FLBLayoutInflator.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBLayoutInflator.h"
#import "FLBResources.h"
#import "FLBAttributes.h"
#import "TBXML.h"
#import "TBXML+ChildIterator.h"
#import "NSString+Convert.h"

static NSString* const FLBInflatorExceptionName = @"FLBLayoutInflatorException";

@implementation FLBLayoutInflator {
    TBXML* layoutXml;
}

-(instancetype) initWithLayout:(NSString *) layoutResource {
    if (self = [super init]) {
        NSString* resourcePath = [FLBResources resolveResourcePath:layoutResource];
        NSError* tbxmlError;
        self->layoutXml = [TBXML tbxmlWithXMLFile:resourcePath error:&tbxmlError];
        if (tbxmlError) {
            @throw [NSException exceptionWithName:FLBInflatorExceptionName
                                           reason:[NSString stringWithFormat:@"Error loading %@, %@", resourcePath, tbxmlError]
                                         userInfo:@{@"error":tbxmlError}];
        }
    }
    return self;
}

-(UIView *) inflate {
    return [self inflateViewFromXml:self->layoutXml.rootXMLElement];
}

-(UIView *) inflateViewFromXml:(TBXMLElement *) element {
    NSString* className = [TBXML elementName:element];
    if (!className) {
        @throw [NSException exceptionWithName:FLBInflatorExceptionName
                                       reason:@"Found element with no name"
                                     userInfo:nil];
    }
    Class clazz = NSClassFromString(className);
    if (!clazz) {
        @throw [NSException exceptionWithName:FLBInflatorExceptionName
                                       reason:[NSString stringWithFormat:@"Failed to find view with class name \"%@\"", className]
                                     userInfo:nil];
    }
    NSLog(@"[INFO]: Inflating <%@>", className);
    UIView* view = [(UIView *)[clazz alloc] initWithFrame:FLBLayoutInflator.minFrame];
    [self applyAttributesToView:view fromElement:element];
    [self inflateChildrenOfView:view fromElement:element];
    return view;
}

-(void) inflateChildrenOfView:(UIView *) view fromElement:(TBXMLElement *) element {
    [TBXML iterateChildrenOfElement:element
                          withBlock:^(TBXMLElement* child) {
                              UIView* childView = [self inflateViewFromXml:child];
                              [view addSubview:childView];
                          }];
}

-(void) applyAttributesToView:(UIView *) view fromElement:(TBXMLElement *) element {
    __block BOOL layoutWidthSet = NO, layoutHeightSet = NO;
    [TBXML iterateAttributesOfElement:element
                            withBlock:^(TBXMLAttribute* attribute, NSString* name, NSString* value) {
                                NSString* propertyName = [name toCamelCaps];
                                propertyName = [NSString stringWithFormat:@"set%@:", propertyName];
                                SEL propertySel = NSSelectorFromString(propertyName);
                                if ([view respondsToSelector:propertySel]) {
                                    [self performSetter:propertySel onView:view withName:name andValue:value];
                                    layoutWidthSet |= [@"layout_width" isEqualToString:name];
                                    layoutHeightSet |= [@"layout_height" isEqualToString:name];
                                } else {
                                    NSLog(@"[WARNING]: View does not recognise property: %@", propertyName);
                                }
                            }];
    if (!layoutWidthSet || !layoutHeightSet) {
        @throw [NSException exceptionWithName:FLBInflatorExceptionName
                                       reason:[NSString stringWithFormat:@"View (`%@`) inflated without both layout_width and layout_height", [TBXML elementName:element]]
                                     userInfo:nil];
    }
}

#define MATCH_ATTRIBUTE(_attr, _type, _resourcesAccessor) \
case _attr: {\
    void (*method)(id, SEL, _type) = (void *)setterImp;\
    _type resolvedValue = [FLBResources _resourcesAccessor:value];\
    method(view, setterSelector, resolvedValue);\
    break;\
}

-(void) performSetter:(SEL) setterSelector onView:(UIView *) view withName:(NSString *) name andValue:(NSString *) value {
    FLBAttributeType type = [FLBAttributes attributeTypeForName:name];
    IMP setterImp = [view methodForSelector:setterSelector];
    switch (type) {
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_STRING, NSString*, stringValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_NS_NUMBER, NSNumber*, numberValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_NS_INTEGER, NSInteger, integerValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_NS_UNSIGNED_INTEGER, NSUInteger, unsignedIntegerValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_BOOL, BOOL, boolValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_INT, int, intValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_CHAR, unichar, charValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_LONG, long, longValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_FLOAT, float, floatValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_DOUBLE, double, doubleValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_CG_FLOAT, CGFloat, cgFloatValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_CG_RECT, CGRect, cgRectValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_CG_SIZE, CGSize, cgSizeValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_CG_POINT, CGPoint, cgPointValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_UI_EDGE_INSETS, UIEdgeInsets, uiEdgeInsetsValue);
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_UI_COLOR, UIColor*, uiColorValue);
        case ATTRIBUTE_TYPE_STRING_HASH: {
            void (*method)(id, SEL, NSInteger) = (void *)setterImp;\
            NSString* resolvedValue = [FLBResources stringValue:value];\
            method(view, setterSelector, resolvedValue.hash);\
            break;
        }
        case ATTRIBUTE_TYPE_VIEW_ORIENTATION: {
            void (*method)(id, SEL, FLBLayoutOrientation) = (void *)setterImp;\
            NSString* resolvedValue = [FLBResources stringValue:value];\
            FLBLayoutOrientation orientation;
            if ([@"vertical" isEqualToString:resolvedValue]) {
                orientation = FLBLayoutOrientationVertical;
            } else if ([@"horizontal" isEqualToString:resolvedValue]) {
                orientation = FLBLayoutOrientationHorizontal;
            } else {
                @throw [NSException exceptionWithName:FLBInflatorExceptionName
                                               reason:[NSString stringWithFormat:@"Unexpected orientation value `%@`", name]
                                             userInfo:nil];
            }
            method(view, setterSelector, orientation);\
            break;
        }
        case ATTRIBUTE_TYPE_VIEW_LAYOUT_RULE: {
            void (*method)(id, SEL, CGFloat) = (void *)setterImp;
            CGFloat layoutRuled = 0.0f;
            if ([@"match_parent" isEqualToString:value]) {
                layoutRuled = FLBLayoutRuleFill;
            } else if ([@"wrap_content" isEqualToString:value]) {
                layoutRuled = FLBLayoutRuleWrap;
            } else {
                layoutRuled = [FLBResources cgFloatValue:value];
            }
            method(view, setterSelector, layoutRuled);
            break;
        }
        default: {
            NSLog(@"[ERROR]: Unable to set `%@` on view of type `%@`", name, NSStringFromClass(view.class));
            break;
        }
    }
}

+(CGRect) minFrame {
    static CGRect rect;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rect = CGRectMake(0, 0, 1, 1);
    });
    return rect;
}

@end
