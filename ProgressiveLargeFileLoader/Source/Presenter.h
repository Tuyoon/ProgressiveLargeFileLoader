//
//  Presenter.h
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Presenter;

@protocol PresenterDelegate <NSObject>

-(void)presenterDidUpdateLoadedStrings:(Presenter*)presenter;
-(void)presenterDidFinishLoading:(Presenter*)presenter;

@end

@interface Presenter : NSObject

- (instancetype)initWithDelegate:(id<PresenterDelegate>)delegate;
- (void)load:(NSURL*)url mask:(NSString*)mask;

- (NSUInteger)numberOfStrings;
- (NSString*)stringForIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
