//
//  SXScroll.m
//  Kana Legends
//
//  Created by Lemark on 8/17/15.
//  Copyright (c) 2015 Kamidojin. All rights reserved.
//
#import "DebuggingAndTestingDefines.h"

#import "SXScroll.h"
#import <math.h>
#import "Helper.h"

extern float globalFontSizeScaleMultiplier;

static const NSString *USERDATA_KEY_SXSCROLLITEMTYPE = @"SXScrollItemType";

@implementation SXScroll{
    
    SKNode *_scrollNodeContainer;
    
    CGPoint _swipeLocationStart;
    CGPoint _swipeLocationEnd;
    
    CGFloat _scrollLimitTop;
    CGFloat _scrollLimitBottom;
    
    CGFloat _touchTimeStart;
    CGFloat _touchTimeEnd;
    CGFloat _touchTimeResult;
    
    CGFloat _swipeSensitivity;
    
    CGFloat _distanceSwipe;
    CGFloat _distanceY;
    CGFloat _distanceX;

    CGFloat _velocity;
    CGFloat _speed;

    CGFloat _marginHeader;
    CGFloat _marginFooter;
    CGFloat _marginItem;
    
    CGFloat _ignoreTouchLocationGreaterThan;
    CGFloat _ignoarTouchLocationLesserThan;
    
    BOOL _isSwipeDirectionUp;
    BOOL _isSwipeDirectionDown;
    BOOL _isSwipeDirectionLeft;
    BOOL _isSwipeDirectionRight;
    BOOL _isSwipeDetected;
    BOOL _isTouched;
    BOOL _isWholeScreenToucheable;
}

+(instancetype)createSXScroll:(SKNode*)aNode ofType:(SXScrollItemType)anItemType{
    SXScroll *newSXScroll = [[SXScroll alloc]initWithNode:aNode ofType:anItemType];
    return newSXScroll;
}

+(void)addItemTypeToNodeUserData:(SKNode*)aNode ofType:(SXScrollItemType)anItemType{
    if(aNode){
        NSUInteger itemType = 0;
        
        if(!aNode.userData){
            aNode.userData = [NSMutableDictionary dictionary];
            itemType = anItemType;
        }else{
            itemType = [[aNode.userData objectForKey:USERDATA_KEY_SXSCROLLITEMTYPE] unsignedIntegerValue];
            
            itemType |= anItemType;
        }
        
        [aNode.userData setObject:@(itemType) forKey:USERDATA_KEY_SXSCROLLITEMTYPE];
    }
}

#ifdef DEBUG
- (void)dealloc
{
    DebugLog(@"DEALLOCATING SXSCROLL")
}
#endif

- (instancetype)initWithNode:(SKNode*)aNode ofType:(SXScrollItemType)anItemType{
    
    if(!aNode){
        NSException *e = [NSException exceptionWithName:@"SKNode" reason:@"*** Object is not initialised or null" userInfo:nil];
        @throw e;
    }
    
    self = [super init];
    if (self) {
        
        _scrollNodeContainer = [SKNode node];
        
        [_scrollNodeContainer setName:@"SXScrollContainer"];
        
        [self setName:@"SXScroll"];
        
        [self setMargin:4 ofItemType:SXScrollItem];
        [self setMargin:10 ofItemType:SXScrollItemHeader];
        [self setMargin:30 ofItemType:SXScrollItemFooter];
        
        [self addChild:_scrollNodeContainer];
        
        [self addItem:aNode ofType:anItemType];
        
        _speed = 0.99;
        _distanceY = 0.0;
        _swipeSensitivity = 0.29;
    }
    
    return self;
}

-(void)resetToStartPosition{
    [_scrollNodeContainer setPosition:CGPointMake(_scrollNodeContainer.position.x, 0.0)];
}

