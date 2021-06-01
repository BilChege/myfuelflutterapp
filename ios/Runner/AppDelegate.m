#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "GoogleMaps/GoogleMaps.h"

@implementation AppDelegate

 - (BOOL)application:(UIApplication *)application
     didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
     [GMSServices provideAPIKey:@"AIzaSyC1oBtZ7QkyEyQRVC5fD6BrC2aYtF8NFqY"];
     [GeneratedPluginRegistrant registerWithRegistry:self];
     return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
@end