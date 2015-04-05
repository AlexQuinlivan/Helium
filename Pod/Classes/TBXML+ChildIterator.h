//
//  TBXML+ChildIterator.h
//  Helium
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "TBXML.h"

@interface TBXML (ChildIterator)

+(void) iterateChildrenOfElement:(TBXMLElement *) anElement
                       withBlock:(TBXMLIterateBlock) iterateBlock;

@end
