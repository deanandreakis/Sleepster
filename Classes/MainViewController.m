//
//  MainViewController.m
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"
#import "iSleepAppDelegate.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "Constants.h"
#import "FUIAlertView.h"
#import "UIColor+FlatUI.h"
#import "UIFont+FlatUI.h"
#import "FUISegmentedControl.h"
#import "UISlider+FlatUI.h"

@interface MainViewController ()

@property(strong, nonatomic) AVAudioPlayer* theSong;
@property(strong, nonatomic) UIColor* theColor;
@property(strong, nonatomic) FUISegmentedControl* segmentedControl; //use this for time selection
@property(strong, nonatomic) UISlider* volumeSlider;

@end

@implementation MainViewController

@synthesize timeOut;
@synthesize natureVolume, volumeSlider, segmentedControl;
@synthesize musicTimerTypes;
@synthesize playerState;
@synthesize interruptedOnPlayback;
@synthesize timerFired;
@synthesize menuBtn;
@synthesize theSong;
@synthesize theColor;

#pragma mark Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        NSString *pathToMusicFile0 = [[NSBundle mainBundle] pathForResource:@"campfire" ofType:@"mp3"];
        theSong = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile0] error:NULL];
        theColor = [UIColor blueColor];
            }
    return self;
}

#pragma mark -
#pragma mark View Cycle
- (void)viewDidAppear:(BOOL)animated
{
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}


- (void)viewDidLoad {
	
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]])
    {
        self.slidingViewController.underLeftViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Menu"];
    }
	
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    self.menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    menuBtn.frame = CGRectMake(8, 10, 34, 24);
    [menuBtn setBackgroundImage:[UIImage imageNamed:@"menuButton.png"] forState:UIControlStateNormal];
    [menuBtn addTarget:self action:@selector(revealMenu:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.menuBtn];
    
	self.view.backgroundColor = [UIColor belizeHoleColor];
	
	/*Setup battery state monitoring*/
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	
	/*Setup audio*/
	//Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];
	
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
	
	NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
	
	NSArray *segmentLabels = [[NSArray alloc] initWithObjects:@"\u221E", @"15", @"30", @"60", @"90",nil];

	playerState = NO;
	
	interruptedOnPlayback = NO;
	
    timeOut = kOffSegmentIndex;
    
	natureVolume = 50.0;
    
    volumeSlider = [[UISlider alloc] init];
    volumeSlider.frame = CGRectMake(14, 340, 293, 23);
    volumeSlider.minimumValue = 1.0;
    volumeSlider.maximumValue = 100.0;
    [volumeSlider setValue:50.0];
    [volumeSlider addTarget:self action:@selector(volumeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [volumeSlider configureFlatSliderWithTrackColor:[UIColor silverColor]
                                  progressColor:[UIColor peterRiverColor]
                                     thumbColor:[UIColor concreteColor]];
    [self.view addSubview:volumeSlider];
    
    
    segmentedControl = [[FUISegmentedControl alloc] initWithItems:segmentLabels];
    segmentedControl.frame = CGRectMake(14, 60, 293, 44);
    [segmentedControl addTarget:self
                         action:@selector(segmentedControlChanged:)
               forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedFont = [UIFont boldFlatFontOfSize:16];
    segmentedControl.selectedFontColor = [UIColor cloudsColor];
    segmentedControl.deselectedFont = [UIFont flatFontOfSize:16];
    segmentedControl.deselectedFontColor = [UIColor cloudsColor];
    segmentedControl.selectedColor = [UIColor peterRiverColor];
    segmentedControl.deselectedColor = [UIColor silverColor];
    segmentedControl.dividerColor = [UIColor midnightBlueColor];
    segmentedControl.cornerRadius = 5.0;
    segmentedControl.selectedSegmentIndex = 0;
    [self.view addSubview:segmentedControl];
		  
	[super viewDidLoad];
}

- (void)viewDidUnload {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



- (void)flipsideViewControllerDidFinish:(InformationViewController *)controller {
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)backlightViewControllerDidFinish:(BacklightViewController *)controller {	
    if([theSong isPlaying] && !timerFired)
	{
        [self dismissViewControllerAnimated:YES completion:nil];
        [theSong pause];
        [theSong setCurrentTime:0];
	    if(timeOut != kOffSegmentIndex)
        {
            [timer invalidate];
        }
	    playerState = NO;
	}
    else if(![theSong isPlaying] && timerFired)
	{
        [self dismissViewControllerAnimated:YES completion:nil];
	}
}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}


- (IBAction) startSleeping {
	
    //check for battery state; if unplugged show an alert
	if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged) {
		FUIAlertView *alertView = [[FUIAlertView alloc]
                                  initWithTitle:@"Plug In"
                                  message:@"Please Plug In to Avoid Draining the Battery"
                                  delegate:nil
                                  cancelButtonTitle:@"Continue"
                                  otherButtonTitles:nil];
         alertView.titleLabel.textColor = [UIColor cloudsColor];
         alertView.titleLabel.font = [UIFont fontWithName:@"Verdana-Bold" size:16];//[UIFont boldFlatFontOfSize:16];
         alertView.messageLabel.textColor = [UIColor cloudsColor];
         alertView.messageLabel.font = [UIFont fontWithName:@"Verdana-Bold" size:14];//[UIFont flatFontOfSize:14];
         alertView.backgroundOverlay.backgroundColor = [[UIColor cloudsColor] colorWithAlphaComponent:0.8];
         alertView.alertContainer.backgroundColor = [UIColor midnightBlueColor];
         alertView.defaultButtonColor = [UIColor cloudsColor];
         alertView.defaultButtonShadowColor = [UIColor asbestosColor];
         alertView.defaultButtonFont = [UIFont fontWithName:@"Verdana-Bold" size:16];//[UIFont boldFlatFontOfSize:16];
         alertView.defaultButtonTitleColor = [UIColor asbestosColor];
         alertView.delegate = self;
		[alertView show];
	} else {
        [self reallyStartSleeping];
    }
}

- (void)reallyStartSleeping
{
	if(timeOut != kOffSegmentIndex)
    {
	    timer = [NSTimer scheduledTimerWithTimeInterval: timeOut
                                                 target: self
                                               selector: @selector(timerFired:)
                                               userInfo: nil
                                                repeats: NO];
	}
    timerFired = NO;
	
	BacklightViewController *controller = [[BacklightViewController alloc] initWithNibName:@"BacklightView" bundle:nil];
	controller.bgDelegate = self;
    controller.backgroundColor = theColor;
	
	/*Play the background music selected*/
	[theSong setVolume:(natureVolume / 100)];
	[theSong play];
	playerState = YES;
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentViewController:controller animated:YES completion:nil];
}

#pragma mark UIAlertView delegate method
- (void)alertView:(FUIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self reallyStartSleeping];
}

