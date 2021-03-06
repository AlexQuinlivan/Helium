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
#import "HLMStyles.h"
#import "HLMLinearLayoutManager.h"
#import "HLMFrameLayoutManager.h"
#import "HLMRelativeLayoutManager.h"
#import "GDataXMLNode.h"
#import "NSString+HLMConvert.h"

static NSString* const HLMInflatorExceptionName = @"HLMLayoutInflatorException";

@interface HLMRawAttribute : NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* value;
@end

@implementation HLMLayoutInflator {
    GDataXMLDocument* layoutXml;
}

-(instancetype) initWithLayout:(NSString *) layoutResource {
    if (self = [super init]) {
        NSString* resourcePath = [NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].bundlePath, [HLMResources resolveResourcePath:layoutResource]];
        NSError* error;
        NSData* data = [[NSFileManager defaultManager] contentsAtPath:resourcePath];
        self->layoutXml = [[GDataXMLDocument alloc] initWithData:data
                                                        encoding:NSUTF8StringEncoding
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
    id inflated = [self inflateViewFromXml:self->layoutXml.rootElement namespaces:@[]];
    if ([inflated isKindOfClass:NSArray.class]) {
        @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                       reason:@"<merge /> used as root element to be inflated"
                                     userInfo:nil];
    }
    return inflated;
}

-(HLMLayoutStandaloneView *) inflateStandalone {
    HLMLayoutStandaloneView* standaloneContainer = [[HLMLayoutStandaloneView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];;
    standaloneContainer.contentView = self.inflate;
    return standaloneContainer;
}

-(NSArray *) inflateAsInclude {
    if ([self->layoutXml.rootElement.name isEqualToString:@"merge"]) {
        NSArray* namespaces = self->layoutXml.rootElement.namespaces ?: @[];
        NSMutableArray* inflatedViews = [NSMutableArray new];
        for (GDataXMLElement* element in self->layoutXml.rootElement.children) {
            if (element.kind != GDataXMLElementKind) {
                continue;
            }
            id inflated = [self inflateViewFromXml:element namespaces:namespaces];
            if ([inflated isKindOfClass:NSArray.class]) {
                [inflatedViews addObjectsFromArray:inflated];
            } else {
                [inflatedViews addObject:inflated];
            }
        }
        return inflatedViews;
    } else {
        id inflated = [self inflateViewFromXml:self->layoutXml.rootElement namespaces:@[]];
        if ([inflated isKindOfClass:NSArray.class]) {
            return inflated;
        }
        return @[inflated];
    }
}

-(id) inflateViewFromXml:(GDataXMLElement *) element namespaces:(NSArray *) namespaces {
    NSString* className = element.name;
    if (!className) {
        @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                       reason:@"Found element with no name"
                                     userInfo:nil];
    }
    if ([@"include" isEqualToString:className]) {
        GDataXMLNode* includeAttr = [element attributeForName:@"view"];
        NSString* includeLayout = includeAttr.stringValue;
        if (!includeLayout) {
            @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                           reason:@"<include /> without view attribute"
                                         userInfo:nil];
        }
        if (element.childCount) {
            @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                           reason:[NSString stringWithFormat:@"<include /> found with children. (View: %@)", includeLayout]
                                         userInfo:nil];
        }
        NSArray* includeViews = [[HLMLayoutInflator alloc] initWithLayout:includeLayout].inflateAsInclude;
        if (includeViews.count == 1) {
            UIView* includeView = includeViews[0];
            [element removeChild:includeAttr];
            [self applyAttributesToView:includeView fromElement:element namespaces:namespaces ignoreRequisites:YES];
            return includeView;
        } else {
            return includeViews;
        }
    } else {
        Class clazz = NSClassFromString(className);
        if (!clazz) {
            @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                           reason:[NSString stringWithFormat:@"Failed to find view with class name \"%@\"", className]
                                         userInfo:nil];
        }
        NSArray* elementNamespaces = element.namespaces;
        if (elementNamespaces.count) {
            NSMutableArray* newNamespaces = [NSMutableArray arrayWithArray:namespaces];
            [newNamespaces addObjectsFromArray:elementNamespaces];
            namespaces = newNamespaces;
        }
        UIView* view = [(UIView *)[clazz alloc] initWithFrame:HLMLayoutInflator.minFrame];
        [self applyAttributesToView:view fromElement:element namespaces:namespaces ignoreRequisites:NO];
        [self inflateChildrenOfView:view fromElement:element namespaces:namespaces];
        if ([view conformsToProtocol:@protocol(HLMLayoutInflationListener)]
            && [view respondsToSelector:@selector(didInflateChildren)]) {
            [view performSelector:@selector(didInflateChildren)];
        }
        return view;
    }
}

