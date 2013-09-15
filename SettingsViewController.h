//
//  SettingsViewController.h
//  SleepMate
//
//  Created by Dean Andreakis on 12/6/12.
//
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate <NSObject>
- (void)settingsViewControllerBgSwitchedOff;
- (void)settingsViewControllerSoundSwitchedOff;
@end

@interface SettingsViewController : UIViewController

-(BOOL)bgSwitchState;
-(BOOL)soundSwitchState;

@property (assign) id<SettingsViewControllerDelegate> settingsDelegate;
@end
