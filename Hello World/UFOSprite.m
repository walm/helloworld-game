//
//  UFOSprite.m
//

#import "UFOSprite.h"

@implementation UFOSprite


+ (UFOSprite*)ufo
{
  return [[UFOSprite alloc] init];
}

- (void)setup
{
  SPMovieClip *ufo = [SPMovieClip movieWithFrames:[Media atlasTexturesWithPrefix:@"ufo_"] fps:5];
  ufo.loop = YES;
  ufo.pivotX = (int)ufo.width / 2;
  ufo.pivotY = (int)ufo.height / 2;
  [self.juggler addObject:ufo];
  [self addChild:ufo];
  
  // play a sound when the image is touched
  [ufo addEventListener:@selector(onTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
  
  // and animate it a little
  SPTween *tween = [SPTween tweenWithTarget:ufo time:1.5 transition:SP_TRANSITION_EASE_IN_OUT];
  [tween animateProperty:@"x" targetValue:ufo.x - 10];
  [tween animateProperty:@"y" targetValue:ufo.y + 10];
  [tween animateProperty:@"rotation" targetValue:0.1];
  tween.loop = SPLoopTypeReverse;
  [self.juggler addObject:tween];
  
}

- (void)onTouched:(SPTouchEvent *)event
{
  NSSet *touches = [event touchesWithTarget:self andPhase:SPTouchPhaseEnded];
  if ([touches anyObject])
  {
    [Media playSound:@"sound.caf"];
  }
}

@end
