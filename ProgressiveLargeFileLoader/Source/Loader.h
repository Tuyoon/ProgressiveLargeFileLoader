//
//  Loader.h
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Loader : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCompletion:(void(^)(void))completion
                        onDataLoad:(void(^)(NSData*))onDataLoad;
- (void)load:(NSURL*)url;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
