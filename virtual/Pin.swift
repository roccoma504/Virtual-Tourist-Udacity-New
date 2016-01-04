//
//  Pin.swift
//  virtualtourist
//
//  Created by Matthew Rocco on 12/6/15.
//  Copyright © 2015 Matthew Rocco. All rights reserved.
//

import CoreData
import MapKit

class Pin : NSObject, MKAnnotation {
    
    // MARK: - Variables
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var id: String?
    
    init(coordinate: CLLocationCoordinate2D,title: String, id: String) {
        self.coordinate = coordinate
        self.title = title
        self.id = id
    }
    
    // Returns the constructed pin.
    func pin() -> Pin {
        return self
    }
}