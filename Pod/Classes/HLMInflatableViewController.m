//
//  HLMInflatableViewController.m
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "HLMInflatableViewController.h"
#import "HLMLayoutInflator.h"
#import "HLMLayoutRootView.h"
#import "HLMResources.h"

@implementation HLMInflatableViewController

-(instancetype) initWithNibName:(NSString *) nibNameOrNil bundle:(NSBundle *) nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

-(void) loadView {
#ifdef VC_INFLATION_PERF
    NSDate* inflationStarted = NSDate.date;
#endif
    NSString* newResource = [HLMResources resolveResourcePath:self.layoutResource];
    UIView* view = self.inflateView;
    view.clipsToBounds = !view.hlm_overridesLayoutGuides;
    HLMLayoutRootView* root = [[HLMLayoutRootView alloc] initWithFrame:CGRectZero];
    root.resource = newResource;
    root.rootView = view;
    if (self.isViewLoaded && self.view) {
        // @todo: Replace with some transition api
        root.frame = self.view.frame;
        root.topLayoutGuide = self.topLayoutGuide;
        root.bottomLayoutGuide = self.bottomLayoutGuide;
        [root layoutSubviews];
        [root layoutSubviews];
    }
    self.view = root;
    root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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

@end