-(void)addItem:(SKNode*)aNode ofType:(SXScrollItemType)anItemType{
    
    if(!_scrollNodeContainer){
        NSException *e = [NSException exceptionWithName:@"SKNode" reason:@"*** Object is not initialised or null" userInfo:nil];
        @throw e;
    }
    
    if(!aNode.userData)
        aNode.userData = [NSMutableDictionary dictionary];
    
    [aNode.userData setObject:@(anItemType) forKey:USERDATA_KEY_SXSCROLLITEMTYPE];

    aNode.position = [self getAdjustedPosition:aNode parentNode:_scrollNodeContainer];

    NSUInteger length = _scrollNodeContainer.children.count;
    
    if(length){
        SKNode *temp = _scrollNodeContainer.children[length-1];
        SXScrollItemType type = [temp.userData[USERDATA_KEY_SXSCROLLITEMTYPE] intValue];
        
        if((type == SXScrollItemHeader && anItemType == SXScrollItem)||(type == SXScrollItem && anItemType == SXScrollItemHeader)){
            aNode.position = CGPointMake(aNode.position.x, aNode.position.y-(_marginHeader*globalFontSizeScaleMultiplier));
        }else if((type == SXScrollItem && anItemType == SXScrollItemHeader)||(type == SXScrollItem && anItemType == SXScrollItem)){
            aNode.position = CGPointMake(aNode.position.x, aNode.position.y-_marginItem);
        }else if((type == SXScrollItem && anItemType == SXScrollItemFooter)||(type == SXScrollItemHeader && anItemType == SXScrollItemFooter)){
            aNode.position = CGPointMake(aNode.position.x, aNode.position.y-_marginFooter);
        }
    }
    
    [_scrollNodeContainer addChild:aNode];

}

-(SKNode *)childNodeWithName:(NSString *)name{
    SKNode *childFound = [super childNodeWithName:name];
    
    if(!childFound){
        childFound = [_scrollNodeContainer childNodeWithName:name];
    
    }
 
    return childFound;
}

-(BOOL)isSwipeDetected{
    return _isSwipeDetected;
}

-(CGFloat)swipeDistance{
    if(_swipeLocationStart.y > _swipeLocationEnd.y)
        return _swipeLocationStart.y-_swipeLocationEnd.y;
    else
        return _swipeLocationEnd.y-_swipeLocationStart.y;
}

-(void)touchStart:(UITouch*)aTouch{
    [_scrollNodeContainer removeAllActions];
    _touchTimeStart = aTouch.timestamp;
    _swipeLocationStart = [aTouch locationInNode:self];
    
//    NSLog(@"TOUCH START TIME: %f",_touchTimeStart);
}

-(void)touchEnd:(UITouch*)aTouch{
    _touchTimeEnd = aTouch.timestamp;
    _swipeLocationEnd = [aTouch locationInNode:self];
  
    _touchTimeResult = _touchTimeEnd - _touchTimeStart;
    
    if(_isSwipeDirectionDown)
        _distanceY = fabs(_distanceY);

    _distanceSwipe = [self swipeDistance];
    
    DebugLog(@"SWIPE DISTANCE: %f",_distanceSwipe)
    
    if(_distanceSwipe > 0)
    {
        _isSwipeDetected = YES;
        
        if(_touchTimeResult < _swipeSensitivity)
            _velocity = fabs(_distanceY/_touchTimeResult);
        else
            _velocity = 0.0;
        
    }else _isSwipeDetected = NO;
    
    
    DebugLog(@"SWIPE DETECTED: %d",_isSwipeDetected)
    
//    NSLog(@"SWIPE DISTANCE %f",_distance);
//    NSLog(@"TOUCH TIME RESULT %f",_touchTimeResult);
//    NSLog(@"TOUCH VELOCITY %f",_velocity);
//    NSLog(@"NODE POSITION %f",_node.position.y);
    
    if(_velocity)
    {
        SKAction *momentum;
        
        if(_isSwipeDirectionUp)
        {
//            NSLog(@"FLICK SWIPE UP");
            momentum = [SKAction customActionWithDuration:1 actionBlock:^(SKNode *node, CGFloat elapsedTime)
            {
                CGPoint newPosition = node.position;
                newPosition.y += _velocity/4;
                if(newPosition.y > _scrollLimitTop)
                    newPosition = CGPointMake(newPosition.x, _scrollLimitTop);

                node.position = newPosition;
            }];
            
            momentum.timingMode = SKActionTimingEaseOut;
            [_scrollNodeContainer runAction:momentum];
            
            _isSwipeDirectionUp = NO;
            
        }
        else if(_isSwipeDirectionDown)
        {
//            NSLog(@"FLICK SWIPE DOWN");
            momentum = [SKAction customActionWithDuration:1 actionBlock:^(SKNode *node, CGFloat elapsedTime)
            {
                CGPoint newPosition = node.position;
                newPosition.y -= _velocity/4;
                if(newPosition.y < _scrollLimitBottom)
                    newPosition = CGPointMake(newPosition.x, _scrollLimitBottom);
                
                node.position = newPosition;
            }];
            
            momentum.timingMode = SKActionTimingEaseOut;
            [_scrollNodeContainer runAction:momentum];
            _isSwipeDirectionDown = NO;
        }
    }

    _distanceY = 0.0;
}

