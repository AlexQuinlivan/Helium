//
//  HLMViewController.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMViewController.h"
#import "HLMLayoutInflator.h"
#import "HLMLayoutRootView.h"
#import "HLMResources.h"

@implementation HLMViewController

-(instancetype) initWithNibName:(NSString *) nibNameOrNil bundle:(NSBundle *) nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self registerNotifications];
    }
    return self;
}

-(void) dealloc {
    [self unregisterNotifications];
}

-(void) loadView {
#ifdef VC_INFLATION_PERF
    NSDate* inflationStarted = NSDate.date;
#endif
    NSString* newResource = [HLMResources resolveResourcePath:self.layoutResource];
    UIView* view = self.inflateView;
    HLMLayoutRootView* root = [[HLMLayoutRootView alloc] initWithFrame:CGRectZero];
    root.resource = newResource;
    root.rootView = view;
    if (self.isViewLoaded && self.view) {
        // @todo: Replace with some transition api
        root.frame = self.view.frame;
        root.topLayoutGuide = self.topLayoutGuide;
        root.bottomLayoutGuide = self.bottomLayoutGuide;
        [root hlm_setNeedsLayout:YES];
    }
    [root hlm_setNeedsLayout:NO];
    root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = root;
    [HLMViewBinder bindViewsInto:self withRootView:self.view];
#ifdef VC_INFLATION_PERF
    NSLog(@"[VERBOSE]: Inflation took %.1fms", [NSDate.date timeIntervalSinceDate:inflationStarted] * 1000.f);
#endif
}

-(UIView *) inflateView {
    HLMLayoutInflator* inflator = [[HLMLayoutInflator alloc] initWithLayout:self.layoutResource];
    return inflator.inflate;
}

-(NSString *) layoutResource {
    @throw [NSException exceptionWithName:@"HLMAbstractSuperImplementationException"
                                   reason:@"-[HLMInflatableViewController layoutResource] should be overridden."
                                 userInfo:nil];
}

-(void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    HLMLayoutRootView* rootView = ((HLMLayoutRootView *) self.view);
    rootView.topLayoutGuide = self.topLayoutGuide;
    rootView.bottomLayoutGuide = self.bottomLayoutGuide;
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation duration:(NSTimeInterval) duration {
    [[NSNotificationCenter defaultCenter] postNotificationName:HLMDeviceConfigDidChangeNotification object:@(toInterfaceOrientation)];
    [self loadView];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void) registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hlm_keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hlm_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void) unregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(void) hlm_keyboardWillShow:(NSNotification *) notification {
    if (!self.isViewLoaded) {
        return;
    }
    CGRect const frame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    ((HLMLayoutRootView *) self.view).keyboardFrame = frame;
    if (!((HLMLayoutRootView *) self.view).rootView.hlm_overridesKeyboardResizing) {
        [UIView animateWithDuration:0.3f animations:^{
            [self.view hlm_setNeedsLayout:YES];
        }];
    }
}

-(void) hlm_keyboardWillHide:(NSNotification *) notification {
    if (!self.isViewLoaded) {
        return;
    }
    ((HLMLayoutRootView *) self.view).keyboardFrame = CGRectZero;
    if (!((HLMLayoutRootView *) self.view).rootView.hlm_overridesKeyboardResizing) {
        [UIView animateWithDuration:0.3f animations:^{
            [self.view hlm_setNeedsLayout:YES];
        }];
    }
}

@end
