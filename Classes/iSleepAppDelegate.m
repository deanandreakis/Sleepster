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
#import "DatabaseManager.h"
#import "Constants.h"

@implementation iSleepAppDelegate


@synthesize window = _window;
@synthesize mainViewController, informationViewController, settingsViewController, soundsViewController, backgroundsViewController,tabBarController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	[Crashlytics startWithAPIKey:@"2eaad7ad1fecfce6c414905676a8175bb2a1c253"];
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [store synchronize];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //initialize CoreData
    [[DatabaseManager sharedDatabaseManager] managedObjectContext];
    
    if([[DatabaseManager sharedDatabaseManager] isDBNotExist])
    {
        [[DatabaseManager sharedDatabaseManager] prePopulate];
    }
    
    mainViewController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
    mainViewController.tabBarItem.title = @"Main";
    mainViewController.tabBarItem.image = [UIImage imageNamed:@"home-2.png"];
    
    informationViewController = [[InformationViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    informationViewController.tabBarItem.title = @"Information";
    informationViewController.tabBarItem.image = [UIImage imageNamed:@"Info.png"];
    
    settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    settingsViewController.tabBarItem.title = @"Settings";
    settingsViewController.tabBarItem.image = [UIImage imageNamed:@"Settings.png"];
    
    UICollectionViewFlowLayout *backgroundLayout = [[UICollectionViewFlowLayout alloc] init];
    UICollectionViewFlowLayout *soundLayout = [[UICollectionViewFlowLayout alloc] init];
    
    soundsViewController = [[SoundsViewController alloc] initWithCollectionViewLayout:soundLayout];
    soundsViewController.tabBarItem.title = @"Sounds";
    soundsViewController.tabBarItem.image = [UIImage imageNamed:@"Speaker-1.png"];
    
    backgroundsViewController = [[BackgroundsViewController alloc] initWithCollectionViewLayout:backgroundLayout];
    backgroundsViewController.tabBarItem.title = @"Backgrounds";
    backgroundsViewController.tabBarItem.image = [UIImage imageNamed:@"Picture-Landscape.png"];
    
    soundLayout.itemSize = CGSizeMake(50, 50);
    soundLayout.minimumInteritemSpacing = 2;
    soundLayout.minimumLineSpacing = 20;
    soundLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    soundLayout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    
    backgroundLayout.itemSize = CGSizeMake(FLICKR_THUMBNAIL_SIZE, FLICKR_THUMBNAIL_SIZE);
    backgroundLayout.minimumInteritemSpacing = 2;
    backgroundLayout.minimumLineSpacing = 20;
    backgroundLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    backgroundLayout.sectionInset = UIEdgeInsetsMake(20, 20, 60, 20);
    
    [soundsViewController setDelegate:mainViewController];
    [backgroundsViewController setDelegate:mainViewController];
    
    tabBarController = [[UITabBarController alloc] init];
    NSArray* array = [NSArray arrayWithObjects:mainViewController,soundsViewController,backgroundsViewController,settingsViewController,informationViewController,nil];
    [tabBarController setViewControllers:array animated:YES];
    
    [self.window setRootViewController:tabBarController];
    [self.window makeKeyAndVisible];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[DatabaseManager sharedDatabaseManager] saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [store synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [[DatabaseManager sharedDatabaseManager] saveContext];
}


+ (iSleepAppDelegate *)appDelegate
{
    return (iSleepAppDelegate *)[[UIApplication sharedApplication] delegate];
}


@end
