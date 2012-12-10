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


@implementation MainViewController

@synthesize timeOut;
@synthesize songIndex;
@synthesize natureVolume;
@synthesize picker;
@synthesize musicSelectionTypes;
@synthesize musicTimerTypes;
@synthesize nightLightColorTypes;
@synthesize song;
@synthesize playerState;
@synthesize interruptedOnPlayback;
@synthesize timerFired;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}

- (IBAction)volumeSliderChanged:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	int volume = (int)(slider.value + 0.5f);
	natureVolume = (float)volume;
}

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

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	//NSLog (@"VIEW DID LOAD");
	
	BOOL hasHighResScreen = NO;
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		CGFloat scale = [[UIScreen mainScreen] scale];
		if (scale > 1.0) {
			hasHighResScreen = YES;
		}
	}
	
	UIColor *background;
	if (hasHighResScreen) {
		background = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"Default@2x.png"]];
	}
	else{
		background = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"Default.png"]];
    }
	self.view.backgroundColor = background;
	
	/*Setup battery state monitoring*/
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	
	/*Setup audio*/
	//Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];
	
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
	
	NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
	
	NSString *pathToMusicFile0 = [[NSBundle mainBundle] pathForResource:@"campfire" ofType:@"mp3"];
	NSString *pathToMusicFile1 = [[NSBundle mainBundle] pathForResource:@"rain" ofType:@"mp3"];
	NSString *pathToMusicFile2 = [[NSBundle mainBundle] pathForResource:@"forest" ofType:@"mp3"];
	NSString *pathToMusicFile3 = [[NSBundle mainBundle] pathForResource:@"stream" ofType:@"mp3"];
	NSString *pathToMusicFile4 = [[NSBundle mainBundle] pathForResource:@"waterfall" ofType:@"mp3"];
	NSString *pathToMusicFile5 = [[NSBundle mainBundle] pathForResource:@"waves" ofType:@"mp3"];
	NSString *pathToMusicFile6 = [[NSBundle mainBundle] pathForResource:@"wind" ofType:@"mp3"];
	NSString *pathToMusicFile7 = [[NSBundle mainBundle] pathForResource:@"heavy-rain" ofType:@"mp3"];
	NSString *pathToMusicFile8 = [[NSBundle mainBundle] pathForResource:@"lake-waves" ofType:@"mp3"];
    NSString *pathToMusicFile9 = [[NSBundle mainBundle] pathForResource:@"ThunderStorm" ofType:@"mp3"];
	
	AVAudioPlayer* song0 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile0] error:NULL];
	AVAudioPlayer* song1 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile1] error:NULL];
	AVAudioPlayer* song2 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile2] error:NULL];
	AVAudioPlayer* song3 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile3] error:NULL];
	AVAudioPlayer* song4 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile4] error:NULL];
	AVAudioPlayer* song5 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile5] error:NULL];
	AVAudioPlayer* song6 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile6] error:NULL];
	AVAudioPlayer* song7 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile7] error:NULL];
	AVAudioPlayer* song8 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile8] error:NULL];
    AVAudioPlayer* song9 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile9] error:NULL];
	
	NSArray* songArray = [[NSArray alloc] initWithObjects:song0,song1,song2,song3,song4,
						  song5,song6,song7,song8,song9,nil];
	
	self.song = songArray;
	
	
	for (int x = 0; x < 10; x++) {
		[[song objectAtIndex:x] setNumberOfLoops:-1];
		[[song objectAtIndex:x] prepareToPlay];
		[[song objectAtIndex:x] setDelegate:self];
	}
	
	self.song;
	
	UILabel *col1_label1 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label1.text = @"\u221E";
	col1_label1.font = [UIFont fontWithName:@"Marker Felt" size:32];
	col1_label1.backgroundColor = [UIColor clearColor];
        
    UILabel *col1_label2 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label2.text = @"15";
	col1_label2.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col1_label2.backgroundColor = [UIColor clearColor];
	
	UILabel *col1_label3 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label3.text = @"30";
	col1_label3.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col1_label3.backgroundColor = [UIColor clearColor];
	
	UILabel *col1_label4 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label4.text = @"60";
	col1_label4.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col1_label4.backgroundColor = [UIColor clearColor];
	
	UILabel *col1_label5 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
	col1_label5.text = @"90";
	col1_label5.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col1_label5.backgroundColor = [UIColor clearColor];
	
	NSArray *musicTimerArray = [[NSArray alloc] initWithObjects:col1_label1, col1_label2,
								col1_label3,col1_label4,col1_label5,nil];
	self.musicTimerTypes = musicTimerArray;

	
	/*Music Selection Array Objects*/
	UILabel *col2_label1 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label1.text = @"Campfire";
	col2_label1.font = [UIFont fontWithName:@"Marker Felt" size:17];
	//col1_label1.adjustsFontSizeToFitWidth = YES;
	col2_label1.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label2 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label2.text = @"Rain";
	col2_label2.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label2.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label3 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label3.text = @"Forest";
	col2_label3.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label3.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label4 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label4.text = @"Stream";
	col2_label4.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label4.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label5 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label5.text = @"Waterfall";
	col2_label5.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label5.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label6 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label6.text = @"Waves";
	col2_label6.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label6.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label7 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label7.text = @"Wind";
	col2_label7.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label7.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label8 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label8.text = @"Heavy Rain";
	col2_label8.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label8.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label9 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label9.text = @"Lake Waves";
	col2_label9.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label9.backgroundColor = [UIColor clearColor];
    
    UILabel *col2_label10 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label10.text = @"Thunder";
	col2_label10.font = [UIFont fontWithName:@"Marker Felt" size:17];
	col2_label10.backgroundColor = [UIColor clearColor];
	
	NSArray *musicSelectionArray = [[NSArray alloc] initWithObjects:col2_label1,col2_label2,
								col2_label3,col2_label4,col2_label5,col2_label6,col2_label7,col2_label8,col2_label9,
                                    col2_label10,nil];
	self.musicSelectionTypes = musicSelectionArray;
	
	/*nightLightColorArray Objects*/
	UILabel *col3_label1 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label1.text = @"";
	col3_label1.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label1.backgroundColor = [UIColor whiteColor];
	
	UILabel *col3_label2 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label2.text = @"";
	col3_label2.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label2.backgroundColor = [UIColor blueColor];
	
	UILabel *col3_label3 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label3.text = @"";
	col3_label3.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label3.backgroundColor = [UIColor redColor];
	
	UILabel *col3_label4 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label4.text = @"";
	col3_label4.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label4.backgroundColor = [UIColor greenColor];
	
	UILabel *col3_label5 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label5.text = @"";
	col3_label5.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label5.backgroundColor = [UIColor blackColor];
	
	UILabel *col3_label6 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label6.text = @"";
	col3_label6.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label6.backgroundColor = [UIColor darkGrayColor];
	
	UILabel *col3_label7 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label7.text = @"";
	col3_label7.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label7.backgroundColor = [UIColor lightGrayColor];
	
	UILabel *col3_label8 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label8.text = @"";
	col3_label8.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label8.backgroundColor = [UIColor grayColor];
	
	UILabel *col3_label9 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label9.text = @"";
	col3_label9.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label9.backgroundColor = [UIColor cyanColor];
	
	UILabel *col3_label10 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label10.text = @"";
	col3_label10.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label10.backgroundColor = [UIColor yellowColor];
	
	UILabel *col3_label11 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label11.text = @"";
	col3_label11.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label11.backgroundColor = [UIColor magentaColor];
	
	UILabel *col3_label12 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label12.text = @"";
	col3_label12.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label12.backgroundColor = [UIColor orangeColor];
	
	UILabel *col3_label13 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label13.text = @"";
	col3_label13.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label13.backgroundColor = [UIColor purpleColor];
	
	UILabel *col3_label14 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label14.text = @"";
	col3_label14.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label14.backgroundColor = [UIColor brownColor];
	
	UILabel *col3_label15 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col3_label15.text = @"";
	col3_label15.font = [UIFont fontWithName:@"Marker Felt" size:14];
	col3_label15.backgroundColor = [UIColor clearColor];
	
	NSArray *nightLightColorArray = [[NSArray alloc] initWithObjects:col3_label1,col3_label2,
									 col3_label3,col3_label4,col3_label5,col3_label6,col3_label7,
									 col3_label8,col3_label9,col3_label10,col3_label11,col3_label12,
									 col3_label13,col3_label14,col3_label15,nil];
	self.nightLightColorTypes = nightLightColorArray;
	
	playerState = NO;
	
	interruptedOnPlayback = NO;
	
	natureVolume = 50.0;
	
	songIndex = 0;
	
	[super viewDidLoad];
}



