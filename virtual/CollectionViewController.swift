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
    
    // MARK: - Outlets
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotoLabel: UILabel!
    
    // MARK: - Variables
    var receivedAnnotation : MKAnnotationView!
    var receivedPinId : String!
    
    // MARK: - Private
    private var appDelegate : AppDelegate!
    private var documentsPath : String!
    private var imagesReadyArray = [Bool!]()
    private var page = 1
    private var photos = [UIImage!]();
    private var photoCount = 0;
    private var managedContext : NSManagedObjectContext!
    private var managedPin : AnyObject!
    
    /**
     Perform setup processing. There are a few common variables that we
     want to set here.
     */
    override func viewDidLoad() {
        documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/"
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        managedPin = objectRetrieve(managedContext, objectid: receivedPinId, entity: "Pin")
        super.viewDidLoad()
    }
    
    /**
     Everytime this view appears we want to show the pin on the mapview as well
     as determine if we need to retrieve images (new pin) or load from Core Data.
     */
    override func viewDidAppear(animated: Bool) {
        
        // Setup the map.
        mapView.delegate = self
        setupMap()
        
        /**
        If the Pin the user clicked on has photos associated with it, load
        the photos that are stored, if not we need to retrieve new photos.
        We also update the UI.
        */
        if objectRetrieve(managedContext,
            objectid: receivedPinId,
            entity: "Pin").valueForKey("photo")?.count > 0 {
                
                retreiveStoredCollection(objectRetrieve(managedContext,
                    objectid: receivedPinId,
                    entity: "Pin") as! NSManagedObject)
                
                updateActivity(false)
        }
        else {
            retrieveNewCollection()
            updateActivity(true)
        }
        newCollectionButton.enabled = false;
        
    }
    
    /**
     This is a helper function that wraps the photo retrieval from Flickr.
     When a download is complete the collection is reloaded.
     */
    private func retrieveNewCollection() {
        getPhotos((receivedAnnotation.annotation?.coordinate.latitude)!,
            long: (receivedAnnotation.annotation?.coordinate.longitude)!) {
                (result) -> Void in
                self.reload()
        }
    }
    
    /**
     Retrieves the stored photos from the documents directory.
     - Parameters:
     - pin - the pin that was retrieved from the mapview.
     */
    private func retreiveStoredCollection(pin : NSManagedObject) {
        
        /**
        For each photo associated with the pin we need to set a true
        for the corresponding index in the image ready array.
        */
        for _ in (pin.valueForKey("photo")?.allObjects)! {
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
     This function will get and download the images from Flickr. The download
     is asyncronous so the completion is marked done everytime an image
     is completed. The collection will reload everytime the completion is
     true which is how we want the collection to react.
     - Parameters:
     - lat - the latitude for the search
     - long - the longitude for the search
     - completion - completion block for the image download
     - Returns: result - when true an image download has been completed.
     */
    private func getPhotos(
        lat : Double,
        long : Double,
        completion: (result: Bool) -> Void) {
            
            // Define a new photo ops object with the lat/long we want.
            let photoOps = PhotoNetworkOps(lat: lat, long: long)
            
            // Get the photos from Flickr.
            photoOps.getFlikrPhoto(page) { (result) -> Void in
                
                // If there was an error, print the message and abort.
                if photoOps.errorPresent() {
                    self.showAlert(photoOps.errorMessage())
                    self.updateActivity(false)
                    self.newCollectionButton.enabled = true
                    return
                }
                
                /**
                Set the photo count to the number of photos Flickr said there
                was for the location and reload the table to show place holder
                images.
                */
                self.photoCount = photoOps.urls().count
                self.reload()
                
                /**
                For each photo in the array we perform the following.
                1. Download the image
                2. Convert the image to NSData
                3. Write the file to the documents directory
                4. Set the image ready flag to true for that image
                5. Save the path to Core Data
                6. Mark the processing complete
                */
                for i in 0...self.photoCount - 1 {
                    self.imagesReadyArray.append(false)
                    photoOps.downloadImage(photoOps.urls()[i], completion: { (result) -> Void in
                        
                        // Convert the image to data for storage.
                        let imageData: NSData =
                        UIImageJPEGRepresentation(photoOps.flickrImage(), 1.0)!
                        
                        let filePath = self.documentsPath.stringByAppendingString(photoOps.fileName())
                        let success = imageData.writeToFile(filePath, atomically: true)
                        if !success {
                            self.showAlert("Could not save image. Your storage may be full. Free some space and try again.")
                            return
                        }
                        
                        self.imagesReadyArray[i] = true
                        self.savePhoto(photoOps.fileName())
                        completion(result: true)
                        
                        // If we have the right number of images enable the button.
                        if self.imagesReadyArray.count >= self.photoCount {
                            dispatch_async(dispatch_get_main_queue(),{
                                self.newCollectionButton.enabled = true
                            })
                        }
                    })
                }
                // Stop the activity spinner.
                self.updateActivity(false)
            }
    }
    
    /**
     Returns the number of cells in the collection.
     - Parameters:
     - collectionView - the collection view
     - numberOfItemsInSection - the number of items in the section
     - Returns: the number of containers
     */
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            noPhotoLabel.hidden = true
            checkCount()
            return photoCount
    }
    
    /**
     Returns the content of the cells.
     - Parameters:
     - collectionView - the collection view
     - cellForItemAtIndexPath - the given index path
     - Returns: the completed cell
     */
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            
            // Define a custom cell.
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
                "cell", forIndexPath: indexPath) as! FlickrCollectionViewCell
            
            // If the images are retrived then set the collection cells.
            guard imagesReadyArray.count > 0
                else {
                    cell.flickrImage.image = UIImage(named:"PlaceHolder.png")
                    return cell
            }
            
            let storedPathSet = managedPin.valueForKey("photo")?.valueForKey("path") as! NSSet
            
            // If the image has been downloaded for the given index set it,
            // if not keep the placeholder image.
            if imagesReadyArray[indexPath.row] == true &&
                storedPathSet.allObjects.count >= indexPath.row + 1 {
                
                let storedPathArray = storedPathSet.allObjects
                let filePath = documentsPath.stringByAppendingString(storedPathArray[indexPath.row] as! String)
                
                // Set the cell image and stop the activity.
                cell.flickrImage.image = UIImage(contentsOfFile: filePath)
                cell.activiy.stopAnimating()
            }
                
            else {
                cell.flickrImage.image = UIImage(named:"PlaceHolder.png")
            }
            
            return cell
    }
    
    /**
     This function in invoked when the user taps an image. We
     remove the object from the collection, update any Core Data objects,
     and delete any underlying files.
     - Parameters:
     - collectionView - the collection view
     - didSelectItemAtIndexPath - the selected container
     */
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
            do {
                // Retrieve all of the stored phots in the pin.
                let storedPhotos = managedPin.valueForKey("photo")?.allObjects
                let photoToRemove = Photo(path: NSURL(string: storedPhotos![indexPath.row].valueForKey("path") as! String)!)
                
                // Remove the photo from the documents directory.
                photoToRemove.deletePhoto()
                
                /**
                Attempt to remove the relationship in Core Data. If successful,
                remove the file from the documents directory. The order is
                important as we don't want to remove the document if Core Data
                bombs out for any reason.
                */
                managedContext.deleteObject(storedPhotos![indexPath.row] as! NSManagedObject)
                try managedContext.save()
                photoCount = photoCount - 1
                checkCount()
                if photoToRemove.isError() {
                    showAlert("Photo could not be removed.")
                }
                
            } catch {
                showAlert("Could not save data. The modification was not saved.")
                return
            }
            collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    /**
     Disable the button, zero out the count, start the activity view,
     mark all of the images not ready, reload the table and retrieve
     a new collection.
     - Parameters:
     - sender - the object that triggered the function
     */
    @IBAction func newCollectionPress(sender: AnyObject) {
        newCollectionButton.enabled = false
        photoCount = 0
        updateActivity(true)
        imagesReadyArray.removeAll()
        reload()
        page = page + 1
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
     Updates the label.
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
            if start {self.activityView.startAnimating()}
            else {self.activityView.stopAnimating()}
        })
    }
    
    /**
     Creates and saves a photo into Core Data.
     - Parameters:
     - path - the full path to the photo
     */
    private func savePhoto(path: String) {
        
        let photoEntity = NSEntityDescription.entityForName("Photo",inManagedObjectContext: managedContext)
        let photo = NSManagedObject(entity: photoEntity!,insertIntoManagedObjectContext: managedContext)
        
        // Set the vales of the new photo.
        do {
            let storedPin = objectRetrieve(managedContext, objectid: receivedPinId, entity: "Pin")
            
            photo.setValue(path, forKey: "path")
            photo.setValue(randomString(), forKey: "id")
            photo.setValue(storedPin, forKey: "pin")
            
            try managedContext.save()
            
        } catch {
            showAlert("Could not save data. The photos were not saved.")
            return
        }
    }
    
    /**
     This subprogram generates an alert for the user based upon conditions
     in the application. This view controller can generate two different
     alerts so this is here only for reuseability.
     */
    private func showAlert(message : String) {
        dispatch_async(dispatch_get_main_queue(),{
            let alertController = UIAlertController(title: "Error!", message:
                message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss",
                style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController,animated: true,completion: nil)
        })
    }
    
    /**
     Checks the count of the collection view and enables the new
     collection button.
     */
    private func checkCount() {
        if photoCount <= 0 {
            dispatch_async(dispatch_get_main_queue(),{
                self.noPhotoLabel.hidden = false
                self.updateLabel("No Photos!")
            })
        }
        self.newCollectionButton.enabled = true
    }
    
}
