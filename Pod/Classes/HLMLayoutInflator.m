//
//  HLMLayoutInflator.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMLayoutInflator.h"
#import "HLMResources.h"
#import "HLMAttributes.h"
#import "HLMLinearLayoutManager.h"
#import "HLMFrameLayoutManager.h"
#import "HLMRelativeLayoutManager.h"
#import "GDataXMLNode.h"
#import "NSString+Convert.h"

static NSString* const HLMInflatorExceptionName = @"HLMLayoutInflatorException";

@implementation HLMLayoutInflator {
    GDataXMLDocument* layoutXml;
}

-(instancetype) initWithLayout:(NSString *) layoutResource {
    if (self = [super init]) {
        NSString* resourcePath = [NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].bundlePath, [HLMResources resolveResourcePath:layoutResource]];
        NSError* error;
        NSData* data = [[NSFileManager defaultManager] contentsAtPath:resourcePath];
        NSLog(@"%@", resourcePath);
        self->layoutXml = [[GDataXMLDocument alloc] initWithData:data
                                                         options:0
                                                           error:&error];
        if (error) {
            @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                           reason:[NSString stringWithFormat:@"Error loading %@, %@", resourcePath, error]
                                         userInfo:@{@"error":error}];
        }
    }
    return self;
}

-(UIView *) inflate {
    return [self inflateViewFromXml:self->layoutXml.rootElement];
}

-(UIView *) inflateViewFromXml:(GDataXMLElement *) element {
    NSString* className = element.name;
    if (!className) {
        @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                       reason:@"Found element with no name"
                                     userInfo:nil];
    }
    Class clazz = NSClassFromString(className);
    if (!clazz) {
        @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                       reason:[NSString stringWithFormat:@"Failed to find view with class name \"%@\"", className]
                                     userInfo:nil];
    }
    NSLog(@"[INFO]: Inflating <%@>", className);
    UIView* view = [(UIView *)[clazz alloc] initWithFrame:HLMLayoutInflator.minFrame];
    view.clipsToBounds = YES;
    [self applyAttributesToView:view fromElement:element];
    [self inflateChildrenOfView:view fromElement:element];
    return view;
}

-(void) inflateChildrenOfView:(UIView *) view fromElement:(GDataXMLElement *) element {
    NSArray* children = element.children;
    for (GDataXMLElement* child in children) {
        UIView* childView = [self inflateViewFromXml:child];
        [view addSubview:childView];
    }
}

-(void) applyAttributesToView:(UIView *) view fromElement:(GDataXMLElement *) element {
    BOOL layoutWidthSet = NO, layoutHeightSet = NO, layoutManagerSet = NO;
    NSArray* attributes = element.attributes;
    for (GDataXMLNode* attribute in attributes) {
        NSString* name = attribute.name;
        NSString* value = attribute.stringValue;
        NSString* propertyName = [name toCamelCaps];
        propertyName = [NSString stringWithFormat:@"set%@:", propertyName];
        SEL propertySel = NSSelectorFromString(propertyName);
        if ([view respondsToSelector:propertySel]
            || [view respondsToSelector:(propertySel = [HLMAttributes selectorAliasForAttributeWithName:name])]) {
            [self performSetter:propertySel onView:view withName:name andValue:value];
            layoutWidthSet |= [@"layout_width" isEqualToString:name];
            layoutHeightSet |= [@"layout_height" isEqualToString:name];
            layoutManagerSet |= [@"layout" isEqualToString:name];
        } else {
            NSLog(@"[WARNING]: View does not recognise property: %@", propertyName);
        }
    }
    if (!layoutManagerSet) {
        //todo: this was incorrect
//        @throw [NSException exceptionWithName:HLMInflatorExceptionName
//                                       reason:[NSString stringWithFormat:@"View (`%@`) inflated without a layout manager being assigned", [TBXML elementName:element]]
//                                     userInfo:nil];
    }
    if (!layoutWidthSet || !layoutHeightSet) {
        @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                       reason:[NSString stringWithFormat:@"View (`%@`) inflated without both layout_width and layout_height", element.name]
                                     userInfo:nil];
    }
}

#define MATCH_ATTRIBUTE(_attr, _type, _resourcesAccessor) \
case _attr: {\
    void (*method)(id, SEL, _type) = (void *)setterImp;\
    _type resolvedValue = [HLMResources _resourcesAccessor:value];\
    method(view, setterSelector, resolvedValue);\
    break;\
}

