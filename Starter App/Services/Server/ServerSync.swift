//
//  ServerSync.swift
//  Starter App
//
//  Created by ismails on 6/5/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import SwiftCloudant
import RealmSwift
import HealthKit

/// ServerSync.swift pulls down data from the server and stores it locally.
class ServerSync: NSObject {
    static let sharedInstance = ServerSync(dbName: "", dbURL: "", dbUsername: "", dbPassword: "")
    
    /// database credentials
    let databaseName: String
    let databaseUrl: String
    let dbUsername: String
    let dbPassword: String
    
    var cloudantClient: CouchDBClient?
    
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
    
    init(dbName: String, dbURL: String, dbUsername: String, dbPassword: String) {
        self.databaseName = dbName
        self.databaseUrl = dbURL
        self.dbUsername = dbUsername
        self.dbPassword = dbPassword
        
        super.init()
        
        if let url = URL(string: databaseUrl) {
            cloudantClient = CouchDBClient(url: url, username: dbUsername, password: dbPassword)
        }
        
        self.fetchAllData_SinceLastSync_FromServer()
    }
    
    /**
     Fetches all data since last sync timestamp and store it to realm.
     */
    func fetchAllData_SinceLastSync_FromServer() {
        let findOperationSelector = [ "insertionDateInSeconds": ["$gt": lastSyncTimestamp.timeIntervalSince1970]]
        
        let sortOptions = [Sort(field: "insertionDateInSeconds", sort: .asc)]
        
        let findOperation = FindDocumentsOperation(selector: findOperationSelector, databaseName: databaseName, sort: sortOptions,
                                                   documentFoundHandler: documentFoundHandler) { (response, httpInfo, error) in
            if let _ = error {
                print("Failed to query database for documents: \(error)")
            } else {
                print("Query completed")
            }
        }
        
        cloudantClient?.add(operation: findOperation)
    }
    
    func documentFoundHandler(document: [String : Any]) {
        print("Found document \(document)")
        
        //let serverUUID = document["_id"] as! String
        var sourceName = "unknown"
        if let docSourceName = document["sourceName"] as? String {
            sourceName = docSourceName
        }
        
        var healthObjType = "unknown"
        if let docHealthObjType = document["healthObjType"] as? String {
            healthObjType = docHealthObjType
        }
        
        var date = Date(timeIntervalSince1970: 0)
        if let docDateInSeconds = document["dateInSeconds"] as? Double {
            date =  Date(timeIntervalSince1970: docDateInSeconds)
        }
        
        var insertionDateInSeconds = 0.0
        if let docInsertionDateInSeconds = document["insertionDateInSeconds"] as? Double {
            insertionDateInSeconds = docInsertionDateInSeconds
        }
        
        var participantId = "-1"
        if let docParticipantId = document["participantId"] as? String {
            participantId = docParticipantId
        }
        
        let sessionId = document["participantId"] as? String
        
        if insertionDateInSeconds > self.lastSyncTimestamp.timeIntervalSince1970 {
            self.lastSyncTimestamp = Date(timeIntervalSince1970: insertionDateInSeconds)
        }
        
        guard let data = document["data"] as? [String:Any] else {
            // should probably throw an error here
            print("Something went wrong. Could not parse 'data' in document from cloudant db.")
            return
        }
        
        let compoundId = HealthData.generateCompoundId(date: date, participantId: participantId, source: sourceName, type: healthObjType)
        if let _ = HealthData.find(id: compoundId) {
            //dont do anything if object already exists
        } else {
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
    
    /**
     Upload local realm data to server
     
     - parameter realmID: pull in the HealthData and HealthDataValue obj using the realmId and upload that data
     */
    func uploadData_ToServer(withRealmID realmID: String) {
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
        let putOperation = PutDocumentOperation(id: UUID().uuidString, revision: nil, body: documentBody, databaseName: databaseName) { (response, httpInfo, operationError) in
            if let error = operationError {
                print("Encountered an error creating document. Error: \(error)")
            } else {
                print("Created document \(response)")
            }
        }
        
        cloudantClient?.add(operation: putOperation)
    }
}
