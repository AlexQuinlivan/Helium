//
//  HLMLayoutRootView.h
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import <UIKit/UIKit.h>
#import "HLMLayout.h"

@protocol HLMLayoutRootView <NSObject>

@property (nonatomic, getter=isDirty) BOOL dirty;

-(BOOL) isInLayout;

@end

@interface HLMLayoutRootView : UIView <HLMLayoutRootView, HLMKeyboardAware>

@property (nonatomic, weak) id<UILayoutSupport> topLayoutGuide;
@property (nonatomic, weak) id<UILayoutSupport> bottomLayoutGuide;
@property (nonatomic, strong) NSString* resource;
@property (nonatomic, weak) UIView* rootView;

@end
