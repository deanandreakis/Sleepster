//
//  DatabaseManager.m
//  TripMate
//
//  Created by Dean Andreakis on 10/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DatabaseManager.h"
#import "SynthesizeSingleton.h"
#import "iSleepAppDelegate.h"
#import "Background.h"
#import "Constants.h"

@interface DatabaseManager ()

@property(assign, nonatomic) BOOL isPermObjectsExist;

@end

@implementation DatabaseManager

SYNTHESIZE_SINGLETON_FOR_CLASS(DatabaseManager);

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize isPermObjectsExist;

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SleepsterModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SleepMate.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)initializeDB
{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SleepMate.sqlite"];
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
}

- (void)deleteAllEntities:(NSString *)nameEntity
{
    NSManagedObjectContext *theContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:nameEntity];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"isFavorite != %@", @YES];
    [fetchRequest setPredicate:filter];
    
    NSError *error;
    NSArray *fetchedObjects = [theContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects)
        {
        [theContext deleteObject:object];
        }
    
    error = nil;
    [theContext save:&error];
}

- (void)prePopulate
{
    if(!isPermObjectsExist) {
        NSArray* colorArray = [[NSArray alloc] initWithObjects:@"whiteColor",
                      @"blueColor", @"redColor", @"greenColor",
                      @"blackColor",@"darkGrayColor",
                      @"lightGrayColor",@"grayColor",
                      @"cyanColor",@"yellowColor",
                      @"magentaColor",@"orangeColor",
                      @"purpleColor",@"brownColor",
                      @"clearColor",nil];
        
        NSManagedObjectContext *context = [self managedObjectContext];
        [context performBlockAndWait:^{
        Background *bg[[colorArray count]];
        for (int index = 0; index < [colorArray count]; index++) {
            bg[index] = [NSEntityDescription insertNewObjectForEntityForName:@"Background"
                                                        inManagedObjectContext:context];
            bg[index].bTitle = colorArray[index];
            bg[index].bThumbnailUrl = nil;
            bg[index].bFullSizeUrl = nil;
            bg[index].bColor = colorArray[index];
            bg[index].isFavorite = @YES;
            bg[index].isImage = @NO;
            bg[index].isLocalImage = @NO;
            bg[index].isSelected = @NO;
        }
        
        Background *bgImage1;
        bgImage1 = [NSEntityDescription insertNewObjectForEntityForName:@"Background"
                                                 inManagedObjectContext:context];
        bgImage1.bTitle = @"z_Independence Grove";
        bgImage1.bThumbnailUrl = @"igrove_1";//name of resource file in jpg format
        bgImage1.bFullSizeUrl = @"igrove_1";
        bgImage1.bColor = nil;
        bgImage1.isFavorite = @YES;
        bgImage1.isImage = @YES;
        bgImage1.isLocalImage = @YES;
        bgImage1.isSelected = @NO;
        
        Background *bgImage2;
        bgImage2 = [NSEntityDescription insertNewObjectForEntityForName:@"Background"
                                                 inManagedObjectContext:context];
        bgImage2.bTitle = @"z_Independence Grove_1";
        bgImage2.bThumbnailUrl = @"grove2";//name of resource file in jpg format
        bgImage2.bFullSizeUrl = @"grove2";
        bgImage2.bColor = nil;
        bgImage2.isFavorite = @YES;
        bgImage2.isImage = @YES;
        bgImage2.isLocalImage = @YES;
        bgImage2.isSelected = @NO;
        
        Background *bgImage3;
        bgImage3 = [NSEntityDescription insertNewObjectForEntityForName:@"Background"
                                                 inManagedObjectContext:context];
        bgImage3.bTitle = @"z_Independence Grove_2";
        bgImage3.bThumbnailUrl = @"grove3";//name of resource file in jpg format
        bgImage3.bFullSizeUrl = @"grove3";
        bgImage3.bColor = nil;
        bgImage3.isFavorite = @YES;
        bgImage3.isImage = @YES;
        bgImage3.isLocalImage = @YES;
        bgImage3.isSelected = @NO;
        
        Background *bgImage4;
        bgImage4 = [NSEntityDescription insertNewObjectForEntityForName:@"Background"
                                                 inManagedObjectContext:context];
        bgImage4.bTitle = @"z_Independence Grove_3";
        bgImage4.bThumbnailUrl = @"grove4";//name of resource file in jpg format
        bgImage4.bFullSizeUrl = @"grove4";
        bgImage4.bColor = nil;
        bgImage4.isFavorite = @YES;
        bgImage4.isImage = @YES;
        bgImage4.isLocalImage = @YES;
        bgImage4.isSelected = @NO;
        
        Background *bgImage5;
        bgImage5 = [NSEntityDescription insertNewObjectForEntityForName:@"Background"
                                                 inManagedObjectContext:context];
        bgImage5.bTitle = @"z_Independence Grove_4";
        bgImage5.bThumbnailUrl = @"grove5";//name of resource file in jpg format
        bgImage5.bFullSizeUrl = @"grove5";
        bgImage5.bColor = nil;
        bgImage5.isFavorite = @YES;
        bgImage5.isImage = @YES;
        bgImage5.isLocalImage = @YES;
        bgImage5.isSelected = @NO;
        
        NSError *error;
        if (![context save:&error]) {
            //NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        }];
    }
    
    [Background fetchPics:^(NSArray *backgrounds) {} withSearchTags:@"ocean,waves,rain,wind,waterfall,stream,forest,fire"];
}


 - (BOOL) isDBNotExist
 {
     NSError *error;
     NSManagedObjectContext *context = [self managedObjectContext];
     NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
     NSEntityDescription *entity = [NSEntityDescription entityForName:@"Background"
                                               inManagedObjectContext:context];
     [fetchRequest setEntity:entity];
     NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
     if([fetchedObjects count] < MIN_NUM_BG_OBJECTS)//change to less then or equal to permanent objects
     {
         if([fetchedObjects count] >= NUM_PERMANENT_BG_OBJECTS)
         {
             isPermObjectsExist = YES;
         } else {
             isPermObjectsExist = NO;
         }
         return TRUE;
     }
     else
     {
         return FALSE;
     }
 }

@end
