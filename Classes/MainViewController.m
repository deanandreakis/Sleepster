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
#import "UIImageView+AFNetworking.h"
#import "iSleepAppDelegate.h"
#import "SettingsViewController.h"

#define UNPLUGGEDGREATER20 90
#define UNPLUGGEDLESS20 91

@interface MainViewController ()

@property(strong, nonatomic) AVAudioPlayer* theSong;
@property(strong, nonatomic) NSMutableArray* theSongArray;
@property(strong, nonatomic) UIColor* theColor;
@property (assign, nonatomic) float natureBrightness;
@property (strong, nonatomic) TimerViewController* controller;
@property (strong, nonatomic) IBOutlet UILabel* timerLabel;
@property (strong, nonatomic) IBOutlet UILabel* minutesLabel;
@property (strong, nonatomic) IBOutlet UIImageView* bgImageView;
@property (strong,nonatomic) NSURL* bgImageURL;
@property (strong, nonatomic) NSMutableArray* bgarray;
@property (strong, nonatomic) NSTimer* bgTimer;
@property (assign, nonatomic) int bgTimerCounter;

@end

@implementation MainViewController

@synthesize timeOut, bgImageURL, bgarray, bgTimer, bgTimerCounter;
@synthesize natureVolume, natureBrightness;
@synthesize musicTimerTypes;
@synthesize playerState;
@synthesize interruptedOnPlayback;
@synthesize timerFired;
@synthesize menuBtn;
@synthesize theSong, theSongArray;
@synthesize theColor, controller, timerLabel, minutesLabel, bgImageView;

#pragma mark Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        NSString *pathToMusicFile0 = [[NSBundle mainBundle] pathForResource:@"campfire" ofType:@"mp3"];
        theSong = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile0] error:NULL];
        [theSong setNumberOfLoops:-1];
		[theSong prepareToPlay];
        theColor = [UIColor whiteColor];
            }
    return self;
}

#pragma mark -
#pragma mark View Cycle


- (void)viewDidLoad {
    
	self.bgImageView.backgroundColor = theColor;
    self.view.backgroundColor = [UIColor whiteColor];
	
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
    timerLabel.text = @"OFF";
    self.minutesLabel.hidden = YES;
    
	natureVolume = 50.0;
    natureBrightness = 0.5;
    
    controller = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];
	controller.timerDelegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    bgarray = [[NSMutableArray alloc] initWithCapacity:5];
    theSongArray = [[NSMutableArray alloc] initWithCapacity:5];
    
	[super viewDidLoad];
}

- (void)viewDidUnload {
}

-(void)viewWillAppear:(BOOL)animated
{
    //cover the case where someone has selected mutiple bg's and then tuned off the option to
    //support mult bg's/rotate bg's.
    if(![[iSleepAppDelegate appDelegate].settingsViewController bgSwitchState])//TODO: are all objects here initd at statup???
    {
        if([bgarray count] > 1)
        {
            [bgarray removeAllObjects];
        }
        //TODO put code here to add permanent bg object
    }
    bgTimerCounter = 0;
    [self.bgImageView setImage:nil];
    self.bgImageURL = nil;
    if([bgarray count] > 0)
    {
        [self bgTimerFired:nil];
        //start a timer and rotate thru Background objects
        bgTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                 target: self
                                               selector: @selector(bgTimerFired:)
                                               userInfo: nil
                                                repeats: YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [bgTimer invalidate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)areSongsPlaying
{
    BOOL retVal = FALSE;
    
    for (AVAudioPlayer* song in theSongArray) {
        if([song isPlaying]){
            retVal = TRUE;
            break;
        }
    }
    
    return retVal;
}

- (void)backlightViewControllerDidFinish:(BacklightViewController *)controller {	
    
    if([self areSongsPlaying] && !timerFired)
	{
        [self dismissViewControllerAnimated:YES completion:nil];
        for (AVAudioPlayer* song in theSongArray) {
            [song pause];
            [song setCurrentTime:0];
        }
	    if(timeOut != kOffSegmentIndex)
        {
            [timer invalidate];
        }
	    playerState = NO;
	}
    else if(![self areSongsPlaying] && timerFired)
	{
        [self dismissViewControllerAnimated:YES completion:nil];
	}
    else if(![self areSongsPlaying] && !timerFired)
	{
        [self dismissViewControllerAnimated:YES completion:nil];
        if(timeOut != kOffSegmentIndex)
        {
            [timer invalidate];
        }
	}
    else if([self areSongsPlaying] && timerFired)
	{
        [self dismissViewControllerAnimated:YES completion:nil];
        for (AVAudioPlayer* song in theSongArray) {
            [song pause];
            [song setCurrentTime:0];
        }
        playerState = NO;
	}
}

- (IBAction) startSleeping {
	
    //check for battery state; if unplugged show an alert
	if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged &&
        [UIDevice currentDevice].batteryLevel >= 0.2f)
    {
		UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Plug In",nil)
                                  message:NSLocalizedString(@"Please Plug In to Avoid Draining the Battery",nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                  otherButtonTitles:nil];
		alertView.tag = UNPLUGGEDGREATER20;
        [alertView show];
	}
    else if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged &&
       [UIDevice currentDevice].batteryLevel < 0.2f)
    {
		UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Plug In",nil)
                                  message:NSLocalizedString(@"batteryproblem",nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                  otherButtonTitles:nil];
		alertView.tag = UNPLUGGEDLESS20;
        [alertView show];
	}
    else //device is plugged in/charging
    {
        [self reallyStartSleeping];
    }
}

