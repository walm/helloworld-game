//
//  Game.m
//

#import "Game.h"
#import "GameController.h"
#import "TitleSprite.h"
#import "RocketSprite.h"
#import "UFOSprite.h"

// --- private interface ---------------------------------------------------------------------------

@interface Game () {
  
  TitleSprite *mTitle;
  BOOL mHasRockets;
  
  NSMutableArray *mRockets;
  NSMutableArray *mUFOs;
  
}

- (void)setup;
- (void)showMenu;
- (void)startGame;
- (void)endGame;
- (void)launchRocketWithTargetAt:(int)x y:(int)y;

@end


// --- class implementation ------------------------------------------------------------------------

@implementation Game

static float s_centerX = 0.0;
static float s_centerY = 0.0;

@synthesize gameWidth  = mGameWidth;
@synthesize gameHeight = mGameHeight;


+ (BOOL)isTallScreen
{
  return [[UIScreen mainScreen] bounds].size.height == 568.0f;
}

+ (float)centerX
{
  return s_centerX;
}

+ (float)centerY
{
  return s_centerY;
}

- (id)initWithWidth:(float)width height:(float)height
{
  if ((self = [super init]))
  {
    mGameWidth = width;
    mGameHeight = height;
    
    s_centerX = mGameWidth/2.0;
    s_centerY = mGameHeight/2.0;
    
    [self setup];
    [self showMenu];
  }
  return self;
}

- (void)setup
{
  // This is where the code of your game will start. 
  // In this sample, we add just a few simple elements to get a feeling about how it's done.
  
  [SPAudioEngine start];  // starts up the sound engine
  
  // The Application contains a very handy "Media" class which loads your texture atlas
  // and all available sound files automatically. Extend this class as you need it --
  // that way, you will be able to access your textures and sounds throughout your 
  // application, without duplicating any resources.
  
  [Media initAtlas];      // loads your texture atlas -> see Media.h/Media.m
  [Media initSound];      // loads all your sounds    -> see Media.h/Media.m
  
  // Set a background
  NSString *bgFileName = @"bg.png";
  if ([Game isTallScreen]) bgFileName = @"bg-568.png";
  SPImage *background = [[SPImage alloc] initWithContentsOfFile:bgFileName];
  background.pivotX = background.width / 2;
  background.pivotY = background.height / 2;
  background.x = mGameWidth / 2;
  background.y = mGameHeight / 2;
  [self addChild:background];
  
}

- (void)showMenu
{
  if (!mTitle) {
    mTitle = [TitleSprite title];
    mTitle.x = [Game centerX];
    mTitle.y = [Game centerY];
    [self addChild:mTitle];
    [mTitle moveSlowUpAndDown];
    [mTitle addEventListener:@selector(onTitleTouched:) atObject:self
                     forType:SP_EVENT_TYPE_TOUCH];
  }
  [[[SPStage mainStage].juggler delayInvocationAtTarget:mTitle byTime:2.0f] fadeIn:nil];
}

- (void)startGame
{
  mUFOs = [[NSMutableArray alloc] init];
  mRockets = [[NSMutableArray alloc] init];
  
  mHasRockets = YES;
 
  // activate touch on scene, which trigger rockets launch
  [self addEventListener:@selector(onSceneTouch:) atObject:self
                 forType:SP_EVENT_TYPE_TOUCH];
}

- (void)endGame
{
  [self removeEventListener:@selector(onSceneTouch:) atObject:self
                    forType:SP_EVENT_TYPE_TOUCH];
  // Game over!!
  [self showMenu];
}

- (void)launchRocketWithTargetAt:(int)x y:(int)y
{
  NSLog(@"Rocket fire at x:%d y:%d", x, y);
  
  RocketSprite *rocket = [RocketSprite rocket];
  rocket.x = [Game centerX];
  rocket.y = mGameHeight - 100.0f;
  [rocket setTargetForX:x y:y];
  [rocket addEventListener:@selector(onRocketTarget:) atObject:self
                   forType:ROCKET_ON_TARGET_EVENT];
  [mRockets addObject:rocket];
  [self addChild:rocket];
}

- (void)onTitleTouched:(SPTouchEvent*)event
{
  [mTitle fadeOut:^{
    [mTitle removeFromParent];
    mTitle = nil;

    [self startGame];
  }];
}

- (void)onSceneTouch:(SPTouchEvent*)event
{
  // TODO: launch rocket at x y pos
  SPTouch *touchStart = [[event touchesWithTarget:self andPhase:SPTouchPhaseBegan] anyObject];
  if (touchStart)
  {
    SPPoint *touchPosition = [touchStart locationInSpace:self];
    if (mHasRockets) [self launchRocketWithTargetAt:touchPosition.x
                                                  y:touchPosition.y];
  }
  
}

- (void)onRocketTarget:(SPEvent*)event
{
  RocketSprite *rocket = (RocketSprite*)event.target;
  [mRockets removeObject:rocket];
  
  // TODO: load new rockets
}

@end
