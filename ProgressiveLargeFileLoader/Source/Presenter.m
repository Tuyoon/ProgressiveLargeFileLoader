//
//  Presenter.m
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import "Presenter.h"
#import "Loader.h"
#import "Parser.h"
#import "StringsManager.h"

static NSString* const kLogFileName = @"results.txt";

@interface Presenter()<StringsManagerDelegate>

@property(nonatomic, weak) id<PresenterDelegate> delegate;
@property(nonatomic, strong) Loader* loader;
@property(nonatomic, strong) Parser* parser;
@property(nonatomic, strong) StringsManager* stringsManager;

@property(nonatomic, strong) NSURL* logsURL;
@property(nonatomic, strong) NSOperationQueue* operationQueue;

@property(nonatomic, weak) NSBlockOperation* delegateNotificationOperation;

@end

@implementation Presenter

- (instancetype)initWithDelegate:(id<PresenterDelegate>)delegate {
    self = [super init];
    if(self) {
        self.logsURL = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:kLogFileName];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.delegate = delegate;
    }
    return self;
}

// MARK: - Public Methods

- (void)load:(NSURL*)url mask:(NSString*)mask {
    [self.loader cancel];
    
    self.parser = [[Parser alloc] initWithMask:mask];
    self.stringsManager = [[StringsManager alloc] initWithURL:self.logsURL delegate:self];
    [self.delegate presenterDidUpdateLoadedStrings:self];
    
    __weak typeof(self) weakSelf = self;
    self.loader = [[Loader alloc] initWithCompletion:^{
        [weakSelf completeLoading];
    } onDataLoad:^(NSData* data) {
        [weakSelf saveData:data];
    }];
    [self.loader load:url];
}

- (NSUInteger)numberOfStrings {
    return [self.stringsManager numberOfStrings];
}

- (NSString*)stringForIndex:(NSUInteger)index {
    return [self.stringsManager stringForIndex: index];
}

// MARK: - Private Methods

- (void)saveData:(NSData*)data {
    __weak typeof(self) weakSelf = self;
    NSOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        NSUInteger linesCount = 0;
        NSData* validData = [weakSelf.parser parse:data count:&linesCount];
        [weakSelf.stringsManager save:validData linesCount:linesCount];
    }];
    
    [self.operationQueue addOperation:operation];
}

- (void)completeLoading {
    __weak typeof(self) weakSelf = self;
    [self.operationQueue addOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate presenterDidFinishLoading:weakSelf];
        });
    }];
}

// MARK: - StringsManager

- (void)stringsManagerDidUpdate:(StringsManager*)stringsManager {
    [self.delegate presenterDidUpdateLoadedStrings:self];
}

@end
