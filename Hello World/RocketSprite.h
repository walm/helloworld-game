//
//  RocketSprite.h
//  Hello World
//
//  Created by Andreas Wålm on 2012-10-31.
//  Copyright (c) 2012 WalmNET. All rights reserved.
//

#import "BaseSprite.h"

#define ROCKET_EXPLODE_EVENT @"rocketExplode"
#define ROCKET_ON_TARGET_EVENT @"rocketOnTarget"

@interface RocketSprite : BaseSprite

@property (nonatomic, assign) int type;

+ (RocketSprite*)rocket;
+ (RocketSprite*)rocketWithType:(int)type;

- (void)setTargetForX:(int)x y:(int)y;

- (void)explode;

@end
