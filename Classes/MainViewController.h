//
//  MainViewController.h
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "InformationViewController.h"
#import "BacklightViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVAudioPlayer+PGFade.h"
#import "SoundsViewController.h"
#import "BackgroundsViewController.h"
#import "TimerViewController.h"
#import "SettingsViewController.h"

#define kMusicTimer 0


@interface MainViewController : UIViewController 
    <BacklightViewControllerDelegate,
AVAudioPlayerDelegate, SoundsViewControllerDelegate, BackgroundsViewControllerDelegate, UIAlertViewDelegate,
UIActionSheetDelegate, SettingsViewControllerDelegate>
{
	NSInteger timeOut;
	float natureVolume;
	NSTimer* timer;
	BOOL playerState;
	BOOL interruptedOnPlayback;
	BOOL timerFired;
}

@property (assign, nonatomic)NSInteger timeOut;
@property (assign, nonatomic)float natureVolume;
@property (assign, nonatomic)BOOL playerState;
@property (readwrite)BOOL interruptedOnPlayback;
@property (readwrite)BOOL timerFired;
@property (strong, nonatomic) UIButton *menuBtn;

- (IBAction)startSleeping;
- (void) timerFired: (NSTimer *) theTimer;
- (IBAction)volumeSliderChanged:(id)sender;

@end