- (void)flipsideViewControllerDidFinish:(InformationViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}

- (void)backlightViewControllerDidFinish:(BacklightViewController *)controller {	
	//NSLog (@"backlight view controller finished");
	if([[song objectAtIndex:songIndex] isPlaying] && !timerFired)
	{
		//NSLog (@" backlight view controller stop the song at index: %i", songIndex);
        [self dismissModalViewControllerAnimated:YES];
        [[song objectAtIndex:songIndex] pause];
        [[song objectAtIndex:songIndex] setCurrentTime:0];
	    if(timeOut != kOffSegmentIndex)
        {
            [timer invalidate];
        }
	    playerState = NO;
	}
    else if(![[song objectAtIndex:songIndex] isPlaying] && timerFired)
	{
        [self dismissModalViewControllerAnimated:YES];
	}
}

- (IBAction)showInfo {    
	
	/*FlipsideViewController *fsController = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	fsController.delegate = self;
	
	fsController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:fsController animated:YES];*/
	
}



- (IBAction) startSleeping {
	
	//NSLog (@"Start Sleeping Play Button Selected");
	
	//check for battery state; if unplugged show an alert
	if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged) {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Plug In" 
							  message:@"Please Plug In to Avoid Draining the Battery"
							  delegate:nil
							  cancelButtonTitle:@"Continue" 
							  otherButtonTitles:nil];
		[alert show];
	}
	
	NSInteger segment = [picker selectedRowInComponent:kMusicTimer];
	NSInteger colorIndex = [picker selectedRowInComponent:kNightlightColor];
	songIndex = [picker selectedRowInComponent:kMusicSelection];
	
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
	
	switch (colorIndex) {
		case 0:
			controller.backgroundColor = [UIColor whiteColor];
			break;
		case 1:
			controller.backgroundColor = [UIColor blueColor];
			break;
		case 2:
			controller.backgroundColor = [UIColor redColor];
			break;
		case 3:
			controller.backgroundColor = [UIColor greenColor];
			break;
		case 4:
			controller.backgroundColor = [UIColor blackColor];
			break;
		case 5:
			controller.backgroundColor = [UIColor darkGrayColor];
			break;
		case 6:
			controller.backgroundColor = [UIColor lightGrayColor];
			break;
		case 7:
			controller.backgroundColor = [UIColor grayColor];
			break;
		case 8:
			controller.backgroundColor = [UIColor cyanColor];
			break;
		case 9:
			controller.backgroundColor = [UIColor yellowColor];
			break;
		case 10:
			controller.backgroundColor = [UIColor magentaColor];
			break;
		case 11:
			controller.backgroundColor = [UIColor orangeColor];
			break;
		case 12:
			controller.backgroundColor = [UIColor purpleColor];
			break;
		case 13:
			controller.backgroundColor = [UIColor brownColor];
			break;
		case 14:
			controller.backgroundColor = [UIColor clearColor];
			break;
		default:
			break;
	}
	
	/*Play the background music selected*/
	//NSLog (@"PLAY: SONG INDEX = %i", songIndex);
	AVAudioPlayer * player = (AVAudioPlayer *)[song objectAtIndex:songIndex];
    [player setVolume:(natureVolume / 100)];
	[player play];
	//NSLog (@"PLAY RETURNED %i", retVal);
	playerState = YES;
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:controller animated:YES];
}
	
