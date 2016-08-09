//
//  DatasetManager.swift
//  Starter App
//
//  Created by ismails on 8/7/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import Alamofire

class CSVDatasetManager: NSObject {
    
    class func downloadAndStoreData() {
        
        //sample csv file for now
//        CSVDatasetManager.retrieveData("") { (success, data, error) -> (Void) in
//            guard success else {
//                print(error)
//                return
//            }
//            
//            print(data)
//            
//            //TODO: store data objects in realm
//        }
    }
    
    /**
     <#Description#>
     
     - parameter fileWebURL:   <#fileURL description#>
     - parameter completed: (success, array of records (Stored as dictionaries), error) -> (Void)
     */
    private class func retrieveData(fileWebURL: String, completed: (Bool, [[String: String]]?, NSError?) -> (Void)) {
        var localPath: NSURL?
        
        Alamofire.download(.GET, fileWebURL, destination: { (temporaryURL, response) in
            let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let pathComponent = response.suggestedFilename! + "-" + String(NSDate().timeIntervalSince1970)
            
            localPath = directoryURL.URLByAppendingPathComponent(pathComponent)
            return localPath!
        })
            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                print(totalBytesRead)
                
                // This closure is NOT called on the main queue for performance
                // reasons. To update your ui, dispatch to the main queue.
                dispatch_async(dispatch_get_main_queue()) {
                    print("Total bytes read on main queue: \(totalBytesRead)")
                }
            }
            .response { request, response, data, error in
                if let error = error {
                    print("Failed with error: \(error)")
                    completed(false, nil, error)
                    return
                }
                
                print("Downloaded file successfully. Parsing file now.")
                
                do {
                    
                    let fileContents = try String(contentsOfURL: localPath!)
                    //print(fileContents)
                    parseCSVContents(localPath!, csvData: fileContents)
                    completed(true, nil, nil)
                } catch {
                    print(error)
                    completed(false, nil, nil)
                    return
                }
                
        }
    }
    
    private class func parseCSVContents(localPath: NSURL, csvData: String)  {
        var dataArray = NSArray(contentsOfCSVURL: localPath)
        
        //first header/column should always be date or date-time
        guard let headers = dataArray[0] as? [String] else { return }
        
        // drop the first row in the array, which is just headers
        dataArray = Array(dataArray.dropFirst())
        
        let dateHeader = headers[0]
        
        if(dateHeader != "date" && dateHeader != "date-time") {
            return
        }
        
        for row in dataArray {
            guard let rowData = row as? [String] else { continue }
            
            let dateStr = rowData[0]
            let dateFormatter = NSDateFormatter()
            
            if dateHeader == "date" {
                dateFormatter.dateFormat = "MM/dd/yy"
            }
            
            guard let dateObj = dateFormatter.dateFromString(dateStr) else { continue }
            
            for (index, itemInRow) in rowData.enumerate() {
                if index == 0 {
                    continue
                }
                
                do {
                    let healthObj = try HealthObject.saveToRealm(headers[index], date: dateObj, source: "csv")
                    try HealthData.saveToRealm("value", value: itemInRow, healthObj: healthObj)
                } catch {
                    print(error)
                }
            }
        }
        
        print("Done parsing CSV Contents")
    }
    
}