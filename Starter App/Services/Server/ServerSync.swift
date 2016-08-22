//
//  ServerSync.swift
//  Starter App
//
//  Created by ismails on 6/5/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import ObjectiveCloudant
import RealmSwift
import HealthKit

/// ServerSync.swift pulls down data from the server and stores it locally.
class ServerSync: NSObject {
    static let sharedInstance = ServerSync()
    
    /// database credentials
    let databaseName = "sensor_data"
    let databaseUrl = "https://859c612f-1dc8-48fe-98ff-b9cdc6a340e6-bluemix.cloudant.com"
    let dbUsername = "859c612f-1dc8-48fe-98ff-b9cdc6a340e6-bluemix"
    let dbPassword = "b65e1a73c02ac1fa23fe84255163ad176903ea1b63aac449882186e6bda16829"
    
    
    var cloudantClient: CDTCouchDBClient?
    var sensorDataDB: CDTDatabase?
    
    /// lastSyncTimestamp is used to determine when the app last synced. 
    /// This is used to fetch new records from the last synced timestamp.
    var lastSyncTimestamp: NSDate {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let date = defaults.objectForKey("lastSyncTimestamp") as? NSDate {
                return date
            }
            
            return NSDate(timeIntervalSince1970: 0)
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue, forKey: "lastSyncTimestamp")
        }
    }
    
    override init() {
        super.init()
        
        if let url = NSURL(string: databaseUrl) {
            cloudantClient = CDTCouchDBClient(forURL: url, username: dbUsername, password: dbPassword)
            sensorDataDB = cloudantClient?[databaseName]
        }
        
        self.fetchAllData_SinceLastSync_FromServer()
    }
    
    /**
     Fetches all data since last sync timestamp and store it to realm.
     */
    func fetchAllData_SinceLastSync_FromServer() {
        guard let sensorDataDB = sensorDataDB else { return }
        
        let findOperation = CDTQueryFindDocumentsOperation()
        
        findOperation.sort = [
            ["insertionDateInSeconds" : "asc"]
        ]
        
        findOperation.selector = [
            "insertionDateInSeconds": [
                "$gt" : lastSyncTimestamp.timeIntervalSince1970
            ]
        ]
        
        findOperation.findDocumentsCompletionBlock = {(bookmark, error) -> Void in
            if let _ = error {
                print("Failed to query database for documents: \(error)")
            } else {
                print("Query completed")
            }
        }
        
        findOperation.documentFoundBlock = {(document) -> Void in
            print("Found document \(document)")
            
//            let serverUUID = document["_id"] as! String
            let sourceName = document["sourceName"] as! String
            let healthObjType = document["healthObjType"] as! String
            let dateInSeconds = document["dateInSeconds"] as! Double
            let insertionDateInSeconds = document["insertionDateInSeconds"] as! Double
            
            if insertionDateInSeconds > self.lastSyncTimestamp.timeIntervalSince1970 {
                self.lastSyncTimestamp = NSDate(timeIntervalSince1970: insertionDateInSeconds)
            }
            
            let data = document["data"] as! [String:NSObject]
            
            
//            if let mapObject = ObjectIDMap.findMapObject(realmID: nil, healthkitUUID: nil, serverUUID: serverUUID) where mapObject.realmID != nil {
//                //dont do anything if object already exists
//            }
            
            if let _ = HealthData.find(usingSecondsSince1970: insertionDateInSeconds) {
                //dont do anything if object already exists
            } else {
               
                
                let date = NSDate(timeIntervalSince1970: dateInSeconds)
                
                do {
                    let healthObj = try HealthData.saveToRealmIfNeeded(healthObjType, date: date, source: sourceName, origin: .Server)
                    
                    for (key, value) in data {
                        try HealthDataValue.saveToRealm(key, value: String(value), healthObj: healthObj)
                    }
                    
//                    try ObjectIDMap.store(realmID: healthObj.id, healthkitUUID: nil, serverUUID: serverUUID)
                    
                    // if you wanted to store this data to healthkit, then uncomment this line
                    //try HealthKitSync.saveRealmData_ToHealthKit(withRealmID: weightHealthObj.id)
                } catch {
                    // do something with error
                }
            }
        }
        
        sensorDataDB.addOperation(findOperation)
    }
    
    /**
     Upload local realm data to server
     
     - parameter realmID: pull in the HealthData and HealthDataValue obj using the realmId and upload that data
     */
    func uploadData_ToServer(withRealmID realmID: String) {
        guard let sensorDataDB = sensorDataDB else { return }
        
        let realm = try! Realm()
        
        var documentBody: [String:NSObject] = [:]
        documentBody["insertionDateInSeconds"] = NSDate().timeIntervalSince1970
        
        //TODO: throw an exception here
        guard let healthObj = realm.objects(HealthData).filter("id == %@", realmID).first else { return }
        let healthDataObjArr = healthObj.dataObjects
        
        var dataDictionary: [String:String] = [:]
        for healthDataObj in healthDataObjArr {
            dataDictionary[healthDataObj.label!] = healthDataObj.value!
        }
        
        documentBody["healthObjType"] = healthObj.type
        documentBody["dateInSeconds"] = healthObj.date!.timeIntervalSince1970
        documentBody["data"] = dataDictionary
        documentBody["sourceName"] = healthObj.source!
        
        // throw an error here
        guard documentBody.count != 0 else { return }
        
        sensorDataDB.putDocumentWithId(NSUUID().UUIDString, body: documentBody, completionHandler: {
            (docId, revId, statusCode, operationError) -> Void in
            if let error = operationError {
                print("Encountered an error creating document. Error: \(error)")
            } else {
                print("Created document \(docId), at revision \(revId)")
                
                do {
//                    try ObjectIDMap.store(realmID: realmID, healthkitUUID: nil, serverUUID: docId)
                } catch {
                    //do something with error
                }
            }
        })
    }
}