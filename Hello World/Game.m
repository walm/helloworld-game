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
  BOOL mIsPlaying;
  BOOL mHasRockets;
  float mBottomLine;
  
  NSMutableArray *mRockets;
  NSMutableArray *mUFOs;
  
}

- (void)setup;
- (void)showMenu;
- (void)startGame;
- (void)endGame;
- (void)addUFOWithContinued:(BOOL)continued;
- (void)launchRocketWithTargetAt:(int)x y:(int)y;
- (void)checkCollisions;
- (BOOL)hasCollided:(SPDisplayObject*)object withObject:(SPDisplayObject*)secondObject;

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
    
    mBottomLine = mGameHeight - 100.0f;
    
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
 
  [self addEventListener:@selector(onEnterFrame:) atObject:self
                 forType:SP_EVENT_TYPE_ENTER_FRAME];
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
  mIsPlaying = YES;
  mHasRockets = YES;
  
  mUFOs = [[NSMutableArray alloc] init];
  mRockets = [[NSMutableArray alloc] init];
  
  [self addUFOWithContinued:YES];
  
  // activate touch on scene, which trigger rockets launch
  [self addEventListener:@selector(onSceneTouch:) atObject:self
                 forType:SP_EVENT_TYPE_TOUCH];
}

- (void)endGame
{
  mIsPlaying = NO;
  
  [self removeEventListener:@selector(onSceneTouch:) atObject:self
                    forType:SP_EVENT_TYPE_TOUCH];
  
  [mRockets removeAllObjects];
  [mUFOs removeAllObjects];
  mRockets = nil;
  mUFOs = nil;
  
  // Game over!!
  [self showMenu];
}

- (void)addUFOWithContinued:(BOOL)continued
{
  if (!mIsPlaying) return;
  
  int xPos = [SPUtils randomIntBetweenMin:20 andMax:mGameWidth-20];
  
  UFOSprite *ufo = [UFOSprite ufo];
  ufo.x = xPos;
  ufo.y = -10;
  ufo.scaleX = ufo.scaleY = 0.5f;
  [ufo addEventListener:@selector(onUFOExplode:) atObject:self
                forType:UFO_EXPLODE_EVENT];
  [self addChild:ufo];
  
  [mUFOs addObject:ufo];
  
  SPTween *tween = [SPTween tweenWithTarget:ufo time:15.0f];
  [tween moveToX:xPos y:mBottomLine];
  [[SPStage mainStage].juggler addObject:tween];

  if (continued)
    [[[SPStage mainStage].juggler delayInvocationAtTarget:self byTime:3.0f] addUFOWithContinued:YES];
}

- (void)launchRocketWithTargetAt:(int)x y:(int)y
{
  RocketSprite *rocket = [RocketSprite rocket];
  rocket.x = [Game centerX];
  rocket.y = mBottomLine;
  [rocket setTargetForX:x y:y];
  [rocket addEventListener:@selector(onRocketTarget:) atObject:self
                   forType:ROCKET_ON_TARGET_EVENT];
  [rocket addEventListener:@selector(onRocketExplode:) atObject:self
                   forType:ROCKET_EXPLODE_EVENT];
  [mRockets addObject:rocket];
  [self addChild:rocket];
}

- (BOOL)hasCollided:(SPDisplayObject*)object withObject:(SPDisplayObject*)secondObject
{
  // check with bounding box method
  SPRectangle *firstBounds = object.bounds;
  SPRectangle *secondBounds = secondObject.bounds;
  
  // make it just a bit smaller
  firstBounds.width -= 10.0f;
  firstBounds.height -= 10.0f;
  secondBounds.width -= 10.0f;
  secondBounds.height -= 10.0f;
  
  return [firstBounds intersectsRectangle:secondBounds];
}

- (void)checkCollisions
{
  RocketSprite *rocket;
  UFOSprite *ufo;
  
  NSMutableArray *rockets = [mRockets copy];
  NSMutableArray *ufos = [mUFOs copy];
  for (int i=0; i<[rockets count]; i++)
  {
    rocket = [rockets objectAtIndex:i];
    
    for (int u=0; u<[ufos count]; u++)
    {
      ufo = [ufos objectAtIndex:u];
      
      if ([self hasCollided:rocket withObject:ufo])
      {
        [ufo explode];
        [rocket explode];
      }
    }
  }
}

#pragma mark EventHandlers

- (void)onEnterFrame:(SPEvent*)event
{
  if (mIsPlaying) {
    [self checkCollisions];
  }
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

- (void)onRocketExplode:(SPEvent*)event
{
  RocketSprite *rocket = (RocketSprite*)event.target;
  [mRockets removeObject:rocket];
}

- (void)onRocketTarget:(SPEvent*)event
{
  RocketSprite *rocket = (RocketSprite*)event.target;
  [mRockets removeObject:rocket];
  
  // TODO: load new rockets
}

- (void)onUFOExplode:(SPEvent*)event
{
  UFOSprite *ufo = (UFOSprite*)event.target;
  [mUFOs removeObject:ufo];
}

- (void)onUFOHit:(SPEvent*)event
{
  UFOSprite *ufo = (UFOSprite*)event.target;
  [mUFOs removeObject:ufo];
  
  // TODO: Game over or lose a life?
}

@end
