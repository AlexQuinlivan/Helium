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

-(void) loadView {
    UIView* view = self.inflateView;
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

@end
