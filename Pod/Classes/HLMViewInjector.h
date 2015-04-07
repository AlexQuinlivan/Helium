//
//  HLMViewInjector.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

#define INJECT_VIEW(_view, _tag) \
-(void) inject_$$ ## _view ## _$$ ## _tag:(id) view {\
    self._view = view;\
}

#define INJECT_VIEW_OPTIONAL(_view, _tag) \
-(void) inject_$$ ## _view ## _$$ ## _tag ## _$$optional:(id) view {\
    self._view = view;\
}

@interface HLMViewInjector : NSObject

+(void) injectViewsInto:(NSObject *) object withRootView:(UIView *) root;

@end
