//
//  BaseSprite.m
//

#import "BaseSprite.h"

@implementation BaseSprite

- (id)init
{
  self = [super init];
  if (self)
  {
    self.juggler = [SPJuggler juggler];
    
    [self addEventListener:@selector(onAddedToStage:) atObject:self
                   forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
    
    [self addEventListener:@selector(onRemovedFromStage:) atObject:self
                   forType:SP_EVENT_TYPE_REMOVED_FROM_STAGE];
  }
  return self;
}

- (void)setup
{
  // Override in subclass
}

- (void)onAddedToStage:(SPEvent*)event
{
  [self setup];
  [Sparrow.juggler addObject:self.juggler];
}

- (void)onRemovedFromStage:(SPEvent*)event
{
  [self.juggler removeAllObjects];
  [self removeAllChildren];
  [Sparrow.juggler removeObject:self.juggler];
}

@end