- (void)reallyStartSleeping
{
	[bgTimer invalidate];
    
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
    NSMutableArray* tempArray = [[NSMutableArray alloc] initWithCapacity:5];
    for (Background* bg in bgarray) {
        NSURL* url = [NSURL URLWithString:bg.bFullSizeUrl];;
        if(url != nil) {
            [tempArray addObject:url];
        }
    }
    blcontroller.bgImageURL = tempArray;
	
    /*Play the background music selected*/
	for (AVAudioPlayer* song in theSongArray) {
        [song setVolume:(natureVolume / 100)];
        [song play];
    }
    //[theSong setVolume:(natureVolume / 100)];
	//[theSong play];
	
    playerState = YES;
	blcontroller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentViewController:blcontroller animated:YES completion:nil];
}

#pragma mark UIAlertView delegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == UNPLUGGEDGREATER20)
    {
        [self reallyStartSleeping];
    }
    else if(alertView.tag == UNPLUGGEDLESS20)
    {
        //user plugs in while the alert is dispalyed
        if ([UIDevice currentDevice].batteryState != UIDeviceBatteryStateUnplugged)//plugged in
        {
            [self reallyStartSleeping];
        }
    }
}

#pragma mark NSTimer Fired
- (void) timerFired: (NSTimer *) theTimer
{
	timerFired = YES;
    for (AVAudioPlayer* song in theSongArray) {
        [song stopWithFadeDuration:fadeoutTime];
    }
    //[theSong stopWithFadeDuration:fadeoutTime];
	playerState = NO;
}

#pragma mark BG NSTimer Fired
- (void) bgTimerFired: (NSTimer *) theTimer
{
    [self displayBackground:bgarray[bgTimerCounter]];
    if(bgTimerCounter < ([bgarray count] - 1))
    {
        bgTimerCounter++;
    } else {
        bgTimerCounter = 0;
    }
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
    //[song setDelegate:self];
    //self.theSong = song;
    
    if(![theSongArray containsObject:song])
    {
        [theSongArray addObject:song];
        [song setDelegate:self];
    }
}

- (void)songDeSelected:(AVAudioPlayer*)song
{
    //NSLog(@"got song removal event");
    [theSongArray removeObject:song];
}

//DESIGN of Multiple BG's: add an array to hold bg objects. Have API's for bg selected and
//bg deselected and just add/remove to the array when these are called from the bg view controller.
//When viewWillAppear() is called for this view, setup a timer to iterate thru the array every 30 seconds
//or so and just execute the logic below to set the bgImageView etc. Probably then best to just pass this
//array of bg objects to the BacklightViewController so it can do the exact same thing.
#pragma mark BackgroundsViewControllerDelegate methods
- (void)backgroundSelected:(Background *)background
{
    //NSLog(@"got background selected event");
    if(![bgarray containsObject:background])
    {
        [bgarray addObject:background];
    }
}

- (void)backgroundDeSelected:(Background *)background
{
    //NSLog(@"got background deselected event");
    [bgarray removeObject:background];
}

#pragma mark background setter
- (void)displayBackground:(Background *)background
{
    if([background.isImage  isEqual: @NO])
    {
        self.theColor = [self convertStringToUIColor:background.bColor];
        self.bgImageView.backgroundColor = theColor;
        [self.bgImageView setImage:nil];
        self.bgImageURL = nil;
    }
    else
    {
        //put code here to set an ImageView.image equal to image passed in background object
        NSURL *imageUrl = [NSURL URLWithString:background.bFullSizeUrl];
        UIImage *placeholder = [UIImage imageNamed:@"thumbnail-default.png"];
        [self.bgImageView setImageWithURL:imageUrl
                         placeholderImage:placeholder];
        self.bgImageURL = imageUrl;
        self.bgImageView.backgroundColor = [UIColor whiteColor];
    }
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
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark TimerViewControllerDelegate

- (void)timerViewControllerDidFinish:(NSInteger)timeValue timerString:(NSString*)string
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.timeOut = timeValue;
    self.timerLabel.text = string;
    if([string isEqualToString:NSLocalizedString(@"OFF",nil)])
    {
        self.minutesLabel.hidden = YES;
    }
    else
    {
        self.minutesLabel.hidden = NO;
    }
}

#pragma mark - Utility Functions
- (UIColor*)convertStringToUIColor:(NSString*)colorString
{
    UIColor* finalColor = [UIColor whiteColor];
    
    if([colorString isEqualToString:@"whiteColor"]) finalColor = [UIColor whiteColor];
    if([colorString isEqualToString:@"blueColor"]) finalColor =  [UIColor blueColor];
    if([colorString isEqualToString:@"redColor"]) finalColor = [UIColor redColor];
    if([colorString isEqualToString:@"greenColor"]) finalColor = [UIColor greenColor];
    if([colorString isEqualToString:@"blackColor"]) finalColor = [UIColor blackColor];
    if([colorString isEqualToString:@"darkGrayColor"]) finalColor = [UIColor darkGrayColor];
    if([colorString isEqualToString:@"lightGrayColor"]) finalColor = [UIColor lightGrayColor];
    if([colorString isEqualToString:@"grayColor"]) finalColor = [UIColor grayColor];
    if([colorString isEqualToString:@"cyanColor"]) finalColor = [UIColor cyanColor];
    if([colorString isEqualToString:@"yellowColor"]) finalColor = [UIColor yellowColor];
    if([colorString isEqualToString:@"magentaColor"]) finalColor = [UIColor magentaColor];
    if([colorString isEqualToString:@"orangeColor"]) finalColor = [UIColor orangeColor];
    if([colorString isEqualToString:@"purpleColor"]) finalColor = [UIColor purpleColor];
    if([colorString isEqualToString:@"brownColor"]) finalColor = [UIColor brownColor];
    if([colorString isEqualToString:@"clearColor"]) finalColor = [UIColor clearColor];
    
    return finalColor;
}

@end
