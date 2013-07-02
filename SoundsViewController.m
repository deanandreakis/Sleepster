//
//  SoundsViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//
//

#import "SoundsViewController.h"
#import "Constants.h"

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
    /*
	UILabel *col2_label1 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label1.text = @"Campfire";
	col2_label1.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	//col1_label1.adjustsFontSizeToFitWidth = YES;
	col2_label1.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label2 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label2.text = @"Rain";
	col2_label2.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label2.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label3 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label3.text = @"Forest";
	col2_label3.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label3.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label4 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label4.text = @"Stream";
	col2_label4.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label4.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label5 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label5.text = @"Waterfall";
	col2_label5.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label5.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label6 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label6.text = @"Waves";
	col2_label6.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label6.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label7 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label7.text = @"Wind";
	col2_label7.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label7.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label8 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label8.text = @"Heavy Rain";
	col2_label8.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label8.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label9 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label9.text = @"Lake Waves";
	col2_label9.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label9.backgroundColor = [UIColor clearColor];
    
    UILabel *col2_label10 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label10.text = @"Thunder";
	col2_label10.font = [UIFont fontWithName:@"Verdana-Bold" size:17];
	col2_label10.backgroundColor = [UIColor clearColor];
	
	NSArray *musicSelectionArray = [[NSArray alloc] initWithObjects:col2_label1,col2_label2,
                                    col2_label3,col2_label4,col2_label5,col2_label6,col2_label7,col2_label8,col2_label9,
                                    col2_label10,nil];
	self.musicSelectionTypes = musicSelectionArray;
     */
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [songArray count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SoundCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor blueColor];
    return cell;
}



#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate songSelected:[songArray objectAtIndex:indexPath.item]];//tell the delegate we selected a song
    NSLog(@"selected index %d", indexPath.item);
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
}

@end
