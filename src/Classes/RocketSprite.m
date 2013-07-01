//
//  RocketSprite.m
//  Hello World
//
//  Created by Andreas Wålm on 2012-10-31.
//  Copyright (c) 2012 WalmNET. All rights reserved.
//

#import "RocketSprite.h"

@interface RocketSprite() {

  SPImage *mImage;
  SXParticleSystem *mExplotions;
  SXParticleSystem *mFire;
  SPSoundChannel *mRocketSound;
}

- (void)explodeDone;

@end

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
  mImage = [SPImage imageWithTexture:[Media atlasTexture:rocketTextureName]];
  mImage.pivotX = (int)mImage.width/2;
  mImage.pivotY = (int)mImage.height/2;
  [self addChild:mImage];
 
  mFire = [[SXParticleSystem alloc] initWithContentsOfFile:@"rocket-fire.pex"];
  mFire.y = mImage.pivotY;
  mFire.scaleX = mFire.scaleY = 0.6f;
  [self addChild:mFire];
  [self.juggler addObject:mFire];
  [mFire start];
  
  mExplotions = [[SXParticleSystem alloc] initWithContentsOfFile:@"rocket-explosion.pex"];
  [self addChild:mExplotions];
  [self.juggler addObject:mExplotions];
  
  self.scaleX = self.scaleY = 0.0f;
  
  mRocketSound = [Media soundChannel:@"rocket.caf"];
  [mRocketSound play];
}

- (void)setTargetForX:(int)x y:(int)y
{
  // point rocket at target
  float angle = atan2(x-self.x, self.y-y) * 180 / M_PI;
  self.rotation = SP_D2R(angle);

  float len = y+50;
  float theta = atan2(y-self.y, x-self.x);
  float endX = (len * cos(theta)) + x;
  float endY = (len * sin(theta)) + y;
  
  SPTween *tween;
  tween = [SPTween tweenWithTarget:self time:0.8f transition:SP_TRANSITION_EASE_IN];
  [tween scaleTo:1.0f];
  [self.juggler addObject:tween];
  
  tween = [SPTween tweenWithTarget:self time:1.2f transition:SP_TRANSITION_EASE_IN];
  [tween moveToX:endX y:endY];
    
    tween.onComplete = ^() {
        [self onArrivedAtTarget];
    };
    
  [self.juggler addObject:tween];
}

- (void)explode
{
  //[self removeFromParent];
  [mFire stop];
  [mFire removeFromParent];
  [mImage removeFromParent];
  [self.juggler removeObjectsWithTarget:self];
  
  SPTween *tween = [SPTween tweenWithTarget:self time:0.2f];
  [tween moveToX:self.x y:self.y-50];
  [self.juggler addObject:tween];
  
  [mExplotions start];
  [[self.juggler delayInvocationAtTarget:self byTime:0.08f] explodeDone];
  [self dispatchEvent:[SPEvent eventWithType:ROCKET_EXPLODE_EVENT]];

  [mRocketSound stop];
  mRocketSound = nil;
  [Media playSound:@"boom.caf"];
}

- (void)explodeDone
{
  [mExplotions stop];
  [[self.juggler delayInvocationAtTarget:self byTime:1.0f] removeFromParent];
}

- (void)onArrivedAtTarget
{
  [self removeFromParent];
  [self dispatchEvent:[SPEvent eventWithType:ROCKET_ON_TARGET_EVENT]];
}

@end
