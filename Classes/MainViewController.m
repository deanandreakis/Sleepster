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
#import "DatabaseManager.h"

#define UNPLUGGEDGREATER20 90
#define UNPLUGGEDLESS20 91

@interface MainViewController ()


@property(strong, nonatomic) NSMutableArray* theSongArray;
@property(strong, nonatomic) UIColor* theColor;
@property (assign, nonatomic) float natureBrightness;
//@property (strong, nonatomic) TimerViewController* controller;
//@property (strong, nonatomic) IBOutlet UILabel* timerLabel;
//@property (strong, nonatomic) IBOutlet UILabel* minutesLabel;
//@property (strong, nonatomic) IBOutlet UIButton* timerButton;

@property (strong, nonatomic) IBOutlet UIImageView* bgImageView;
@property (strong,nonatomic) NSURL* bgImageURL;
@property (strong, nonatomic) NSMutableArray* bgarray;
@property (strong, nonatomic) NSTimer* bgTimer;
@property (assign, nonatomic) int bgTimerCounter;
@property (assign, nonatomic) BOOL isBgInit;//indicates that the bg item has been pulled from the db and put into the array
@property (assign, nonatomic) BOOL isSoundInit;
@property (assign, nonatomic) BOOL isBgOrig;//indicates that the bg item in the array is the default one
@property (assign, nonatomic) BOOL isSoundOrig;
@property (strong, nonatomic) IBOutlet UISlider* volumeSlider;
@property (strong, nonatomic) IBOutlet UISlider* brightnessSlider;
@property (strong, nonatomic) IBOutlet UIImageView* volumeImageView;
@property (strong, nonatomic) IBOutlet UIImageView* brightnessImageView;
@end

@implementation MainViewController

@synthesize timeOut, bgImageURL, bgarray, bgTimer, bgTimerCounter,volumeImageView, brightnessImageView;
@synthesize natureVolume, natureBrightness;
@synthesize playerState;
@synthesize interruptedOnPlayback;
@synthesize timerFired;
@synthesize menuBtn;
@synthesize theSongArray, isBgInit, isSoundInit, isBgOrig, isSoundOrig;
@synthesize theColor, bgImageView, volumeSlider, brightnessSlider;

#pragma mark Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    //NSLog(@"INIT");
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        theColor = [UIColor whiteColor];
        isSoundInit = FALSE;
        isBgInit = FALSE;
        isSoundOrig = FALSE;
        isBgOrig = FALSE;
    }
    return self;
}

#pragma mark -
#pragma mark View Cycle


- (void)viewDidLoad {
    //NSLog(@"viewDidLoad");
	self.bgImageView.backgroundColor = theColor;
    self.view.backgroundColor = [UIColor whiteColor];
	
	/*Setup battery state monitoring*/
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	
	/*Setup audio*/
	//Registers this class as the delegate of the audio session.
    //[[AVAudioSession sharedInstance] setDelegate: self];
	
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
	
	NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
	
	playerState = NO;
	
	interruptedOnPlayback = NO;
	
    timeOut = kOffSegmentIndex;
    //timerLabel.text = @"OFF";
    //self.minutesLabel.hidden = YES;
    
	natureVolume = 50.0;
    natureBrightness = [[UIScreen mainScreen] brightness];//0.5;
    
    //self.brightnessSlider.value = 50.0;
    
    //controller = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];
	//controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //controller.restorationIdentifier = RESTORATION_ID_TIMER_VC;
    
    bgarray = [[NSMutableArray alloc] initWithCapacity:5];
    theSongArray = [[NSMutableArray alloc] initWithCapacity:5];
    
    
    if ([[UIScreen mainScreen] bounds].size.height == 568){
        //add your 4-inch specific code here
        volumeSlider.frame = CGRectMake(18, 406, 260, 34);
        volumeImageView.frame = CGRectMake(284, 410, 20, 20);
        brightnessSlider.frame = CGRectMake(18, 463, 260, 34);
        brightnessImageView.frame = CGRectMake(284, 467, 20, 20);
        
        //minutesLabel.frame = CGRectMake(166, 369, 63, 21);
        //timerLabel.frame = CGRectMake(145, 369, 47, 21);
        //timerButton.frame = CGRectMake(138, 330, 44, 44);
        
        bgImageView.frame = CGRectMake(10, 20, 300, 300);

    } else {
        volumeSlider.frame = CGRectMake(18, 353, 260, 34);
        volumeImageView.frame = CGRectMake(284, 357, 20, 20);
        brightnessSlider.frame = CGRectMake(18, 390, 260, 34);
        brightnessImageView.frame = CGRectMake(284, 394, 20, 20);
        
        //minutesLabel.frame = CGRectMake(166, 325, 63, 21);
        //timerLabel.frame = CGRectMake(145, 325, 47, 21);
        //timerButton.frame = CGRectMake(138, 286, 44, 44);
        
        bgImageView.frame = CGRectMake(25, 20, 270, 270);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveTimerNotification:)
                                                 name:@"TIMER_NOTIFICATION"
                                               object:nil];
     
    
	[super viewDidLoad];
}

