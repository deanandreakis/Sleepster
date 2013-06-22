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
#import <Crashlytics/Crashlytics.h>

@implementation iSleepAppDelegate


@synthesize window = _window;
@synthesize mainViewController, informationViewController, settingsViewController, soundsViewController, backgroundsViewController,tabBarController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	[Crashlytics startWithAPIKey:@"2eaad7ad1fecfce6c414905676a8175bb2a1c253"];
    
    application.idleTimerDisabled = YES;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    mainViewController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
    mainViewController.tabBarItem.title = @"Main";
    mainViewController.tabBarItem.image = [UIImage imageNamed:@"home-2.png"];
    
    informationViewController = [[InformationViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    informationViewController.tabBarItem.title = @"Information";
    informationViewController.tabBarItem.image = [UIImage imageNamed:@"Info.png"];
    
    settingsViewController = [[SettingsViewController alloc] initWithNibName:nil bundle:nil];
    settingsViewController.tabBarItem.title = @"Settings";
    settingsViewController.tabBarItem.image = [UIImage imageNamed:@"Settings.png"];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    soundsViewController = [[SoundsViewController alloc] initWithCollectionViewLayout:layout];
    soundsViewController.tabBarItem.title = @"Sounds";
    soundsViewController.tabBarItem.image = [UIImage imageNamed:@"Speaker-1.png"];
    
    backgroundsViewController = [[BackgroundsViewController alloc] initWithCollectionViewLayout:layout];
    backgroundsViewController.tabBarItem.title = @"Backgrounds";
    backgroundsViewController.tabBarItem.image = [UIImage imageNamed:@"Picture-Landscape.png"];
    
    layout.itemSize = CGSizeMake(64, 64);
    layout.minimumInteritemSpacing = 64;
    layout.minimumLineSpacing = 64;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(32, 32, 32, 32);
    
    [soundsViewController setDelegate:mainViewController];
    [backgroundsViewController setDelegate:mainViewController];
    
    tabBarController = [[UITabBarController alloc] init];
    NSArray* array = [NSArray arrayWithObjects:mainViewController,soundsViewController,backgroundsViewController,settingsViewController,informationViewController,nil];
    [tabBarController setViewControllers:array animated:YES];
    
    [self.window setRootViewController:tabBarController];
    [self.window makeKeyAndVisible];
}

+ (iSleepAppDelegate *)appDelegate
{
    return (iSleepAppDelegate *)[[UIApplication sharedApplication] delegate];
}


@end
