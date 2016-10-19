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
    
    enum FileFormat: String {
        case None
        case HealthData
        case SessionMetadata
    }
    
    /**
     List of datasets (in csv format) that must be downloaded.
     */
    static let csvDataURLs: [String] = [
         "https://dl.dropboxusercontent.com/u/15940305/sample-health-data/participant-1/session-1/session1-metadata.csv"
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
        guard let dataNSArray = dataArrayWR, var dataArray = Array(dataNSArray) as? [[String]] else { return }
        
        let headers = dataArray[0]
        
        var format: FileFormat = .None
        
        if headers[0] == "participantId" && headers[1] == "sessionId" && headers[2] == "timestamp" {
            format = .HealthData
        } else if headers == ["id", "name", "desc", "startTime", "stopTime"] {
            format = .SessionMetadata
        }
        
        switch format {
        case .HealthData:
            parseHealthData(dataArray)
        case .SessionMetadata:
            parseSessionMetadata(dataArray)
        default:
            break
        }
        
        print("Done parsing CSV Contents")
        print("Deleting File")
        deleteFile(localPath)
    }
    
    private class func parseSessionMetadata(_ data: [[String]]) {
        //headers
        let headers = data[0]
        
        // drop the first row in the array, which is just headers
        let dataArray = Array(data.dropFirst())
        
        for rowData in dataArray {
            
            let id = rowData[0]
            let name = rowData[1]
            let description = rowData[2]
            
            var startTime = Date()
            if let startTimeUnix = Double(rowData[3]) {
                startTime = Date(timeIntervalSince1970: startTimeUnix)
            }
            
            var endTime = Date()
            if let endTimeUnix = Double(rowData[4]) {
                endTime = Date(timeIntervalSince1970: endTimeUnix)
            }
            
            do {
                try Session.saveToRealm(id, name: name, description: description, startTime: startTime, endTime: endTime)
            } catch {
                print(error)
            }
        }
        
    }
    
    private class func parseHealthData(_ data: [[String]]) {
        let headers = data[0]
        
        // drop the first row in the array, which is just headers
        let dataArray = Array(data.dropFirst())
        
        for rowData in dataArray {
            let participantId = rowData[0]
            let sessionId = rowData[1]
            
            guard let unixTimestamp = Double(rowData[2]) else { continue }
            let dateObj = Date(timeIntervalSince1970: unixTimestamp)
            
            for (index, itemInRow) in rowData.enumerated() {
                if index <= 2 {
                    continue
                }
                
                do {
                    let healthObj = try HealthData.saveToRealm(headers[index], date: dateObj, source: "csv", participantId: participantId, sessionId: sessionId) //, origin: .CSV)
                    let _ = try HealthDataValue.saveToRealm("value", value: itemInRow, healthObj: healthObj)
                } catch {
                    print(error)
                }
            }
        }
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
