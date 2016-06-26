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

class ServerSync: NSObject {
    static let sharedInstance = ServerSync()
    
    let databaseName = "sensor_data"
    var cloudantClient: CDTCouchDBClient?
    var sensorDataDB: CDTDatabase?
    
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
        
        if let url = NSURL(string: "https://859c612f-1dc8-48fe-98ff-b9cdc6a340e6-bluemix.cloudant.com") {
            cloudantClient = CDTCouchDBClient(forURL: url, username: "859c612f-1dc8-48fe-98ff-b9cdc6a340e6-bluemix", password: "b65e1a73c02ac1fa23fe84255163ad176903ea1b63aac449882186e6bda16829")
            sensorDataDB = cloudantClient?[databaseName]
        }
        
        self.fetchAllData_SinceLastSync_FromServer()
    }
    
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
            
            let serverUUID = document["_id"] as! String
            let sourceName = document["sourceName"] as! String
            let healthObjType = document["healthObjType"] as! String
            let dateInSeconds = document["dateInSeconds"] as! Double
            let insertionDateInSeconds = document["insertionDateInSeconds"] as! Double
            
            if insertionDateInSeconds > self.lastSyncTimestamp.timeIntervalSince1970 {
                self.lastSyncTimestamp = NSDate(timeIntervalSince1970: insertionDateInSeconds)
            }
            
            let data = document["data"] as! [String:NSObject]
            
            if let mapObject = ObjectIDMap.findMapObject(realmID: nil, healthkitUUID: nil, serverUUID: serverUUID) where mapObject.realmID != nil {
                //dont do anything if object already exists
            } else {
                switch healthObjType {
                case String(Weight):
                    let weightValue = data["value"] as! Double
                    let date = NSDate(timeIntervalSince1970: dateInSeconds)
                    
                    do {
                        guard let realmObj = try Weight.saveToRealm(weightValue: weightValue, date: date, sourceName: sourceName) else { return }
                        try ObjectIDMap.store(realmID: realmObj.id, healthkitUUID: nil, serverUUID: serverUUID)
                        
                        try HealthKitSync.saveRealmData_ToHealthKit(withRealmID: realmObj.id)
                    } catch {
                        // do something with error
                    }
                    
                default:
                    break
                }
            }
        }
        
        sensorDataDB.addOperation(findOperation)
    }
    
    func uploadData_ToServer(withRealmID realmID: String, healthObjectType: String) {
        guard let sensorDataDB = sensorDataDB else { return }
        
        let realm = try! Realm()
        
        var documentBody: [String:NSObject] = [:]
        documentBody["insertionDateInSeconds"] = NSDate().timeIntervalSince1970
        
        switch healthObjectType {
        case String(Weight):
            guard let weightObj = realm.objects(Weight).filter("id == %@", realmID).first else { break }
            
            documentBody["healthObjType"] = String(Weight)
            documentBody["dateInSeconds"] = weightObj.date!.timeIntervalSince1970
            documentBody["data"] = ["value" : weightObj.value.value!]
            documentBody["sourceName"] = weightObj.source!
            
            
        default:
            break
        }
        
        // throw an error here
        guard documentBody.count != 0 else { return }
        
        sensorDataDB.putDocumentWithId(NSUUID().UUIDString, body: documentBody, completionHandler: {
            (docId, revId, statusCode, operationError) -> Void in
            if let error = operationError {
                print("Encountered an error creating document. Error: \(error)")
            } else {
                print("Created document \(docId), at revision \(revId)")
                
                do {
                    try ObjectIDMap.store(realmID: realmID, healthkitUUID: nil, serverUUID: docId)
                } catch {
                    //do something with error
                }
            }
        })
    }
}