-(void) inflateChildrenOfView:(UIView *) view fromElement:(GDataXMLElement *) element namespaces:(NSArray *) namespaces {
    NSArray* children = element.children;
    NSUInteger inflatedCount = 0;
    for (GDataXMLElement* child in children) {
        if (child.kind != GDataXMLElementKind) {
            continue;
        }
        inflatedCount++;
        id inflated = [self inflateViewFromXml:child namespaces:namespaces];
        if ([inflated isKindOfClass:NSArray.class]) {
            for (UIView* child in inflated) {
                [self didInflateView:child asChildOfView:view];
            }
        } else {
            [self didInflateView:inflated asChildOfView:view];
        }
    }
    if (!view.hlm_layoutManager && inflatedCount) {
        @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                       reason:[NSString stringWithFormat:@"View (`%@`) inflated with no layout and has children", element.name]
                                     userInfo:nil];
    }
}

-(void) didInflateView:(UIView *) view asChildOfView:(UIView *) superview {
    [superview addSubview:view];
    if ([superview conformsToProtocol:@protocol(HLMLayoutInflationListener)]
        && [superview respondsToSelector:@selector(didInflateChild:)]) {
        [superview performSelector:@selector(didInflateChild:) withObject:view];
    }
}

-(void) applyAttributesToView:(UIView *) view fromElement:(GDataXMLElement *) element namespaces:(NSArray *) namespaces ignoreRequisites:(BOOL) ignoreRequisites {
    BOOL layoutWidthSet = NO, layoutHeightSet = NO, layoutManagerSet = view.hlm_layoutManager != nil;
    NSArray* attributeElements = element.attributes;
    NSMutableArray* attributes = [[NSMutableArray alloc] initWithCapacity:attributeElements.count];
    for (GDataXMLNode* attribute in attributeElements) {
        if (attribute.kind != GDataXMLAttributeKind) {
            continue;
        }
        NSString* name = attribute.name;
        NSString* value = attribute.stringValue;
        if ([@"helium:style" isEqualToString:name]) {
            value = [value stringByReplacingOccurrencesOfString:@"  " withString:@" "];
            NSArray* components = [value componentsSeparatedByString:@" "];
            for (NSInteger i = components.count-1; i >= 0; i--) {
                NSString* styleName = components[i];
                HLMStyle* style = [HLMStyles styleWithName:styleName];
                while (style) {
                    NSMutableArray* styleAttrs = [[NSMutableArray alloc] initWithCapacity:style.entries.count];
                    for (HLMStyleEntry* entry in style.entries) {
                        HLMRawAttribute* rawAttribute = [HLMRawAttribute new];
                        rawAttribute.name = entry.name;
                        rawAttribute.value = entry.value;
                        [styleAttrs addObject:rawAttribute];
                    }
                    [styleAttrs addObjectsFromArray:attributes];
                    attributes = styleAttrs;
                    style = style.parent;
                }
            }
        } else {
            HLMRawAttribute* rawAttribute = [HLMRawAttribute new];
            rawAttribute.name = name;
            rawAttribute.value = value;
            [attributes addObject:rawAttribute];
        }
    }
    for (HLMRawAttribute* attribute in attributes) {
        NSString* name = attribute.name;
        NSString* value = attribute.value;
        NSString* nmspace = nil;
        for (GDataXMLNode* namespaceCandidate in namespaces) {
            NSString* candidateName = namespaceCandidate.name;
            NSString* candidateNeedle = [NSString stringWithFormat:@"%@:", namespaceCandidate.name];
            NSRange testedRange = [name rangeOfString:candidateNeedle];
            if (testedRange.location == 0) {
                nmspace = candidateName;
                name = [name substringFromIndex:testedRange.length];
                break;
            }
        }
        HLMAttribute* hlmAttribute = [HLMAttributes attributeWithName:name inNamespace:nmspace forView:view];
        if (!hlmAttribute) {
            NSLog(@"[ERROR]: Undeclared attribute `%@` skipped", name);
        } else {
            if ([view respondsToSelector:hlmAttribute.setter]) {
                [self setAttribute:hlmAttribute
                            onView:view
                         withValue:value];
                layoutWidthSet |= [@"layout_width" isEqualToString:name];
                layoutHeightSet |= [@"layout_height" isEqualToString:name];
                layoutManagerSet |= [@"layout" isEqualToString:name];
            } else {
                NSLog(@"[WARNING]: View does not recognise property: %@", hlmAttribute.name);
            }
        }

    }
    if (!ignoreRequisites && (!layoutWidthSet || !layoutHeightSet)) {
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

-(void) setAttribute:(HLMAttribute *) attribute onView:(UIView *) view withValue:(NSString *) value {
    HLMAttributeType type = attribute.type;
    SEL setterSelector = attribute.setter;
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
        MATCH_ATTRIBUTE(ATTRIBUTE_TYPE_VIEW_LAYOUT_MANAGER, id <HLMLayoutManager>, layoutManagerValue);
        case ATTRIBUTE_TYPE_IDENTIFIER:
        case ATTRIBUTE_TYPE_STRING_HASH: {
            void (*method)(id, SEL, NSUInteger) = (void *)setterImp;
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
        case ATTRIBUTE_TYPE_UI_FONT: {
            void (*method)(id, SEL, UIFont*) = (void *)setterImp;
            UIFont* font;
            UIFont* currentFont;
            NSString* fontName = [HLMResources stringValue:value];
            if ([view respondsToSelector:@selector(font)]) {
                currentFont = [(id)view font];
            }
            font = [UIFont fontWithName:fontName size:(currentFont.pointSize) ?: 15];
            method(view, setterSelector, font);
            break;
        }
        case ATTRIBUTE_TYPE_UI_IMAGE: {
            void (*method)(id, SEL, UIImage*) = (void *)setterImp;
            UIImage* image = [UIImage imageNamed:value];
            method(view, setterSelector, image);
            break;
        }
        case ATTRIBUTE_TYPE_UI_IMAGE_RENDERING_MODE: {
            void (*method)(id, SEL, UIImageRenderingMode) = (void *)setterImp;
            UIImageRenderingMode renderingMode;
            if ([@"automatic" isEqualToString:value]) {
                renderingMode = UIImageRenderingModeAutomatic;
            } else if ([@"always_original" isEqualToString:value]) {
                renderingMode = UIImageRenderingModeAlwaysOriginal;
            } else if ([@"always_template" isEqualToString:value]) {
                renderingMode = UIImageRenderingModeAlwaysTemplate;
            } else {
                @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                               reason:[NSString stringWithFormat:@"Unexpected image rendering mode found `%@`", value]
                                             userInfo:nil];
            }
            method(view, setterSelector, renderingMode);
            break;
        }
        case ATTRIBUTE_TYPE_UI_VIEW_CONTENT_MODE: {
            void (*method)(id, SEL, UIViewContentMode) = (void *)setterImp;
            UIViewContentMode contentMode;
            if ([@"fill" isEqualToString:value]) {
                contentMode = UIViewContentModeScaleToFill;
            } else if ([@"aspect_fit" isEqualToString:value]) {
                contentMode = UIViewContentModeScaleAspectFit;
            } else if ([@"aspect_fill" isEqualToString:value]) {
                contentMode = UIViewContentModeScaleAspectFill;
            } else if ([@"redraw" isEqualToString:value]) {
                contentMode = UIViewContentModeRedraw;
            } else if ([@"center" isEqualToString:value]) {
                contentMode = UIViewContentModeCenter;
            } else if ([@"top" isEqualToString:value]) {
                contentMode = UIViewContentModeTop;
            } else if ([@"bottom" isEqualToString:value]) {
                contentMode = UIViewContentModeBottom;
            } else if ([@"left" isEqualToString:value]) {
                contentMode = UIViewContentModeLeft;
            } else if ([@"right" isEqualToString:value]) {
                contentMode = UIViewContentModeRight;
            } else if ([@"top_left" isEqualToString:value]) {
                contentMode = UIViewContentModeTopLeft;
            } else if ([@"top_right" isEqualToString:value]) {
                contentMode = UIViewContentModeTopRight;
            } else if ([@"bottom_left" isEqualToString:value]) {
                contentMode = UIViewContentModeBottomLeft;
            } else if ([@"bottom_right" isEqualToString:value]) {
                contentMode = UIViewContentModeBottomRight;
            } else {
                @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                               reason:[NSString stringWithFormat:@"Unexpected view content mode found `%@`", value]
                                             userInfo:nil];
            }
            method(view, setterSelector, contentMode);
            break;
        }
        case ATTRIBUTE_TYPE_TEXT_ALIGNMENT: {
            void (*method)(id, SEL, NSTextAlignment) = (void *)setterImp;
            NSTextAlignment alignment;
            if ([@"left" isEqualToString:value]) {
                alignment = NSTextAlignmentLeft;
            } else if ([@"right" isEqualToString:value]) {
                alignment = NSTextAlignmentRight;
            } else if ([@"center" isEqualToString:value]) {
                alignment = NSTextAlignmentCenter;
            } else if ([@"justified" isEqualToString:value]) {
                alignment = NSTextAlignmentJustified;
            } else if ([@"natural" isEqualToString:value]) {
                alignment = NSTextAlignmentNatural;
            } else {
                @throw [NSException exceptionWithName:HLMInflatorExceptionName
                                               reason:[NSString stringWithFormat:@"Unexpected text alignment found `%@`", value]
                                             userInfo:nil];
            }
            method(view, setterSelector, alignment);
            break;
        }
        default: {
            NSLog(@"[ERROR]: Unable to set `%@` on view of type `%@`", attribute.name, NSStringFromClass(view.class));
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

@implementation HLMRawAttribute

-(NSString *) description {
    return [NSString stringWithFormat:@"%@=\"%@\"", self.name, self.value];
}

@end
