//
//  UFOSprite.m
//

#import "UFOSprite.h"

@interface UFOSprite() {

  SXParticleSystem *mExplotions;
  SPMovieClip *mUfo;
}

- (void)sayHello;

@end

@implementation UFOSprite

+ (UFOSprite*)ufo
{
  return [[UFOSprite alloc] init];
}

- (void)setup
{
  mUfo = [SPMovieClip movieWithFrames:[Media atlasTexturesWithPrefix:@"ufo_"] fps:5];
  mUfo.loop = YES;
  mUfo.pivotX = (int)mUfo.width / 2;
  mUfo.pivotY = (int)mUfo.height / 2;
  [self.juggler addObject:mUfo];
  [self addChild:mUfo];
  
  // and animate it a little
  SPTween *tween = [SPTween tweenWithTarget:mUfo time:1.5 transition:SP_TRANSITION_EASE_IN_OUT];
  [tween animateProperty:@"x" targetValue:mUfo.x - 10];
  [tween animateProperty:@"y" targetValue:mUfo.y + 10];
  [tween animateProperty:@"rotation" targetValue:0.1];
  //tween.loop = SPLoopTypeReverse;
    tween.reverse = TRUE;
    
    [self.juggler addObject:tween];
  
  mExplotions = [[SXParticleSystem alloc] initWithContentsOfFile:@"ufo-explosion.pex"];
  [self addChild:mExplotions];
  [self.juggler addObject:mExplotions];
  
  // Say hello within 2s
  float delay = [SPUtils randomFloat] * 1.0;
  [[self.juggler delayInvocationAtTarget:self byTime:delay] sayHello];
}

- (void)explode
{
  SPTween *tween = [SPTween tweenWithTarget:mUfo time:0.3f transition:SP_TRANSITION_EASE_IN_BACK];
  [tween fadeTo:0.0f];
  [tween scaleTo:0.0f];
  [self.juggler addObject:tween];
  
  [mExplotions start];
  [[self.juggler delayInvocationAtTarget:self byTime:0.1f] explodeDone];
  [self dispatchEvent:[SPEvent eventWithType:UFO_EXPLODE_EVENT]];
}

- (void)explodeDone
{
  SPTween *tween = [SPTween tweenWithTarget:self time:1.0f];
  [tween fadeTo:0.0];
  [self.juggler addObject:tween];
  
  [mExplotions stop];
  
  [[self.juggler delayInvocationAtTarget:self byTime:1.0f] removeFromParent];
}

- (void)sayHello
{
  [Media playSound:@"hello.caf"];
}

@end
