//
//  FLBViewInjector.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBViewInjector.h"
#import <objc/runtime.h>

static NSString* const FLBViewInjectorPrefix = @"inject_$$";
static NSString* const FLBInjectorSeperator = @"_$$";

@implementation FLBViewInjector

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
        NSString* tagName;
        
        // Check method name matches pattern
        if (![methodName hasPrefix:FLBViewInjectorPrefix]) {
            continue;
        }
        
        // Extract values from method name
        methodName = [methodName stringByReplacingOccurrencesOfString:FLBViewInjectorPrefix withString:@""];
        methodName = [methodName stringByReplacingOccurrencesOfString:@":" withString:@""];
        NSArray* components = [methodName componentsSeparatedByString:FLBInjectorSeperator];
        viewName = components[0];
        tagName = components[1];
        
        // Find the view to inject
        UIView* injectable = [root viewWithTag:tagName.hash];
        if (!injectable) {
            @throw [NSException exceptionWithName:@"FLBViewInjectionException"
                                           reason:[NSString stringWithFormat:@"Unable to find view with tag `%@`", tagName]
                                         userInfo:nil];
        }
        
        // Call setter
        IMP setterImp = [object methodForSelector:selector];
        void (*setter)(id, SEL, id) = (void *)setterImp;
        setter(object, selector, injectable);
        
    }
    free(methods);
    
    // todo: uicontrol-touch-up injection?
}

@end