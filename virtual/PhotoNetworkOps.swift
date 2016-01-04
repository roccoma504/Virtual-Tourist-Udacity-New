//
//  PhotoNetworkOps.swift
//  virtual
//
//  Created by Matthew Rocco on 12/20/15.
//  Copyright © 2015 Matthew Rocco. All rights reserved.
//

import Foundation
import UIKit

class PhotoNetworkOps {
    
    //MARK: - Private
    private var filename : String!
    private var image : UIImage!
    private var lat : Double
    private var long : Double
    private var urlArray = [NSURL]()

    init(lat : Double, long : Double){
        self.lat = lat
        self.long = long
    }

    /**
     Retrieves the photos from Flickr.
     - Parameters:
     - page - the page at which we want to get photos for
     */
    func getFlikrPhoto(page : Int, completion: (result: Bool) -> Void) {
        
        // Defines the base URL and the arguments for the request.
        let BASE_URL = "https://api.flickr.com/services/rest/"
        
        let methodArguments = [
            "method": "flickr.photos.search",
            "api_key": KEY,
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1",
            "lat": String(lat),
            "lon": String(long),
            "page" : String(page),
            "per_page" : "6"
        ]
        
        // Defines the session, url, and request.
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            // Check if there is an error with the request.
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            // Check the status code and print it out.
            guard let statusCode = (
                response as? NSHTTPURLResponse)?.statusCode where
                statusCode >= 200 && statusCode <= 299 else {
                    if let response = response as? NSHTTPURLResponse {
                        print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                    } else if let response = response {
                        print("Your request returned an invalid response! Response: \(response)!")
                    } else {
                        print("Your request returned an invalid response!")
                    }
                    return
            }
            // Check if there is actually data.
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            var json : Dictionary<String, AnyObject>
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data,
                    options: .AllowFragments) as! Dictionary<String, AnyObject>
                
                // Check to see if the response is in the way we expect it to be.
                guard let photosDictionary = json["photos"] as? NSDictionary,
                    photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                        print("Cannot find keys 'photos' and 'photo' in \(json)")
                        return
                }
                
                if photoArray.count > 0 {
                    
                    for i in 0...(photoArray.count-1) {
                        let photoDictionary = photoArray[i] as [String: AnyObject]
                        
                        // Check to see if there is a url_m link.
                        guard let imageUrlString = photoDictionary["url_m"] as? String else {
                            print("Cannot find key 'url_m' in \(photoDictionary)")
                            return
                        }
                        
                        // If there is an image, update the url array
                        // and mark the completion. This will tell the view
                        // to add a placeholder image.
                        let imageURL = NSURL(string: imageUrlString)
                        if let _ = NSData(contentsOfURL: imageURL!) {
                            self.urlArray.append(imageURL!)
                            if i >= (photoArray.count - 1) {
                            completion(result: true)
                            }

                        } else {
                            print("Image does not exist at \(imageURL)")
                        }
                    }
                }
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
        }
        task.resume()
    }
    
    /**
     Downloads an image from a given URL.
     - Parameters:
     - url - URL where we want to download the image
     */
    func downloadImage(url: NSURL, completion: (result: Bool) -> Void)  {
        getDataFromUrl(url) { (data, response, error)  in
            guard let data = data where error == nil else { return }
            self.filename = response?.suggestedFilename ?? ""
            self.image = UIImage(data: data)!
            completion(result: true)
        }
    }
    
    /** Returns an array of NSURLs.
     - Returns: the array of urls
     */
    func urls() -> [NSURL] {
        return urlArray
    }
    
    /** Returns a Flickr image.
     - Returns: the current Flickr image
     */
    func flickrImage() -> UIImage {
        return image
    }
    
    /** Returns a filename .
     - Returns: the current Flickr image filename
     */
    func fileName() -> String {
        return filename
    }
    
    /** Returns a Flickr image.
     - Parameters:
     - url - URL where we want to download the image
     */
    private func getDataFromUrl(url:NSURL,
        completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    

    /** Converts a input dict to a usable string.
     - Parameters:
     - parameters: - the dictionary that needs to be escaped
     - Returns: the escaped string
     */
    private func escapedParameters(dictionary: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in dictionary {
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(
                NSCharacterSet.URLQueryAllowedCharacterSet())
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}
    