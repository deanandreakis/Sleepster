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
//#import <Crashlytics/Crashlytics.h>
#import "DatabaseManager.h"
#import "Constants.h"
#import "SleepsterIAPHelper.h"

@implementation iSleepAppDelegate


@synthesize window = _window;
@synthesize mainViewController, informationViewController, settingsViewController, soundsViewController, backgroundsViewController,tabBarController;

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //[Crashlytics startWithAPIKey:CRASHLYTICS_KEY];
    
    [SleepsterIAPHelper sharedInstance];
    
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
    mainViewController.restorationIdentifier = RESTORATION_ID_MAIN_VC;
    
    informationViewController = [[InformationViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    informationViewController.tabBarItem.title = @"Information";
    informationViewController.tabBarItem.image = [UIImage imageNamed:@"Info.png"];
    informationViewController.restorationIdentifier = RESTORATION_ID_INFO_VC;
    
    settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    settingsViewController.tabBarItem.title = @"Settings";
    settingsViewController.tabBarItem.image = [UIImage imageNamed:@"Settings.png"];
    settingsViewController.restorationIdentifier = RESTORATION_ID_SETTINGS_VC;
    
    UICollectionViewFlowLayout *backgroundLayout = [[UICollectionViewFlowLayout alloc] init];
    
    soundsViewController = [[SoundsViewController alloc] initWithNibName:@"SoundsViewController" bundle:nil];
    soundsViewController.tabBarItem.title = @"Sounds";
    soundsViewController.tabBarItem.image = [UIImage imageNamed:@"Speaker-1.png"];
    soundsViewController.restorationIdentifier = RESTORATION_ID_SOUNDS_VC;
    
    backgroundsViewController = [[BackgroundsViewController alloc] initWithCollectionViewLayout:backgroundLayout];
    backgroundsViewController.tabBarItem.title = @"Backgrounds";
    backgroundsViewController.tabBarItem.image = [UIImage imageNamed:@"Picture-Landscape.png"];
    backgroundsViewController.restorationIdentifier = RESTORATION_ID_BG_VC;
    
    backgroundLayout.itemSize = CGSizeMake(FLICKR_THUMBNAIL_SIZE, FLICKR_THUMBNAIL_SIZE);
    backgroundLayout.minimumInteritemSpacing = 2;
    if ([[UIScreen mainScreen] bounds].size.height == 568){
        //add your 4-inch specific code here
        backgroundLayout.minimumLineSpacing = 30;
    } else {
        backgroundLayout.minimumLineSpacing = 20;
    }
    backgroundLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    backgroundLayout.sectionInset = UIEdgeInsetsMake(20, 20, 60, 20);
    
    [soundsViewController setDelegate:mainViewController];
    [backgroundsViewController setDelegate:mainViewController];
    [settingsViewController setSettingsDelegate:mainViewController];
    
    tabBarController = [[UITabBarController alloc] init];
    tabBarController.restorationIdentifier = RESTORATION_ID_TAB_BAR_C;
    NSArray* array = [NSArray arrayWithObjects:mainViewController,soundsViewController,backgroundsViewController,settingsViewController,informationViewController,nil];
    [tabBarController setViewControllers:array animated:YES];
    
    [self.window setRootViewController:tabBarController];
    [self.window makeKeyAndVisible];
    
    return YES;
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
    if([[DatabaseManager sharedDatabaseManager] isDBNotExist])
    {
        [[DatabaseManager sharedDatabaseManager] prePopulate];
    }
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

#pragma mark state preservation and restoration
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return YES;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {
    
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder {
    
}

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {

    /*We dont need to return the view controllers created above since the willFinishLaunchingWithOptions method
     executes before the restoration process, thus all those view controllers are created and in memory and the implicit
     search by the system will find those objects.*/
    return nil;
    
    /*NSString* identifier = (NSString*)[identifierComponents lastObject];
    if([identifier isEqualToString:@"SettingsViewControllerID"])
    {
        return settingsViewController;
    } else if([identifier isEqualToString:@"UITabBarControllerID"])
    {
        return tabBarController;
    }
    else {
        return nil;
    }*/
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if ([self.window.rootViewController.presentedViewController isKindOfClass: [BacklightViewController class]])
    {
        BacklightViewController *secondController = (BacklightViewController *) self.window.rootViewController.presentedViewController;
        
        if (secondController.isPresented)
            return UIInterfaceOrientationMaskAll;
        else return UIInterfaceOrientationMaskPortrait;
    }
    else return UIInterfaceOrientationMaskPortrait;
}

+ (iSleepAppDelegate *)appDelegate
{
    return (iSleepAppDelegate *)[[UIApplication sharedApplication] delegate];
}


@end