- (void)viewDidUnload {
}

//moved all this stuff here because it executes after the state restoration decode
- (void)viewDidAppear:(BOOL)animated {
    //NSLog(@"viewDidAppear");
    if (!isBgInit) {
        //go pull the bg object out of database and put in bgarray
        NSError *error;
        NSManagedObjectContext *context = [[DatabaseManager sharedDatabaseManager] managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Background"
                                                  inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"isLocalImage" ascending:NO];
        NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"isImage" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2,nil];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        //NSLog(@"NUM OBJECTS: %d",[fetchedObjects count]);
        for (Background* bg in fetchedObjects) {
            if([bg.isImage isEqual:@YES]){
                if([bg.isLocalImage isEqual:@YES]){
                    [bgarray addObject:bg];
                    [[iSleepAppDelegate appDelegate].backgroundsViewController setSelected:bg];
                    break;
                }
            }
        }
        //[bgarray addObject:fetchedObjects[0]];
        
        isBgInit = TRUE;
        isBgOrig = TRUE;
    }
    
    if (!isSoundInit) {
        //put sound object in sound array
        NSString *pathToMusicFile3 = [[NSBundle mainBundle] pathForResource:@"stream" ofType:@"mp3"];
        AVAudioPlayer* song3 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile3] error:NULL];
        [song3 setNumberOfLoops:-1];
		[song3 prepareToPlay];
        [theSongArray addObject:song3];
        [song3 setDelegate:self];
        [[iSleepAppDelegate appDelegate].soundsViewController setSelected:3];
        isSoundInit = TRUE;
        isSoundOrig = TRUE;
    }
    
    bgTimerCounter = 0;
    [self.bgImageView setImage:nil];//displays the bg image
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

-(void)viewWillAppear:(BOOL)animated
{
    //NSLog(@"viewWillAppear");
}

-(void)viewWillDisappear:(BOOL)animated
{
    [bgTimer invalidate];
}

