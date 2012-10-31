//
//  Game.m
//

#import "Game.h"
#import "GameController.h"
#import "TitleSprite.h"

// --- private interface ---------------------------------------------------------------------------

@interface Game () {
  
  TitleSprite *mTitle;
  
}

- (void)setup;
- (void)onResize:(SPResizeEvent *)event;

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
  
  // The scaffold autorotates the game to all supported device orientations.
  // Choose the orienations you want to support in the Target Settings ("Summary"-tab).
  // To update the game content accordingly, listen to the "RESIZE" event; it is dispatched
  // to all game elements (just like an ENTER_FRAME event).
  // 
  // To force the game to start up in landscape, add the key "Initial Interface Orientation" to
  // the "App-Info.plist" file and choose any landscape orientation.
  
  [self addEventListener:@selector(onResize:) atObject:self forType:SP_EVENT_TYPE_RESIZE];
  
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

- (void)onResize:(SPResizeEvent *)event
{
  NSLog(@"new size: %.0fx%.0f (%@)", event.width, event.height, 
        event.isPortrait ? @"portrait" : @"landscape");
}

- (void)onTitleTouched:(SPTouchEvent*)event
{
  [mTitle fadeOut:^{
    [mTitle removeFromParent];
    mTitle = nil;
  }];
  
  // TODO: Start game
}

@end
