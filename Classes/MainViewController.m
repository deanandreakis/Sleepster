//
//  MainViewController.m
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"
#import <Social/Social.h>
#import "iSleepAppDelegate.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "Constants.h"
#import "FUIAlertView.h"
#import "UIColor+FlatUI.h"
#import "UIFont+FlatUI.h"

@interface MainViewController ()

@property(strong, nonatomic) AVAudioPlayer* theSong;
@property(strong, nonatomic) UIColor* theColor;

@end

@implementation MainViewController

@synthesize timeOut;
@synthesize natureVolume;
@synthesize picker;
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
    
	self.view.backgroundColor = UIColorFromRGB(0x2980b9);
	
	/*Setup battery state monitoring*/
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	
	/*Setup audio*/
	//Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];
	
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
	
	NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
	
	UILabel *col1_label1 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label1.text = @"\u221E";
	col1_label1.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col1_label1.backgroundColor = [UIColor clearColor];
        
    UILabel *col1_label2 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label2.text = @"15";
	col1_label2.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col1_label2.backgroundColor = [UIColor clearColor];
	
	UILabel *col1_label3 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label3.text = @"30";
	col1_label3.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col1_label3.backgroundColor = [UIColor clearColor];
	
	UILabel *col1_label4 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label4.text = @"60";
	col1_label4.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col1_label4.backgroundColor = [UIColor clearColor];
	
	UILabel *col1_label5 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label5.text = @"90";
	col1_label5.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col1_label5.backgroundColor = [UIColor clearColor];
	
	NSArray *musicTimerArray = [[NSArray alloc] initWithObjects:col1_label1, col1_label2,
								col1_label3,col1_label4,col1_label5,nil];
	self.musicTimerTypes = musicTimerArray;

	playerState = NO;
	
	interruptedOnPlayback = NO;
	
	natureVolume = 50.0;
		  
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
        /*alertView.titleLabel.textColor = [UIColor cloudsColor];
        alertView.titleLabel.font = [UIFont boldFlatFontOfSize:16];
        alertView.messageLabel.textColor = [UIColor cloudsColor];
        alertView.messageLabel.font = [UIFont flatFontOfSize:14];
        alertView.backgroundOverlay.backgroundColor = [[UIColor cloudsColor] colorWithAlphaComponent:0.8];
        alertView.alertContainer.backgroundColor = [UIColor midnightBlueColor];
        alertView.defaultButtonColor = [UIColor cloudsColor];
        alertView.defaultButtonShadowColor = [UIColor asbestosColor];
        alertView.defaultButtonFont = [UIFont boldFlatFontOfSize:16];
        alertView.defaultButtonTitleColor = [UIColor asbestosColor];*/
		[alertView show];
	}
	
	NSInteger segment = [picker selectedRowInComponent:kMusicTimer];
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
	
- (void) timerFired: (NSTimer *) theTimer
{
	timerFired = YES;
    [theSong stopWithFadeDuration:fadeoutTime];
	playerState = NO;
}


#pragma mark -
#pragma mark Picker Data Source Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.musicTimerTypes count];
}

#pragma mark Picker Delegate Methods
- (UIView *)pickerView:(UIPickerView *)pickerView 
    viewForRow:(NSInteger)row 
    forComponent:(NSInteger)component 
    reusingView:(UIView *)view
{
    return [self.musicTimerTypes objectAtIndex:row];
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

#pragma msrk BackgroundsViewControllerDelegate methods
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

#pragma mark Social Network Methods

- (IBAction) tweeterButton:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:@"Tweeting from my own app! :)"];
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure \
                                  your device has an internet connection and you have \
                                  at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction) facebookButton:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *fbSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbSheet setInitialText:@"Facebooking from my own app! :)"];
        [self presentViewController:fbSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't facebook right now, make sure \
                                  your device has an internet connection and you have \
                                  at least one Facebook account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

@end