-(void) performSetter:(SEL) setterSelector onView:(UIView *) view withName:(NSString *) name andValue:(NSString *) value {
    HLMAttributeType type = [HLMAttributes attributeTypeForName:name];
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
            void (*method)(id, SEL, NSInteger) = (void *)setterImp;
            NSString* resolvedValue = [HLMResources stringValue:value];
            method(view, setterSelector, resolvedValue.hash);
            break;
        }
        case ATTRIBUTE_TYPE_VIEW_ORIENTATION: {
            void (*method)(id, SEL, HLMLayoutOrientation) = (void *)setterImp;
            NSString* resolvedValue = [HLMResources stringValue:value];
            HLMLayoutOrientation orientation;
            if ([@"vertical" isEqualToString:resolvedValue]) {
                orientation = HLMLayoutOrientationVertical;
            } else if ([@"horizontal" isEqualToString:resolvedValue]) {
                orientation = HLMLayoutOrientationHorizontal;
            } else {
                @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                               reason:[NSString stringWithFormat:@"Unexpected orientation value `%@`", value]
                                             userInfo:nil];
            }
            method(view, setterSelector, orientation);
            break;
        }
        case ATTRIBUTE_TYPE_VIEW_LAYOUT_PARAM: {
            void (*method)(id, SEL, CGFloat) = (void *)setterImp;
            CGFloat layoutRuled = 0.0f;
            if ([@"match_parent" isEqualToString:value]) {
                layoutRuled = HLMLayoutParamMatch;
            } else if ([@"wrap_content" isEqualToString:value]) {
                layoutRuled = HLMLayoutParamWrap;
            } else {
                layoutRuled = [HLMResources cgFloatValue:value];
            }
            method(view, setterSelector, layoutRuled);
            break;
        }
        case ATTRIBUTE_TYPE_VIEW_LAYOUT_MANAGER: {
            void (*method)(id, SEL, id<HLMLayoutManager>) = (void *)setterImp;
            id<HLMLayoutManager> manager = nil;
            if ([@"linear" isEqualToString:value]) {
                manager = [HLMLinearLayoutManager new];
            } else if ([@"frame" isEqualToString:value]) {
                manager = [HLMFrameLayoutManager new];
            } else if ([@"relative" isEqualToString:value]) {
                manager = [HLMRelativeLayoutManager new];
//            } else if (self.someMapOfUserDefinedLayouts[value]) {
//            todo: Make extensible
            } else {
                @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                               reason:[NSString stringWithFormat:@"Unexpected layout `%@`", value]
                                             userInfo:nil];
            }
            method(view, setterSelector, manager);
            break;
        }
        case ATTRIBUTE_TYPE_VIEW_GRAVITY: {
            void (*method)(id, SEL, HLMGravity) = (void *)setterImp;
            HLMGravity gravity = 0;
            value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSArray* gravityQualifiers = [value componentsSeparatedByString:@"|"];
            for (NSString* qualifier in gravityQualifiers) {
                if ([@"top" isEqualToString:qualifier]) {
                    gravity |= HLMGravityTop;
                } else if ([@"bottom" isEqualToString:qualifier]) {
                    gravity |= HLMGravityBottom;
                } else if ([@"left" isEqualToString:qualifier]) {
                    gravity |= HLMGravityLeft;
                } else if ([@"right" isEqualToString:qualifier]) {
                    gravity |= HLMGravityRight;
                } else if ([@"center_vertical" isEqualToString:qualifier]) {
                    gravity |= HLMGravityCenterVertical;
                } else if ([@"center_horizontal" isEqualToString:qualifier]) {
                    gravity |= HLMGravityCenterHorizontal;
                } else if ([@"fill_vertical" isEqualToString:qualifier]) {
                    gravity |= HLMGravityFillVertical;
                } else if ([@"fill_horizontal" isEqualToString:qualifier]) {
                    gravity |= HLMGravityFillHorizontal;
                } else if ([@"center" isEqualToString:qualifier]) {
                    gravity |= HLMGravityCenter;
                } else if ([@"fill" isEqualToString:qualifier]) {
                    gravity |= HLMGravityFill;
                } else {
                    @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                                   reason:[NSString stringWithFormat:@"Unexpected gravity constant found `%@`", qualifier]
                                                 userInfo:nil];
                }
            }
            method(view, setterSelector, gravity);
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
