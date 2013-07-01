//
//  BaseSprite.h
//

#import "SPSprite.h"
#import "SXParticleSystem.h"

typedef void (^ OnCompletionBlock)();

@interface BaseSprite : SPSprite

@property (nonatomic, retain) SPJuggler *juggler;

@end
