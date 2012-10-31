//
//  BaseSprite.h
//

#import "SPSprite.h"

typedef void (^ OnCompletionBlock)();

@interface BaseSprite : SPSprite

@property (nonatomic, retain) SPJuggler *juggler;

@end
