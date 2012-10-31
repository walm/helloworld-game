//
//  Game.m
//

#import "Game.h"

// --- private interface ---------------------------------------------------------------------------

@interface Game ()

- (void)setup;
- (void)onImageTouched:(SPTouchEvent *)event;
- (void)onResize:(SPResizeEvent *)event;

@end


// --- class implementation ------------------------------------------------------------------------

@implementation Game

@synthesize gameWidth  = mGameWidth;
@synthesize gameHeight = mGameHeight;


+ (BOOL)isTallScreen
{
  return [[UIScreen mainScreen] bounds].size.height == 568.0f;
}

- (id)initWithWidth:(float)width height:(float)height
{
  if ((self = [super init]))
  {
    mGameWidth = width;
    mGameHeight = height;
    
    [self setup];
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
  
  
  NSString *bgFileName = @"bg.png";
  if ([Game isTallScreen]) bgFileName = @"bg-568.png";
  SPImage *background = [[SPImage alloc] initWithContentsOfFile:bgFileName];
  background.pivotX = background.width / 2;
  background.pivotY = background.height / 2;
  background.x = mGameWidth / 2;
  background.y = mGameHeight / 2;
  [self addChild:background];
  

  // Display the Sparrow egg
  
  SPImage *image = [[SPImage alloc] initWithTexture:[Media atlasTexture:@"ufo_1"]];
  image.pivotX = (int)image.width / 2;
  image.pivotY = (int)image.height / 2;
  image.x = mGameWidth / 2;
  image.y = mGameHeight / 2 + 40;
  [self addChild:image];
  
  // play a sound when the image is touched
  [image addEventListener:@selector(onImageTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
  
  // and animate it a little
  SPTween *tween = [SPTween tweenWithTarget:image time:1.5 transition:SP_TRANSITION_EASE_IN_OUT];
  [tween animateProperty:@"y" targetValue:image.y + 30];
  [tween animateProperty:@"rotation" targetValue:0.1];
  tween.loop = SPLoopTypeReverse;
  [[SPStage mainStage].juggler addObject:tween];
  
  
  // The scaffold autorotates the game to all supported device orientations. 
  // Choose the orienations you want to support in the Target Settings ("Summary"-tab).
  // To update the game content accordingly, listen to the "RESIZE" event; it is dispatched
  // to all game elements (just like an ENTER_FRAME event).
  // 
  // To force the game to start up in landscape, add the key "Initial Interface Orientation" to
  // the "App-Info.plist" file and choose any landscape orientation.
  
  [self addEventListener:@selector(onResize:) atObject:self forType:SP_EVENT_TYPE_RESIZE];
  
}

- (void)onImageTouched:(SPTouchEvent *)event
{
  NSSet *touches = [event touchesWithTarget:self andPhase:SPTouchPhaseEnded];
  if ([touches anyObject])
  {
    [Media playSound:@"sound.caf"];
  }
}

- (void)onResize:(SPResizeEvent *)event
{
  NSLog(@"new size: %.0fx%.0f (%@)", event.width, event.height, 
        event.isPortrait ? @"portrait" : @"landscape");
}

@end
