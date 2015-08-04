//
//  NSString+HLMConvert.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (HLMConvert)

/**
 *  Convert self from an underscore seperated string to
 *  a camel case seperated string
 *
 *  @return self in camel case
 */
-(NSString*) hlm_toCamelCase;

/**
 *  Convert self from an underscore seperated string to
 *  a camel caps seperated string
 *
 *  @return self in camel caps
 */
-(NSString*) hlm_toCamelCaps;

/**
 *  Convert self from a camel case string to an underscore
 *  seperated string
 *
 *  @return self in underscore seperation
 */
-(NSString*) hlm_toUnderscore;

@end
