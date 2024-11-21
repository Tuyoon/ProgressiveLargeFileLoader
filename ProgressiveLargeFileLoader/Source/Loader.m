//
//  Loader.m
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import "Loader.h"

static NSUInteger const kMinimumDataSizeToSave = 100 * 1024;

@interface Loader()<NSURLSessionDataDelegate>

@property(nonatomic, strong) NSURLSession* session;
@property(nonatomic, copy) void (^onDataLoad)(NSData* data);
@property(nonatomic, copy) void (^completion)(void);
@property(nonatomic, strong) NSMutableData* loadedData;

@end

@implementation Loader

- (instancetype)initWithCompletion:(void(^)(void))completion
                        onDataLoad:(void(^)(NSData*))onDataLoad {
    self = [super init];
    if(self) {
        self.onDataLoad = onDataLoad;
        self.completion = completion;
        
        self.session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                                     delegate:self
                                                delegateQueue:NSOperationQueue.mainQueue];
    }
    return self;
}

- (void)load:(NSURL*)url {
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask* task = [self.session dataTaskWithRequest:request];
    [task resume];
}

- (void)cancel {
    [self.session invalidateAndCancel];
}

// MARK: - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask didReceiveData:(NSData*)data {
    if(self.loadedData == nil) {
        self.loadedData = [NSMutableData dataWithData:data];
    } else {
        [self.loadedData appendData:data];
    }
    if(self.loadedData.length >= kMinimumDataSizeToSave) {
        if(self.onDataLoad) {
            self.onDataLoad(self.loadedData);
        }
        self.loadedData = nil;
    }
}

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error {
    if(self.loadedData.length > 0) {
        if(self.onDataLoad) {
            self.onDataLoad(self.loadedData);
        }
    }
    if(self.completion) {
        self.completion();
    }
}

@end
