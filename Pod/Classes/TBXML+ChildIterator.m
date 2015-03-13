//
//  TBXML+ChildIterator.m
//  Pods
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import "TBXML+ChildIterator.h"

@implementation TBXML (ChildIterator)

+(void) iterateChildrenOfElement:(TBXMLElement *) parentElement withBlock:(TBXMLIterateBlock) iterateBlock {
    // Obtain first element from parent
    TBXMLElement* element = parentElement->firstChild;
    
    // if element is valid
    while (element) {
        
        // Call the iterateBlock with the element
        iterateBlock(element);
        
        // Obtain the next element
        element = element->nextSibling;
    }
}

@end
