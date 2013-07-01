//
//  UFOSprite.h
//

#import "SPSprite.h"
#import "BaseSprite.h"

#define UFO_EXPLODE_EVENT @"ufoExplode"

@interface UFOSprite : BaseSprite

+ (UFOSprite*)ufo;

- (void)explode;

@end
