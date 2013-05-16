//
//  MenuViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 3/10/13.
//
//

#import "MenuViewController.h"
#import "ECSlidingViewController.h"
#import "iSleepAppDelegate.h"

#define IMAGEVIEW_TAG 5
#define LABELVIEW_TAG 6

@interface MenuViewController ()

@property (strong, nonatomic) NSArray *mainMenu;
@property (strong, nonatomic) NSArray *toolsMenu;
@property (strong, nonatomic) NSArray *mainMenuIcons;
@property (strong, nonatomic) NSArray *toolsMenuIcons;

@end

@implementation MenuViewController

@synthesize mainMenu, toolsMenu, mainMenuIcons, toolsMenuIcons;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mainMenu = [NSArray arrayWithObjects:@"Main", @"Sounds", @"Backgrounds", nil];
    self.toolsMenu = [NSArray arrayWithObjects:@"Information", @"Settings", @"Rate This App",nil];
    self.mainMenuIcons = [NSArray arrayWithObjects:@"home-2.png", @"Speaker-1.png",  @"Picture-Landscape.png",nil];
    self.toolsMenuIcons = [NSArray arrayWithObjects:@"Info.png", @"Settings.png",  @"Fav-1.png", nil];
    
    [self.slidingViewController setAnchorRightRevealAmount:250.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    self.tableView.backgroundColor = [UIColor darkGrayColor];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.tableView setScrollEnabled:FALSE];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(section == 0)
    {
    return [self.mainMenu count];
    } else {
        return [self.toolsMenu count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"pCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UIImageView* imageView = (UIImageView *)[cell viewWithTag:IMAGEVIEW_TAG];
    UILabel* labelView = (UILabel *)[cell viewWithTag:LABELVIEW_TAG];
    
    if(indexPath.section == 0)
    {
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [self.mainMenuIcons objectAtIndex:indexPath.row]]];
        labelView.text = [NSString stringWithFormat:@"%@", [self.mainMenu objectAtIndex:indexPath.row]];
    } else{
        if(indexPath.row == 0)
        {
            CGRect frame = imageView.frame;
            frame.origin.x = 12;
            frame.origin.y = 12;
            frame.size.width = 5;
            frame.size.height = 20;
            imageView.frame = frame;
        }
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [self.toolsMenuIcons objectAtIndex:indexPath.row]]];
        labelView.text = [NSString stringWithFormat:@"%@", [self.toolsMenu objectAtIndex:indexPath.row]];
    }
    labelView.font = [UIFont fontWithName:@"Verdana-Bold" size:18];
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* hView = nil;
    hView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 305, 32)];
    [hView setBackgroundColor:[UIColor lightGrayColor]];
    
    if(section == 1)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 6, 305, 21)];
        [label setText:@"Tools"];
        [label setFont:[UIFont fontWithName:@"Verdana-Bold" size:15]];
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor lightGrayColor];
        [hView addSubview:label];
    }
    
    return hView;
}

/*
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView* fView = nil;
    fView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 305, 32)];
    [fView setBackgroundColor:[UIColor darkGrayColor]];
    
    if(section == 1)
    {
        UIImageView* theImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"kmoon.png"]];
        [theImageView setFrame:CGRectMake(50, 50, 50, 50)];
        [fView addSubview:theImageView];
    }
    
    return fView;
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 1)
    {
    return 32;
    } else{
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    //if(section == 1)
   // {
     //   return 132;
   // } else{
        return 0;
   // }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *newTopViewController = nil;
    
    if(indexPath.section == 0)
    {
        switch (indexPath.row) {
            case 0:
                newTopViewController = (UIViewController*)[iSleepAppDelegate appDelegate].mainViewController;
                break;
            case 1:
                newTopViewController = (UIViewController*)[iSleepAppDelegate appDelegate].soundsViewController;
                break;
            case 2:
                newTopViewController = (UIViewController*)[iSleepAppDelegate appDelegate].backgroundsViewController;
                break;
            default:
                break;
        }
    } else{
        switch (indexPath.row) {
            case 0:
                newTopViewController = (UIViewController*)[iSleepAppDelegate appDelegate].informationViewController;
                break;
            case 1:
                newTopViewController = (UIViewController*)[iSleepAppDelegate appDelegate].settingsViewController;
                break;
            case 2:
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=417667154"]];
                break;
            default:
                break;
        }
    }
    
    if(newTopViewController != nil)
    {
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    }
}

@end
