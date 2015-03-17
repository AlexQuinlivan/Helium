//
//  FLBLayoutRootView.m
//  Pods
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import "FLBLayoutRootView.h"
#import "FLBLayout.h"

@implementation FLBLayoutRootView

-(void) layoutSubviews {
    [super layoutSubviews];
    NSUInteger subviewCount = self.subviews.count;
    if (subviewCount > 1) {
        @throw [NSException exceptionWithName:@"FLBLayoutException"
                                       reason:@"FLBLayoutRootView has > 1 subviews. Expected 0..1"
                                     userInfo:nil];
    } else if (subviewCount) {
        UIView* subview = self.subviews[0];
        if (!subview.flb_layoutManager) {
            @throw [NSException exceptionWithName:@"FLBLayoutException"
                                           reason:[NSString stringWithFormat:@"View `(%@)` found in layout pass without layout manager", NSStringFromClass(subview.class)]
                                         userInfo:nil];
        }
        [subview.flb_layoutManager flb_measure:subview];
        [subview.flb_layoutManager flb_layout:subview];
    }
}

@end
