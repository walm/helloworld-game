//
//  Game.h
//

#import <Foundation/Foundation.h>
#import <UIKit/UIDevice.h>

@interface Game : SPSprite
{
  @private 
    float mGameWidth;
    float mGameHeight;
}

- (id)initWithWidth:(float)width height:(float)height;

@property (nonatomic, assign) float gameWidth;
@property (nonatomic, assign) float gameHeight;

@end
