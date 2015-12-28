//
//  ViewController.swift
//  virtual
//
//  Created by Matthew Rocco on 12/17/15.
//  Copyright © 2015 Matthew Rocco. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // #MARK : Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // #MARK : Private
    private var clickedPin : Pin!
    private var pins = [NSManagedObject]()
    
    /**
     On load set up the map view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        addTapAction(mapView: mapView, target:self, action: "addAnnotation:")
        loadMapConfig()
        fetchPins()
        print(pins)
    }
    
    /**
     On disappear set the current state of the map into defaults and remove
     the pins.
     */
    override func viewDidDisappear(animated: Bool) {
        setMapConfig()
    }
    
    /**
     Configures the pin(s).
     - Parameters:
     - mapView - the mapview to add the action to
     - viewForAnnotation - the annotation view
     - Returns: a custom pin.
     */
    func mapView(mapView: MKMapView, viewForAnnotation : MKAnnotation) -> MKAnnotationView? {
        let pin = MKPinAnnotationView(annotation: viewForAnnotation, reuseIdentifier: "pin")
        pin.animatesDrop = true
        pin.canShowCallout = true
        return pin
    }
    
    /**
     Controls the placement of pins on the map.
     */
    private func processAnnotations() {
        for i in pins {
            let tempPin = Pin(
                coordinate: CLLocationCoordinate2D(
                    latitude: i.valueForKey("lat") as!Double,
                    longitude: i.valueForKey("long") as! Double),
                title:"title",
                id:(i.valueForKey("id") as? String)!)
            
            dispatch_async(dispatch_get_main_queue(),{
                print("add")
                self.mapView.addAnnotation(tempPin)
            })
        }
    }
    
    /**
     Adds the annotation to the map
     - Parameters:
     - gestureRecognizer: the gesture that the user performed
     */
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        let location = getTappedLocation(mapView: mapView, gestureRecognizer: gestureRecognizer)
        
        // Add an annotation to the map. We need to remove the gesture recognizer
        // to prevent a bunch of pins from being created.
        let annotation = MKPointAnnotation()
        annotation.coordinate = location;
        annotation.title = "View Pictures"
        mapView.addAnnotation(annotation)
        mapView.removeGestureRecognizer(mapView.gestureRecognizers![0])
        
        // Create a new pin object and add it to the pin array.
        savePin(annotation.coordinate.latitude, long: annotation.coordinate.longitude,id: String(pins.count + 1))
        
        print ("Pin count -> " + String(pins.count))
        addTapAction(mapView: mapView, target:self, action: "addAnnotation:")
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView: MKAnnotationView) {
        clickedPin = Pin(coordinate: CLLocationCoordinate2D(latitude:
            didSelectAnnotationView.annotation!.coordinate.latitude,
            longitude: didSelectAnnotationView.annotation!.coordinate.longitude),
            title: "",
            id: String(pins.count))
        self.performSegueWithIdentifier("mapToPictures", sender: self)
    }
    
    /**
     Adds a gesture recognizer to the mapview.
     - Parameters:
     - mapView - the mapview to add the action to
     - target - the target for the tap (self)
     - action - the action to be performed
     - tapDuration - the length of the tap before activation
     */
    func addTapAction(mapView mapView: MKMapView,
        target: AnyObject,
        action: Selector,
        tapDuration: Double = 0.5) {
            // Define the recongizer based on the input parameters and set the tap
            // length to 1 second.
            let longPressRecognizer = UILongPressGestureRecognizer(
                target: target,
                action: action)
            longPressRecognizer.minimumPressDuration = tapDuration
            // Add gesture recognizer to the map.
            mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    //MARK: State Data
    
    /**
    Set the current map configuration based on the current state
    of the mapview.
    */
    private func setMapConfig() {
        print("data set")
        NSUserDefaults.standardUserDefaults().setObject(
            mapView.centerCoordinate.latitude, forKey: "centerLat")
        NSUserDefaults.standardUserDefaults().setObject(
            mapView.centerCoordinate.longitude, forKey: "centerLong")
        NSUserDefaults.standardUserDefaults().setObject(
            mapView.region.span.latitudeDelta, forKey: "deltaLat")
        NSUserDefaults.standardUserDefaults().setObject(
            mapView.region.span.longitudeDelta, forKey: "deltaLong")
    }
    
    /**
     Configure the mapview based on what is in defaults.
     */
    private func loadMapConfig() {
        
        // Define the defaults.
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // If there is data in the defaults, configure the mapview. The center
        // lat is the first thing that gets set so if the set fails on a data
        // element before it then nothing will exist here.
        if let _ = defaults.objectForKey("deltaLong") {
            
            // Set the center coord and span and adjust the map accordingly.
            let centerCoord = CLLocationCoordinate2D(
                latitude:  (defaults.objectForKey("centerLat") as? Double)!,
                longitude: (defaults.objectForKey("centerLong") as? Double)!)
            let span = MKCoordinateSpan(
                latitudeDelta: (defaults.objectForKey("deltaLat") as? Double)!,
                longitudeDelta: (defaults.objectForKey("deltaLong") as? Double)!)
            let region:MKCoordinateRegion = MKCoordinateRegionMake(centerCoord, span)
            
            mapView.centerCoordinate = centerCoord
            mapView.setRegion(region, animated: true)
        }
    }
    
    /**
     Returns a location based on the tap.
     - Parameters:
     - mapView - the mapview to add the action to
     - gestureRecognizer - the gesture that the user performed
     - Returns: A 2d location
     */
    func getTappedLocation(mapView mapView: MKMapView,
        gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D{
            let touchPoint = gestureRecognizer.locationInView(mapView)
            return mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
    }
    
    /**
     Preps for the segue.
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "mapToPictures") {
            let navigationController = segue.destinationViewController
            let destView = navigationController as! CollectionViewController
            let clickedAnnotationView = MKAnnotationView(annotation:
                clickedPin, reuseIdentifier: "Pin")
            
            destView.receivedPinId = clickedPin.id
            destView.receivedAnnotation = clickedAnnotationView
        }
    }
    
    /**
     Creates and saves a pin into Core Data.
     - Parameters:
     - lat - the latitude of the pin
     - long - the longitude of the pin
     */
    func savePin(lat: Double, long: Double, id: String) {
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let entity =  NSEntityDescription.entityForName("Pin",
            inManagedObjectContext:managedContext)
        
        let pin = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext: managedContext)
        
        pin.setValue(lat, forKey: "lat")
        pin.setValue(long, forKey: "long")
        pin.setValue(id, forKey: "id")
        
        do {
            try managedContext.save()
            pins.append(pin)
            print("pin saved")
            print(pin)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
            showAlert("Could not save data. The new pin was not saved.")
        }
    }
    
    /**
     Retrieves the pins from core data and sets the pins
     array with the retreived values. If successful, the
     map is reloaded with the persistent data.
     */
    func fetchPins() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            pins = results as! [NSManagedObject]
            processAnnotations()
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            showAlert("Could not fetch data. Please reload the application")
        }
    }
    
    
    /** This subprogram generates an alert for the user based upon conditions
     in the application. This view controller can generate two different
     alerts so this is here only for reuseability.
     */
    func showAlert(message : String) {
        dispatch_async(dispatch_get_main_queue(),{
            let alertController = UIAlertController(title: "Error!", message:
                message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss",
                style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController,animated: true,completion: nil)
        })
    }
}
