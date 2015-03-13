//
//  AQInflatableViewController.m
//  Pods
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "AQInflatableViewController.h"
#import "AQLayoutInflator.h"

@implementation AQInflatableViewController

-(void) loadView {
    UIView* view = self.inflateView;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
    [AQViewInjector injectViewsInto:self withRootView:self.view];
}

-(UIView *) inflateView {
    AQLayoutInflator* inflator = [[AQLayoutInflator alloc] initWithLayout:self.layoutResource];
    return inflator.inflate;
}

-(NSString *) layoutResource {
    @throw [NSException exceptionWithName:@"AQAbstractSuperImplementationException"
                                   reason:@"-[AQInflatableViewController layoutResource] should be overridden."
                                 userInfo:nil];
}

@end
