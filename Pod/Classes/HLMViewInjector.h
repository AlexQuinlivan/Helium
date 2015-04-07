//
//  HLMViewInjector.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

#define INJECT_VIEW(_view, _tag) \
-(void) injectview_$$ ## _view ## _$$ ## _tag:(id) view {\
    self._view = view;\
}

#define INJECT_VIEW_OPTIONAL(_view, _tag) \
-(void) injectview_$$ ## _view ## _$$ ## _tag ## _$$optional:(id) view {\
    self._view = view;\
}

#define INJECT_VIEWS_1(_viewarray, _tag) \
-(void) injectviews_$$ ## _viewarray ## _$$ ## _tag:(id) views {\
    self._viewarray = views;\
}

#define INJECT_VIEWS_2(_viewarray, T1, T2) INJECT_VIEWS_1(_viewarray, T1 ## _$$ ## T2)
#define INJECT_VIEWS_3(_viewarray, T1, T2, T3) INJECT_VIEWS_2(_viewarray, T1, T2 ## _$$ ## T3)
#define INJECT_VIEWS_4(_viewarray, T1, T2, T3, T4) INJECT_VIEWS_3(_viewarray, T1, T2, T3 ## _$$ ## T4)
#define INJECT_VIEWS_5(_viewarray, T1, T2, T3, T4, T5) INJECT_VIEWS_4(_viewarray, T1, T2, T3, T4 ## _$$ ## T5)
#define INJECT_VIEWS_6(_viewarray, T1, T2, T3, T4, T5, T6) INJECT_VIEWS_5(_viewarray, T1, T2, T3, T4, T5 ## _$$ ## T6)
#define INJECT_VIEWS_7(_viewarray, T1, T2, T3, T4, T5, T6, T7) INJECT_VIEWS_6(_viewarray, T1, T2, T3, T4, T5, T6 ## _$$ ## T7)
#define INJECT_VIEWS_8(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8) INJECT_VIEWS_7(_viewarray, T1, T2, T3, T4, T5, T6, T7 ## _$$ ## T8)
#define INJECT_VIEWS_9(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8, T9) INJECT_VIEWS_8(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8 ## _$$ ## T9)
#define INJECT_VIEWS_10(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) INJECT_VIEWS_9(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8, T9 ## _$$ ## T10)


@interface HLMViewInjector : NSObject

+(void) injectViewsInto:(NSObject *) object withRootView:(UIView *) root;

@end