- (void) timerFired: (NSTimer *) theTimer
{
	/*resolved crash where timer fired and then user hits backlight view
	  and then the call to [timer invalidate] crashed the system*/

	timerFired = YES;
    [[song objectAtIndex:songIndex] stopWithFadeDuration:fadeoutTime];
	//[[song objectAtIndex:songIndex] pause];
	//[[song objectAtIndex:songIndex] setCurrentTime:0];
	playerState = NO;
}



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	//NSLog (@"MEMORY WARNING RECEIVED");
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}



#pragma mark -
#pragma mark Picker Data Source Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger retVal = 0;
	
	switch (component) {
		case kMusicSelection:
			retVal = [self.musicSelectionTypes count];
			break;
		case kMusicTimer:
			retVal = [self.musicTimerTypes count];
			break;
		case kNightlightColor:
			retVal = [self.nightLightColorTypes count];
			break;
		default:
			break;
	}
	return retVal;
}

#pragma mark Picker Delegate Methods
- (UIView *)pickerView:(UIPickerView *)pickerView 
    viewForRow:(NSInteger)row 
    forComponent:(NSInteger)component 
    reusingView:(UIView *)view
{
 if(component == kMusicSelection)
     return [self.musicSelectionTypes objectAtIndex:row];
 else if(component == kMusicTimer)
     return [self.musicTimerTypes objectAtIndex:row];
 else
     return [self.nightLightColorTypes objectAtIndex:row];
}

#pragma mark AVAudioPlayer delegate methods
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
	
    //NSLog (@"Interrupted. The system has paused audio playback.");
    
    if (playerState) {
		
        playerState = NO;
        interruptedOnPlayback = YES;
    }
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
	
	//NSLog (@"Interruption ended. Resuming audio playback.");
    
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

@end
