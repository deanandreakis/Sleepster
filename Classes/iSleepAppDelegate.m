//
//  iSleepAppDelegate.m
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "iSleepAppDelegate.h"
#import "MainViewController.h"
#import "InformationViewController.h"
#import "SettingsViewController.h"
#import "SoundsViewController.h"
#import "BackgroundsViewController.h"

@implementation iSleepAppDelegate


@synthesize window;
@synthesize mainViewController;
@synthesize tabBarController, fsController, settingsViewController, soundsViewController, backgroundsViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	application.idleTimerDisabled = YES;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	MainViewController *aController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	self.mainViewController = aController;
	mainViewController.tabBarItem.title = @"Main";
    
    mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
    
    fsController = [[InformationViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	fsController.tabBarItem.title = @"Info";
    
    settingsViewController = [[SettingsViewController alloc] initWithNibName:nil bundle:nil];
    settingsViewController.tabBarItem.title = @"Options";
    
    soundsViewController = [[SoundsViewController alloc] initWithNibName:nil bundle:nil];
    soundsViewController.tabBarItem.title = @"Sounds";
    
    backgroundsViewController = [[BackgroundsViewController alloc] initWithNibName:nil bundle:nil];
    backgroundsViewController.tabBarItem.title = @"Backgrounds";
    
    tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:aController,soundsViewController,backgroundsViewController,settingsViewController,fsController,nil]];
                                          
    //[window addSubview:[mainViewController view]];
    [self.window setRootViewController:tabBarController];
    //window.rootViewController = tabBarController;
    [window makeKeyAndVisible];
}



@end
