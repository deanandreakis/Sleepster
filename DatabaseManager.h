//
//  DatabaseManager.h
//  TripMate
//
//  Created by Dean Andreakis on 10/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DatabaseManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (DatabaseManager *)sharedDatabaseManager;
//- (void) prePopulate:(NSString *)tripName startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (void) initializeDB;
//- (void) printAllTrips;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
