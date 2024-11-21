//
//  Parser.m
//  ProgressiveLargeFileLoader
//
//  Created by Admin on 21.11.2024.
//

#import "Parser.h"
#include <malloc/malloc.h>

typedef struct {
    NSUInteger starsCount;
    NSUInteger questionMarksCount;
} MaskSide;

typedef struct {
    MaskSide begin;
    MaskSide end;
    const uint8_t* bytes;
    NSUInteger bytesCount;
} MaskConfiguration;

@interface Parser()

@property(nonatomic, strong) NSString* mask;
@property MaskConfiguration maskConfiguration;

@property uint8_t* unparsedBytes;
@property(nonatomic, assign) NSUInteger unparsedBytesCount;

@end

@implementation Parser

- (instancetype)initWithMask:(NSString*)mask {
    self = [super init];
    if(self) {
        self.mask = mask;
        [self prepare];
    }
    return self;
}

- (void)dealloc {
    if(self.unparsedBytes != NULL) {
        free(self.unparsedBytes);
        self.unparsedBytes = NULL;
    }
}

- (void)prepare {
    NSData* data = [self.mask dataUsingEncoding:NSUTF8StringEncoding];
    if(data.length == 0) {
        return;
    }
    
    const uint8_t* bytes = data.bytes;
    
    BOOL hasStarAtBegin = bytes[0] == '*';
    BOOL hasStarAtEnd = bytes[data.length - 1] == '*';
    
    BOOL hasQuestionMarkAtBegin = bytes[0] == '?';
    BOOL hasQuestionMarkAtEnd = bytes[data.length - 1] == '?';
    
    NSUInteger starsCountAtBegin = 0;
    NSUInteger starsCountAtEnd = 0;
    
    NSUInteger questionMarksCountAtBegin = 0;
    NSUInteger questionMarksCountAtEnd = 0;
    
    if(hasStarAtBegin || hasQuestionMarkAtBegin) {
        for(NSUInteger i = 0; i < data.length; i++) {
            uint8_t byte = bytes[i];
            BOOL isStar = byte == '*';
            BOOL isQuestionMark = byte == '?';
            
            if(isStar) {
                starsCountAtBegin++;
            } else if(isQuestionMark) {
                questionMarksCountAtBegin++;
            } else {
                break;
            }
        }
    }
    
    if((hasStarAtEnd || hasQuestionMarkAtEnd) && data.length > 1) {
        for(NSUInteger i = (data.length - 1); i >= 0; i--) {
            uint8_t byte = bytes[i];
            BOOL isStar = byte == '*';
            BOOL isQuestionMark = byte == '?';
            
            if(isStar) {
                starsCountAtEnd++;
            } else if(isQuestionMark) {
                questionMarksCountAtEnd++;
            } else {
                break;
            }
        }
    }
    
    NSUInteger bytesCount = data.length - starsCountAtBegin - questionMarksCountAtBegin - starsCountAtEnd - questionMarksCountAtEnd;
    
    uint8_t* newBytes = malloc(bytesCount);
    [self copyBytes:(bytes + starsCountAtBegin + questionMarksCountAtBegin) newBytes:newBytes count:bytesCount];
    
    MaskConfiguration maskConfiguration = {
        .begin = {
            .starsCount = starsCountAtBegin,
            .questionMarksCount = questionMarksCountAtBegin
        },
            .end = {
                .starsCount = starsCountAtEnd,
                .questionMarksCount = questionMarksCountAtEnd
            },
            .bytes = newBytes,
            .bytesCount = bytesCount
    };
    self.maskConfiguration = maskConfiguration;
}

