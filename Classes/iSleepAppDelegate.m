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


@synthesize window;
@synthesize mainViewController, informationViewController, settingsViewController, soundsViewController, backgroundsViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	[Crashlytics startWithAPIKey:@"2eaad7ad1fecfce6c414905676a8175bb2a1c253"];
    
    application.idleTimerDisabled = YES;
    
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
    mainViewController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
    informationViewController = [[InformationViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    settingsViewController = [[SettingsViewController alloc] initWithNibName:nil bundle:nil];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    soundsViewController = [[SoundsViewController alloc] initWithCollectionViewLayout:layout];
    layout.itemSize = CGSizeMake(64, 64);
    layout.minimumInteritemSpacing = 64;
    layout.minimumLineSpacing = 64;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(32, 32, 32, 32);
    backgroundsViewController = [[BackgroundsViewController alloc] initWithNibName:nil bundle:nil];
    [soundsViewController setDelegate:mainViewController];

    //[self.window setRootViewController:self];
    //[window makeKeyAndVisible];
}

+ (iSleepAppDelegate *)appDelegate
{
    return (iSleepAppDelegate *)[[UIApplication sharedApplication] delegate];
}


@end
