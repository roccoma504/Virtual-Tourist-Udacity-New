//
//  Utilities.swift
//  virtual
//
//  Created by Matthew Rocco on 1/2/16.
//  Copyright © 2016 Matthew Rocco. All rights reserved.
//

import CoreData
import Foundation

func randomString() -> String {
    var s = [String]()
    for _ in (1...5) {
        s.append(String(arc4random_uniform(10)))
    }
    return s.joinWithSeparator("")
}

func objectRetrieve(context : NSManagedObjectContext, objectid : String, entity : String) -> AnyObject {
    
    let pinEntity = NSEntityDescription.entityForName(entity,inManagedObjectContext: context)
    let request = NSFetchRequest()
    request.entity = pinEntity
    request.predicate = NSPredicate(format: "(id = %@)", objectid)
    
    print("id -> " + objectid)
    
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

