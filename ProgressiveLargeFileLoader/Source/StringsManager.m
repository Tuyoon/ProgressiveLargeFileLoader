//
//  StringsManager.m
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import "StringsManager.h"

static NSUInteger const kPageSize = 1000;

@interface StringsManager()

@property(nonatomic, weak) id<StringsManagerDelegate> delegate;
@property(nonatomic, assign, readwrite) NSUInteger count;
@property(nonatomic, strong) NSMutableArray* linesOffsets;
@property(nonatomic, strong) NSFileHandle* fileHandle;


@property(nonatomic, strong) NSMutableDictionary<NSNumber*, NSString*>* stringsMap;
@property(nonatomic, assign) NSUInteger topIndex;
@property(nonatomic, assign) NSUInteger bottomIndex;
@property(nonatomic, assign) BOOL isLoading;

@property(nonatomic, assign, readonly) NSUInteger offsetInFile;

@end

@implementation StringsManager

- (instancetype)initWithURL:(NSURL*)url delegate:(id<StringsManagerDelegate>)delegate {
    self = [super init];
    if(self) {
        self.delegate = delegate;
        self.stringsMap = [NSMutableDictionary new];
        self.linesOffsets = [NSMutableArray new];
        [NSFileManager.defaultManager createFileAtPath:url.path contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForUpdatingURL:url error:nil];
    }
    return self;
}

- (void)dealloc {
    [self.fileHandle closeFile];
}

// MARK: - Public Methods

- (void)save:(NSData*)data linesCount:(NSUInteger)linesCount {
    if(data.length == 0) {
        return;
    }
    BOOL isInitialData = self.count == 0;
    self.count += linesCount;
    
    if(data) {
        @synchronized (self.fileHandle) {
            [self.fileHandle seekToEndOfFile];
            [self.fileHandle writeData:data];
            if(isInitialData) {
                [self updateStringsForIndex:0];
            }
        }
    }
}

- (NSUInteger)numberOfStrings {
    return self.count;
}

- (NSString*)stringForIndex:(NSUInteger)index {
    NSString* line = self.stringsMap[@(index)];
    [self updateStringsForIndex:index];
    return line ?: @"";
}

// MARK: - Private Methods

- (NSUInteger)offsetInFile {
    if(@available(iOS 13.0, *)) {
        unsigned long long offset;
        [self.fileHandle getOffset:&offset error:nil];
        return offset;
    } else {
        return [self.fileHandle offsetInFile];
    }
}

- (void)seekToFileOffset:(NSUInteger)offset {
    if(@available(iOS 13.0, *)) {
        [self.fileHandle seekToOffset:offset error:nil];
    } else {
        [self.fileHandle seekToFileOffset:offset];
    }
}

- (void)fillStringsForPage:(NSUInteger)index {
    NSUInteger startIndex = self.linesOffsets.count;
    for(NSUInteger i = startIndex; i <= index; i++) {
        NSUInteger lastLineOffset = [self.linesOffsets.lastObject unsignedIntValue];
        [self seekToFileOffset:lastLineOffset];
        [self readNextLine];
        [self.linesOffsets addObject:@(self.offsetInFile)];
    }
}

- (NSString*)readNextLine {
    NSData* lineData = [self.fileHandle readDataOfLength:1];
    NSMutableData* lineBuffer = [NSMutableData data];
    
    while (lineData && [lineData length] > 0) {
        if(*(char*)[lineData bytes] == '\n') {
            break;
        }
        [lineBuffer appendData:lineData];
        lineData = [self.fileHandle readDataOfLength:1];
    }
    
    NSString* line = [[NSString alloc] initWithData:lineBuffer encoding:NSUTF8StringEncoding];
    return line;
}

- (void)updateStringsForIndex:(NSInteger)index {
    if (self.isLoading) {
        return;
    }
    NSUInteger page = index / kPageSize;
    NSInteger start = page * kPageSize - kPageSize;
    if(start < 0) {
        start = 0;
    }
    NSInteger end = MIN(self.count - 1, page * kPageSize + kPageSize + kPageSize);
    if((start > 0 && start < self.topIndex) || end > self.bottomIndex) {
        self.isLoading = YES;
        [self loadStringsForStart:start end:end];
        [self unloadStringsForStart:start end:end];
    } else if(self.count < kPageSize && self.stringsMap.count < self.count) {
        self.isLoading = YES;
        [self loadStringsForStart:0 end:(self.count - 1)];
    }
}

- (void)loadStringsForStart:(NSInteger)start end:(NSUInteger)end {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(start == 0 && self.linesOffsets.count == 0) {
            [self.linesOffsets addObject:@(0)];
        }
        
        NSMutableDictionary<NSNumber *, NSString *> *newLines = [NSMutableDictionary dictionary];
        for (NSInteger i = start; i <= end; i++) {
            if (!self.stringsMap[@(i)]) {
                NSUInteger lineOffset = [self.linesOffsets[i] unsignedIntegerValue];
                [self.fileHandle seekToFileOffset:lineOffset];
                NSString *line = [self readNextLine];
                [self.linesOffsets addObject:@(self.offsetInFile)];
                if (line) {
                    newLines[@(i)] = line;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.stringsMap addEntriesFromDictionary:newLines];
            self.topIndex = start;
            self.bottomIndex = end;
            self.isLoading = NO;
            [self.delegate stringsManagerDidUpdate:self];
        });
    });
}

- (void)unloadStringsForStart:(NSInteger)start end:(NSUInteger)end {
    for (NSNumber *key in [self.stringsMap allKeys]) {
        NSInteger lineIndex = key.integerValue;
        if (lineIndex < start || lineIndex > end) {
            [self.stringsMap removeObjectForKey:key];
        }
    }
}

@end
