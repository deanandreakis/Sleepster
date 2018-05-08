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
@property (strong, nonatomic) NSMutableArray* selectedIndexPath;
@property (nonatomic, assign) BOOL isSingleSelectToDeselect;
@end

@implementation BackgroundsViewController
{
    NSMutableArray *_objectChanges;
    NSMutableArray *_sectionChanges;
    int counter;
    UIGestureRecognizer *tapper;
}

@synthesize menuBtn, selectedIndexPath, isSingleSelectToDeselect;
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
    
    self.collectionView.restorationIdentifier = @"backgroundsCollectionViewID";
    
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
    counter = 0;
    
    selectedIndexPath = [[NSMutableArray alloc] initWithCapacity:5];
    
    tapper = [[UITapGestureRecognizer alloc]
              initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];
}

- (void)viewDidAppear:(BOOL)animated
{
    if([[iSleepAppDelegate appDelegate].settingsViewController bgSwitchState])//TODO: are all objects here initd at statup???
    {
        //allows multiple selection
        self.collectionView.allowsMultipleSelection = YES;
    }
    else
    {
        //if([self.collectionView.indexPathsForSelectedItems count] > 1)//more then one item selected
        if([selectedIndexPath count] > 1)//more then one item selected
        {
            for (NSObject* object in selectedIndexPath) { //self.collectionView.indexPathsForSelectedItems) {
                NSIndexPath* indexPath = (NSIndexPath*)object;
                [self.collectionView deselectItemAtIndexPath:indexPath animated:FALSE];
                
                UICollectionViewCell *cell =[self.collectionView cellForItemAtIndexPath:indexPath];
                for(UIView *subview in [cell.contentView subviews]) {
                    if(subview.tag == SELECTED_IMAGE_TAG)
                    {
                        [subview removeFromSuperview];
                    }
                }
            }
            [selectedIndexPath removeAllObjects];
            //TODO: put code here to select a permanent bg image
        } else if([selectedIndexPath count] == 1) {
            //we are in single select mode and there is one item selected
            isSingleSelectToDeselect = YES;
        } else if([selectedIndexPath count] == 0) {
            isSingleSelectToDeselect = NO;
        }
        self.collectionView.allowsMultipleSelection = NO;
    }
    
    //BUG: If we dont allow multiple selection then I think the indexPathsForSelectedItems array
    //is not useful and does not contain the single selected item
    
    //BUG: SOmetimes last single selected item is not deselected so we need to add logic to
    //selectedItem to say if we are in single select mode and we selected an item we need to call deselect
    //on the old item in the array.
    //NSLog(@"SELECTED INDEX PATH NUM OBJECTS IS %d", [selectedIndexPath count]);
    for (NSObject* object in selectedIndexPath) {//self.collectionView.indexPathsForSelectedItems) {
        NSIndexPath* indexPath = (NSIndexPath*)object;
        [self.collectionView selectItemAtIndexPath:indexPath animated:FALSE scrollPosition:UICollectionViewScrollPositionNone];
        UICollectionViewCell *cell =[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell setSelected:TRUE];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    //NSLog(searchBar.text.description);
    [[DatabaseManager sharedDatabaseManager] deleteAllEntities:@"Background"];
    [_delegate removeAllBackgrounds];
    [Background fetchPics:^(NSArray *backgrounds) {} withSearchTags:searchBar.text];
    
    //1. After searching, the selected pic index needs to be reset to item 0,0 and sent to our delegate so its actually selected
    for (NSObject* object in selectedIndexPath) { //self.collectionView.indexPathsForSelectedItems) {
        NSIndexPath* indexPath = (NSIndexPath*)object;
        [self.collectionView deselectItemAtIndexPath:indexPath animated:FALSE];
        
        UICollectionViewCell *cell =[self.collectionView cellForItemAtIndexPath:indexPath];
        for(UIView *subview in [cell.contentView subviews]) {
            if(subview.tag == SELECTED_IMAGE_TAG)
                {
                [subview removeFromSuperview];
                }
        }
    }
    [selectedIndexPath removeAllObjects];
    
    // 2. the built-in pics needs to be appended to the search result pics just like when we first download pics on app install
    // see the prePopulate method in the databaseManager class
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
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
        
        NSURL *imageUrl = nil;
        if([bg.isLocalImage isEqual:@NO]){
            imageUrl = [NSURL URLWithString:bg.bThumbnailUrl];
            UIImage *placeholder = [UIImage imageNamed:@"thumbnail-default.png"];
            [imageView setImageWithURL:imageUrl
                      placeholderImage:placeholder];
        } else {
            NSString *pathToImage = [[NSBundle mainBundle] pathForResource:bg.bThumbnailUrl ofType:@"jpg"];
            UIImage* imageG = [[UIImage alloc] initWithContentsOfFile:pathToImage];
            [imageView setImage:imageG];
        }

        
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
    
    
    //if([self.collectionView.indexPathsForSelectedItems containsObject:indexPath])
    if([selectedIndexPath containsObject:indexPath])
    {
        NSString *pathToSelectedImage = [[NSBundle mainBundle] pathForResource:@"check_mark_green" ofType:@"png"];
        UIImage* selectedImage = [[UIImage alloc] initWithContentsOfFile:pathToSelectedImage];
        UIImageView* selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        selectedImageView.frame = CGRectMake(0, 0, 20, 20);
        selectedImageView.tag = SELECTED_IMAGE_TAG;
        [cell.contentView addSubview:selectedImageView];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [cell setSelected:TRUE];
    } else {
        for(UIView *subview in [cell.contentView subviews]) {
            if(subview.tag == SELECTED_IMAGE_TAG)
            {
                [subview removeFromSuperview];
            }
        }
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        [cell setSelected:FALSE];
    }
    
    //NSLog(@"CELL FOR ROW index %d", indexPath.item);
    //NSLog(@"NUM IN ARRAY %d", [self.collectionView.indexPathsForSelectedItems count]);
    
    return cell;
}


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(isSingleSelectToDeselect && ([selectedIndexPath count] == 1)) {
        [self.collectionView.delegate collectionView:collectionView didDeselectItemAtIndexPath:[selectedIndexPath objectAtIndex:0]];
        isSingleSelectToDeselect = NO;
        //NSLog(@"TRIGGER!!!!!!!!!!!!");
    }
    
    if(![selectedIndexPath containsObject:indexPath])
    //if(![self.collectionView.indexPathsForSelectedItems containsObject:indexPath])
    {
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        Background *bg = (Background*)managedObject;
        [self.delegate backgroundSelected:bg];//tell the delegate we selected a background
        [selectedIndexPath addObject:indexPath];
        
        UICollectionViewCell *cell =[collectionView cellForItemAtIndexPath:indexPath];
        NSString *pathToSelectedImage = [[NSBundle mainBundle] pathForResource:@"check_mark_green" ofType:@"png"];
        UIImage* selectedImage = [[UIImage alloc] initWithContentsOfFile:pathToSelectedImage];
        UIImageView* selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        selectedImageView.frame = CGRectMake(0, 0, 20, 20);
        selectedImageView.tag = SELECTED_IMAGE_TAG;
        [cell.contentView addSubview:selectedImageView];
        //[collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        //NSLog(@"SELECTED index %d", indexPath.item);
    }
    //NSLog(@"SELECTED index %d", indexPath.item);
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
    [selectedIndexPath removeObject:indexPath];
    
    //NSLog(@"DESELECTED index %d", indexPath.item);
}

