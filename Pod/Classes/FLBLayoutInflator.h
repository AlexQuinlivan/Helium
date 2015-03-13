//
//  FLBLayoutInflator.h
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>
#import "FLBLayout.h"

@interface FLBLayoutInflator : NSObject

-(instancetype) initWithLayout:(NSString *) layoutResource;

-(UIView *) inflate;

@end
