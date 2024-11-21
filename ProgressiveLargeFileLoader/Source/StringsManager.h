//
//  StringsManager.h
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class StringsManager;

@protocol StringsManagerDelegate <NSObject>
- (void)stringsManagerDidUpdate:(StringsManager*)stringsManager;
@end

@interface StringsManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSURL*)url delegate:(id<StringsManagerDelegate>)delegate;

- (void)save:(NSData*)data linesCount:(NSUInteger)linesCount;

- (NSUInteger)numberOfStrings;
- (NSString*)stringForIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