#pragma mark UIDataSourceModelAssociation
- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)indexPath inView:(UIView *)view
{
    //NSLog(@"BG ENCODE");
    NSString *identifier = nil;
    if (indexPath && view)
    {
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        Background *bg = (Background*)managedObject;
        NSURL *moURI = [[bg objectID] URIRepresentation];
        identifier = [moURI absoluteString];
    }
    NSLog(@"BG ENCODE IDENTIFIER %@", identifier);
    return identifier;
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view
{
    //NSLog(@"BG DECODE");
    NSLog(@"BG DECODE IDENTIFIER %@", identifier);
    NSIndexPath *indexPath = nil;
    if (identifier && view)
    {
        NSURL* url = [NSURL URLWithString:identifier];
        NSPersistentStoreCoordinator* coordinator = [[DatabaseManager sharedDatabaseManager] persistentStoreCoordinator];
        NSManagedObjectContext* context = [[DatabaseManager sharedDatabaseManager] managedObjectContext];
        NSManagedObjectID* objectID  = [coordinator managedObjectIDForURIRepresentation:url];
        Background* bg = (Background*)[context existingObjectWithID:objectID error:NULL];
        indexPath = [self.fetchedResultsController indexPathForObject:bg];
    }
    
    if(indexPath != nil) { //fixes crashlytics issue #2 for version 2.0
        [self.collectionView.delegate collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
    }
    
    return indexPath;
}

#pragma mark setSelected
-(void)setSelected:(Background*)bg
{
    NSIndexPath *indexPath = nil;
    for (Background* bgTemp in [self.fetchedResultsController fetchedObjects]) {
        if([bgTemp.bFullSizeUrl isEqualToString:bg.bFullSizeUrl])
        {
            indexPath = [self.fetchedResultsController indexPathForObject:bgTemp];
            break;
        }
    }
    if(indexPath != nil)
    {
        [self.collectionView.delegate collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
    }
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
    //NOTE: The cacheName param is set to nil on purpose!!!! When the db keeps rebuilding itself due to not pulling
    //down images from Flickr upon startup, this cache would prevent a new actual fetch from occuring and result in
    //a coredata related exception.
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[DatabaseManager sharedDatabaseManager] managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    /*
	     Replace this implementation with code to handle the error appropriately.
         
	     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	     */
	    //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    //abort();
	}
    
    //NSLog(@"FetchedResultsConmtroller Number returned:%d",[self.fetchedResultsController.fetchedObjects count]);
    
    return __fetchedResultsController;
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            //NSLog(@"INSERT");//this is all that shows up when flickr bg's added; there all inserted before the permanent bg's
            /*just go thru the selectedIndexPath array and increment the indexPath.row each time we come here*/
            counter = counter+1;
            break;
        case NSFetchedResultsChangeDelete:
            //NSLog(@"DELETE");
            break;
        case NSFetchedResultsChangeUpdate:
            //NSLog(@"UPDATE");
            break;
        case NSFetchedResultsChangeMove:
            //NSLog(@"MOVE");
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
//    for (NSIndexPath* path in selectedIndexPath) {
//        NSIndexPath* newIndexPath =  [NSIndexPath indexPathForItem:path.item+counter inSection:0];
//        [selectedIndexPath replaceObjectAtIndex:[selectedIndexPath indexOfObject:path] withObject:newIndexPath];
//        [self.collectionView.delegate collectionView:self.collectionView didSelectItemAtIndexPath:newIndexPath];
//    }
    counter = 0;
    [self.collectionView reloadData];
}

@end
