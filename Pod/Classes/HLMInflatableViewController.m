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

@implementation HLMInflatableViewController

-(instancetype) initWithNibName:(NSString *) nibNameOrNil bundle:(NSBundle *) nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

-(void) loadView {
    UIView* view = self.inflateView;
    view.clipsToBounds = !view.hlm_overridesLayoutGuides;
    UIView* root = [[HLMLayoutRootView alloc] initWithFrame:CGRectZero];
    [root addSubview:view];
    self.view = root;
    root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [HLMViewInjector injectViewsInto:self withRootView:self.view];
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

@end
