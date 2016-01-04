//
//  Utilities.swift
//  virtual
//
//  Created by Matthew Rocco on 1/2/16.
//  Copyright © 2016 Matthew Rocco. All rights reserved.
//

import CoreData
import Foundation

/**
 Returns a random string of 5 characters to be used for generating IDs.
*/
func randomString() -> String {
    var s = [String]()
    for _ in (1...5) {
        s.append(String(arc4random_uniform(10)))
    }
    return s.joinWithSeparator("")
}

/**
 Retrieves an object from the Core Data store.
 - Parameters:
 - context - the managed context for Core Data
 - objectid - the objectid associated with the entity
 - entity - the entity we want to find
 */
func objectRetrieve(context : NSManagedObjectContext,
    objectid : String,
    entity : String) -> AnyObject {
    
    // Define the entity and the request.
    let entityToFind = NSEntityDescription.entityForName(entity,inManagedObjectContext: context)
    let request = NSFetchRequest()
    
    // Set the entity and the predicate to the request.
    request.entity = entityToFind
    request.predicate = NSPredicate(format: "(id = %@)", objectid)
    
    // Attempt to find the object(s) in core data and return the first vale.
    do {
        let results = try context.executeFetchRequest(request)
        guard results.count > 0 else {
            return []
        }
        return results[0]
        
    }
    catch {
        return []
    }
}

