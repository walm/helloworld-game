//
//  RocketSprite.m
//  Hello World
//
//  Created by Andreas Wålm on 2012-10-31.
//  Copyright (c) 2012 WalmNET. All rights reserved.
//

#import "RocketSprite.h"

@implementation RocketSprite

+ (RocketSprite*)rocket
{
  return [RocketSprite rocketWithType:1];
}

+ (RocketSprite*)rocketWithType:(int)type
{
  return [[RocketSprite alloc] initWithType:type];
}

- (id)initWithType:(int)type
{
  self = [super init];
  if (self) {
    self.type = type;
  }
  return self;
}

- (void)setup
{
  NSString *rocketTextureName = [NSString stringWithFormat:@"rocket%d", self.type];
  SPImage *image = [SPImage imageWithTexture:[Media atlasTexture:rocketTextureName]];
  image.pivotX = (int)image.width/2;
  image.pivotY = (int)image.height/2;
  [self addChild:image];
}

- (void)setTargetForX:(int)x y:(int)y
{
  // point rocket at target
  self.rotation = SP_D2R(atan2(x-self.x, self.y-y) * 180 / M_PI);
  self.scaleX = self.scaleY = 0.0;
  
  SPTween *tween;
  
  tween = [SPTween tweenWithTarget:self time:0.8f transition:SP_TRANSITION_EASE_IN];
  [tween scaleTo:1.0f];
  [self.juggler addObject:tween];
  
  tween = [SPTween tweenWithTarget:self time:1.0f transition:SP_TRANSITION_EASE_IN];
  [tween moveToX:x y:y];
  [tween addEventListener:@selector(onArrivedAtTarget:) atObject:self
                  forType:SP_EVENT_TYPE_TWEEN_COMPLETED];
  [self.juggler addObject:tween];
}

- (void)onArrivedAtTarget:(SPEvent*)event
{
  [self removeFromParent];
  [self dispatchEvent:[SPEvent eventWithType:ROCKET_ON_TARGET_EVENT]];
}

@end
