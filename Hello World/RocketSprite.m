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

@end
