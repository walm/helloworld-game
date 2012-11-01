//
//  TitleSprite.m
//  Hello World
//
//  Created by Andreas Wålm on 2012-10-31.
//  Copyright (c) 2012 WalmNET. All rights reserved.
//

#import "TitleSprite.h"

@implementation TitleSprite


+ (TitleSprite*)title
{
  return [[TitleSprite alloc] init];
}

- (void)setup
{
  mImage = [SPImage imageWithTexture:[Media atlasTexture:@"hello-title"]];
  mImage.pivotX = (int)mImage.width/2;
  mImage.pivotY = (int)mImage.height/2;
  mImage.alpha = 0.0f;
  mImage.scaleX = mImage.scaleY = 0.0f;
  [self addChild:mImage];
}

- (void)fadeIn:(OnCompletionBlock)completion;
{
  mCompletionBlock = completion;
  SPTween *tween = [SPTween tweenWithTarget:mImage time:0.3f];
  [tween fadeTo:1.0f];
  [tween scaleTo:1.0f];
  [tween addEventListener:@selector(onFadeCompletion:) atObject:self
                  forType:SP_EVENT_TYPE_TWEEN_COMPLETED];
  [self.juggler addObject:tween];
}

- (void)fadeOut:(OnCompletionBlock)completion;
{
  mCompletionBlock = completion;
  SPTween *tween = [SPTween tweenWithTarget:mImage time:0.3f];
  [tween fadeTo:0.0f];
  [tween scaleTo:0.0f];
  [tween addEventListener:@selector(onFadeCompletion:) atObject:self
                  forType:SP_EVENT_TYPE_TWEEN_COMPLETED];
  [self.juggler addObject:tween];
}

- (void)onFadeCompletion:(SPEvent*)event
{
  if (mCompletionBlock) mCompletionBlock();
  mCompletionBlock = nil;
}

- (void)moveSlowUpAndDown
{
  SPTween *tween = [SPTween tweenWithTarget:self time:20.0 transition:SP_TRANSITION_EASE_IN_OUT];
  [tween animateProperty:@"y" targetValue:self.y-30.0f];
  tween.loop = SPLoopTypeReverse;
  [self.juggler addObject:tween];
}
@end
