//
//  RocketSprite.h
//  Hello World
//
//  Created by Andreas Wålm on 2012-10-31.
//  Copyright (c) 2012 WalmNET. All rights reserved.
//

#import "BaseSprite.h"

@interface RocketSprite : BaseSprite

@property (nonatomic, assign) int type;

+ (RocketSprite*)rocket;
+ (RocketSprite*)rocketWithType:(int)type;

- (void)setTargetForX:(int)x y:(int)y;

@end
