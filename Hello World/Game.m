//
//  Game.m
//

#import "Game.h"
#import "GameController.h"
#import "TitleSprite.h"
#import "RocketSprite.h"
#import "UFOSprite.h"
#import "SXParticleSystem.h"

// --- private interface ---------------------------------------------------------------------------

@interface Game () {
  
  BOOL mIsPlaying;
  float mBottomLine;
  int mLifes;
  int mLoadedRockters;
  long mScore;
  float mUfoSpeed;
  float mUfoDelay;
  NSMutableArray *mRockets;
  NSMutableArray *mUFOs;
  
  TitleSprite *mTitle;
  SPSprite *mPlayStage;
  SPTextField *mScoreLabel;
  SPTextField *mLifeAndRocketsLabel;
  SPImage *mLifeImage;
}

- (void)setup;
- (void)showMenu;
- (void)startGame;
- (void)endGame;
- (void)addUFOWithContinued:(BOOL)continued;
- (void)addHitAtX:(int)x;
- (void)launchRocketWithTargetAt:(int)x y:(int)y;
- (void)checkCollisions;
- (void)updateScore;
- (void)updateLifeAndRocketCount;
- (void)speedUpGame;
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
   
    if (mGameHeight < 500) {
      mBottomLine = mGameHeight - 50.0f;
    } else {
      mBottomLine = mGameHeight - 100.0f;
    }
    
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

  mPlayStage = [SPSprite sprite];
  [self addChild:mPlayStage];

  mScoreLabel = [SPTextField textFieldWithText:@"Score: 0"];
  mScoreLabel.visible = NO;
  mScoreLabel.width = 180.0;
  mScoreLabel.hAlign = SPHAlignLeft;
  mScoreLabel.color = SP_WHITE;
  mScoreLabel.fontSize = 15;
  mScoreLabel.y = mGameHeight - 80.0f;
  mScoreLabel.x = 10.0f;
  [self addChild:mScoreLabel];

  mLifeAndRocketsLabel = [SPTextField textFieldWithText:@"Life: 0 Rockets: 0"];
  mLifeAndRocketsLabel.visible = NO;
  mLifeAndRocketsLabel.width = 180.0;
  mLifeAndRocketsLabel.hAlign = SPHAlignRight;
  mLifeAndRocketsLabel.color = SP_WHITE;
  mLifeAndRocketsLabel.fontSize = 15;
  mLifeAndRocketsLabel.y = mScoreLabel.y;
  mLifeAndRocketsLabel.x = mGameWidth - 195.0f;
  [self addChild:mLifeAndRocketsLabel];
  
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
  [[[SPStage mainStage].juggler delayInvocationAtTarget:mTitle byTime:1.0f] fadeIn:nil];
}

- (void)startGame
{
  mIsPlaying = YES;
  mUfoDelay = 3.0f;
  mUfoSpeed = 10.0f;
  mLoadedRockters = 2;
  mLifes = 3;
  mScore = 0;

  // clear stage
  [[SPStage mainStage].juggler removeObjectsWithTarget:mPlayStage];
  [mPlayStage removeAllChildren];
  mPlayStage.alpha = 1.0f;
  mUFOs = [[NSMutableArray alloc] init];
  mRockets = [[NSMutableArray alloc] init];

  mScoreLabel.visible = YES;
  mLifeAndRocketsLabel.visible = YES;
  
  [self updateLifeAndRocketCount];
  [self addUFOWithContinued:YES];
  
  // activate touch on scene, which trigger rockets launch
  [self addEventListener:@selector(onSceneTouch:) atObject:self
                 forType:SP_EVENT_TYPE_TOUCH];
  
  [[[SPStage mainStage].juggler delayInvocationAtTarget:self byTime:15.0f] speedUpGame];
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
 
  [[SPStage mainStage].juggler removeAllObjects];

  SPTween *tween = [SPTween tweenWithTarget:mPlayStage time:10.0f];
  [tween fadeTo:0.0f];
  [[SPStage mainStage].juggler addObject:tween];
  
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
  [ufo addEventListener:@selector(onUFOExplode:) atObject:self
                forType:UFO_EXPLODE_EVENT];
  [mPlayStage addChild:ufo];
  
  [mUFOs addObject:ufo];
  
  SPTween *tween = [SPTween tweenWithTarget:ufo time:mUfoSpeed];
  [tween moveToX:xPos y:mBottomLine];
  [tween addEventListener:@selector(onUFOHit:) atObject:self
                  forType:SP_EVENT_TYPE_TWEEN_COMPLETED];
  [[SPStage mainStage].juggler addObject:tween];

  if (continued)
    [[[SPStage mainStage].juggler delayInvocationAtTarget:self byTime:mUfoDelay] addUFOWithContinued:YES];
}