#pragma mark NSTimer Fired
- (void) timerFired: (NSTimer *) theTimer
{
	timerFired = YES;
    [theSong stopWithFadeDuration:fadeoutTime];
	playerState = NO;
}


#pragma mark AVAudioPlayer delegate methods
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
	
    if (playerState) {
		
        playerState = NO;
        interruptedOnPlayback = YES;
    }
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {

    // Reactivates the audio session, whether or not audio was playing
    //      when the interruption arrived.
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
    if (interruptedOnPlayback) {
		
        [player prepareToPlay];
        [player play];
        playerState = YES;
        interruptedOnPlayback = NO;
    }
}

#pragma mark SoundsViewControllerDelegate methods

- (void)songSelected:(AVAudioPlayer*)song
{
    NSLog(@"got song event");
    [song setDelegate:self];
    self.theSong = song;
}

#pragma mark BackgroundsViewControllerDelegate methods
- (void)backgroundSelected:(UIColor *)background
{
    NSLog(@"got background event");
    self.theColor = background;
}

#pragma mark Volume Slider

- (IBAction)volumeSliderChanged:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	int volume = (int)(slider.value + 0.5f);
	natureVolume = (float)volume;
}

#pragma mark Segmented Control

- (IBAction)segmentedControlChanged:(id)sender
{
	FUISegmentedControl *scontrol = (FUISegmentedControl *)sender;
    NSInteger segment = scontrol.selectedSegmentIndex;
	switch (segment) {
		case kFifteenMinSegmentIndex:
			timeOut = 900 - fadeoutTime;//seconds
			break;
		case kThirtyMinSegmentIndex:
			timeOut = 1800 - fadeoutTime;//seconds
			break;
		case kSixtyMinSegmentIndex:
			timeOut = 3600 - fadeoutTime;//seconds
			break;
		case kNinetyMinSegmentIndex:
			timeOut = 5400 - fadeoutTime;//seconds
			break;
        case kOffSegmentIndex:
			timeOut = kOffSegmentIndex;//seconds
			break;
		default:
			timeOut = kOffSegmentIndex;
			break;
	}
}


@end
