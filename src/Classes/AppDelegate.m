//
//  AppDelegate.m
//  AppScaffold
//

#import "AppDelegate.h"
#import "Game.h"
#import "GameController.h"

@implementation AppDelegate

// --- c functions ---

void onUncaughtException(NSException *exception)
{
    NSLog(@"uncaught exception: %@", exception.description);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&onUncaughtException);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    _Window = [[UIWindow alloc] initWithFrame:screenBounds];
    
    _ViewController = [[SPViewController alloc] init];
    
    
    // Your game will have a different size depending on where it's running!
    // If your game is landscape only set "Initial Interface Orientation" to
    // a landscape orientation in App-Info.plist.
    
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    int width  = isPad ? 384 : screenBounds.size.width;
    int height = isPad ? 512 : screenBounds.size.height;
    
    // Enable some common settings here:
    //
    // _viewController.showStats = YES;
    _ViewController.multitouchEnabled = YES;
    _ViewController.preferredFramesPerSecond = 60;
    
    //GameController *gameController = [[GameController alloc] initWithWidth:width height:height];
        
    [_ViewController startWithRoot:[Game class] supportHighResolutions:YES doubleOnPad:YES];
    
    //[_ViewController stage] = gameController;

    
    [_Window setRootViewController:_ViewController];
    [_Window makeKeyAndVisible];

    
    
    return YES;
}

@end
