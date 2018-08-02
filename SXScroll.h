//
//  SXScroll.h
//  Kana Legends
//
//  Created by Lemark on 8/17/15.
//  Copyright (c) 2015 Kamidojin. All rights reserved.
//

@import UIKit;
@import SpriteKit;
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, SXScrollItemType) {
    SXScrollItemNone = 0,
    SXScrollItemHeader = 1 << 0,
    SXScrollItemFooter = 1 << 1,
    SXScrollItem =  1 << 2,
    SXScrollItemSearchIgnore = 1<<3
};

typedef NS_OPTIONS(NSUInteger, SXScrollMarginType) {
    SXScrollMarginNone = 0,
    SXScrollMarginDefault = 1 << 0,
};

@interface SXScroll : SKNode

+(instancetype)createSXScroll:(SKNode*)aNode ofType:(SXScrollItemType)anItemType;
+(void)addItemTypeToNodeUserData:(SKNode*)aNode ofType:(SXScrollItemType)anItemType;

-(void)resetToStartPosition;

-(void)addItem:(SKNode*)aNode ofType:(SXScrollItemType)anItemType;

-(BOOL)isSwipeDetected;

-(void)touchStart:(UITouch*)aTouch;
-(void)touchEnd:(UITouch*)aTouch;
-(void)touchMove:(UITouch*)aTouch;

-(SKNode*)getTouchedItem:(CGPoint)aPoint;
-(SKNode*)getTouchedItemWithName:(NSString*)name atPoint:(CGPoint)aPoint;
-(SKNode*)getTouchedItemWithUserDataKey:(NSString*)aKey atPoint:(CGPoint)aPoint;

-(NSUInteger)getCountItems;
-(CGSize)getFrameSize;

-(void)setWholeScreenToucheable:(BOOL)status;

-(void)setIgnoreTouchLocationGreaterThan:(CGFloat)location;
-(void)setIgnoreTouchLocationLesserThan:(CGFloat)location;

-(void)setScrollLimitTop:(float)aLimit;
-(void)setScrollLimitBottom:(float)aLimit;
-(void)setSwipeSensitivity:(float)aValue;
-(void)setMargin:(float)aMargin ofItemType:(SXScrollItemType)anItemType;
@end
