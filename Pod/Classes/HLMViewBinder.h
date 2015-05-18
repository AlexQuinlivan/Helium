//
//  HLMViewBinder.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

#define BIND_VIEW(_view, _tag) \
-(void) bindview_$$ ## _view ## _$$ ## _tag:(id) view {\
    self._view = view;\
}

#define BIND_VIEW_OPTIONAL(_view, _tag) \
-(void) bindview_$$ ## _view ## _$$ ## _tag ## _$$optional:(id) view {\
    self._view = view;\
}

#define BIND_VIEWS_1(_viewarray, _tag) \
-(void) bindviews_$$ ## _viewarray ## _$$ ## _tag:(id) views {\
    self._viewarray = views;\
}

#define BIND_VIEWS_2(_viewarray, T1, T2) BIND_VIEWS_1(_viewarray, T1 ## _$$ ## T2)
#define BIND_VIEWS_3(_viewarray, T1, T2, T3) BIND_VIEWS_2(_viewarray, T1, T2 ## _$$ ## T3)
#define BIND_VIEWS_4(_viewarray, T1, T2, T3, T4) BIND_VIEWS_3(_viewarray, T1, T2, T3 ## _$$ ## T4)
#define BIND_VIEWS_5(_viewarray, T1, T2, T3, T4, T5) BIND_VIEWS_4(_viewarray, T1, T2, T3, T4 ## _$$ ## T5)
#define BIND_VIEWS_6(_viewarray, T1, T2, T3, T4, T5, T6) BIND_VIEWS_5(_viewarray, T1, T2, T3, T4, T5 ## _$$ ## T6)
#define BIND_VIEWS_7(_viewarray, T1, T2, T3, T4, T5, T6, T7) BIND_VIEWS_6(_viewarray, T1, T2, T3, T4, T5, T6 ## _$$ ## T7)
#define BIND_VIEWS_8(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8) BIND_VIEWS_7(_viewarray, T1, T2, T3, T4, T5, T6, T7 ## _$$ ## T8)
#define BIND_VIEWS_9(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8, T9) BIND_VIEWS_8(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8 ## _$$ ## T9)
#define BIND_VIEWS_10(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) BIND_VIEWS_9(_viewarray, T1, T2, T3, T4, T5, T6, T7, T8, T9 ## _$$ ## T10)

#define BIND_TARGET(_tag, _ui_control_event) \
-(void) controltarget_$$ ## _tag ## _$$ ## _ui_control_event

#define BIND_TARGET_OPTIONAL(_tag, _ui_control_event) \
-(void) controltarget_$$ ## _tag ## _$$ ## _ui_control_event ## _$$optional

@interface HLMViewBinder : NSObject

+(void) bindViewsInto:(NSObject *) object withRootView:(UIView *) root;

@end
