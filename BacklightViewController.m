//
//  BacklightViewController.m
//  iSleep
//
//  Created by Dean Andreakis on 6/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BacklightViewController.h"
#import "UIImageView+AFNetworking.h"
#import <Crashlytics/Crashlytics.h>

@interface BacklightViewController ()

@property(assign, nonatomic) int bgTimerCounter;
@property (strong, nonatomic) NSTimer* bgTimer;

@end

@implementation BacklightViewController

@synthesize bgDelegate;
@synthesize backgroundColor, brightness, bgImageView, bgImageURL, bgTimerCounter, bgTimer;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bgImageView.backgroundColor = backgroundColor;
    [self.bgImageView setImage:nil];
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
    NSURL* imageUrl = (NSURL*)bgImageURL[bgTimerCounter];
    if([imageUrl isFileReferenceURL] || [imageUrl isFileURL]){
        NSData *bgImageData = [NSData dataWithContentsOfURL:imageUrl];
        UIImage *img = [UIImage imageWithData:bgImageData];
        [self.bgImageView setImage:img];
    } else{
        UIImage *placeholder = [UIImage imageNamed:@"thumbnail-default.png"];
        [self.bgImageView setImageWithURL:imageUrl
                             placeholderImage:placeholder];
    }
}


- (IBAction)done:(id)sender {
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




@end
