//
//  iSleepAppDelegate.h
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

@class MainViewController;
@class InformationViewController;
@class SettingsViewController;
@class SoundsViewController;
@class BackgroundsViewController;

@interface iSleepAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *mainViewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) MainViewController *mainViewController;
@property (nonatomic, strong) InformationViewController *fsController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) SoundsViewController *soundsViewController;
@property (nonatomic, strong) BackgroundsViewController *backgroundsViewController;


@property (strong, nonatomic) UITabBarController *tabBarController;

@end

