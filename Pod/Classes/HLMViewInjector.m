//
//  HLMViewInjector.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMViewInjector.h"
#import <objc/runtime.h>

static NSString* const HLMViewInjectorPrefix = @"injectview_$$";
static NSString* const HLMViewArrayInjectorPrefix = @"injectviews_$$";
static NSString* const HLMControlTargetInjectorPrefix = @"viewtarget_$$";
static NSString* const HLMInjectorSeperator = @"_$$";
static NSString* const HLMInjectorSettingOptional = @"optional";

@implementation HLMViewInjector

+(void) injectViewsInto:(NSObject *) object withRootView:(UIView *) root {
    
    // Inject views
    unsigned int count;
    Method* methods = class_copyMethodList([object class], &count);
    for (int i = 0; i < count; i++) {
        
        // Get the method to parse
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char* cMethodName = sel_getName(selector);
        NSString* methodName = [NSString stringWithCString:cMethodName encoding:NSUTF8StringEncoding];
        NSString* viewName;
        id injectable;
        
        // Check method name matches pattern
        if ([methodName hasPrefix:HLMViewInjectorPrefix]) {
            
            // Extract values from method name
            NSString* injectorSetting;
            NSString* tagName;
            methodName = [methodName stringByReplacingOccurrencesOfString:HLMViewInjectorPrefix withString:@""];
            methodName = [methodName stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSArray* components = [methodName componentsSeparatedByString:HLMInjectorSeperator];
            viewName = components[0];
            tagName = components[1];
            injectorSetting = (components.count > 2) ? components[2] : nil;
            
            // Find the view to inject
            injectable = [root viewWithTag:tagName.hash];
            if (!injectable) {
                if ([injectorSetting isEqualToString:HLMInjectorSettingOptional]) {
                    return;
                } else {
                    @throw [NSException exceptionWithName:@"HLMViewInjectionException"
                                                   reason:[NSString stringWithFormat:@"Unable to find view with tag `%@`. "
                                                           @"Did you mean for this to be an optional view? "
                                                           @"Try INJECT_VIEW_OPTIONAL(prop, tag)", tagName]
                                                 userInfo:nil];
                }
            }
            
            // Call setter
            IMP setterImp = [object methodForSelector:selector];
            void (*setter)(id, SEL, id) = (void *)setterImp;
            setter(object, selector, injectable);

        } else if ([methodName hasPrefix:HLMViewArrayInjectorPrefix]) {
            
            // Extract values from method name
            methodName = [methodName stringByReplacingOccurrencesOfString:HLMViewArrayInjectorPrefix withString:@""];
            methodName = [methodName stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSArray* components = [methodName componentsSeparatedByString:HLMInjectorSeperator];
            viewName = components[0];
            
            // Find the view to inject
            NSMutableArray* views = [NSMutableArray new];
            for (int i = 1; i < components.count; i++) {
                NSString* tagName = components[i];
                UIView* view = [root viewWithTag:tagName.hash];
                if (!view) {
                    @throw [NSException exceptionWithName:@"HLMViewInjectionException"
                                                   reason:[NSString stringWithFormat:@"Unable to find view with tag `%@`. "
                                                           @"Did you mean for this to be an optional view? "
                                                           @"Try INJECT_VIEW_OPTIONAL(prop, tag)", tagName]
                                                 userInfo:nil];
                }
                [views addObject:view];
            }
            injectable = views;
            
            // Call setter
            IMP setterImp = [object methodForSelector:selector];
            void (*setter)(id, SEL, id) = (void *)setterImp;
            setter(object, selector, injectable);
            
        } else if ([methodName hasPrefix:HLMControlTargetInjectorPrefix]) {
            
            // Extract values from method name
            methodName = [methodName stringByReplacingOccurrencesOfString:HLMControlTargetInjectorPrefix withString:@""];
            NSArray* components = [methodName componentsSeparatedByString:HLMInjectorSeperator];
            NSString* tagName = components[0];
            NSString* controlEventName = components[1];
            
            // Find the view to inject
            UIView* view = [root viewWithTag:tagName.hash];
            if (!view) {
                @throw [NSException exceptionWithName:@"HLMControlTargetInjectionException"
                                               reason:[NSString stringWithFormat:@"Unable to find view with tag `%@`. "
                                                       @"Did you mean for this to be an optional target injection? "
                                                       @"Try TARGET_OPTIONAL(tag, controlEvent)", tagName]
                                             userInfo:nil];
            }
            if (![view isKindOfClass:[UIControl class]]) {
                @throw [NSException exceptionWithName:@"HLMControlTargetInjectionException"
                                               reason:[NSString stringWithFormat:@"View with tag `%@` and class `%@` "
                                                       @"is not a kind of UIControl. Try making it a UIControl subclass.",
                                                       tagName, NSStringFromClass([view class])]
                                             userInfo:nil];
            }
            
            // Get the type of control event
            NSNumber* controlEventNumber = self.controlEventMap[controlEventName];
            if (!controlEventNumber) {
                @throw [NSException exceptionWithName:@"HLMControlTargetInjectionException"
                                               reason:[NSString stringWithFormat:@"Unknown control event `%@`", controlEventName]
                                             userInfo:nil];
            }
            UIControlEvents controlEvent = [controlEventNumber unsignedIntegerValue];
            
            // Add Target
            [(UIControl *) view addTarget:object
                                   action:selector
                         forControlEvents:controlEvent];
            
        }
        
    }
    free(methods);

}

+(NSDictionary *) controlEventMap {
    
    static NSDictionary* controlEventMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controlEventMap = @{
                            @"UIControlEventTouchDown" : @(UIControlEventTouchDown),
                            @"UIControlEventTouchDownRepeat" : @(UIControlEventTouchDownRepeat),
                            @"UIControlEventTouchDragInside" : @(UIControlEventTouchDragInside),
                            @"UIControlEventTouchDragOutside" : @(UIControlEventTouchDragOutside),
                            @"UIControlEventTouchDragEnter" : @(UIControlEventTouchDragEnter),
                            @"UIControlEventTouchDragExit" : @(UIControlEventTouchDragExit),
                            @"UIControlEventTouchUpInside" : @(UIControlEventTouchUpInside),
                            @"UIControlEventTouchUpOutside" : @(UIControlEventTouchUpOutside),
                            @"UIControlEventTouchCancel" : @(UIControlEventTouchCancel),
                            @"UIControlEventValueChanged" : @(UIControlEventValueChanged),
                            @"UIControlEventEditingDidBegin" : @(UIControlEventEditingDidBegin),
                            @"UIControlEventEditingChanged" : @(UIControlEventEditingChanged),
                            @"UIControlEventEditingDidEnd" : @(UIControlEventEditingDidEnd),
                            @"UIControlEventEditingDidEndOnExit" : @(UIControlEventEditingDidEndOnExit),
                            @"UIControlEventAllTouchEvents" : @(UIControlEventAllTouchEvents),
                            @"UIControlEventAllEditingEvents" : @(UIControlEventAllEditingEvents),
                            @"UIControlEventApplicationReserved" : @(UIControlEventApplicationReserved),
                            @"UIControlEventSystemReserved" : @(UIControlEventSystemReserved),
                            @"UIControlEventAllEvents" : @(UIControlEventAllEvents),
                            };
    });
    return controlEventMap;
    
}

@end
