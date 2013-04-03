//
//  SoundsViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//
//

#import "SoundsViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@interface SoundsViewController ()

@property(strong, nonatomic) NSArray* songArray;
@property (strong, nonatomic) UIButton *menuBtn;

@end

@implementation SoundsViewController

@synthesize songArray;
@synthesize menuBtn;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    [self.view addSubview:self.menuBtn];//stopped at 2:11 of iOS Slide Menu Tutorial - Part 3
    
    
    // Do any additional setup after loading the view from its nib.
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"SoundCell"];
    
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
	
	songArray = [[NSArray alloc] initWithObjects:song0,song1,song2,song3,song4,
						  song5,song6,song7,song8,song9,nil];
	
	
	
	for (int x = 0; x < 10; x++) {
		[[songArray objectAtIndex:x] setNumberOfLoops:-1];
		[[songArray objectAtIndex:x] prepareToPlay];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    //NSString *searchTerm = self.searches[section];
    //return [self.searchResults[searchTerm] count];
    return [songArray count];
}

// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    //return [self.searches count];
    return 1;
}

// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SoundCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor blueColor];
    return cell;
}

// 4
/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Select Item
    [self.delegate songSelected:[songArray objectAtIndex:indexPath.item]];//tell the delegate we selected a song
    NSLog(@"selected index %d", indexPath.item);
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

@end
