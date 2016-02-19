//
//  BacklightViewController.m
//  iSleep
//
//  Created by Dean Andreakis on 6/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BacklightViewController.h"
#import "UIImageView+AFNetworking.h"
#import "Background.h"
//#import <Crashlytics/Crashlytics.h>

@interface BacklightViewController ()

@property(assign, nonatomic) int bgTimerCounter;
@property (strong, nonatomic) NSTimer* bgTimer;
@property (strong, nonatomic) IBOutlet UIButton* btn;
@end

@implementation BacklightViewController

@synthesize bgDelegate, btn;
@synthesize backgroundColor, brightness, bgImageView, bgImageURL, bgTimerCounter, bgTimer, isPresented;

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.view.backgroundColor = [UIColor blackColor];
    isPresented = true;
    self.bgImageView.backgroundColor = backgroundColor;
    [self.bgImageView setImage:nil];
    
    self.bgImageView.frame = [UIScreen mainScreen].bounds;
    self.btn.frame = [UIScreen mainScreen].bounds;;
    
    [[UIScreen mainScreen] setBrightness:brightness];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelDidChange:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    bgTimerCounter = 0;
    if([bgImageURL count] > 0)
    {
        [self bgTimerFired:nil];
        //start a timer and rotate thru Background objects
        bgTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                   target: self
                                                 selector: @selector(bgTimerFired:)
                                                 userInfo: nil
                                                  repeats: YES];
    }
}

#pragma mark BG NSTimer Fired
- (void) bgTimerFired: (NSTimer *) theTimer
{
    [self displayBackground];
    if(bgTimerCounter < ([bgImageURL count] - 1))
    {
        bgTimerCounter++;
    } else {
        bgTimerCounter = 0;
    }
}

#pragma mark background setter
- (void)displayBackground
{
    Background* background = (Background*)bgImageURL[bgTimerCounter];
    if([background.isImage  isEqual: @NO])
    {
        self.backgroundColor = [self convertStringToUIColor:background.bColor];
        [self.bgImageView setImage:nil];
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
        
        self.bgImageView.backgroundColor = [UIColor whiteColor];
    }
}


- (IBAction)done:(id)sender {
    isPresented = false;
    [bgTimer invalidate];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.bgDelegate backlightViewControllerDidFinish:self];
}

-(void)batteryLevelDidChange:(NSNotification *)notification
{
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    if(batteryLevel <= 0.1f && [UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged)
    {
        [self done:nil];
    }
    //NSLog(@"BATTERY LEVEL CHANGED TO: %f", batteryLevel);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
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

#pragma mark state preservation and restoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
}

@end
