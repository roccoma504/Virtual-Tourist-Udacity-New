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
    
    private var lat : Double
    private var long : Double
    private var image : UIImage!
    
    private var urlArray = [NSURL]()
    
    private var filename : String!

    
    init(lat : Double, long : Double){
        self.lat = lat
        self.long = long
    }
    
    func getFlikrPhoto(completion: (result: Bool) -> Void) {
        
        let BASE_URL = "https://api.flickr.com/services/rest/"
        
        /* 2 - API method arguments */
        let methodArguments = [
            "method": "flickr.photos.search",
            "api_key": KEY,
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1",
            "lat": String(lat),
            "lon": String(long),
            "page" : "1",
            "per_page" : "3"
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        //print(urlString)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
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
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            var json : Dictionary<String, AnyObject>
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data,
                    options: .AllowFragments) as! Dictionary<String, AnyObject>
                
                /* GUARD: Are the "photos" and "photo" keys in our result? */
                guard let photosDictionary = json["photos"] as? NSDictionary,
                    photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                        print("Cannot find keys 'photos' and 'photo' in \(json)")
                        return
                }
                
                if photoArray.count > 0 {
                    
                    for i in 0...(photoArray.count-1) {
                        let photoDictionary = photoArray[i] as [String: AnyObject]
                        
                        /* GUARD: Does our photo have a key for 'url_m'? */
                        guard let imageUrlString = photoDictionary["url_m"] as? String else {
                            print("Cannot find key 'url_m' in \(photoDictionary)")
                            return
                        }
                        
                        /* 8 - If an image exists at the url, set the image and title */
                        let imageURL = NSURL(string: imageUrlString)
                        if let _ = NSData(contentsOfURL: imageURL!) {
                            print(imageURL)
                            self.urlArray.append(imageURL!)
                            if i >= (photoArray.count - 1) {
                            completion(result: true)
                            }

                        } else {
                            print("Image does not exist at \(imageURL)")
                        }
                    }
                }
                print("parsed right")
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
        }
        task.resume()
    }
    
    func downloadImage(url: NSURL, completion: (result: Bool) -> Void)  {
        print("Download Started")
        print("lastPathComponent: " + (url.lastPathComponent ?? ""))
        getDataFromUrl(url) { (data, response, error)  in
            guard let data = data where error == nil else { return }
            self.filename = response?.suggestedFilename ?? ""
            print(response?.suggestedFilename ?? "")
            print("Download Finished")
            self.image = UIImage(data: data)!
            completion(result: true)
        }
    }
    
    /** Returns an array of NSURLs.
     - Returns: The array of urls.
     */
    func urls() -> [NSURL] {
        return urlArray
    }
    
    func flickrImage() -> UIImage {
        return image
    }
    
    func fileName() -> String {
        return filename
    }
    
    
    private func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
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
    