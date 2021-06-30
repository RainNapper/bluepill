//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled May 11 2021 09:30:43).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <XCTAutomationSupport/XCElementSnapshot.h>

#import <XCTest/XCUIElementAttributes-Protocol.h>
#import <XCTest/XCUIElementSnapshot-Protocol.h>

@class NSArray, NSDictionary, NSString;

@interface XCElementSnapshot (TreeManagement) <XCUIElementAttributes, XCUIElementSnapshot>
- (id)reparentedOrphanElementMatchingAccessibilityElement:(id)arg1 inconsistentRelationshipDescriptions:(id *)arg2 error:(id *)arg3;
- (id)_snapshotForAccessibilityElement:(id)arg1 error:(id *)arg2;
- (id)snapshotFetchingIfNeededIntoTreeForAccessibilityElement:(id)arg1 error:(id *)arg2;
- (id)hitPointForScrolling:(id *)arg1;
- (id)hitPoint:(id *)arg1;
- (id)hostingAndOrientationTransformedRect:(struct CGRect)arg1 error:(id *)arg2;
- (id)_transformRectWithRequest:(id)arg1 error:(id *)arg2;
- (id)hostingAndOrientationTransformedPoint:(struct CGPoint)arg1 error:(id *)arg2;
- (id)_transformPointWithRequest:(id)arg1 error:(id *)arg2;
- (_Bool)_canTransformPoint:(struct CGPoint)arg1;
- (id)_transformParametersOrError:(id *)arg1;
- (id)_transformParametersFromDictionary:(id)arg1 error:(id *)arg2;
- (id)_hitPointTransformationRequestOrError:(id *)arg1;
- (id)_visiblePointOrError:(id *)arg1;
- (_Bool)_elementIsContainerSubviewWithMatchingFrame:(id)arg1;
- (id)hitTest:(struct CGPoint)arg1;
@property(readonly) NSArray *suggestedHitpoints;
@property(readonly, copy) NSDictionary *dictionaryRepresentation;

// Remaining properties
@property(readonly) NSArray *children;
@property(readonly) unsigned long long elementType;
@property(readonly, getter=isEnabled) _Bool enabled;
@property(readonly) struct CGRect frame;
@property(readonly) _Bool hasFocus;
@property(readonly) long long horizontalSizeClass;
@property(readonly) NSString *identifier;
@property(readonly, copy) NSString *label;
@property(readonly) NSString *placeholderValue;
@property(readonly, getter=isSelected) _Bool selected;
@property(readonly, copy) NSString *title;
@property(readonly) id value;
@property(readonly) long long verticalSizeClass;
@end

