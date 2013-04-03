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

#define kMusicSelection 0
#define kMusicTimer 1
#define kNightlightColor 2
#define fadeoutTime 30

@interface MainViewController : UIViewController 
    <FlipsideViewControllerDelegate,BacklightViewControllerDelegate,UIPickerViewDelegate,UIPickerViewDataSource,
AVAudioPlayerDelegate, SoundsViewControllerDelegate>
{
	IBOutlet UIPickerView *picker;
	NSArray *musicSelectionTypes;
	NSArray *musicTimerTypes;
	NSArray *nightLightColorTypes;
	NSArray *songArray;
	
	enum{
		kOffSegmentIndex = 0,
		kFifteenMinSegmentIndex,
		kThirtyMinSegmentIndex,
		kSixtyMinSegmentIndex,
		kNinetyMinSegmentIndex
	} kSegment;
	
	NSInteger timeOut;
	NSInteger songIndex;
	float natureVolume;
	NSTimer* timer;
	BOOL playerState;
	BOOL interruptedOnPlayback;
	BOOL timerFired;
}

@property (assign, nonatomic)NSInteger timeOut;
@property (assign, nonatomic)NSInteger songIndex;
@property (assign, nonatomic)float natureVolume;
@property (nonatomic, strong)UIPickerView *picker;
@property (nonatomic, strong)NSArray *musicSelectionTypes;
@property (nonatomic, strong)NSArray *musicTimerTypes;
@property (nonatomic, strong)NSArray *nightLightColorTypes;
@property (nonatomic, strong)NSArray *songArray;
@property (assign, nonatomic)BOOL playerState;
@property (readwrite)BOOL interruptedOnPlayback;
@property (readwrite)BOOL timerFired;
@property (strong, nonatomic) UIButton *menuBtn;

- (IBAction)showInfo;
- (IBAction)startSleeping;
- (void) timerFired: (NSTimer *) theTimer;
- (IBAction)volumeSliderChanged:(id)sender;
- (IBAction)tweeterButton:(id)sender;
- (IBAction)facebookButton:(id)sender;

@end
