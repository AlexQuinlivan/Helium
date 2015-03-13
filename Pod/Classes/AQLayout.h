//
//  AQLayout.h
//  Pods
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AQLayoutRule) {
    AQLayoutRuleWrap = -1, // Orientation size ignores previous values and wraps its layout out subviews
    AQLayoutRuleFill = -2, // Orientation size matches parent's size at layout time
};

typedef NS_ENUM(NSInteger, AQLayoutOrientation) {
    AQLayoutOrientationVertical,
    AQLayoutOrientationHorizontal,
};

/**
 * A protocol that all views allowing subviews at inflation time
 * must conform to if they wish to be inflated.
 */
@protocol AQLayout <NSObject> @end