#pragma mark state preservation and restoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:self.timeOut forKey:@"timeOut"];//NSInteger timeOut;
	//[coder encodeObject:self.timerLabel.text forKey:@"timerLabel"];
    
    [coder encodeFloat:self.natureVolume forKey:@"natureVolume"];//float natureVolume;
    
    //for a containing VC we just need to call encode on it to trigger
    //its encode/decode calls, so we dont need to decode it here
    //[coder encodeObject:controller forKey:@"TimerViewController"];
	
    /*NSMutableArray* songURLArray = [[NSMutableArray alloc] initWithCapacity:5];
    for (AVAudioPlayer* song in theSongArray) {
        NSURL* songURL = song.url;
        [songURLArray addObject:songURL];
    }
    [coder encodeObject:songURLArray forKey:@"songURLArray"];*/
    
    [coder encodeObject:self.theColor forKey:@"theColor"];//UIColor* theColor;
    [coder encodeFloat:self.natureBrightness forKey:@"natureBrightness"];//float natureBrightness;
    
    /*NSMutableArray* bgURLArray = [[NSMutableArray alloc] initWithCapacity:5];
    for (Background* bg in self.bgarray) {
        NSURL *moURI = [[bg objectID] URIRepresentation];
        [bgURLArray addObject:moURI];
    }
    [coder encodeObject:bgURLArray forKey:@"bgURLArray"];*/
    
    [coder encodeBool:self.isBgInit forKey:@"isBgInit"];//BOOL isBgInit;
    [coder encodeBool:self.isSoundInit forKey:@"isSoundInit"];//BOOL isSoundInit;
    [coder encodeBool:self.isBgOrig forKey:@"isBgOrig"];//BOOL isBgOrig;
    [coder encodeBool:self.isSoundOrig forKey:@"isSoundOrig"];//BOOL isSoundOrig;
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    //NSLog(@"DECODE");
    [super decodeRestorableStateWithCoder:coder];
    
    self.timeOut = [coder decodeIntegerForKey:@"timeOut"];//NSInteger timeOut;
	//self.timerLabel.text = [coder decodeObjectForKey:@"timerLabel"];
    /*if([self.timerLabel.text isEqualToString:NSLocalizedString(@"OFF",nil)])
    {
        self.minutesLabel.hidden = YES;
    }
    else
    {
        self.minutesLabel.hidden = NO;
    }*/
    
    self.natureVolume = [coder decodeFloatForKey:@"natureVolume"];
    [self.volumeSlider setValue:self.natureVolume/100.0 animated:NO];
	
    //don't save since the SoundsViewController will refill the array on restore
    /*NSMutableArray* songURLArray = [[NSMutableArray alloc] initWithCapacity:5];
    songURLArray = [coder decodeObjectForKey:@"songURLArray"];
    [self.theSongArray removeAllObjects];
    for (NSURL* url in songURLArray) {
        AVAudioPlayer* song = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:NULL];
        [song setNumberOfLoops:-1];
		[song prepareToPlay];
        [self.theSongArray addObject:song];
        [song setDelegate:self];
    }*/
    
    self.theColor =  [coder decodeObjectForKey:@"theColor"];//UIColor* theColor;
    self.natureBrightness = [coder decodeFloatForKey:@"natureBrightness"];//float natureBrightness;
    [self.brightnessSlider setValue:self.natureBrightness animated:NO];
    [[UIScreen mainScreen] setBrightness:natureBrightness];
    
    /*NSMutableArray* bgURLArray = [[NSMutableArray alloc] initWithCapacity:5];
    bgURLArray = [coder decodeObjectForKey:@"bgURLArray"];
    [self.bgarray removeAllObjects];
    NSManagedObjectContext *context = [[DatabaseManager sharedDatabaseManager] managedObjectContext];
    for (NSURL* url in bgURLArray) {
        NSManagedObjectID* objectId = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
        [self.bgarray addObject:[context objectWithID:objectId]];
    }*/
    
    self.isBgInit = [coder decodeBoolForKey:@"isBgInit"];//BOOL isBgInit;
    self.isSoundInit = [coder decodeBoolForKey:@"isSoundInit"];//BOOL isSoundInit;
    self.isBgOrig = [coder decodeBoolForKey:@"isBgOrig"];//BOOL isBgOrig;
    self.isSoundOrig = [coder decodeBoolForKey:@"isSoundOrig"];//BOOL isSoundOrig;
}

