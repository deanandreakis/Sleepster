//
//  BackgroundsViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//
//

#import "BackgroundsViewController.h"
#import "Constants.h"
#import "Background.h"

@interface BackgroundsViewController ()
@property (strong, nonatomic) NSArray *colorArray;
@property (strong, nonatomic) UIButton *menuBtn;
@property (nonatomic, strong) NSArray *backgrounds;
@end

@implementation BackgroundsViewController
@synthesize menuBtn, colorArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"BackgroundCell"];
    
    colorArray = [[NSArray alloc] initWithObjects:[UIColor whiteColor],
                  [UIColor blueColor], [UIColor redColor],[UIColor greenColor],
                  [UIColor blackColor],[UIColor darkGrayColor],
                  [UIColor lightGrayColor],[UIColor grayColor],
                  [UIColor cyanColor],[UIColor yellowColor],
                  [UIColor magentaColor],[UIColor orangeColor],
                  [UIColor purpleColor],[UIColor brownColor],
                  [UIColor clearColor],nil];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    /* Fetch Flickr Photos */
    [Background fetchPics:^(NSArray *backgrounds) {
        self.backgrounds = backgrounds;
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [colorArray count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"BackgroundCell" forIndexPath:indexPath];
    cell.backgroundColor = [colorArray objectAtIndex:indexPath.item];
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate backgroundSelected:[colorArray objectAtIndex:indexPath.item]];//tell the delegate we selected a background
    NSLog(@"selected index %d", indexPath.item);
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
}

@end
