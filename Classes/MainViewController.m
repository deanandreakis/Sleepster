//
//  MainViewController.m
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MainViewController.h"
#import "iSleepAppDelegate.h"
#import "Constants.h"

@interface MainViewController ()

@property(strong, nonatomic) AVAudioPlayer* theSong;
@property(strong, nonatomic) UIColor* theColor;
@property (assign, nonatomic)float natureBrightness;
@property (strong, nonatomic) TimerViewController* controller;

@end

@implementation MainViewController

@synthesize timeOut;
@synthesize natureVolume, natureBrightness;
@synthesize musicTimerTypes;
@synthesize playerState;
@synthesize interruptedOnPlayback;
@synthesize timerFired;
@synthesize menuBtn;
@synthesize theSong;
@synthesize theColor, controller;

#pragma mark Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        NSString *pathToMusicFile0 = [[NSBundle mainBundle] pathForResource:@"campfire" ofType:@"mp3"];
        theSong = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile0] error:NULL];
        theColor = [UIColor whiteColor];
            }
    return self;
}

#pragma mark -
#pragma mark View Cycle


- (void)viewDidLoad {
    
	self.view.backgroundColor = theColor;//[UIColor whiteColor];
	
	/*Setup battery state monitoring*/
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	
	/*Setup audio*/
	//Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];
	
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
	
	NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
	
	playerState = NO;
	
	interruptedOnPlayback = NO;
	
    timeOut = kOffSegmentIndex;
    
	natureVolume = 50.0;
    natureBrightness = 0.5;
    
    controller = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];
	controller.timerDelegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

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

- (IBAction) startSleeping {
	
    //check for battery state; if unplugged show an alert
	if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged) {
		UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Plug In"
                                  message:@"Please Plug In to Avoid Draining the Battery"
                                  delegate:nil
                                  cancelButtonTitle:@"Continue"
                                  otherButtonTitles:nil];
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
	
	BacklightViewController *blcontroller = [[BacklightViewController alloc] initWithNibName:@"BacklightView" bundle:nil];
	blcontroller.bgDelegate = self;
    blcontroller.backgroundColor = theColor;
    blcontroller.brightness = natureBrightness;
	
	/*Play the background music selected*/
	[theSong setVolume:(natureVolume / 100)];
	[theSong play];
	playerState = YES;
	blcontroller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentViewController:blcontroller animated:YES completion:nil];
}

#pragma mark UIAlertView delegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
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
    self.view.backgroundColor = theColor;
}

#pragma mark Volume Slider

- (IBAction)volumeSliderChanged:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	int volume = (int)(slider.value + 0.5f);
	natureVolume = (float)volume;
}

#pragma mark Brightness Slider

- (IBAction)brightnessSliderChanged:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	natureBrightness = slider.value;
    [[UIScreen mainScreen] setBrightness:natureBrightness];
}

#pragma mark Timer Button

- (IBAction)timerButtonSelected:(id)sender
{
    //open the TimerViewController
    //TimerViewController *controller = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];
	//controller.timerDelegate = self;
    //controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self presentViewController:controller animated:YES completion:nil];
}

#pragma mark TimerViewControllerDelegate

- (void)timerViewControllerDidFinish:(NSInteger)timeValue
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.timeOut = timeValue;
}

@end
