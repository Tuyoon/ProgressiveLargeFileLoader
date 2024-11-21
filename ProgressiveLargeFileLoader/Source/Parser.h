//
//  Parser.h
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Parser : NSObject

- (instancetype)initWithMask:(NSString*)mask;
- (NSData*)parse:(NSData*)data count:(NSUInteger*)linesCount;

@end

NS_ASSUME_NONNULL_END
