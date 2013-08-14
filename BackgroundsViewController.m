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
#import "DatabaseManager.h"
#import "UIImageView+AFNetworking.h"
#import "iSleepAppDelegate.h"
#import "SettingsViewController.h"

#define SELECTED_IMAGE_TAG 99

@interface BackgroundsViewController ()
@property (strong, nonatomic) UIButton *menuBtn;
@property (nonatomic, strong) NSArray *backgrounds;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
//@property (strong, nonatomic) UIImageView* selectedImageView;
@property (strong, nonatomic) NSMutableArray* selectedIndexPath;
@end

@implementation BackgroundsViewController
{
    NSMutableArray *_objectChanges;
    NSMutableArray *_sectionChanges;
}

@synthesize menuBtn, selectedIndexPath;
@synthesize fetchedResultsController = __fetchedResultsController;

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
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
    
    selectedIndexPath = [[NSMutableArray alloc] initWithCapacity:5];
}

- (void)viewWillAppear:(BOOL)animated
{
    if([[iSleepAppDelegate appDelegate].settingsViewController bgSwitchState])//TODO: are all objects here initd at statup???
    {
        //allows multiple selection
        self.collectionView.allowsMultipleSelection = YES;
    }
    else
    {
        self.collectionView.allowsMultipleSelection = NO;
    }
    
    for (NSObject* object in self.collectionView.indexPathsForSelectedItems) {
        NSIndexPath* indexPath = (NSIndexPath*)object;
        [self.collectionView selectItemAtIndexPath:indexPath animated:FALSE scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return [[self.fetchedResultsController sections] count];;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"BackgroundCell" forIndexPath:indexPath];
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    Background *bg = (Background*)managedObject;
    
    if([bg.isImage  isEqual: @YES])
    {
        UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];
        imageView.frame = CGRectMake(0, 0, FLICKR_THUMBNAIL_SIZE, FLICKR_THUMBNAIL_SIZE);//this is same size as backgroundLayout.itemSize set in app delegate
        NSURL *imageUrl = [NSURL URLWithString:bg.bThumbnailUrl];
        [imageView setImageWithURL:imageUrl
                             placeholderImage:nil];
        [cell.contentView addSubview:imageView];
        cell.backgroundColor = [UIColor clearColor];
    }
    else
    {
        cell.backgroundColor = [self convertStringToUIColor:(NSString*)bg.bColor];
        for(UIView *subview in [cell.contentView subviews]) {
            [subview removeFromSuperview];
        }
    }
    
    
    if([self.collectionView.indexPathsForSelectedItems containsObject:indexPath])
    //if([selectedIndexPath containsObject:indexPath])
    {
        NSString *pathToSelectedImage = [[NSBundle mainBundle] pathForResource:@"check_mark_green" ofType:@"png"];
        UIImage* selectedImage = [[UIImage alloc] initWithContentsOfFile:pathToSelectedImage];
        UIImageView* selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        selectedImageView.frame = CGRectMake(0, 0, 20, 20);
        selectedImageView.tag = SELECTED_IMAGE_TAG;
        [cell.contentView addSubview:selectedImageView];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
        for(UIView *subview in [cell.contentView subviews]) {
            if(subview.tag == SELECTED_IMAGE_TAG)
            {
                [subview removeFromSuperview];
            }
        }
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    
    //NSLog(@"CELL FOR ROW index %d", indexPath.item);
    
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //if(![selectedIndexPath containsObject:indexPath])
    //if(![self.collectionView.indexPathsForSelectedItems containsObject:indexPath])
    //{
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        Background *bg = (Background*)managedObject;
        [self.delegate backgroundSelected:bg];//tell the delegate we selected a background
        
        UICollectionViewCell *cell =[collectionView cellForItemAtIndexPath:indexPath];
        NSString *pathToSelectedImage = [[NSBundle mainBundle] pathForResource:@"check_mark_green" ofType:@"png"];
        UIImage* selectedImage = [[UIImage alloc] initWithContentsOfFile:pathToSelectedImage];
        UIImageView* selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        selectedImageView.frame = CGRectMake(0, 0, 20, 20);
        selectedImageView.tag = SELECTED_IMAGE_TAG;
        [cell.contentView addSubview:selectedImageView];
        //[selectedIndexPath addObject:indexPath];
        //[collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    //}
    NSLog(@"SELECTED index %d", indexPath.item);
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    Background *bg = (Background*)managedObject;
    [self.delegate backgroundDeSelected:bg];//tell the delegate we deselected a background
    
    UICollectionViewCell *cell =[collectionView cellForItemAtIndexPath:indexPath];
    for(UIView *subview in [cell.contentView subviews]) {
        if(subview.tag == SELECTED_IMAGE_TAG)
        {
            [subview removeFromSuperview];
        }
    }
    
    //[collectionView deselectItemAtIndexPath:indexPath animated:NO];
    //[selectedIndexPath removeObject:indexPath];
    
    NSLog(@"DESELECTED index %d", indexPath.item);
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Background" inManagedObjectContext:[[DatabaseManager sharedDatabaseManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"isFavorite" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"bTitle" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor1,sortDescriptor2, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[DatabaseManager sharedDatabaseManager] managedObjectContext] sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    /*
	     Replace this implementation with code to handle the error appropriately.
         
	     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	     */
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    //abort();
	}
    
    //NSLog(@"FetchedResultsConmtroller Number returned:%d",[self.fetchedResultsController.fetchedObjects count]);
    
    return __fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    
    [_sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([_sectionChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _sectionChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0)
    {
        
        if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self.collectionView reloadData];
            
        } else {
            
            [self.collectionView performBatchUpdates:^{
                
                for (NSDictionary *change in _objectChanges)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                                [self.collectionView.window endEditing:YES];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                                break;
                        }
                    }];
                }
            } completion:nil];
        }
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in _objectChanges) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 0) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeDelete:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 1) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }
    
    return shouldReload;
}

@end
