//
//  AQLayoutInflator.h
//  Pods
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

@interface AQLayoutInflator : NSObject

-(instancetype) initWithLayout:(NSString *) layoutResource;

-(UIView *) inflate;

@end
