//
//  VDMigrationController.h
//  VisualDiffer
//
//  Created by davide ficano on 13/03/13.
//  Copyright (c) 2013 visualdiffer.com
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOPMigrationController : NSObject

@property (strong) NSManagedObjectModel *destinationModel;

- (instancetype)initWithModelName:(NSString*)modelName;

- (BOOL)requiresMigration:(NSURL*)sourceStoreURL
                    error:(NSError**)outError;
- (BOOL)migrateURL:(NSURL*)sourceStoreURL
             toURL:(NSURL*)destinationStoreURL
             error:(NSError **)error;

+ (NSURL* _Nullable)pickDestinationURLWith:(NSURL*)sourceStoreURL;
@end

NS_ASSUME_NONNULL_END
