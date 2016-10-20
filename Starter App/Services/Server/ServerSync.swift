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
    var lastSyncTimestamp: Date {
        get {
            let defaults = UserDefaults.standard
            if let date = defaults.object(forKey: "lastSyncTimestamp") as? Date {
                return date
            }
            
            return Date(timeIntervalSince1970: 0)
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: "lastSyncTimestamp")
        }
    }
    
    override init() {
        super.init()
        
        if let url = URL(string: databaseUrl) {
            cloudantClient = CDTCouchDBClient(for: url, username: dbUsername, password: dbPassword)
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
        
        let selector = [
            "$gt" : String(describing: lastSyncTimestamp.timeIntervalSince1970)
        ]
        
        findOperation.selector = [
            "insertionDateInSeconds": selector as NSObject
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
            
            let participantId = document["participantId"] as! String
            let sessionId = document["participantId"] as! String
            
            if insertionDateInSeconds > self.lastSyncTimestamp.timeIntervalSince1970 {
                self.lastSyncTimestamp = Date(timeIntervalSince1970: insertionDateInSeconds)
            }
            
            let data = document["data"] as! [String:NSObject]
            
            if let _ = HealthData.find(usingSecondsSince1970: insertionDateInSeconds, andType: healthObjType) {
                //dont do anything if object already exists
            } else {
               
                
                let date = Date(timeIntervalSince1970: dateInSeconds)
                
                do {
                    let healthObj = try HealthData.saveToRealm(healthObjType, date: date, source: sourceName, participantId: participantId, sessionId: sessionId) //, origin: .Server)
                    
                    for (key, value) in data {
                        let _ = try HealthDataValue.saveToRealm(key, value: String(describing: value), healthObj: healthObj)
                    }
                    
                    // if you wanted to store this data to healthkit, then uncomment this line
                    //try HealthKitSync.saveRealmData_ToHealthKit(withRealmID: weightHealthObj.id)
                } catch {
                    // do something with error
                }
            }
        }
        
        sensorDataDB.add(findOperation)
    }
    
    /**
     Upload local realm data to server
     
     - parameter realmID: pull in the HealthData and HealthDataValue obj using the realmId and upload that data
     */
    func uploadData_ToServer(withRealmID realmID: String) {
        guard let sensorDataDB = sensorDataDB else { return }
        
        let realm = try! Realm()
        
        var documentBody: [String:NSObject] = [:]
        documentBody["insertionDateInSeconds"] = Date().timeIntervalSince1970 as NSObject?
        
        //TODO: throw an exception here
        guard let healthObj = realm.objects(HealthData.self).filter("id == %@", realmID).first else { return }
        let healthDataObjArr = healthObj.dataObjects
        
        var dataDictionary: [String:String] = [:]
        for healthDataObj in healthDataObjArr {
            dataDictionary[healthDataObj.label!] = healthDataObj.value!
        }
        
        documentBody["healthObjType"] = healthObj.type as NSObject?
        documentBody["dateInSeconds"] = healthObj.date.timeIntervalSince1970 as NSObject?
        documentBody["data"] = dataDictionary as NSObject?
        documentBody["sourceName"] = healthObj.source as NSObject?
        documentBody["participantId"] = healthObj.participantId as NSObject?
        
        if let sessionId = healthObj.sessionId {
            documentBody["sessionId"] = sessionId as NSObject?
        }
        
        // throw an error here
        guard documentBody.count != 0 else { return }
        
        //TODO: check to see if a document with the same timestamp exists first
        
        sensorDataDB.putDocument(withId: UUID().uuidString, body: documentBody, completionHandler: {
            (docId, revId, statusCode, operationError) -> Void in
            if let error = operationError {
                print("Encountered an error creating document. Error: \(error)")
            } else {
                print("Created document \(docId), at revision \(revId)")
            }
        })
    }
}
