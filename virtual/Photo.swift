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
    
    init(path : NSURL) {
        self.path = path
    }
}