-(void)touchMove:(UITouch*)aTouch{
    CGPoint currTouchLocation = [aTouch locationInNode:self];
    CGPoint prevTouchLocation = [aTouch previousLocationInNode:self];
    
    // TODO:
    // CONTROL TOUCH DETECTION - WHOLE SCREEN OR JUST CONTAINER
    if(!_isWholeScreenToucheable){
        if(![_scrollNodeContainer containsPoint:currTouchLocation])
            return;
    }
    
    CGFloat deltaY = currTouchLocation.y - prevTouchLocation.y;
    
//    _distanceSwipe = fabs(deltaY);
//    
//    DebugLog(@"DISTANCE: %f",_distanceSwipe);
    
//    CGFloat deltaX = currTouchLocation.x - prevTouchLocation.x;
    
    if(deltaY < 1){
        _isSwipeDirectionDown = YES;
        _isSwipeDirectionUp = NO;
        _distanceY -= _speed;
    }
    
    if(deltaY > 1){
        _isSwipeDirectionUp = YES;
        _isSwipeDirectionDown = NO;
        _distanceY += _speed;
    }
    
    _scrollNodeContainer.position = CGPointMake(_scrollNodeContainer.frame.origin.x, _scrollNodeContainer.frame.origin.y+deltaY);
    
    if(_scrollNodeContainer.position.y <= _scrollLimitBottom)
        _scrollNodeContainer.position = CGPointMake(_scrollNodeContainer.frame.origin.x, _scrollLimitBottom);
    
    if(_scrollNodeContainer.position.y >= _scrollLimitTop)
        _scrollNodeContainer.position = CGPointMake(_scrollNodeContainer.frame.origin.x, _scrollLimitTop);
    
}

-(void)setMargin:(float)aMargin ofItemType:(SXScrollItemType)anItemType{
    
    switch(anItemType){
            
        case SXScrollItemHeader:{
            _marginHeader = aMargin;
        }break;
        
        case SXScrollItemFooter:{
            _marginFooter = aMargin;
        }break;
            
            
        case SXScrollItem:{
            _marginItem = aMargin;
        }break;
            
        default:break;
    }
}

-(void)setWholeScreenToucheable:(BOOL)status{
    _isWholeScreenToucheable = status;
}

-(void)setScrollLimitTop:(float)aLimit{
//    if(aLimit == 0){
//        _scrollLimitTop = [_scrollNodeContainer calculateAccumulatedFrame].size.height;
//        return;
//    }
    
    _scrollLimitTop = aLimit;
}

-(void)setScrollLimitBottom:(float)aLimit{
    if(aLimit)
        _scrollLimitBottom = -aLimit;
    else
        _scrollLimitBottom = 0;
}

-(void)setSwipeSensitivity:(float)aValue{
    if(aValue > 1)
        aValue = 1;
    
    _swipeSensitivity = aValue;
}

-(void)setIgnoreTouchLocationGreaterThan:(CGFloat)location{
    _ignoreTouchLocationGreaterThan = location;
}

-(void)setIgnoreTouchLocationLesserThan:(CGFloat)location{
    _ignoarTouchLocationLesserThan = location;
}

