//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled May 11 2021 09:30:43).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class NSMutableArray;
@protocol OS_dispatch_queue, OS_dispatch_semaphore;

@interface XCTBlockingQueue : NSObject
{
    _Bool _finalized;
    NSObject<OS_dispatch_queue> *_mutex;
    NSObject<OS_dispatch_semaphore> *_sema;
    NSMutableArray *_objects;
}

- (void).cxx_destruct;
@property _Bool finalized; // @synthesize finalized=_finalized;
@property(readonly) NSMutableArray *objects; // @synthesize objects=_objects;
@property(readonly) NSObject<OS_dispatch_semaphore> *sema; // @synthesize sema=_sema;
@property(readonly) NSObject<OS_dispatch_queue> *mutex; // @synthesize mutex=_mutex;
- (void)finalize;
- (id)dequeueObject;
- (void)enqueueObject:(id)arg1;
- (void)enqueueObjects:(id)arg1;
- (id)init;

@end
