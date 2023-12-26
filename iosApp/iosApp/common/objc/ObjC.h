#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(__attribute__((noescape)) void(^)())tryBlock error:(__autoreleasing NSError **)error;

@end

#endif /* Header_h */