-(CGPoint)getAdjustedPosition:(SKNode*)aNode parentNode:(SKNode*)parentNode{
    CGPoint position = aNode.position;
    
    
    CGFloat width=0,height=0;
    
    CGRect accumulatedFrameSize = [parentNode calculateAccumulatedFrame];
    
    accumulatedFrameSize.size.width == INFINITY ? (width=0) : (width=accumulatedFrameSize.size.width);
    accumulatedFrameSize.size.height == INFINITY ? (height=0) : (height=accumulatedFrameSize.size.height);
    
    position.x = 0.0;
    position.y = (parentNode.position.y - height);
    
    if([aNode isKindOfClass:[SKSpriteNode class]]){
        SKSpriteNode *spriteNode = (SKSpriteNode*)aNode;
        spriteNode.anchorPoint = CGPointMake(0.5, 1.0);
        
    }else if([aNode isKindOfClass:[SKLabelNode class]])
    {
        SKLabelNode *labelNode = (SKLabelNode*)aNode;
        labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
        labelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        
    }else if([aNode isKindOfClass:[SKShapeNode class]]){
        
        SKShapeNode *shapeNode = (SKShapeNode*) aNode;
        position.y = (parentNode.position.y - height)-(shapeNode.frame.size.height/2);
        
    }
    
    return position;
}


-(SKNode*)getTouchedItem:(CGPoint)aPoint{
    if(_ignoreTouchLocationGreaterThan){
        if(aPoint.y > _ignoreTouchLocationGreaterThan)
            return nil;
    }
    
    SKNode *touchedItem;
    
    CGPoint localPoint = [self convertPoint:aPoint fromNode:self.parent];
    
    if([_scrollNodeContainer containsPoint:localPoint]){
     
        localPoint = [_scrollNodeContainer convertPoint:localPoint fromNode:self];
        
        touchedItem = [_scrollNodeContainer nodeAtPoint:localPoint];
        
        
        if([touchedItem isEqualToNode:_scrollNodeContainer] ||[touchedItem.userData[USERDATA_KEY_SXSCROLLITEMTYPE] intValue] == SXScrollItemHeader ||[touchedItem.userData[USERDATA_KEY_SXSCROLLITEMTYPE] intValue] == SXScrollItemFooter){
            touchedItem = nil;
        }
    }
    
    return touchedItem;
}

-(SKNode*)getTouchedItemWithName:(NSString*)name atPoint:(CGPoint)aPoint{
    if(_ignoreTouchLocationGreaterThan){
        if(aPoint.y > _ignoreTouchLocationGreaterThan)
            return nil;
    }
    
    SKNode *touchedItem;
    
    CGPoint localPoint = [self convertPoint:aPoint fromNode:self.parent];
    
    if([_scrollNodeContainer containsPoint:localPoint]){
        
        localPoint = [_scrollNodeContainer convertPoint:localPoint fromNode:self];
        
        if(name){
            NSArray *items;
            items = [_scrollNodeContainer nodesAtPoint:localPoint];
            
            for(SKNode *node in items){
                if([node.name isEqualToString:name]){
                    touchedItem = node;
                    break;
                }
            }
        }
    }
    
    return touchedItem;
}


-(SKNode*)getTouchedItemWithUserDataKey:(NSString*)aKey atPoint:(CGPoint)aPoint{

    if(_ignoreTouchLocationGreaterThan){
        if(aPoint.y > _ignoreTouchLocationGreaterThan)
            return nil;
    }
    
    SKNode *touchedItem;
    NSArray *items;
    NSArray *allKeys;
    
    
    CGPoint localPoint = [self convertPoint:aPoint fromNode:self.parent];

    if(![_scrollNodeContainer containsPoint:localPoint])
        return nil;
    
    
    items = [self nodesAtPoint:localPoint];
    
    SKNode *node;
    
    NSEnumerator *enumerator = [items objectEnumerator];
    
    while((node = [enumerator nextObject])){
        
        if((allKeys = node.userData.allKeys)){
            
            NSEnumerator *keyEnumerator = [allKeys objectEnumerator];
            NSString *keyFound;
            
            while((keyFound = [keyEnumerator nextObject])){
                if([keyFound isEqualToString:aKey])

                    return (touchedItem = node);
            }
       
        }
    }
    
    return touchedItem;
}

-(NSUInteger)getCountItems{
    return _scrollNodeContainer.children.count;
}

-(CGSize)getFrameSize{
    return [_scrollNodeContainer calculateAccumulatedFrame].size;
}

@end
