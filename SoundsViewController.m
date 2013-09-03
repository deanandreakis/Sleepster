//
//  SoundsViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//
//

#import "SoundsViewController.h"
#import "Constants.h"

#define SELECTED_IMAGE_TAG 99

@interface SoundsViewController ()
@property(strong, nonatomic) NSArray* songArray;
@property(strong, nonatomic) NSArray* musicSelectionArray;
@property (strong, nonatomic) UIButton *menuBtn;
@end

@implementation SoundsViewController

@synthesize songArray, musicSelectionArray;
@synthesize menuBtn;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
	UILabel *col2_label1 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label1.text = @"Campfire";
	col2_label1.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	//col1_label1.adjustsFontSizeToFitWidth = YES;
	col2_label1.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label2 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label2.text = @"Rain";
	col2_label2.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label2.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label3 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label3.text = @"Forest";
	col2_label3.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label3.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label4 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label4.text = @"Stream";
	col2_label4.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label4.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label5 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label5.text = @"Waterfall";
	col2_label5.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label5.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label6 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label6.text = @"Waves";
	col2_label6.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label6.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label7 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label7.text = @"Wind";
	col2_label7.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label7.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label8 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label8.text = @"Heavy Rain";
	col2_label8.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label8.backgroundColor = [UIColor clearColor];
	
	UILabel *col2_label9 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label9.text = @"Lake Waves";
	col2_label9.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label9.backgroundColor = [UIColor clearColor];
    
    UILabel *col2_label10 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,90,20)];
	col2_label10.text = @"Thunder";
	col2_label10.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	col2_label10.backgroundColor = [UIColor clearColor];
	
	musicSelectionArray = [[NSArray alloc] initWithObjects:col2_label1,col2_label2,
                                    col2_label3,col2_label4,col2_label5,col2_label6,col2_label7,col2_label8,col2_label9,
                                    col2_label10,nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [songArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UILabel* tempLabel =  (UILabel*)[musicSelectionArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = tempLabel.text;
    cell.textLabel.font = tempLabel.font;
    cell.textLabel.backgroundColor = tempLabel.backgroundColor;
    
    return cell;
}



#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate songSelected:[songArray objectAtIndex:indexPath.item]];//tell the delegate we selected a song
    NSLog(@"selected index %d", indexPath.row);
    
    UITableViewCell *cell =[tableView cellForRowAtIndexPath:indexPath];
    NSString *pathToSelectedImage = [[NSBundle mainBundle] pathForResource:@"check_mark_green" ofType:@"png"];
    UIImage* selectedImage = [[UIImage alloc] initWithContentsOfFile:pathToSelectedImage];
    UIImageView* selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
    selectedImageView.frame = CGRectMake(0, 0, 20, 20);
    selectedImageView.tag = SELECTED_IMAGE_TAG;
    cell.accessoryView = selectedImageView;
    //[cell.accessoryView addSubview:selectedImageView];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"deselected index %d", indexPath.row);
    
    UITableViewCell *cell =[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryView = nil;
    /*for(UIView *subview in [cell.accessoryView subviews]) {
        if(subview.tag == SELECTED_IMAGE_TAG)
        {
            [subview removeFromSuperview];
        }
    }*/
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 50;
}

@end
