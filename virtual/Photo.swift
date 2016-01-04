//
//  Photo.swift
//  virtual
//
//  Created by Matthew Rocco on 12/17/15.
//  Copyright © 2015 Matthew Rocco. All rights reserved.
//

import CoreData
import MapKit

class Photo : NSManagedObject {
    
    private var path : NSURL!
    private var deleteFail : Bool = false
    
    
    /**
     Initialize a photo object.
     */
    init(path: NSURL) {
        self.path = path
    }
    
    /**
     This function is called when a user taps on the photo. It will remove
     the photo from the documents directory based on the path the object was
     initialized with.
     */
    func deletePhoto() {
        let documentsPath =
        NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true)[0]
        
        let fileManager = NSFileManager.defaultManager()
        let filePath = documentsPath.stringByAppendingString(String(path))
        do {
            try fileManager.removeItemAtPath(filePath)
        }
        catch {
            deleteFail = true
            print("remove fail")
        }
    }
    
    /**
     Returns the error flag
     - Returns: the error flag.
     */
    func isError() -> Bool {
        return deleteFail
    }
}
