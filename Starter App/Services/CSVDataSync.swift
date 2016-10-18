//
//  DatasetManager.swift
//  Starter App
//
//  Created by ismails on 8/7/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import CHCSVParser
import RealmSwift
import Alamofire


class CSVDataSync: NSObject {
    
    /**
     List of datasets (in csv format) that must be downloaded.
     */
    static let csvDataURLs: [String] = [
         "https://www.dropbox.com/s/36vlywzpxw2hixn/fitbit-minified.csv?dl=1"
    ]
    
    /**
     This will retrieve csv data from the list of URLs above.
     If the dataset has already been downloaded, it will not download it again. This is tracked through storing records of data downloads in Realm.
     */
    class func retrieveAllCSVData() {
        let realm = try! Realm()
        
        for url in csvDataURLs {
            let records = realm.objects(DataDownloadRecord.self).filter("url == %@", url)
            if records.count == 0 {
                CSVDataSync.downloadAndStoreData(url)
            }
        }
    }
    
    /**
     A helper function to download and store data from a url.
     
     - parameter url: url where the dataset must be downloaded from
     */
    fileprivate class func downloadAndStoreData(_ url: String) {
        //sample csv file for now
        CSVDataSync.retrieveData(url) { (success, data, error) -> (Void) in
            guard success else {
                print("error retrieving data for url: \(url). error: \(error)")
                return
            }
            
            do {
                let _ = try DataDownloadRecord.saveToRealm(url, date: Date())
            } catch {
                print(error)
            }
        }
    }
    
    /**
     A function to retrieve a dataset (in CSV format) from some URL, store it locally, and process it.
     
     - parameter fileWebURL:   url where the dataset must be downloaded from
     - parameter completed: (success, array of records (Stored as dictionaries), error) -> (Void)
     */
    fileprivate class func retrieveData(_ fileWebURL: String, completed: @escaping (Bool, [[String: String]]?, NSError?) -> (Void)) {
        

        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentsURL.appendPathComponent("data-\(String(NSDate().timeIntervalSince1970)).csv")
            
            return (documentsURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(fileWebURL, to: destination).response { response in
            print(response)
            
            if response.error == nil, let fileURL = response.destinationURL {
                parseCSVContents(fileURL)
            }
        }
    }
    
    /**
     Function to parse the contents of the csv file. The csv file must be in a specific format:
     ROW HEADERS:   date (or date-time)      healthObjTypeName1      healthObjTypeName2      and so on...
     
     This function will automatically store health objects and health data in Realm.
     
     - parameter localPath: the local path of where the csv file is stored
     */
    private class func parseCSVContents(_ localPath: URL)  {
        let dataArrayWR = NSArray(contentsOfCSVURL: localPath)

        //first header/column should always be date or date-time
        guard var dataArray = dataArrayWR, let headers = dataArray[0] as? [String] else { return }
        
        // drop the first row in the array, which is just headers
        dataArray = Array(dataArray.dropFirst()) as NSArray
        
        let dateHeader = headers[0]
        
        if(dateHeader != "date" && dateHeader != "date-time") {
            return
        }
        
        for row in dataArray {
            guard let rowData = row as? [String] else { continue }
            
            let dateStr = rowData[0]
            let dateFormatter = DateFormatter()
            
            if dateHeader == "date" {
                dateFormatter.dateFormat = "MM/dd/yy"
            }
            
            guard let dateObj = dateFormatter.date(from: dateStr) else { continue }
            
            for (index, itemInRow) in rowData.enumerated() {
                if index == 0 {
                    continue
                }
                
                do {
                    let healthObj = try HealthData.saveToRealm(headers[index], date: dateObj, source: "csv", origin: .CSV)
                    //                    let healthObj = try HealthData.saveToRealm(headers[index], date: dateObj, source: "csv")
                    let _ = try HealthDataValue.saveToRealm("value", value: itemInRow, healthObj: healthObj)
                    
                    //                    try ObjectIDMap.store(realmID: healthObj.id, healthkitUUID: nil, serverUUID: nil)
                } catch {
                    print(error)
                }
            }
        }
        
        print("Done parsing CSV Contents")
        print("Deleting File")
        deleteFile(localPath)
    }
    
    
    private class func deleteFile(_ fileURL: URL) {
        let fileManager = FileManager.default
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
}