- (void)addHitAtX:(int)x
{
  SXParticleSystem *hit = [[SXParticleSystem alloc] initWithContentsOfFile:@"earth-hit.pex"];
  hit.y = mBottomLine;
  hit.x = x;
  hit.rotation = SP_D2R(180);
  [mPlayStage addChild:hit];
  [[SPStage mainStage].juggler addObject:hit];
  [hit start];
}

- (void)launchRocketWithTargetAt:(int)x y:(int)y
{
  if (mLoadedRockters <= 0) return;

  int rocketType = [SPUtils randomIntBetweenMin:1 andMax:4];
  RocketSprite *rocket = [RocketSprite rocketWithType:rocketType];
  rocket.x = [SPUtils randomIntBetweenMin:[Game centerX]-100 andMax:[Game centerX]+100]; //[Game centerX];
  rocket.y = mBottomLine;
  [rocket setTargetForX:x y:y];
  [rocket addEventListener:@selector(onRocketTarget:) atObject:self
                   forType:ROCKET_ON_TARGET_EVENT];
  [rocket addEventListener:@selector(onRocketExplode:) atObject:self
                   forType:ROCKET_EXPLODE_EVENT];
  [mRockets addObject:rocket];
  [mPlayStage addChild:rocket];
  
  mLoadedRockters--;
  [self updateLifeAndRocketCount];
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
        mScore += 100;
        [self updateScore];
      }
    }
  }
}

- (void)speedUpGame
{
  if (!mIsPlaying) return;
  
  mUfoSpeed -= 1.0f;
  mUfoDelay -= 0.2f;

  // maximum speed and delay
  if (mUfoSpeed < 3.0f) mUfoSpeed = 3.0f;
  if (mUfoDelay < 0.5f) mUfoDelay = 0.5f;

  [[[SPStage mainStage].juggler delayInvocationAtTarget:self byTime:5.0f] speedUpGame];
}

- (void)updateScore
{
  mScoreLabel.text = [NSString stringWithFormat:@"Score: %ld", mScore];
}

- (void)updateLifeAndRocketCount
{
  mLifeAndRocketsLabel.text = [NSString stringWithFormat:@"Life: %d Rockets: %d", mLifes, mLoadedRockters];
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
  SPTouch *touchStart = [[event touchesWithTarget:self andPhase:SPTouchPhaseBegan] anyObject];
  if (touchStart)
  {
    SPPoint *touchPosition = [touchStart locationInSpace:self];
    [self launchRocketWithTargetAt:touchPosition.x
                                 y:touchPosition.y];
  }
  
}

- (void)onRocketExplode:(SPEvent*)event
{
  RocketSprite *rocket = (RocketSprite*)event.target;
  [mRockets removeObject:rocket];
  mLoadedRockters++;
  [self updateLifeAndRocketCount];
}

- (void)onRocketTarget:(SPEvent*)event
{
  RocketSprite *rocket = (RocketSprite*)event.target;
  [mRockets removeObject:rocket];
  mLoadedRockters++;
  [self updateLifeAndRocketCount];
}

- (void)onUFOExplode:(SPEvent*)event
{
  UFOSprite *ufo = (UFOSprite*)event.target;
  [[SPStage mainStage].juggler removeObjectsWithTarget:ufo];
  [mUFOs removeObject:ufo];
}

- (void)onUFOHit:(SPEvent*)event
{
  SPTween *tween = (SPTween*)event.target;
  UFOSprite *ufo = (UFOSprite*)tween.target;
  [mUFOs removeObject:ufo];

  [self addHitAtX:(int)ufo.x];
  [ufo explode];

  mLifes--;
  [self updateLifeAndRocketCount];
  if (mLifes == 0) [self endGame];
}

@end
