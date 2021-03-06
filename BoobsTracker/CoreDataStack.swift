//
//  CoreDataStack.swift
//
//
//  Created by Fernando Rodríguez Romero on 21/02/16.
//  Copyright © 2016 udacity.com. All rights reserved.
//

import CoreData

// MARK: - CoreDataStack

struct CoreDataStack {
    
    static var shared = CoreDataStack(modelName: "Model")!
    
    // MARK: Properties
    
    let model: NSManagedObjectModel
    let coordinator: NSPersistentStoreCoordinator
    let modelURL: URL
    let dbURL: URL
    let context: NSManagedObjectContext
    
    // MARK: Initializers
    
    init?(modelName: String) {
        
        // Assumes the model is in the main bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName) in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        // Create the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // create a context and add connect it to the coordinator
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        
        // Add a SQLite store located in the documents folder
        let fm = FileManager.default
        
        //fm.containerURL(forSecurityApplicationGroupIdentifier: "hyston.ios.BoobsTracker")
        
        //guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
        guard let docUrl = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.hyston.ios.BoobsTracker") else {
            print("Unable to reach the documents folder")
            return nil
        }
        
        self.dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        // Options for migration
        let options = [NSInferMappingModelAutomaticallyOption : true, NSMigratePersistentStoresAutomaticallyOption : true]
        
        do {
            try addStoreCoordinator(storeType: NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }
    
    // MARK: Utils
    
    func addStoreCoordinator(storeType: String, configuration: String?, storeURL: URL, options : [NSObject : AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
}


// MARK: - CoreDataStack (Removing Data)

extension CoreDataStack  {
    
    func dropAllData() throws {
        // delete all the objects in the db. This won't delete the files, it will
        // just leave empty tables.
        try coordinator.destroyPersistentStore(at: dbURL, ofType:NSSQLiteStoreType , options: nil)
        try addStoreCoordinator(storeType: NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

// MARK: - CoreDataStack (Save)

extension CoreDataStack {
    
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    func autoSave(delayInSeconds: Int) {
        
        if delayInSeconds > 0 {
            do {
                try saveContext()
                print("Autosaving")
            } catch {
                print("Error while autosaving")
            }
            
            let time = DispatchTime.now() + .seconds(delayInSeconds)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delayInSeconds: delayInSeconds)
            }
        }
    }
}
