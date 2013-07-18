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

@implementation DatabaseManager

SYNTHESIZE_SINGLETON_FOR_CLASS(DatabaseManager);

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

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
        abort();
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


//- (void)prePopulate:(NSString *)tripName startDate:(NSDate *)startDate endDate:(NSDate *)endDate
//{
//    NSManagedObjectContext *context = [self managedObjectContext];
//    Trip *trip = [NSEntityDescription insertNewObjectForEntityForName:@"Trip" 
//                                               inManagedObjectContext:context];
//    trip.name = tripName;
//    trip.startDate = startDate;
//    trip.endDate = endDate;
//    
//    /*This block reads strings from custom.strings and populates a Home array with them*/
//    int numHomeStrings = 11; // number of pre-populated home strings
//    NSString *homeString = @"Home_";
//    NSMutableArray *homeArray = [NSMutableArray arrayWithCapacity:numHomeStrings];
//    Home *home[numHomeStrings];
//    for (int index = 0; index < numHomeStrings; index++) {
//        home[index] = [NSEntityDescription insertNewObjectForEntityForName:@"Home" 
//                                                    inManagedObjectContext:context];
//        NSNumber *number = [NSNumber numberWithInt:index];
//        home[index].itemDescription = NSLocalizedStringFromTable ([homeString stringByAppendingString:
//                                                                   [number stringValue]], @"Custom", nil);
//        home[index].completionStatus = FALSE;
//        home[index].trip = trip;
//        [homeArray addObject:home[index]];
//    }
//    
//    /*This block reads strings from custom.strings and populates a Packing array with them*/
//    int numPackStrings = 8; // number of pre-populated pack strings
//    NSString *packString = @"Packing_";
//    NSMutableArray *packArray = [NSMutableArray arrayWithCapacity:numPackStrings];
//    Packing *pack[numPackStrings];
//    for (int index = 0; index < numPackStrings; index++) {
//        pack[index] = [NSEntityDescription insertNewObjectForEntityForName:@"Packing" 
//                                                    inManagedObjectContext:context];
//        NSNumber *number = [NSNumber numberWithInt:index];
//        pack[index].itemDescription = NSLocalizedStringFromTable ([packString stringByAppendingString:
//                                                                   [number stringValue]], @"Custom", nil);
//        pack[index].completionStatus = FALSE;
//        pack[index].trip = trip;
//        [packArray addObject:pack[index]];
//    }
//    
//    /*This block reads strings from custom.strings and populates a Leaving array with them*/
//    int numLeavingStrings = 12; // number of pre-populated pack strings
//    NSString *leavingString = @"Leaving_";
//    NSMutableArray *leavingArray = [NSMutableArray arrayWithCapacity:numLeavingStrings];
//    Leaving *leaving[numLeavingStrings];
//    for (int index = 0; index < numLeavingStrings; index++) {
//        leaving[index] = [NSEntityDescription insertNewObjectForEntityForName:@"Leaving" 
//                                                       inManagedObjectContext:context];
//        NSNumber *number = [NSNumber numberWithInt:index];
//        leaving[index].itemDescription = NSLocalizedStringFromTable ([leavingString stringByAppendingString:
//                                                                      [number stringValue]], @"Custom", nil);
//        leaving[index].completionStatus = FALSE;
//        leaving[index].trip = trip;
//        [leavingArray addObject:leaving[index]];
//    }
//    
//    /*This block reads strings from custom.strings and populates an Itinerary array with them*/
//    int numItineraryStrings = 4; // number of pre-populated returning strings
//    NSString *itineraryString = @"Itinerary_";
//    NSMutableArray *itineraryArray = [NSMutableArray arrayWithCapacity:numItineraryStrings];
//    Itinerary *itinerary[numItineraryStrings];
//    for (int index = 0; index < numItineraryStrings; index++) {
//        itinerary[index] = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" 
//                                                       inManagedObjectContext:context];
//        NSNumber *number = [NSNumber numberWithInt:index];
//        itinerary[index].itemDescription = NSLocalizedStringFromTable ([itineraryString stringByAppendingString:
//                                                                      [number stringValue]], @"Custom", nil);
//        itinerary[index].completionStatus = FALSE;
//        itinerary[index].trip = trip;
//        [itineraryArray addObject:itinerary[index]];
//    }
//    
//    /*This block reads strings from custom.strings and populates an Returning array with them*/
//    int numReturningStrings = 5; // number of pre-populated returning strings
//    NSString *returningString = @"Returning_";
//    NSMutableArray *returningArray = [NSMutableArray arrayWithCapacity:numReturningStrings];
//    Returning *returning[numReturningStrings];
//    for (int index = 0; index < numReturningStrings; index++) {
//        returning[index] = [NSEntityDescription insertNewObjectForEntityForName:@"Returning" 
//                                                         inManagedObjectContext:context];
//        NSNumber *number = [NSNumber numberWithInt:index];
//        returning[index].itemDescription = NSLocalizedStringFromTable ([returningString stringByAppendingString:
//                                                                        [number stringValue]], @"Custom", nil);
//        returning[index].completionStatus = FALSE;
//        returning[index].trip = trip;
//        [returningArray addObject:returning[index]];
//    }
//    
//    //Adds the Home, Packing, Leaving, Itinierary, Returning entities to the Trip Entitiy
//    [trip addHome:[NSOrderedSet orderedSetWithArray:homeArray]];
//    [trip addPacking:[NSOrderedSet orderedSetWithArray:packArray]];
//    [trip addLeaving:[NSOrderedSet orderedSetWithArray:leavingArray]];
//    [trip addItinerary:[NSOrderedSet orderedSetWithArray:itineraryArray]];
//    [trip addReturning:[NSOrderedSet orderedSetWithArray:returningArray]];
//    
//    NSError *error;
//    if (![context save:&error]) {
//        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
//    }
//}

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

@end
