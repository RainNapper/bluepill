//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled May 11 2021 09:30:43).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class NSString;

__attribute__((visibility("hidden")))
@interface XCUIRecorderTimingMessage : NSObject
{
    double _start;
    NSString *_message;
}

+ (id)descriptionForTimingMessages:(id)arg1;
+ (id)messageWithString:(id)arg1;
- (void).cxx_destruct;
@property(copy) NSString *message; // @synthesize message=_message;
@property double start; // @synthesize start=_start;

@end

