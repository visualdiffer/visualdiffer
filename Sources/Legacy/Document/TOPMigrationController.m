//
//  VDMigrationController.m
//  VisualDiffer
//
//  Created by davide ficano on 13/03/13.
//  Copyright (c) 2013 visualdiffer.com
//

#import "TOPMigrationController.h"

@implementation TOPMigrationController

- (instancetype)initWithModelName:(NSString*)modelName {
    self = [super init];

    if (self) {
        NSURL* targetModelURL = [[NSBundle mainBundle] URLForResource:modelName
                                                        withExtension:@"momd"];
        _destinationModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:targetModelURL];
    }
    return self;
}

- (BOOL)requiresMigration:(NSURL*)sourceStoreURL
                    error:(NSError**)outError {
    NSDictionary* sourceMetadata =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSBinaryStoreType
                                                               URL:sourceStoreURL
                                                           options:nil
                                                             error:outError];

    if (sourceMetadata == nil) {
        return NO;
    }

    return ![self.destinationModel isConfiguration:nil
                  compatibleWithStoreMetadata:sourceMetadata];
}

- (BOOL)migrateStore:(NSURL*)sourceStoreURL
             toStore:(NSURL*)destinationStoreURL
               error:(NSError**)outError {
    NSBundle* bundle = [NSBundle mainBundle];
    NSMutableArray * modelPaths = [NSMutableArray array];
    NSArray * modelDirectories = [bundle pathsForResourcesOfType:@"momd" inDirectory:nil];
    for (NSString * path in modelDirectories) {
        NSString * subdirectory = [path lastPathComponent];

        NSArray * array = [bundle pathsForResourcesOfType:@"mom" inDirectory:subdirectory];
        [modelPaths addObjectsFromArray:array];
    }
    // Current model is the first element
    [modelPaths sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        // sort in descending order
        return -[obj1 caseInsensitiveCompare:obj2];
    }];

    // upgrade only from version 1.x to 1.y where y = x + 1 (eg from 1.1 to 1.2, from 1.0 to 1.1)
    // don't upgrade from version 1.0 to 1.2
    NSUInteger index = modelPaths.count > 1 ? 1 : 0;
    NSManagedObjectModel* sourceModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPaths[index]]];

    // Try to get an inferred mapping model.
    NSMappingModel *mappingModel =
    [NSMappingModel inferredMappingModelForSourceModel:sourceModel
                                      destinationModel:self.destinationModel
                                                 error:outError];

    // If Core Data cannot create an inferred mapping model, return NO.
    if (!mappingModel) {
        return NO;
    }

    // Get the migration manager class to perform the migration.
    NSValue *classValue =
    [NSPersistentStoreCoordinator registeredStoreTypes][NSBinaryStoreType];
    Class binaryStoreClass = (Class)[classValue pointerValue];
    Class binaryStoreMigrationManagerClass = [binaryStoreClass migrationManagerClass];

    NSMigrationManager *manager = [[binaryStoreMigrationManagerClass alloc]
                                   initWithSourceModel:sourceModel
                                   destinationModel:self.destinationModel];

    BOOL success = [manager migrateStoreFromURL:sourceStoreURL
                                           type:NSBinaryStoreType
                                        options:nil
                               withMappingModel:mappingModel
                               toDestinationURL:destinationStoreURL
                                destinationType:NSBinaryStoreType
                             destinationOptions:nil
                                          error:outError];


    return success;
}

- (BOOL)migrateURL:(NSURL*)sourceStoreURL toURL:(NSURL*)destinationStoreURL error:(NSError **)outError {
    NSURL* temporaryDirectory = [[self class] temporaryDirectoryAppropriateForURL:destinationStoreURL];
    NSURL* tempDestURL = [temporaryDirectory URLByAppendingPathComponent:@"migration"];

    BOOL result = [self migrateStore:sourceStoreURL toStore:tempDestURL error:outError];

    if (result) {
        NSFileManager* fileManager = [NSFileManager defaultManager];

        if ([fileManager fileExistsAtPath:[destinationStoreURL path]]) {
            [fileManager removeItemAtURL:destinationStoreURL error:outError];
        }
        [fileManager moveItemAtURL:tempDestURL toURL:destinationStoreURL error:outError];
    }

    return result;
}

+ (NSURL*)pickDestinationURLWith:(NSURL*)sourceStoreURL {
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    savePanel.title = NSLocalizedString(@"Document Migration", nil);
    savePanel.message = NSLocalizedString(@"Your document needs to be upgraded. This manual step is required by Apple Sandbox rules", nil);
    savePanel.directoryURL = [sourceStoreURL URLByDeletingLastPathComponent];
    savePanel.nameFieldStringValue = [sourceStoreURL lastPathComponent];

    if ([savePanel runModal] == NSModalResponseOK) {
        return savePanel.URL;
    }
    return nil;
}

+ (NSURL*)temporaryDirectoryAppropriateForURL:(NSURL*)sourceURL {
    NSError* error = nil;

    NSURL* intermediateURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
                                                                    inDomain:NSUserDomainMask
                                                           appropriateForURL:sourceURL
                                                                      create:YES
                                                                       error:&error];

    if (!intermediateURL) {
        TOP_METHOD_LOG(@"Error finding temporary directory for URL %@: %@", sourceURL, error);
    }

    return intermediateURL;
}

@end