- (NSData*)parse:(NSData*)data count:(NSUInteger*)linesCount {
    const uint8_t* bytes = data.bytes;
    NSUInteger i = 0;
    NSUInteger length = data.length;
    NSUInteger unparsedBytesCount = 0;
    
    NSMutableData* validData = [NSMutableData new];
    NSUInteger currentlinesCount = 0;
    while((i + unparsedBytesCount) < length) {
        unparsedBytesCount = 0;
        if(bytes[i] == '\r' || bytes[i] == '\n') {
            i++;
            continue;
        }

        for(NSUInteger j = i; j < length; j++) {
            if(bytes[j] != '\r' && bytes[j] != '\n') {
                unparsedBytesCount++;
                continue;
            }
            
            unparsedBytesCount = 0;
            
            NSUInteger previousUnparsedBytesCount = self.unparsedBytesCount;
            NSUInteger lineLength = j - i;
            NSUInteger bytesCount = previousUnparsedBytesCount + lineLength + 1;
            uint8_t newBytes[bytesCount];
            if(previousUnparsedBytesCount > 0) {
                [self copyBytes:self.unparsedBytes newBytes:newBytes count:previousUnparsedBytesCount];
                free(self.unparsedBytes);
                self.unparsedBytes = NULL;
                self.unparsedBytesCount = 0;
            }
            [self copyBytes:(bytes + i) newBytes:(newBytes + previousUnparsedBytesCount) count:lineLength];
            NSUInteger count = (previousUnparsedBytesCount + lineLength);
            BOOL valid = [self checkMask:newBytes count:count];
            if(valid) {
                [validData appendBytes:newBytes length:count];
                [validData appendBytes:(const uint8_t*)"\n" length:1];
                currentlinesCount++;
            }
            
            i = j;
            break;
        }
    }
    
    if(unparsedBytesCount > 0) {
        uint8_t* unparsedBytes = malloc(unparsedBytesCount);
        memcpy(unparsedBytes, &bytes[data.length - unparsedBytesCount], unparsedBytesCount);
        self.unparsedBytes = unparsedBytes;
        self.unparsedBytesCount = unparsedBytesCount;
    }
    
    *linesCount = currentlinesCount;
    return validData;
}

-(BOOL)checkMask:(const uint8_t*)bytes count:(NSUInteger)count {
    const uint8_t* result = [self findSubarray:bytes count:count subbytes:self.maskConfiguration.bytes subcount:self.maskConfiguration.bytesCount];
    if(result == NULL) {
        return NO;
    }
    
    NSUInteger startIndex = result - bytes;
    NSUInteger endIndex = startIndex + self.maskConfiguration.bytesCount;
    if(startIndex == endIndex) {
        return YES;
    }
    if(self.maskConfiguration.begin.questionMarksCount > 0) {
        if(self.maskConfiguration.begin.questionMarksCount != startIndex) {
            return NO;
        }
    } else if(self.maskConfiguration.begin.starsCount == 0 && startIndex != 0) {
        return NO;
    }
    if(self.maskConfiguration.end.questionMarksCount > 0) {
        if((count - endIndex) != self.maskConfiguration.end.questionMarksCount ) {
            return NO;
        }
    } else if(self.maskConfiguration.end.starsCount == 0 && endIndex != count) {
        return NO;
    }
    
    return YES;
}

-(NSString*)bytesToString:(const uint8_t*)bytes length:(size_t)length {
    char* string = malloc(length + 1);
    if(!string) {
        return NULL;
    }
    
    memcpy(string, bytes, length);
    string[length] = '\0';
    
    NSString* nsstring = [NSString stringWithUTF8String:string];
    free(string);
    return nsstring;
}

-(void)copyBytes:(const uint8_t*)bytes newBytes:(uint8_t*)newBytes count:(size_t)count {
    memcpy(newBytes, bytes, count);
    newBytes[count] = '\0';
}

-(const uint8_t*)findSubarray:(const uint8_t*)bytes count:(size_t)count subbytes:(const uint8_t*)subbytes subcount:(size_t)subcount {
    if(subcount > count) {
        return NULL;
    }

    for (size_t i = 0; i <= count - subcount; i++) {
        if(memcmp(bytes + i, subbytes, subcount) == 0) {
            return bytes + i;
        }
    }

    return NULL;
}

@end
