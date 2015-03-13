//
//  FLBAssociatedObjects.h
//  FlatBalloon
//
//  Created by Alex Quinlivan on 13/03/15.
//
//

#import <objc/runtime.h>

#define ASSOCIATE_OBJECT(_type, _name, _camel) \
@dynamic _name;\
static char k##_camel##AssociationKey; \
-(void) set##_camel:(_type *) val {\
    objc_setAssociatedObject(self, &k##_camel##AssociationKey, val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
}\
ASSOCIATED_ACCESSOR(_type*, _name, self, &k##_camel##AssociationKey)


#define ASSOCIATE_NUMBER(_type, _name, _camel, _nsnumberaccessor) \
ASSOCIATE_VALUE_NO_SETTER(_type, _name, _camel, _nsnumberaccessor)\
-(void) set##_camel:(_type) val {\
    objc_setAssociatedObject(self, &k##_camel##AssociationKey, @(val), OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
}\


#define ASSOCIATE_VALUE(_type, _name, _camel, _nsvalueaccessor) \
ASSOCIATE_VALUE_NO_SETTER(_type, _name, _camel, _nsvalueaccessor)\
-(void) set##_camel:(_type) val {\
    objc_setAssociatedObject(self, &k##_camel##AssociationKey, [NSValue valueWith##_type:val], OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
}\

#define ASSOCIATE_VALUE_NO_SETTER(_type, _name, _camel, _nsvalueaccessor) \
@dynamic _name;\
static char k##_camel##AssociationKey;\
ASSOCIATED_ACCESSOR(_type, _name, _nsvalueaccessor, &k##_camel##AssociationKey)


#define ASSOCIATED_ACCESSOR(_type, _name, _accessor, _key) \
-(_type) _name {\
    return [objc_getAssociatedObject(self, _key) _accessor];\
}\
