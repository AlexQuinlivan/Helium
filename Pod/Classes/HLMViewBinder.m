//
//  HLMViewBinder.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMViewBinder.h"
#import "HLMLayout.h"
#import <objc/runtime.h>

static NSString* const HLMViewBinderPrefix = @"bindview_$$";
static NSString* const HLMViewArrayBinderPrefix = @"bindviews_$$";
static NSString* const HLMControlTargetBindPrefix = @"controltarget_$$";
static NSString* const HLMBinderSeperator = @"_$$";
static NSString* const HLMBinderSettingOptional = @"optional";

@implementation HLMViewBinder

+(void) bindViewsInto:(NSObject *) object withRootView:(UIView *) root {
    
    // Bind views
    unsigned int count;
    Method* methods = class_copyMethodList([object class], &count);
    for (int i = 0; i < count; i++) {
        
        // Get the method to parse
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char* cMethodName = sel_getName(selector);
        NSString* methodName = [NSString stringWithCString:cMethodName encoding:NSUTF8StringEncoding];
        NSString* viewName;
        id bindable;
        
        // Check method name matches pattern
        if ([methodName hasPrefix:HLMViewBinderPrefix]) {
            
            // Extract values from method name
            NSString* binderSetting;
            NSString* hlmidName;
            methodName = [methodName stringByReplacingOccurrencesOfString:HLMViewBinderPrefix withString:@""];
            methodName = [methodName stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSArray* components = [methodName componentsSeparatedByString:HLMBinderSeperator];
            viewName = components[0];
            hlmidName = components[1];
            binderSetting = (components.count > 2) ? components[2] : nil;
            
            // Find the view to bind
            bindable = [root hlm_viewWithId:hlmidName.hash];
            if (!bindable) {
                if ([binderSetting isEqualToString:HLMBinderSettingOptional]) {
                    // Nil setter
                    IMP setterImp = [object methodForSelector:selector];
                    void (*setter)(id, SEL, id) = (void *)setterImp;
                    setter(object, selector, nil);
                    continue;
                } else {
                    @throw [NSException exceptionWithName:@"HLMViewBindingException"
                                                   reason:[NSString stringWithFormat:@"Unable to find view with id `%@`. "
                                                           @"Did you mean for this to be an optional view? "
                                                           @"Try BIND_VIEW_OPTIONAL(prop, id)", hlmidName]
                                                 userInfo:nil];
                }
            }
            
            // Call setter
            IMP setterImp = [object methodForSelector:selector];
            void (*setter)(id, SEL, id) = (void *)setterImp;
            setter(object, selector, bindable);

        } else if ([methodName hasPrefix:HLMViewArrayBinderPrefix]) {
            
            // Extract values from method name
            methodName = [methodName stringByReplacingOccurrencesOfString:HLMViewArrayBinderPrefix withString:@""];
            methodName = [methodName stringByReplacingOccurrencesOfString:@":" withString:@""];
            NSArray* components = [methodName componentsSeparatedByString:HLMBinderSeperator];
            viewName = components[0];
            
            // Find the view to bind
            NSMutableArray* views = [NSMutableArray new];
            for (int i = 1; i < components.count; i++) {
                NSString* hlmidName = components[i];
                UIView* view = [root hlm_viewWithId:hlmidName.hash];
                if (!view) {
                    @throw [NSException exceptionWithName:@"HLMViewBindingException"
                                                   reason:[NSString stringWithFormat:@"Unable to find view with id `%@`. "
                                                           @"Did you mean for this to be an optional view? "
                                                           @"Try BIND_VIEW_OPTIONAL(prop, id)", hlmidName]
                                                 userInfo:nil];
                }
                [views addObject:view];
            }
            bindable = views;
            
            // Call setter
            IMP setterImp = [object methodForSelector:selector];
            void (*setter)(id, SEL, id) = (void *)setterImp;
            setter(object, selector, bindable);
            
        } else if ([methodName hasPrefix:HLMControlTargetBindPrefix]) {
            
            // Extract values from method name
            NSString* binderSetting;
            methodName = [methodName stringByReplacingOccurrencesOfString:HLMControlTargetBindPrefix withString:@""];
            NSArray* components = [methodName componentsSeparatedByString:HLMBinderSeperator];
            NSString* hlmidName = components[0];
            NSString* controlEventName = components[1];
            binderSetting = (components.count > 2) ? components[2] : nil;
            
            // Find the view to bind
            UIView* view = [root hlm_viewWithId:hlmidName.hash];
            if (!view) {
                if ([binderSetting isEqualToString:HLMBinderSettingOptional]) {
                    // Nil setter
                    IMP setterImp = [object methodForSelector:selector];
                    void (*setter)(id, SEL, id) = (void *)setterImp;
                    setter(object, selector, nil);
                    continue;
                } else {
                    @throw [NSException exceptionWithName:@"HLMControlTargetBindingException"
                                                   reason:[NSString stringWithFormat:@"Unable to find view with id `%@`. "
                                                           @"Did you mean for this to be an optional target binding? "
                                                           @"Try BIND_TARGET_OPTIONAL(id, controlEvent)", hlmidName]
                                                 userInfo:nil];
                }
            }
            if (![view isKindOfClass:[UIControl class]]) {
                @throw [NSException exceptionWithName:@"HLMControlTargetBindingException"
                                               reason:[NSString stringWithFormat:@"View with id `%@` and class `%@` "
                                                       @"is not a kind of UIControl. Try making it a UIControl subclass.",
                                                       hlmidName, NSStringFromClass([view class])]
                                             userInfo:nil];
            }
            
            // Get the type of control event
            NSNumber* controlEventNumber = self.controlEventMap[controlEventName];
            if (!controlEventNumber) {
                @throw [NSException exceptionWithName:@"HLMControlTargetBindingException"
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
