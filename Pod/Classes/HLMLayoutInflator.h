//
//  HLMLayoutInflator.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>
#import "HLMLayout.h"
#import "HLMLayoutStandaloneView.h"

@interface HLMLayoutInflator : NSObject

-(instancetype) initWithLayout:(NSString *) layoutResource;

-(UIView *) inflate;

// @todo: Describe this
-(HLMLayoutStandaloneView *) inflateStandalone;

@end

@protocol HLMLayoutInflationListener <NSObject>
@optional

// @todo: Better name? Steal onInflate?
-(void) didInflateChildren;

-(void) didInflateChild:(UIView *) childView;

@end