#pragma mark basic methods
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) dealloc
{
    // If you don't remove yourself as an observer, the Notification Center
    // will continue to try and send notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    /*if(bgarray.count == 0)
    {
        blcontroller.backgroundColor = theColor;
    } else {
        blcontroller.backgroundColor = [UIColor whiteColor];
    }*/
    blcontroller.backgroundColor = theColor;
    blcontroller.brightness = natureBrightness;
    //blcontroller.restorationIdentifier = RESTORATION_ID_BACKLIGHT_VC;
    NSMutableArray* tempArray = [[NSMutableArray alloc] initWithCapacity:5];
    for (Background* bg in bgarray) {
        
        NSURL *url = nil;
        if([bg.isLocalImage isEqual:@NO]){
            url = [NSURL URLWithString:bg.bFullSizeUrl];
        } else {
            url = [[NSBundle mainBundle]
                        URLForResource:bg.bFullSizeUrl withExtension:@"jpg"];
        }
        
        if(url != nil) {
            [tempArray addObject:url];
        }
    }
    blcontroller.bgImageURL = tempArray;
	
    /*Play the background music selected*/
	for (AVAudioPlayer* song in theSongArray) {
        [song setVolume:(natureVolume / 100.0)];
        [song play];
    }
    
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
    if(isSoundOrig)
    {
        [theSongArray removeAllObjects];
        isSoundOrig = FALSE;
    }
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
    if(isBgOrig)
    {
        [bgarray removeAllObjects];
        isBgOrig = FALSE;
    }
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
        NSURL *imageUrl = nil;
        if([background.isLocalImage isEqual:@NO]){
            imageUrl = [NSURL URLWithString:background.bFullSizeUrl];
            UIImage *placeholder = [UIImage imageNamed:@"thumbnail-default.png"];
            [self.bgImageView setImageWithURL:imageUrl
                             placeholderImage:placeholder];
        } else {
            imageUrl = [[NSBundle mainBundle]
             URLForResource:background.bFullSizeUrl withExtension:@"jpg"];
            NSString *pathToImage = [[NSBundle mainBundle] pathForResource:background.bFullSizeUrl ofType:@"jpg"];
            UIImage* imageG = [[UIImage alloc] initWithContentsOfFile:pathToImage];
            [self.bgImageView setImage:imageG];
        }
        
        self.bgImageURL = imageUrl;
        self.bgImageView.backgroundColor = [UIColor whiteColor];
    }
}


#pragma mark Volume Slider

- (IBAction)volumeSliderChanged:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	//int volume = (int)(slider.value + 0.5f);
    natureVolume = slider.value * 100.0;//(float)volume;
}

#pragma mark Brightness Slider

- (IBAction)brightnessSliderChanged:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	natureBrightness = slider.value;
    [[UIScreen mainScreen] setBrightness:natureBrightness];
}


#pragma mark TimerViewControllerDelegate

- (void) receiveTimerNotification:(NSNotification *) notification
{
    //[self dismissViewControllerAnimated:YES completion:nil];
    
    NSNumber* value = (NSNumber*)[notification.userInfo objectForKey:@"timeout"];
    NSInteger timeValue = [value integerValue];
    
    //NSString* string = (NSString*)[notification.userInfo objectForKey:@"timerstring"];
    
    self.timeOut = timeValue;
    
    /*self.timerLabel.text = string;
    if([string isEqualToString:NSLocalizedString(@"OFF",nil)])
    {
        self.minutesLabel.hidden = YES;
    }
    else
    {
        self.minutesLabel.hidden = NO;
    }*/
}

#pragma mark SettingsViewControllerDelegate

- (void)settingsViewControllerBgSwitchedOff {
    [bgarray removeAllObjects];
    //go pull the bg object out of database and put in bgarray
    NSError *error;
    NSManagedObjectContext *context = [[DatabaseManager sharedDatabaseManager] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Background"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"isLocalImage" ascending:NO];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"isImage" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2,nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    //NSLog(@"NUM OBJECTS: %d",[fetchedObjects count]);
    for (Background* bg in fetchedObjects) {
        if([bg.isImage isEqual:@YES]){
            if([bg.isLocalImage isEqual:@YES]){
                [bgarray addObject:bg];
                break;
            }
        }
    }
    //[bgarray addObject:fetchedObjects[0]];
    
    isBgInit = TRUE;
    isBgOrig = TRUE;
}
- (void)settingsViewControllerSoundSwitchedOff {
    [theSongArray removeAllObjects];
    
    //put sound object in sound array
    NSString *pathToMusicFile3 = [[NSBundle mainBundle] pathForResource:@"stream" ofType:@"mp3"];
    AVAudioPlayer* song3 = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:pathToMusicFile3] error:NULL];
    [song3 setNumberOfLoops:-1];
    [song3 prepareToPlay];
    [theSongArray addObject:song3];
    [song3 setDelegate:self];
    isSoundInit = TRUE;
    isSoundOrig = TRUE;
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
