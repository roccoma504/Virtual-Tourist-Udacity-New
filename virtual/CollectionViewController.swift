//
//  CollectionViewController.swift
//  virtual
//
//  Created by Matthew Rocco on 12/17/15.
//  Copyright © 2015 Matthew Rocco. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate {
    
    // #MARK : Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotoLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    // #MARK : Variables
    var receivedAnnotation : MKAnnotationView!
    var receivedPinId : String!
    
    // #MARK : Private
    private var photoCount = 0;
    private var photos = [UIImage!]();
    private var imagesReadyArray = [Bool!]()
    private var managedPhotos = [NSManagedObject]()
    
    /**
     Perform setup processing.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupMap()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        if pinRequest(managedContext).valueForKey("photo")?.count > 0 {
            retreiveStoredCollection(pinRequest(managedContext) as! NSManagedObject)
        }
        else {
            retrieveNewCollection()
            updateActivity(true)
        }
        
        newCollectionButton.enabled = false;
    }
    
    /**
     Performs all processing to retrieve a new collection.
     */
    private func retrieveNewCollection() {
        getPhotos((receivedAnnotation.annotation?.coordinate.latitude)!,
            long: (receivedAnnotation.annotation?.coordinate.longitude)!) { (result) -> Void in
                self.reload()
        }
    }
    
    private func retreiveStoredCollection(pin : NSManagedObject) {
        updateActivity(false)
        
        
        // Get the document directory path, append the file name (we assume the
        // filename from Flickr is unique), and write the image to disk.
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true)[0]
        
        print(documentsPath)
        
        
        

        for path in pin.valueForKey("photo")!.valueForKey("path")! as! NSSet {
            let image = UIImage(contentsOfFile: path as! String)
            if image == nil {
                print("missing image at: \(path)")
            }
            print("Loading image from path: \(path)")
            photos.append(image)
            imagesReadyArray.append(true)
        }
        photoCount = pin.valueForKey("photo")!.count
        self.reload()
    }
    
    /**
     Sets up the map based on the pushed pin.
     */
    private func setupMap() {
        // Set the location based on the pushed pin.
        let coordinates = receivedAnnotation.annotation?.coordinate
        
        // Scope the mapview.
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01 , 0.01)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(coordinates!, span)
        
        // Create annotation.
        let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinates!
        
        // Plot the annotation on the map and center the view
        // on the newly created pin.
        mapView.addAnnotation(pointAnnotation)
        mapView.centerCoordinate = coordinates!
        mapView.setRegion(region, animated: true)
    }
    
    /**
     Gets the photos from Flickr.
     */
    private func getPhotos(lat : Double, long : Double, completion: (result: Bool) -> Void) {
        
        let photoOps = PhotoNetworkOps(lat: lat, long: long)
        photoOps.getFlikrPhoto { (result) -> Void in
            
            self.photoCount = photoOps.urls().count
            self.reload()
            for i in 0...self.photoCount - 1 {
                self.imagesReadyArray.append(false)
                photoOps.downloadImage(photoOps.urls()[i], completion: { (result) -> Void in
                    
                    // Convert the image to data for Core Data storage.
                    let imageData: NSData = UIImageJPEGRepresentation(photoOps.flickrImage(), 1.0)!
                    
                    // Get the document directory path, append the file name (we assume the
                    // filename from Flickr is unique), and write the image to disk.
                    let documentsPath = NSSearchPathForDirectoriesInDomains(
                        .DocumentDirectory, .UserDomainMask, true)[0]
                    let filePath = documentsPath.stringByAppendingString("/"+photoOps.fileName())
                    print(filePath)
                    let success = imageData.writeToFile(filePath, atomically: true)
                    if !success {
                        self.showAlert("Could not save image. Your storage may be full. Free some space and try again.")
                        return
                    }
                    
                    self.photos.append(photoOps.flickrImage())
                    self.imagesReadyArray[i] = true
                    self.savePhoto(filePath)
                    completion(result: true)
                    if self.imagesReadyArray.count >= self.photoCount {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.newCollectionButton.enabled = true
                        })
                    }
                })
            }
            self.updateActivity(false)
        }
    }
    
    /**
     Returns the number of cells in the collection.
     */
    func collectionView(
        collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            noPhotoLabel.hidden = true
            
            if photoCount == 0 {
                noPhotoLabel.hidden = false
                updateLabel("No Photos!")
            }
            return photoCount
    }
    
    /**
     Defines the content of the cell.
     */
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
                "cell", forIndexPath: indexPath) as! FlickrCollectionViewCell
            
            // If the images are retrived then set the collection cells.
            guard imagesReadyArray.count > 0
                else {
                    cell.flickrImage.image = UIImage(named:"PlaceHolder.png")
                    return cell
            }
            if imagesReadyArray[indexPath.row] == true {
                cell.flickrImage.image = photos[indexPath.row]
                cell.activiy.stopAnimating()
            }
                
            else {
                cell.flickrImage.image = UIImage(named:"PlaceHolder.png")
            }
            
            return cell
    }
    
    /**
     When a cell is tapped remove it from the array, update the count
     */
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
            self.photos.removeAtIndex(indexPath.row)
            photoCount = photoCount - 1
            collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    /**
     Disable the button, wipe out the photos array, reload the table
     and start over.
     */
    @IBAction func newCollectionPress(sender: AnyObject) {
        newCollectionButton.enabled = false
        photoCount = 0
        updateActivity(true)
        imagesReadyArray = [false]
        photos = []
        reload()
        retrieveNewCollection()
    }
    
    /**
     Reloads the collection.
     */
    private func reload() {
        dispatch_async(dispatch_get_main_queue(),{
            self.collectionView.reloadData()
        })
    }
    
    /**
     Updates the label
     */
    private func updateLabel(text : String) {
        dispatch_async(dispatch_get_main_queue(),{
            self.noPhotoLabel.text = text
        })
    }
    
    /**
     Updates the activity view.
     */
    private func updateActivity(start : Bool) {
        dispatch_async(dispatch_get_main_queue(),{
            if start {
                self.activityView.startAnimating()
            }
            else {
                self.activityView.stopAnimating()
            }
        })
    }
    
    /**
     Creates and saves a photo into Core Data.
     - Parameters:
     - lat - the latitude of the pin
     - long - the longitude of the pin
     */
    func savePhoto(path: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let photoEntity = NSEntityDescription.entityForName("Photo",inManagedObjectContext: managedContext)
        let photo = NSManagedObject(entity: photoEntity!,insertIntoManagedObjectContext: managedContext)
        
        do {
            photo.setValue(path, forKey: "path")
            photo.setValue(pinRequest(managedContext), forKey: "pin")
            try managedContext.save()
        } catch let error as NSError  {
            showAlert("Could not save data. The photos were not saved.")
        }
    }
    
    func pinRequest(context : NSManagedObjectContext) -> AnyObject {
        
        let pinEntity = NSEntityDescription.entityForName("Pin",inManagedObjectContext: context)
        let request = NSFetchRequest()
        request.entity = pinEntity
        request.predicate = NSPredicate(format: "(id = %@)", receivedPinId)
        
        do {
            let results = try context.executeFetchRequest(request)
            return results[0]
            
        }
        catch {
            showAlert("Could not acces Core Data. Your photos were not saved")
            return []
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
