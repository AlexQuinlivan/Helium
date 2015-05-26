//
//  HLMLayoutRootView.h
//  Helium
//
//  Created by Alex Quinlivan on 17/03/15.
//
//

#import <UIKit/UIKit.h>

@interface HLMLayoutRootView : UIView

@property (nonatomic, weak) id<UILayoutSupport> topLayoutGuide;
@property (nonatomic, weak) id<UILayoutSupport> bottomLayoutGuide;
@property (nonatomic, strong) NSString* resource;
@property (nonatomic, weak) UIView* rootView;

@end
