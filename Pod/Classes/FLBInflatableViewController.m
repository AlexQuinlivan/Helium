//
//  FLBInflatableViewController.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBInflatableViewController.h"
#import "FLBLayoutInflator.h"
#import "FLBLayoutRootView.h"

@implementation FLBInflatableViewController

-(void) loadView {
    UIView* view = self.inflateView;
    UIView* root = [[FLBLayoutRootView alloc] initWithFrame:CGRectZero];
    [root addSubview:view];
    self.view = root;
    root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [FLBViewInjector injectViewsInto:self withRootView:self.view];
}

-(UIView *) inflateView {
    FLBLayoutInflator* inflator = [[FLBLayoutInflator alloc] initWithLayout:self.layoutResource];
    return inflator.inflate;
}

-(NSString *) layoutResource {
    @throw [NSException exceptionWithName:@"FLBAbstractSuperImplementationException"
                                   reason:@"-[FLBInflatableViewController layoutResource] should be overridden."
                                 userInfo:nil];
}

@end
