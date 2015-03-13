//
//  FLBInflatableViewController.m
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "FLBInflatableViewController.h"
#import "FLBLayoutInflator.h"

@implementation FLBInflatableViewController

-(void) loadView {
    UIView* view = self.inflateView;
    self.view = view;
    UIViewAutoresizing mask = UIViewAutoresizingNone;
    mask |= (view.layoutWidth == FLBLayoutRuleFill) ? UIViewAutoresizingFlexibleWidth : 0;
    mask |= (view.layoutHeight == FLBLayoutRuleFill) ? UIViewAutoresizingFlexibleHeight : 0;
    view.autoresizingMask = mask;
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
