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
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
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
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
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
        //[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
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
        [context lock];
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
        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        [context unlock];
    }
    
    [Background fetchPics:^(NSArray *backgrounds) {
    }];
}

/*
- (void) printAllTrips
{
    // Test listing all Trips
    NSError *error;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" 
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (Trip *trip in fetchedObjects) {
        NSLog(@"Trip Name: %@", trip.name);
        for(Home *home in trip.home) {
            NSLog(@"Home List: %@", home.itemDescription);
        }
        for(Packing *pack in trip.packing) {
            NSLog(@"Packing List: %@", pack.itemDescription);
        }
        for(Leaving *leaving in trip.leaving) {
            NSLog(@"Leaving List: %@", leaving.itemDescription);
        }
        for(Itinerary *itinerary in trip.itinerary) {
            NSLog(@"Itinerary List: %@", itinerary.itemDescription);
        }
        for(Returning *returning in trip.returning) {
            NSLog(@"Returning List: %@", returning.itemDescription);
        }
    }
}*/


 - (BOOL) isDBNotExist
 {
     // Test listing all Trips
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
         //iterate thru db and remove all objects
         /*for (NSManagedObject *object in fetchedObjects) {
             [context deleteObject:object];
         }
         NSError *error;
         if (![context save:&error]) {
             NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
         }*/
         return TRUE;
     }
     else
     {
         return FALSE;
     }
 }

@end
